#' Get spatial objects of amenities
#'
#' @description
#' This function search amenities as defined by OpenStreetMap on a restricted
#' area defined by
#' a bounding box in the form of (<min_latitude>, <min_longitude>,
#' <max_latitude>, <max_longitude>).
#'
#' @inheritParams geo_amenity
#' @inheritParams geo_lite_sf
#'
#' @return A `sf` object with the results.
#'
#' @details
#'
#' Bounding boxes can be located using different online tools, as
#' [Bounding Box Tool](https://boundingbox.klokantech.com/).
#'
#' For a full list of valid amenities see
#' <https://wiki.openstreetmap.org/wiki/Key:amenity>.
#'
#' @family spatial
#' @family amenity
#'
#' @examplesIf nominatim_check_access()
#' \donttest{
#' # Madrid, Spain
#'
#' library(ggplot2)
#'
#' bbox <- c(
#'   -3.888954, 40.311977,
#'   -3.517916, 40.643729
#' )
#'
#' # Restaurants and pubs
#'
#' rest_pub <- geo_amenity_sf(bbox,
#'   c("restaurant", "pub"),
#'   limit = 50
#' )
#'
#'
#' ggplot(rest_pub) +
#'   geom_sf()
#'
#' # Hospital as polygon
#'
#' hosp <- geo_amenity_sf(bbox,
#'   "hospital",
#'   points_only = FALSE
#' )
#'
#' ggplot(hosp) +
#'   geom_sf()
#' }
#' @export
geo_amenity_sf <- function(bbox,
                           amenity,
                           limit = 1,
                           full_results = FALSE,
                           return_addresses = TRUE,
                           verbose = FALSE,
                           custom_query = list(),
                           points_only = TRUE,
                           strict = FALSE) {
  # nocov start

  if (limit > 50) {
    message(paste(
      "Nominatim provides 50 results as a maximum. ",
      "Your query may be incomplete"
    ))

    limit <- min(50, limit)
  }

  # nocov end

  # Loop
  all_res <- NULL

  for (i in seq_len(length(amenity))) {
    # Check if we have already launched the query
    if (amenity[i] %in% all_res$query) {
      if (verbose) {
        message(
          amenity[i],
          " already cached.\n",
          "Skipping download."
        )
      }

      res_single <- dplyr::filter(
        all_res,
        .data$query == amenity[i],
        .data$nmlite_first == 1
      )
      res_single$nmlite_first <- 0
    } else {
      res_single <- geo_amenity_sf_single(
        bbox = bbox,
        amenity = amenity[i],
        limit,
        full_results,
        return_addresses,
        verbose,
        custom_query,
        points_only
      )
      # Add index
      res_single <- dplyr::bind_cols(res_single, nmlite_first = 1)
    }

    all_res <- dplyr::bind_rows(all_res, res_single)
  }

  all_res <- dplyr::select(all_res, -.data$nmlite_first)

  if (strict) {
    bbox_sf <- bbox_to_poly(bbox)
    strict <- sf::st_covered_by(all_res, bbox_sf, sparse = FALSE)
    all_res <- all_res[strict, ]
  }

  return(all_res)
}



#' @noRd
#' @inheritParams geo_amenity_sf
geo_amenity_sf_single <- function(bbox,
                                  amenity,
                                  limit = 1,
                                  full_results = TRUE,
                                  return_addresses = TRUE,
                                  verbose = FALSE,
                                  custom_query = list(),
                                  points_only = TRUE) {
  bbox_txt <- paste0(bbox, collapse = ",")


  api <- "http://192.168.100.143:8080/search?"

  url <- paste0(
    api, "viewbox=",
    bbox_txt,
    "&q=[",
    amenity,
    "]&format=geojson&limit=", limit
  )

  if (full_results) {
    url <- paste0(url, "&addressdetails=1")
  }

  if (!isTRUE(points_only)) {
    url <- paste0(url, "&polygon_geojson=1")
  }

  if (length(custom_query) > 0) {
    opts <- NULL
    for (i in seq_len(length(custom_query))) {
      nlist <- names(custom_query)[i]
      val <- paste0(custom_query[[i]], collapse = ",")


      opts <- paste0(opts, "&", nlist, "=", val)
    }

    url <- paste0(url, opts)
  }

  if (!"bounded" %in% names(custom_query)) {
    url <- paste0(url, "&bounded=1")
  }

  # Download

  json <- tempfile(fileext = ".geojson")

  res <- api_call(url, json, isFALSE(verbose))

  # nocov start
  if (isFALSE(res)) {
    message(url, " not reachable.")
    result_out <- data.frame(query = amenity)
    return(invisible(result_out))
  }

  # nocov end

  sfobj <- sf::st_read(json,
    stringsAsFactors = FALSE,
    quiet = isFALSE(verbose)
  )


  # Check if null and return

  if (length(names(sfobj)) == 1) {
    message("No results for query ", amenity)
    result_out <- data.frame(query = amenity)
    return(invisible(result_out))
  }


  # Prepare output
  result_out <- data.frame(query = amenity)

  df_sf <- tibble::as_tibble(sf::st_drop_geometry(sfobj))

  # Rename original address

  names(df_sf) <-
    gsub("address", "osm.address", names(df_sf))

  names(df_sf) <- gsub("display_name", "address", names(df_sf))

  if (return_addresses || full_results) {
    disp_name <- df_sf["address"]
    result_out <- cbind(result_out, disp_name)
  }

  # If full
  if (full_results) {
    rest_cols <- df_sf[, !names(df_sf) %in% "address"]
    result_out <- cbind(result_out, rest_cols)
  }

  result_out <- sf::st_sf(result_out, geometry = sf::st_geometry(sfobj))
  return(result_out)
}

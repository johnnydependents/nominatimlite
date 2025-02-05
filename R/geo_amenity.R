#' Geocode amenities
#'
#' @description
#' This function search amenities as defined by OpenStreetMap on a restricted
#' area defined by
#' a bounding box in the form of (<min_latitude>, <min_longitude>,
#' <max_latitude>, <max_longitude>).
#'
#'
#' @param bbox A numeric vector of latitude and longitude (<min_latitude>,
#'   <min_longitude>, <max_latitude>, <max_longitude>) that restrict the search
#'   area. See Details.
#' @param amenity A character of a vector of character with the amenities to be
#'   geolocated (i.e. `c("pub", "restaurant")`). See Details or
#'   [nominatimlite::osm_amenities].
#' @param custom_query API-specific parameters to be used.
#'   See [nominatimlite::geo_lite()].
#' @param strict Logical TRUE/FALSE. Force the results to be included inside
#' the `bbox`. Note that Nominatim default behaviour may return results located
#' outside the provided bounding box.
#'
#' @inheritParams geo_lite
#'
#' @return A `tibble` with the results.
#'
#' @family amenity
#' @family geocoding
#' @details
#'
#' Bounding boxes can be located using different online tools, as
#' [Bounding Box Tool](https://boundingbox.klokantech.com/).
#'
#' For a full list of valid amenities see
#' <https://wiki.openstreetmap.org/wiki/Key:amenity>.
#'
#'
#' @examplesIf nominatim_check_access()
#' \donttest{
#' # Times Square, NY, USA
#' bbox <- c(
#'   -73.9894467311, 40.75573629,
#'   -73.9830630737, 40.75789245
#' )
#'
#' geo_amenity(
#'   bbox = bbox,
#'   amenity = "restaurant"
#' )
#'
#' # Several amenities
#' geo_amenity(
#'   bbox = bbox,
#'   amenity = c("restaurant", "pub")
#' )
#'
#' # Increase limit and use with strict
#' geo_amenity(
#'   bbox = bbox,
#'   amenity = c("restaurant", "pub"),
#'   limit = 10,
#'   strict = TRUE
#' )
#' }
#'
#' @export
geo_amenity <- function(bbox,
                        amenity,
                        lat = "lat",
                        long = "lon",
                        limit = 1,
                        full_results = FALSE,
                        return_addresses = TRUE,
                        verbose = FALSE,
                        custom_query = list(),
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
      res_single <- geo_amenity_single(
        bbox = bbox,
        amenity = amenity[i],
        lat,
        long,
        limit,
        full_results,
        return_addresses,
        verbose,
        custom_query
      )
      # Add index
      res_single <- dplyr::bind_cols(res_single, nmlite_first = 1)
    }

    all_res <- dplyr::bind_rows(all_res, res_single)
  }

  all_res <- dplyr::select(all_res, -.data$nmlite_first)

  if (strict) {
    strict <- all_res[lat] >= bbox[2] &
      all_res[lat] <= bbox[4] &
      all_res[long] >= bbox[1] &
      all_res[long] <= bbox[3]

    strict <- as.logical(strict)

    all_res <- all_res[strict, ]
  }



  return(all_res)
}



#' @noRd
#' @inheritParams geo_amenity
geo_amenity_single <- function(bbox,
                               amenity,
                               lat = "lat",
                               long = "lon",
                               limit = 1,
                               full_results = TRUE,
                               return_addresses = TRUE,
                               verbose = FALSE,
                               custom_query = list()) {
  bbox_txt <- paste0(bbox, collapse = ",")


  api <- "http://192.168.100.143:8080/search?"

  url <- paste0(
    api, "viewbox=",
    bbox_txt,
    "&q=[",
    amenity,
    "]&format=json&limit=", limit
  )

  if (full_results) {
    url <- paste0(url, "&addressdetails=1")
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

  json <- tempfile(fileext = ".json")



  res <- api_call(url, json, isFALSE(verbose))

  # nocov start
  if (isFALSE(res)) {
    message(url, " not reachable.")
    result_out <- tibble::tibble(query = amenity, a = NA, b = NA)
    names(result_out) <- c("query", lat, long)
    return(invisible(result_out))
  }
  # nocov end

  result <- tibble::as_tibble(jsonlite::fromJSON(json, flatten = TRUE))

  if (nrow(result) > 0) {
    result$lat <- as.double(result$lat)
    result$lon <- as.double(result$lon)
  }
  nmes <- names(result)
  nmes[nmes == "lat"] <- lat
  nmes[nmes == "lon"] <- long

  names(result) <- nmes

  if (nrow(result) == 0) {
    message("No results for query ", amenity)
    result_out <- tibble::tibble(query = amenity, a = NA, b = NA)
    names(result_out) <- c("query", lat, long)
    return(invisible(result_out))
  }

  # Rename
  names(result) <- gsub("address.", "", names(result))
  names(result) <- gsub("namedetails.", "", names(result))
  names(result) <- gsub("display_name", "address", names(result))


  # Prepare output
  result_out <- tibble::tibble(query = amenity)


  # Output
  result_out <- cbind(result_out, result[lat], result[long])

  if (return_addresses || full_results) {
    disp_name <- result["address"]
    result_out <- cbind(result_out, disp_name)
  }


  # If full
  if (full_results) {
    rest_cols <- result[, !names(result) %in% c(long, lat, "address")]
    result_out <- cbind(result_out, rest_cols)
  }

  result_out <- tibble::as_tibble(result_out)


  return(result_out)
}

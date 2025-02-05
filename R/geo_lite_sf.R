#' Get spatial objects through geocoding
#'
#' @description
#' This function allows you to geocode addresses and return the corresponding
#' spatial object.
#'
#' The parameter `points_only` specifies whether the function results will be
#' points (all Nominatim results are guaranteed to have at least point
#' geometry) or possibly other spatial objects.
#'
#' Note that the type of geometry returned in case of `points_only = FALSE`
#' will depend on the object being geocoded:
#'
#'   * administrative areas, major buildings and the like will be
#'     returned as polygons
#'   * rivers, roads and their like as lines
#'   * amenities may be points even in case of a `points_only = FALSE` call
#'
#' The function is vectorized, allowing for multiple addresses to be geocoded;
#' in case of `points_only = FALSE`  multiple geometry types may be returned.
#'
#' @param points_only Logical `TRUE/FALSE`. Whether to return only spatial
#' points (`TRUE`, which is the default) or potentially other shapes as
#' provided by the Nominatim API (`FALSE`).
#'
#' @inheritParams geo_lite
#'
#' @details
#' See <https://nominatim.org/release-docs/latest/api/Search/> for additional
#' parameters to be passed to `custom_query`.
#'
#' @return A `sf` object with the results.
#'
#' @examplesIf nominatim_check_access()
#' \donttest{
#' # Map - Points
#' library(ggplot2)
#'
#' string <- "Statue of Liberty, NY, USA"
#' sol <- geo_lite_sf(string)
#'
#' ggplot(sol) +
#'   geom_sf()
#'
#' sol_poly <- geo_lite_sf(string, points_only = FALSE)
#'
#' ggplot(sol_poly) +
#'   geom_sf() +
#'   geom_sf(data = sol, color = "red")
#'
#'
#' # Several results
#'
#' Madrid <- geo_lite_sf("Madrid",
#'   limit = 2,
#'   points_only = FALSE, full_results = TRUE
#' )
#'
#'
#' ggplot(Madrid) +
#'   geom_sf(fill = NA)
#'
#' Starbucks <- geo_lite_sf("Starbucks, New York",
#'   limit = 20, full_results = TRUE
#' )
#'
#'
#' ggplot(Starbucks) +
#'   geom_sf()
#' }
#' @export
#'
#' @seealso [geo_lite()]
#' @family spatial

geo_lite_sf <- function(address,
                        limit = 1,
                        return_addresses = TRUE,
                        full_results = FALSE,
                        verbose = FALSE,
                        custom_query = list(),
                        points_only = TRUE) {
  address_par <- address
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

  for (i in seq_len(length(address_par))) {
    # Check if we have already launched the query
    if (address_par[i] %in% all_res$query) {
      if (verbose) {
        message(
          address_par[i],
          " already cached.\n",
          "Skipping download."
        )
      }

      res_single <- dplyr::filter(
        all_res,
        .data$query == address_par[i],
        .data$nmlite_first == 1
      )
      res_single$nmlite_first <- 0
    } else {
      res_single <- geo_lite_sf_single(
        address = address_par[i],
        limit,
        return_addresses,
        full_results,
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

  return(all_res)
}

#' @noRd
#' @inheritParams geo_lite

geo_lite_sf_single <- function(address,
                               limit = 1,
                               return_addresses = TRUE,
                               full_results = FALSE,
                               verbose = FALSE,
                               custom_query = list(),
                               points_only = TRUE) {
  api <- "http://192.168.100.143:8080/search?q="

  # Replace spaces with +
  address2 <- gsub(" ", "+", address)

  # Compose url
  url <- paste0(api, address2, "&format=geojson&limit=", limit)

  if (!isTRUE(points_only)) {
    url <- paste0(url, "&polygon_geojson=1")
  }


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

    url <- paste0(url, "&", opts)
  }

  # Download

  json <- tempfile(fileext = ".geojson")

  res <- api_call(url, json, quiet = isFALSE(verbose))


  # nocov start

  if (isFALSE(res)) {
    message(url, " not reachable.")
    result_out <- data.frame(query = address)
    return(invisible(result_out))
  }
  # nocov end

  sfobj <- sf::st_read(json,
    stringsAsFactors = FALSE,
    quiet = isFALSE(verbose)
  )

  # Check if null and return

  if (length(names(sfobj)) == 1) {
    message("No results for query ", address)
    result_out <- data.frame(query = address)
    return(invisible(result_out))
  }

  # Prepare output

  result_out <- data.frame(query = address)

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

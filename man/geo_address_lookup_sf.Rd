% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geo_address_lookup_sf.R
\name{geo_address_lookup_sf}
\alias{geo_address_lookup_sf}
\title{Get spatial objects from OSM ids}
\usage{
geo_address_lookup_sf(
  osm_ids,
  type = c("N", "W", "R"),
  full_results = FALSE,
  return_addresses = TRUE,
  verbose = FALSE,
  custom_query = list(),
  points_only = TRUE
)
}
\arguments{
\item{osm_ids}{vector of OSM identifiers (\code{c(00000, 11111, 22222)}).}

\item{type}{vector of the type of the OSM type associated to each \code{osm_ids}.
Possible values are node ("N"), way ("W") or relation ("R"). If a single
value is provided it would be recycled.}

\item{full_results}{returns all available data from the geocoding service if TRUE.
If FALSE (default) then only latitude and longitude columns are returned from the geocoding service.}

\item{return_addresses}{return input addresses with results if TRUE. Note that
most services return the input addresses with \code{full_results = TRUE} and setting
return_addresses to FALSE does not prevent this.}

\item{verbose}{if TRUE then detailed logs are output to the console. FALSE is default. Can be set
permanently with \code{options(tidygeocoder.verbose = TRUE)}}

\item{custom_query}{API-specific parameters to be used, passed as a named
list (i.e. \code{list(countrycodes = "US")}). See Details.}

\item{points_only}{Logical \code{TRUE/FALSE}. Whether to return only spatial
points (\code{TRUE}, which is the default) or potentially other shapes as
provided by the Nominatim API (\code{FALSE}).}
}
\value{
A \code{sf} object with the results.
}
\description{
This function allows you to extract the spatial objects for specific
OSM objects.
}
\details{
See \url{https://nominatim.org/release-docs/latest/api/Search/} for additional
parameters to be passed to \code{custom_query}.
}
\examples{
\dontshow{if (nominatim_check_access()) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
\donttest{
# Notre Dame Cathedral, Paris

NotreDame <- geo_address_lookup_sf(
  osm_ids = c(201611261),
  type = c("W")
)

library(ggplot2)

ggplot(NotreDame) +
  geom_sf()

NotreDame_poly <- geo_address_lookup_sf(
  osm_ids = c(201611261),
  type = c("W"),
  points_only = FALSE
)

ggplot(NotreDame_poly) +
  geom_sf()
}
\dontshow{\}) # examplesIf}
}
\seealso{
Other spatial: 
\code{\link{bbox_to_poly}()},
\code{\link{geo_amenity_sf}()},
\code{\link{geo_lite_sf}()},
\code{\link{reverse_geo_lite_sf}()}

Other lookup: 
\code{\link{geo_address_lookup}()}
}
\concept{lookup}
\concept{spatial}

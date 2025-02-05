% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geo_amenity.R
\name{geo_amenity}
\alias{geo_amenity}
\title{Geocode amenities}
\usage{
geo_amenity(
  bbox,
  amenity,
  lat = "lat",
  long = "lon",
  limit = 1,
  full_results = FALSE,
  return_addresses = TRUE,
  verbose = FALSE,
  custom_query = list(),
  strict = FALSE
)
}
\arguments{
\item{bbox}{A numeric vector of latitude and longitude (<min_latitude>,
<min_longitude>, <max_latitude>, <max_longitude>) that restrict the search
area. See Details.}

\item{amenity}{A character of a vector of character with the amenities to be
geolocated (i.e. \code{c("pub", "restaurant")}). See Details or
\link{osm_amenities}.}

\item{lat}{latitude column name (i.e. \code{"lat"}).}

\item{long}{longitude column name (i.e. \code{"long"}).}

\item{limit}{maximum number of results to return per input address. Note
that each query returns a maximum of 50 results.}

\item{full_results}{returns all available data from the geocoding service if TRUE.
If FALSE (default) then only latitude and longitude columns are returned from the geocoding service.}

\item{return_addresses}{return input addresses with results if TRUE. Note that
most services return the input addresses with \code{full_results = TRUE} and setting
return_addresses to FALSE does not prevent this.}

\item{verbose}{if TRUE then detailed logs are output to the console. FALSE is default. Can be set
permanently with \code{options(tidygeocoder.verbose = TRUE)}}

\item{custom_query}{API-specific parameters to be used.
See \code{\link[=geo_lite]{geo_lite()}}.}

\item{strict}{Logical TRUE/FALSE. Force the results to be included inside
the \code{bbox}. Note that Nominatim default behaviour may return results located
outside the provided bounding box.}
}
\value{
A \code{tibble} with the results.
}
\description{
This function search amenities as defined by OpenStreetMap on a restricted
area defined by
a bounding box in the form of (<min_latitude>, <min_longitude>,
<max_latitude>, <max_longitude>).
}
\details{
Bounding boxes can be located using different online tools, as
\href{https://boundingbox.klokantech.com/}{Bounding Box Tool}.

For a full list of valid amenities see
\url{https://wiki.openstreetmap.org/wiki/Key:amenity}.
}
\examples{
\dontshow{if (nominatim_check_access()) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
\donttest{
# Times Square, NY, USA
bbox <- c(
  -73.9894467311, 40.75573629,
  -73.9830630737, 40.75789245
)

geo_amenity(
  bbox = bbox,
  amenity = "restaurant"
)

# Several amenities
geo_amenity(
  bbox = bbox,
  amenity = c("restaurant", "pub")
)

# Increase limit and use with strict
geo_amenity(
  bbox = bbox,
  amenity = c("restaurant", "pub"),
  limit = 10,
  strict = TRUE
)
}
\dontshow{\}) # examplesIf}
}
\seealso{
Other amenity: 
\code{\link{bbox_to_poly}()},
\code{\link{geo_amenity_sf}()},
\code{\link{osm_amenities}}

Other geocoding: 
\code{\link{geo_address_lookup}()},
\code{\link{geo_lite}()},
\code{\link{reverse_geo_lite}()}
}
\concept{amenity}
\concept{geocoding}

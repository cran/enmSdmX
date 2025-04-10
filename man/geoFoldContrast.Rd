% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geoFoldContrast.r
\name{geoFoldContrast}
\alias{geoFoldContrast}
\title{Assign geographically-distinct k-folds to background/absence sites}
\usage{
geoFoldContrast(
  contrast,
  pres,
  presFolds,
  contrastLongLat = 1:2,
  presLongLat = 1:2,
  ...
)
}
\arguments{
\item{contrast}{A "spatial points" object representing contrast sites:
\itemize{
    \item A \code{SpatVector} or \code{sf} vector with points
     \item A \code{data.frame} or \code{matrix}: Points will be assumed to have the WGS84 coordinate system (i.e., unprojected), and \code{contrastLongLat} should denote the columns with coordinates.
}}

\item{pres}{A "spatial points" object representing presence sites:
\itemize{
    \item A \code{SpatVector} or \code{sf} vector with points
     \item A \code{data.frame} or \code{matrix}: Points will be assumed to have the WGS84 coordinate system (i.e., unprojected), and \code{presLongLat} should denote the columns with coordinates.
}}

\item{presFolds}{Numeric vector: These provide the folds to which \code{pres} are assigned. There must be one value per point in \code{pres}.}

\item{contrastLongLat, presLongLat}{Character or integer vector: A character or integer vector specifying the columns in \code{contrast} and \code{pres} corresponding to longitude and latitude (in that order). The default is to assume that the first two columns in \code{contrast} represent coordinates. These are ignored if \code{contrast} or \code{pres} are a \code{SpatVector} or an \code{sf} object.}

\item{...}{Additional arguments (unused)}
}
\value{
A vector of integers the same length as the number of points in \code{contrast}. Each integer indicates which fold a point in \code{contrast} belongs to.
}
\description{
This function generates geographically-distinct cross-validation folds, or "geo-folds" of background or absence sites (i.e., "contrast" sites). Each contrast site is assigned to a fold based on the fold of the presence site that is closest. Typically, this function is run after \code{\link{geoFold}} is run to assign presences to folds.
}
\examples{
library(sf)
library(terra)

# lemur occurrence data
data(mad0)
data(lemurs)
crs <- getCRS('WGS84')
ll <- c('longitude', 'latitude')

# use occurrences of all species... easier to see on map
occs <- st_as_sf(lemurs, coords = ll, crs = getCRS('WGS84'))

# create 100 background points
mad0 <- vect(mad0)
bg <- spatSample(mad0, 100)

### assign 3 folds to occurrences and to background sites
k <- 3
minIn <- floor(nrow(occs) / k) # maximally spread between folds

presFolds <- geoFold(occs, k = k, minIn = minIn)
bgFolds <- geoFoldContrast(bg, pres = occs, presFolds = presFolds)

# number of sites per fold
table(presFolds)
table(bgFolds)

# map
plot(mad0, border = 'gray', main = paste(k, 'geo-folds'))
plot(bg, pch = 3, col = bgFolds + 1, add = TRUE)
plot(st_geometry(occs), pch = 20 + presFolds, bg = presFolds + 1, add = TRUE)

legend(
	'bottomright',
	legend = c(
		'presence fold 1',
		'presence fold 2',
		'presence fold 3',
		'background fold 1',
		'background fold 2',
		'background fold 3'
	),
	pch = c(21, 22, 23, 3, 3),
	col = c(rep('black', 3), 2, 3),
	pt.bg = c(2, 3, 4, NA, NA)
)
}
\seealso{
\code{\link{geoFold}}
}

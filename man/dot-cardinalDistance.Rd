% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bioticVelocity.r
\name{.cardinalDistance}
\alias{.cardinalDistance}
\title{Movement of occupied cells in a given direction of a fixed point}
\usage{
.cardinalDistance(
  direction,
  longOrLat,
  coordVect,
  x1,
  x2,
  refCoord,
  x1weightedLongs,
  x1weightedLats,
  x2weightedLongs,
  x2weightedLats,
  x1weightedElev = NULL,
  x2weightedElev = NULL
)
}
\arguments{
\item{direction}{Any of: \code{'n'} (north), \code{'s'} (south), \code{'e'} (east), or \code{'w'} (west).}

\item{longOrLat}{Numeric matrix, latitude or longitudes. If \code{direction} is \code{'n'} or \code{'s'} this must be latitudes. If \code{direction} is \code{'e'} or \code{'w'} this must be longitudes.}

\item{coordVect}{Vector of latitude or longitude of cell centers, depending on value of \code{longOrLat}. If latitude, these \emph{must} go from south to north. If \code{longitude}, these \emph{must} go from west to east.}

\item{x1}{Matrix of weights in time 1 (i.e., population size).}

\item{x2}{Matrix of weights in time 2 (i.e., population size).}

\item{refCoord}{Numeric, latitude or longitude (depending on \code{longOrLat}) of reference point from which to partition the weights into a northern, southern, eastern, or western portion.}

\item{x1weightedLongs}{Matrix of longitudes weighted (i.e., by population size, given by \code{x1}).}

\item{x1weightedLats}{Matrix of latitudes weighted (i.e., by population size, given by \code{x1}).}

\item{x2weightedLongs}{Matrix of longitudes weighted (i.e., by population size, given by \code{x2}).}

\item{x2weightedLats}{Matrix of latitudes weighted (i.e., by population size, given by \code{x2}).}

\item{x1weightedElev}{Matrix of elevations weighted by x1 or \code{NULL}.}

\item{x2weightedElev}{Matrix of elevations weighted by x2 or \code{NULL}.}
}
\value{
A list object with distance moved and abundance of all cells north/south/east/west of reference point.
}
\description{
This function calculates the weighted distance moved by a mass represented by set of cells which fall north, south, east, or west of a given location (i.e., typically the centroid of the starting population). Values >0 confer movement to the north, south, east, or west of this location.
}
\keyword{internal}

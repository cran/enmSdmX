#' Thin spatial points so that there is but one per raster cell
#'
#' This function thins spatial points such that no more than one point falls within each cell of a reference raster. If more than one point falls in a cell, the first point in the input data is retained unless the user specifies a priority for keeping points.
#'
#' @param x Points. This can be either a \code{data.frame}, \code{matrix}, \code{SpatVector}, or \code{sf} object.
#' @param rast \code{SpatRaster} object.
#' @param longLat Two-element character vector \emph{or} two-element integer vector. If \code{x} is a \code{data.frame}, then this should be a character vector specifying the names of the fields in \code{x} \emph{or} a two-element vector of integers that correspond to longitude and latitude (in that order). For example, \code{c('long', 'lat')} or \code{c(1, 2)}. If \code{x} is a \code{matrix}, then this is a two-element vector indicating the column numbers in \code{x} that represent longitude and latitude. For example, \code{c(1, 2)}. If \code{x} is an \code{sf} object then this is ignored.
#' @param priority Either \code{NULL}, in which case for every cell with more than one point the first point in \code{x} is chosen, or a numeric or character vector indicating preference for some points over others when points occur in the same cell. There should be the same number of elements in \code{priority} as there are points in \code{x}. Priority is assigned by the natural sort order of \code{priority}. For example, for 3 points in a cell for which \code{priority} is \code{c(2, 1, 3)}, the script will retain the second point and discard the rest. Similarly, if \code{priority} is \code{c('z', 'y', 'x')} then the third point will be chosen. Priorities assigned to points in other cells are ignored when thinning points in a particular cell.
#' @return Object of class \code{x}.
#' @examples
#'
#' \donttest{
#' # This example can take >10 second to run.
#'
#' library(terra)
#' x <- data.frame(
#'     long=c(-90.1, -90.1, -90.2, 20),
#'     lat=c(38, 38, 38, 38), point=letters[1:4]
#' )
#' rast <- rast() # empty raster covering entire world with 1-degree resolution
#' elimCellDuplicates(x, rast, longLat=c(1, 2))
#' elimCellDuplicates(x, rast, longLat=c(1, 2), priority=c(3, 2, 1, 0))
#'
#' }
#' @export
elimCellDuplicates <- function(
	x,
	rast,
	longLat = NULL,
	priority = NULL
) {

	# get coordinates
	if (inherits(x, 'SpatVector')) {
		xy <- terra::geom(x)[ , c('x', 'y'), drop=FALSE]
	} else if (inherits(x, 'sf')) {
		xy <- sf::st_coordinates(x)[ , c('X', 'Y'), drop=FALSE]
	} else {
		xy <- x[ , longLat, drop=FALSE]
	}
	
	xy <- as.matrix(xy)

	# get cell numbers for each point and adjoin with data frame
	cellNum <- terra::cellFromXY(rast, xy)

	# remember original row names
	index <- seq_along(xy)

	# define priority
	if (is.null(priority)) priority <- seq_along(xy)

	# index of points to remove
	removeThese <- integer()

	# remove redundant points in each cell
	uniCells <- unique(cellNum)
	for (thisCell in uniCells) {

		# if more than one point per cell
		if (sum(cellNum == thisCell) > 1) {

			thisRow <- index[thisCell == cellNum]
			thisPriority <- priority[thisCell == cellNum]

			thisRow <- thisRow[order(thisPriority)]
			removeThese <- c(removeThese, thisRow[2:length(thisRow)])

		}

	}

	# remove redundant points
	if (length(removeThese) > 0) x <- x[-removeThese, ]
	
	x

}

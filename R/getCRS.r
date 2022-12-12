#' WKT string for a named coordinate reference system or a spatial object
#'
#' Retrieve the Well-Known text string (WKT2) for a coordinate reference system (CRS) by name or from a spatial object. The most common usage of the function is to return the WKT2 string using an easy-to-remember name. For example, \code{getCRS('wgs84')} returns the WKT2 string for the WGS84 datum. To get a table of strings, just use \code{getsCRS()}.
#'
#' @param x This can be any of:
#' \itemize{
#'		\item Name of CRS: Each CRS has one "long" name and at least one "short" name, which appear in the table returned by \code{getCRS()}. You can use the "long" name of the CRS, or either of the two "short" names.  Spaces, case, and dashes are ignored, but to make the codes more memorable, they are shown as having them.
#' 		\item \code{NULL} (default): This returns a table of projections with their "long" and "short" names (nearly the same as \code{data(crss)}).
#'		\item An object of class \code{SpatVector}, \code{SpatRaster}, or \code{sf}. If this is a "\code{Spat}" object, then a character vector with the CRS in WKT form is returned. If a \code{sf} is supplied, then a \code{crs} object is returned in WKT format.
#' }
#'
#' @param warn If \code{TRUE} (default), then print a warning if the name of the CRS cannot be found.
#' @param nice If \code{TRUE}, then print the CRS in a formatted manner and return it invisible. Default is \code{FALSE}.
#'
#' @return A string representing WKT2 (well-known text) object or a \code{data.frame}.
#'
#' @examples
#'
#' # just WKT2 strings
#' getCRS('WGS84')
#' getCRS('Mollweide')
#' getCRS('WorldClim')
#'
#' # WKT2 strings nice for your eyes
#' getCRS('WGS84', TRUE)
#' 
#' data(mad0)
#' getCRS(mad0)
#'
#' @export

getCRS <- function(
	x = NULL,
	nice = FALSE,
	warn = TRUE
) {

	crss <- NULL
	utils::data('crss', envir=environment(), package='enmSdmX')
	
	# return table
	if (is.null(x)) {
		out <- crss[ , c('alias1', 'alias2', 'alias3', 'region', 'projected', 'peojGeometry', 'datum', 'type', 'notes')]
	} else if (inherits(x, c('SpatVector', 'SpatRaster'))) {
		out <- terra::crs(x)
	} else if (inherits(x, 'sf')) {
		out <- sf::st_crs(x)
	} else {
	# return WKT2

		x <- tolower(x)
		x <- gsub(x, pattern=' ', replacement='')
		x <- gsub(x, pattern='-', replacement='')
		
		alias1 <- crss$alias1
		alias2 <- crss$alias2
		alias3 <- crss$alias3
		
		alias1 <- tolower(alias1)
		alias2 <- tolower(alias2)
		alias3 <- tolower(alias3)
		
		alias1 <- gsub(alias1, pattern=' ', replacement='')
		alias2 <- gsub(alias2, pattern=' ', replacement='')
		alias3 <- gsub(alias3, pattern=' ', replacement='')
		
		alias1 <- gsub(alias1, pattern='-', replacement='')
		alias2 <- gsub(alias2, pattern='-', replacement='')
		alias3 <- gsub(alias3, pattern='-', replacement='')
		
		this <- which(x == alias1)
		if (length(this) == 0L) this <- which(x == alias2)
		if (length(this) == 0L) this <- which(x == alias3)
		if (length(this) != 0L) {
			out <- crss$wkt2[this]
		} else {
			out <- NA
			if (warn) warning('CRS name cannot be found. It must match one of "long", "short1", or "short2" in the table retuned by data(crss).')
		}
		
	}

	if (nice & !is.null(x)) {
		cat(out)
		utils::flush.console()
		invisible(out)
	} else {
		out
	}

}

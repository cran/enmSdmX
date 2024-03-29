#' @name mad0
#'
#' @title Madagascar spatial object
#'
#' @description Outline of Madagascar from GADM.  The geometry has been simplified from the version available in GADM, so pleased do not use this for "official" analyses.
#'
#' @docType data
#'
#' @usage data(mad0, package='enmSdmX')
#'
#' @format An object of class \code{sf}.
#'
#' @keywords Madagascar
#'
#' @source \href{https://gadm.org}{GADM}
#' 
#' @examples
#'
#' library(sf)
#' data(mad0)
#' mad0
#' plot(st_geometry(mad0), main='Madagascar')
#'
NULL

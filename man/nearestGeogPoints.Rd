% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nearestGeogPoints.r
\name{nearestGeogPoints}
\alias{nearestGeogPoints}
\title{Minimum convex polygon from a set of spatial polygons and/or points}
\usage{
nearestGeogPoints(
  pts = NULL,
  polys = NULL,
  centerFrom = "pts",
  return = "mcp",
  terra = TRUE
)
}
\arguments{
\item{pts}{Either \code{NULL} (default) or a set of spatial points. This can be either a \code{SpatVector} (\code{terra} package) or \code{POINTS} or \code{MULTIPOINTS} \code{sf} object (\code{sf} package). \emph{These must be in an equal-area projection!} This can also be a \code{Spatial} object (e.g., \code{SpatialPoints} or \code{SpatialPointsDataFrame}) from the \pkg{sp} package, but \emph{the \code{sp} package will be deprecated in 2023}.}

\item{polys}{Either \code{NULL} (default), or an object representing spatial polygons of (for example) counties in which a species is known to reside. \emph{This must be in an equal-area projection!}. This object can be either a \code{SpatVector} (\pkg{terra} package)), or \code{POLYGON}, \code{MULTIPOLYGON}, \code{LINESTRING}, or \code{MULTILINESTRING} \code{sf} object (\pkg{sf} package). This can also be a \code{Spatial} object (e.g., \code{SpatialPolygons} or \code{SpatialPolygonsDataFrame}) from the \pkg{sp} package, \emph{the \code{sp} package will be deprecated in 2023}.}

\item{centerFrom}{Indicates how to locate the "reference" centroid used to identify points on each polygon. This is only relevant if both \code{pts} and \code{polys} are not \code{NULL}.
\itemize{
    \item \code{'pts'}: The default is to use the centroid of \code{pts}, which finds the centroid of \code{pts}, then finds the location on the border of each polygon closest to this centroid.
    \item \code{'polys'}: This option will first calculate the centroid of each polygon, then the centroid of these points, and then find the location on the border of each polygon closest to this point.
    \item \code{'both'}: This option first calculates the centroid of each polygon, then finds the joint centroid of these points plus of \code{pts}, and lastly locates on the border of each polygon the point closest to this grand centroid.
}}

\item{return}{Determines what is returned:
\itemize{
        \item \code{'mcp'} (default): The minimum convex polygon
    \item \code{'mcpPoints'}: Points of the vertices of the minimum convex polygon
    \item \code{'polyPoints'}: The point on each \code{poly} polygon closest to the given center
}}

\item{terra}{If \code{TRUE} (default), the return an object of class \code{SpatVector}. Otherwise, return an object of class \code{sf}.}
}
\value{
\code{SpatVector}, or \code{sf POLYGON} representing a minimum convex polygon.
}
\description{
This function implements the "nearest geographic point" method (Smith et al. 2023) to enable the use of occurrence records geolocated only to a general place (e.g., a country or province), along with occurrences georeferenced with little error. The function returns a minimum convex polygon (MCP) constructed from a set of spatial polygons and/or points.
}
\details{
This function constructs a minimum convex polygon (MCP) from a set of spatial points and/or spatial polygons. The manner in which this is done depends on whether \code{polys} and/or \code{pts} are specified:
\itemize{
\item Only \code{pts} is supplied: The MCP is constructed directly from the points.
\item Only \code{polys} is supplied: The MCP is constructed from the point on each polygon closest to the centroid of the centroids of the polygons.
\item Both \code{pts} and \code{polys} are supplied: The MCP is constructed from the combined set of \code{pts} \emph{and} from the point on each polygon closest to the centroid of \code{pts}. By default, the function uses the centroid of the precise occurrences in step (1), but this can be changed to the centroid of the centroids of the polygons or the centroid of the points defined by the union of precise occurrence points plus the centroids of the polygons.
}

The function can alternatively return the points on the vertices of the MCP, or points on the input polygons closest to the reference centroid.
}
\examples{

library(sf)
library(terra)

#######################################################
### example using SpatVector inputs (terra package) ###
#######################################################

### prepare data
################

# Get coordinate reference systems:
# * WGS84
# * Tananarive (Paris) / Laborde Grid - EPSG:29701
wgs84 <- getCRS('WGS84')
madProj <- getCRS('Madagascar Albers')

# outline of Madagascar faritras
data(mad1)
mad1 <- vect(mad1)
mad1 <- project(mad1, madProj)

# lemur point data
data(lemurs)
redBelly <- lemurs[lemurs$species == 'Eulemur rubriventer', ]
ll <- c('longitude', 'latitude')
redBelly <- vect(redBelly, geom=ll, crs=wgs84)
redBelly <- project(redBelly, madProj)

# *fake* lemur farita-level data
faritras <- c('Toamasina', 'Atsimo-Atsinana',
'Amoron\'i mania', 'Sava', 'Itasy')
polys <- mad1[mad1$NAME_2 \%in\% faritras, ]

### apply Nearest Geographic Point method
#########################################

# get three kinds of minimum convex polygons (MCPs):

# MCP using just polygons
mcpPolys <- nearestGeogPoints(polys = polys)

# MCP using just points
mcpPts <- nearestGeogPoints(pts = redBelly)

# MCP using points & polys
mcpPolysPoints <- nearestGeogPoints(pts = redBelly, polys = polys)

# compare extent of occurrence (EOO) in m2
expanse(mcpPolys)
expanse(mcpPts)
expanse(mcpPolysPoints)

### plot minimum convex polygons
################################

# MCP from precise occurrences only
plot(mad1, border='gray', main='MCP points only')
plot(polys, col='gray80', add=TRUE)
plot(mcpPts, col=scales::alpha('red', 0.4), add=TRUE)
plot(redBelly, pch=21, bg='red', add=TRUE)

legend('topleft', 
legend=c('Precise occurrence', 'Imprecise occurrence', 'MCP'),
fill=c(NA, 'gray', scales::alpha('red', 0.4)),
pch=c(21, NA, NA),
pt.bg=c('red', NA, NA),
border=c(NA, 'black', 'black'))

# MCP from imprecise occurrences only
plot(mad1, border='gray', main='MCP polys only')
plot(polys, col='gray80', add=TRUE)
plot(mcpPolys, col=scales::alpha('orange', 0.4), add=TRUE)
plot(redBelly, pch=21, bg='red', add=TRUE)

legend('topleft', 
legend=c('Precise occurrence', 'Imprecise occurrence', 'MCP'),
fill=c(NA, 'gray', scales::alpha('orange', 0.4)),
pch=c(21, NA, NA),
pt.bg=c('red', NA, NA),
border=c(NA, 'black', 'black'))

# MCP from precise and imprecise occurrences
plot(mad1, border='gray', main='MCP polys + points')
plot(polys, col='gray80', add=TRUE)
plot(mcpPolysPoints, col=scales::alpha('green', 0.4), add=TRUE)
plot(redBelly, pch=21, bg='red', add=TRUE)

legend('topleft', 
legend=c('Precise occurrence', 'Imprecise occurrence', 'MCP'),
fill=c(NA, 'gray', scales::alpha('green', 0.4)),
pch=c(21, NA, NA),
pt.bg=c('red', NA, NA),
border=c(NA, 'black', 'black'))

############################################
### example using sf inputs (sf package) ###
############################################

### prepare data
################

# Get coordinate reference systems:
# * WGS84
# * Tananarive (Paris) / Laborde Grid - EPSG:29701
madProj <- sf::st_crs(getCRS('Madagascar Albers'))
wgs84 <- getCRS('WGS84')

# outline of Madagascar faritras
data(mad1)
mad1 <- sf::st_transform(mad1, madProj)

# lemur point occurrence data
data(lemurs)
redBelly <- lemurs[lemurs$species == 'Eulemur rubriventer', ]
ll <- c('longitude', 'latitude')
redBelly <- sf::st_as_sf(redBelly[ , ll], crs=wgs84, coords=ll)
redBelly <- sf::st_transform(redBelly, madProj)

# *fake* farita-level occurrences
faritras <- c('Toamasina', 'Atsimo-Atsinana',
'Amoron\'i mania', 'Sava', 'Itasy')
polys <- mad1[mad1$NAME_2 \%in\% faritras, ]

### apply Nearest Geographic Point method
#########################################

# get three kinds of minimum convex polygons (MCPs):

# MCP using just polygons
mcpPolys <- nearestGeogPoints(polys = polys, terra = FALSE)

# MCP using just points
mcpPts <- nearestGeogPoints(pts = redBelly, terra = FALSE)

# MCP using points & polys
mcpPolysPoints <- nearestGeogPoints(pts = redBelly, polys = polys,
terra = FALSE)

# extent of occurrence (EOO) in m2
sf::st_area(mcpPolys)
sf::st_area(mcpPts)
sf::st_area(mcpPolysPoints)

### plot minimum convex polygons
################################

# MCP from precise occurrences only
plot(st_geometry(mad1), border='gray', main='MCP points only')
plot(st_geometry(polys), col='gray80', add=TRUE)
plot(st_geometry(mcpPts), col=scales::alpha('red', 0.4), add=TRUE)
plot(st_geometry(redBelly), pch=21, bg='red', add=TRUE)

legend('topleft', 
legend=c('Precise occurrence', 'Imprecise occurrence', 'MCP'),
fill=c(NA, 'gray', scales::alpha('red', 0.4)),
pch=c(21, NA, NA),
pt.bg=c('red', NA, NA),
border=c(NA, 'black', 'black'))

# MCP from imprecise occurrences only
plot(st_geometry(mad1), border='gray', main='MCP points only')
plot(st_geometry(polys), col='gray80', add=TRUE)
plot(st_geometry(mcpPolys), col=scales::alpha('orange', 0.4), add=TRUE)
plot(st_geometry(redBelly), pch=21, bg='red', add=TRUE)

legend('topleft', 
legend=c('Precise occurrence', 'Imprecise occurrence', 'MCP'),
fill=c(NA, 'gray', scales::alpha('orange', 0.4)),
pch=c(21, NA, NA),
pt.bg=c('red', NA, NA),
border=c(NA, 'black', 'black'))

# MCP from precise and imprecise occurrences
plot(st_geometry(mad1), border='gray', main='MCP points only')
plot(st_geometry(polys), col='gray80', add=TRUE)
plot(st_geometry(mcpPolysPoints), col=scales::alpha('green', 0.4), add=TRUE)
plot(st_geometry(redBelly), pch=21, bg='red', add=TRUE)

legend('topleft', 
legend=c('Precise occurrence', 'Imprecise occurrence', 'MCP'),
fill=c(NA, 'gray', scales::alpha('green', 0.4)),
pch=c(21, NA, NA),
pt.bg=c('red', NA, NA),
border=c(NA, 'black', 'black'))

### NOTE
# Using SpatVector input (terra package) yields EOOs that are slightly
# larger than using Spatial* (sp) or sf (sf) objects (by about 0.03-0.07\%
# in this example). The difference arises because terra::expanse() yields a
# different value than sf::st_area.
}
\references{
Smith, A.B., Murphy, S.J., Henderson, D., and Erickson, K.D. 2023. Including imprecisely georeferenced specimens improves accuracy of species distribution models and estimates of niche breadth.  \emph{Global Ecology and Biogeography} 32:342-355. \doi{https://doi.org/10.1111/geb.13628} Open access pre-print: \doi{10.1101/2021.06.10.447988}.
}
\seealso{
\code{\link{nearestEnvPoints}} for the "nearest environmental point" method, a related application for estimating niche breadth in environmental space.
}

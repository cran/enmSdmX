\donttest{

# NB: The examples below show a very basic modeling workflow. They have been 
# designed to work fast, not produce accurate, defensible models. They can
# take a few minutes to run.

library(mgcv)
library(sf)
library(terra)
set.seed(123)

### setup data
##############

# environmental rasters
rastFile <- system.file('extdata/madClim.tif', package='enmSdmX')
madClim <- rast(rastFile)

# coordinate reference system
wgs84 <- getCRS('WGS84')

# lemur occurrence data
data(lemurs)
occs <- lemurs[lemurs$species == 'Eulemur fulvus', ]
occs <- vect(occs, geom=c('longitude', 'latitude'), crs=wgs84)

occs <- elimCellDuplicates(occs, madClim)

occEnv <- extract(madClim, occs, ID = FALSE)
occEnv <- occEnv[complete.cases(occEnv), ]
	
# create 10000 background sites (or as many as raster can support)
bgEnv <- terra::spatSample(madClim, 20000)
bgEnv <- bgEnv[complete.cases(bgEnv), ]
bgEnv <- bgEnv[1:min(10000, nrow(bgEnv)), ]

# collate occurrences and background sites
presBg <- data.frame(
  presBg = c(
    rep(1, nrow(occEnv)),
    rep(0, nrow(bgEnv))
  )
)

env <- rbind(occEnv, bgEnv)
env <- cbind(presBg, env)

predictors <- c('bio1', 'bio12')

### calibrate models
####################

# Note that all of the trainXYZ functions can made to go faster using the
# "cores" argument (set to just 1, by default). The examples below will not
# go too much faster using more cores because they are simplified, but
# you can try!
cores <- 1

# MaxEnt
mx <- trainMaxEnt(
	data = env,
	resp = 'presBg',
	preds = predictors,
	regMult = 1, # too few values for reliable model, but fast
	verbose = TRUE,
	cores = cores
)

# MaxNet
mn <- trainMaxNet(
	data = env,
	resp = 'presBg',
	preds = predictors,
	regMult = 1, # too few values for reliable model, but fast
	verbose = TRUE,
	cores = cores
)

# generalized linear model (GLM)
gl <- trainGLM(
	data = env,
	resp = 'presBg',
	preds = predictors,
	scale = TRUE, # automatic scaling of predictors
	verbose = TRUE,
	cores = cores
)

# generalized additive model (GAM)
ga <- trainGAM(
	data = env,
	resp = 'presBg',
	preds = predictors,
	verbose = TRUE,
	cores = cores
)

# natural splines
ns <- trainNS(
	data = env,
	resp = 'presBg',
	preds = predictors,
	scale = TRUE, # automatic scaling of predictors
	df = 1:2, # too few values for reliable model(?)
	verbose = TRUE,
	cores = cores
)

# boosted regression trees
envSub <- env[1:1049, ] # subsetting data to run faster
brt <- trainBRT(
	data = envSub,
	resp = 'presBg',
	preds = predictors,
	learningRate = 0.001, # too few values for reliable model(?)
	treeComplexity = c(2, 3), # too few values for reliable model, but fast
	minTrees = 1200, # minimum trees for reliable model(?), but fast
	maxTrees = 1200, # too small for reliable model(?), but fast
	tryBy = 'treeComplexity',
	anyway = TRUE, # return models that did not converge
	verbose = TRUE,
	cores = cores
)

# random forests
rf <- trainRF(
	data = env,
	resp = 'presBg',
	preds = predictors,
	numTrees = c(100, 500), # using at least 500 recommended, but fast!
	verbose = TRUE,
	cores = cores
)

### make maps of models
#######################

# NB We do not have to scale rasters before predicting GLMs and NSs because we
# used the `scale = TRUE` argument in trainGLM() and trainNS().

mxMap <- predictEnmSdm(mx, madClim)
mnMap <- predictEnmSdm(mn, madClim) 
glMap <- predictEnmSdm(gl, madClim)
gaMap <- predictEnmSdm(ga, madClim)
nsMap <- predictEnmSdm(ns, madClim)
brtMap <- predictEnmSdm(brt, madClim)
rfMap <- predictEnmSdm(rf, madClim)

maps <- c(
	mxMap,
	mnMap,
	glMap,
	gaMap,
	nsMap,
	brtMap,
	rfMap
)

names(maps) <- c('MaxEnt', 'MaxNet', 'GLM', 'GAM', 'NSs', 'BRTs', 'RFs')
fun <- function() plot(occs, col='black', pch=3, add=TRUE)
plot(maps, fun = fun, nc = 4)

### compare model responses to BIO12 (mean annual precipitation)
################################################################

# make a data frame holding all other variables at mean across occurrences,
# varying only BIO12
occEnvMeans <- colMeans(occEnv, na.rm=TRUE)
occEnvMeans <- rbind(occEnvMeans)
occEnvMeans <- as.data.frame(occEnvMeans)
climFrame <- occEnvMeans[rep(1, 100), ]
rownames(climFrame) <- NULL

minBio12 <- min(env$bio12)
maxBio12 <- max(env$bio12)
climFrame$bio12 <- seq(minBio12, maxBio12, length.out=100)

predMx <- predictEnmSdm(mx, climFrame)
predMn <- predictEnmSdm(mn, climFrame)
predGl <- predictEnmSdm(gl, climFrame)
predGa <- predictEnmSdm(ga, climFrame)
predNat <- predictEnmSdm(ns, climFrame)
predBrt <- predictEnmSdm(brt, climFrame)
predRf <- predictEnmSdm(rf, climFrame)


plot(climFrame$bio12, predMx,
xlab='BIO12', ylab='Prediction', type='l', ylim=c(0, 1))

lines(climFrame$bio12, predMn, lty='solid', col='red')
lines(climFrame$bio12, predGl, lty='dotted', col='blue')
lines(climFrame$bio12, predGa, lty='dashed', col='green')
lines(climFrame$bio12, predNat, lty=4, col='purple')
lines(climFrame$bio12, predBrt, lty=5, col='orange')
lines(climFrame$bio12, predRf, lty=6, col='cyan')

legend(
   'topleft',
   inset = 0.01,
   legend = c(
	'MaxEnt',
	'MaxNet',
	'GLM',
	'GAM',
	'NS',
	'BRT',
	'RF'
   ),
   lty = c(1, 1:6),
   col = c(
	'black',
	'red',
	'blue',
	'green',
	'purple',
	'orange',
	'cyan'
   ),
   bg = 'white'
)

### compare response curves ###
###############################

modelNames <- c('MaxEnt', 'MaxNet', 'GLM', 'GAM', 'NS', 'BRT', 'RF')

responses <- responseCurves(
	models = list(mx, mn, gl, ga, ns, brt, rf),
	env = bgEnv,
	ref = occEnv,
	vars = predictors,
	modelNames = modelNames
)

print(responses)

}


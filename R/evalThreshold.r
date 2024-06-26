#' Weighted thresholds for predictions
#'
#' This function is similar to the \code{\link[predicts]{threshold}} function in the \pkg{predicts} package, which calculates thresholds to create binary predictions from continuous values. However, unlike that function, it allows the user to specify weights for presences and absence/background predictions. The output will thus be the threshold that best matches the specified criterion taking into account the relative weights of the input values.
#' @param pres Numeric vector. Predicted values at test presences.
#' @param contrast Numeric vector. Predicted values at background/absence sites.
#' @param presWeight Numeric vector same length as \code{pres}. Relative weights of presence sites. The default is to assign each presence a weight of 1.
#' @param contrastWeight Numeric vector same length as \code{contrast}. Relative weights of background sites. The default is to assign each presence a weight of 1.
#' @param at Character or character vector, name(s) of threshold(s) to calculate. The default is to calculate them all.
#' \itemize{
#' 		\item \code{'msss'}: Threshold that the maximizes the sum of sensitivity and specificity.
#' 		\item \code{'mdss'}: Threshold that minimizes the difference between sensitivity and specificity.
#' 		\item \code{'minPres'}: Minimum prediction across presences. This threshold is not weighted.
#' 		\item \code{'prevalence'}: Prevalence of presences (sum(presence weights) / sum(presence weights + background weights))'
#' 		\item \code{'sensitivity'}: Threshold that most closely returns the sensitivity specified by \code{sensitivity}.
#' }
#' @param sensitivity Value of specificity to match (used only if \code{at} contains \code{'sensitivity'}).
#' @param thresholds Numeric vector. Thresholds at which to calculate the sum of sensitivity and specificity. The default evaluates all values from 0 to 1 in steps of 0.01.
#' @param na.rm Logical. If \code{TRUE} then remove any presences and associated weights and background predictions and associated weights with \code{NA}s.
#' @param ... Other arguments (unused).
#' @return Named numeric vector.
#' Fielding, A.H. and J.F. Bell. 1997. A review of methods for the assessment of prediction errors in conservation presence/absence models. \emph{Environmental Conservation} 24:38-49. \doi{10.1017/S0376892997000088}
#'
#' @seealso \code{\link[predicts]{threshold}}, \code{\link[predicts]{pa_evaluate}}, \code{\link{evalAUC}}, \code{\link{evalMultiAUC}}, \code{\link{evalContBoyce}}, \code{\link{evalThresholdStats}}, \code{\link{evalTjursR2}}, \code{\link{evalTSS}}
#'
#' @examples
#' set.seed(123)
#' 
#' # set of bad and good predictions at presences
#' bad <- runif(100)^2
#' good <- runif(100)^0.1
#' hist(good, breaks=seq(0, 1, by=0.1), border='green', main='Presences')
#' hist(bad, breaks=seq(0, 1, by=0.1), border='red', add=TRUE)
#' pres <- c(bad, good)
#' contrast <- runif(1000)
#' evalThreshold(pres, contrast)
#' 
#' # upweight bad predictions
#' presWeight <- c(rep(1, 100), rep(0.1, 100))
#' evalThreshold(pres, contrast, presWeight=presWeight)
#' 
#' # upweight good predictions
#' presWeight <- c(rep(0.1, 100), rep(1, 100))
#' evalThreshold(pres, contrast, presWeight=presWeight)
#' @export

evalThreshold <- function(
	pres,
	contrast,
	presWeight = rep(1, length(pres)),
	contrastWeight = rep(1, length(contrast)),
	at = c('msss', 'mdss', 'minPres', 'prevalence', 'sensitivity'),
	sensitivity = 0.9,
	thresholds = seq(0, 1, by=0.001),
	na.rm = FALSE,
	...
) {

	# if all NAs
	if (all(is.na(pres)) | all(is.na(contrast))) return(NA)

	# remove NAs
	if (na.rm) {

		cleanedPres <- omnibus::naOmitMulti(pres, presWeight)
		pres <- cleanedPres[[1]]
		presWeight <- cleanedPres[[2]]

		cleanedContrast <- omnibus::naOmitMulti(contrast, contrastWeight)
		contrast <- cleanedContrast[[1]]
		contrastWeight <- cleanedContrast[[2]]

	}

	### calculate thresholds
	########################

	# used for several thresholds
	sumPresWeights <- sum(presWeight)
	sumContrastWeights <- sum(contrastWeight)
		
	# output
	out <- numeric()
	
	if (any(c('msss', 'mdss') %in% at)) {
	
		# first, calculate TPR, TNR, and FNR across all possible thresholds
	
		# at
		numPres <- length(pres)
		numContrast <- length(contrast)
		
		# true pos/neg and false pos/neg rates
		tpr <- tnr <- fnr <- rep(NA, length(thresholds))
		
		# for each threshold
		for (i in seq_along(thresholds)) {
			
			thisThresh <- thresholds[i]
		
			# which presences/contrast sites are CORRECTLY predicted at this threshold
			whichCorrectPres <- which(pres >= thisThresh)
			whichCorrectContrast <- which(contrast < thisThresh)
			
			numCorrectPres <- length(whichCorrectPres)
			numCorrectContrast <- length(whichCorrectContrast)
			
			anyCorrectPres <- (numCorrectPres > 0)
			anyCorrectContrast <- (numCorrectContrast > 0)
			
			# which presences/contrast sites are INCORRECTLY predicted at this threshold
			whichIncorrectPres <- which(pres < thisThresh)
			whichIncorrectContrast <- which(contrast >= thisThresh)
			
			numIncorrectPres <- length(whichIncorrectPres)
			numIncorrectContrast <- length(whichIncorrectContrast)
			
			anyIncorrectPres <- (numIncorrectPres > 0)
			anyIncorrectContrast <- (numIncorrectContrast > 0)
			
			# weights of CORRECTLY predicted predictions
			correctPresWeights <- if (anyCorrectPres) {
				sum(presWeight[whichCorrectPres])
			} else {
				0
			}
			
			correctContrastWeights <- if (anyCorrectContrast) {
				sum(contrastWeight[whichCorrectContrast])
			} else {
				0
			}
			
			# weights of INCORRECTLY predicted predictions
			incorrectPresWeights <- if (anyIncorrectPres) {
				sum(presWeight[whichIncorrectPres])
			} else {
				0
			}
			
			incorrectContrastWeights <- if (anyIncorrectContrast) {
				sum(contrastWeight[whichIncorrectContrast])
			} else {
				0
			}
			
			# true positive/negative rates
			tpr[i] <- correctPresWeights / sumPresWeights
			tnr[i] <- correctContrastWeights / sumContrastWeights
		
			# false positive/negative rates
			# fpr[i] <- incorrectPresWeights / sumPresWeights
			fnr[i] <- incorrectContrastWeights / sumContrastWeights
		
		}
			
		# second, calculate threshold
		if ('msss' %in% at) {
			x <- thresholds[which.max(tpr + tnr)]
			if (length(x) == 0) x <- NA
			out <- c(out, x)
			names(out)[length(out)] <- 'msss'
		}

		if ('mdss' %in% at) {
			x <- thresholds[which.min(abs(tpr - tnr))]
			if (length(x) == 0) x <- NA
			out <- c(out, x)
			names(out)[length(out)] <- 'mdss'
		}
	
	}

	### minimum presence prediction (unweighted)
	if ('minPres' %in% at) {
	
		x <- min(pres)
		if (length(x) == 0) x <- NA
		out <- c(out, x)
		names(out)[length(out)] <- 'minPres'
		
	}

	### prevalence (weighted)
	if ('prevalence' %in% at) {
	
		x <- sumPresWeights / (sumPresWeights + sumContrastWeights)
		# if (x > 1) warning('Prevalence threshold is >1. The sum of presence weights may be larger than the sum of absence/background weights.')
		if (length(x) == 0) x <- NA
		out <- c(out, x)
		names(out)[length(out)] <- 'prevalence'
		
	}

	### fixed sensitivity (weighted)
	if ('sensitivity' %in% at) {
	
		presOrder <- order(pres)
		pres <- pres[presOrder]
		presWeight <- presWeight[presOrder]
		sens <- 1 - cumsum(presWeight) / sumPresWeights
		x <- pres[which.min(abs(sensitivity - sens))]
		out <- c(out, x)
		names(out)[length(out)] <- 'sensitivity'
		
	}

	out
	
}

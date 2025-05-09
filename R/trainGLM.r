#' Calibrate a generalized linear model (GLM)
#'
#' @description This function constructs a generalized linear model. By default, the model is constructed in a two-stage process.  First, the "construct" phase generates a series of simple models with univariate, quadratic, or 2-way-interaction terms. These simple models are then ranked based on their AICc. Second, the "select" phase creates a "full" model from the simple models such that there is at least \code{presPerTermInitial} presences (if the response is binary) or data rows (if not) for each coefficient to be estimated (not counting the intercept). Finally, it selects the best model using AICc from all possible subsets of this "full" model, while respecting marginality (i.e., all lower-order terms of higher-order terms appear in the model).
#'
#' The function outputs any or all of: a table with AICc for all evaluated models; all models evaluated in the "selection" phase; and/or the single model with the lowest AICc.
#'
#' @param data Data frame.
#' @param resp Response variable. This is either the name of the column in \code{data} or an integer indicating the column in \code{data} that has the response variable. The default is to use the first column in \code{data} as the response.
#' @param preds Character vector or integer vector. Names of columns or column indices of predictors. The default is to use the second and subsequent columns in \code{data}.
#' @param scale Either \code{NA} (default), or \code{TRUE} or \code{FALSE}. If \code{TRUE}, the predictors will be centered and scaled by dividing by subtracting their means then dividing by their standard deviations. The means and standard deviations will be returned in the model object under an element named "\code{scales}". For example, if you do something like \code{model <- trainGLM(data, scale=TRUE)}, then you can get the means and standard deviations using \code{model$scales$mean} and \code{model$scales$sd}. If \code{FALSE}, no scaling is done. If \code{NA} (default), then the function will check to see if non-factor predictors have means ~0 and standard deviations ~1. If not, then a warning will be printed, but the function will continue to do its operations.
#' @param family Name of family for data error structure (see \code{\link[stats]{family}}). Default is to use the 'binomial' family.
#' @param construct Logical. If \code{TRUE} (default) then construct model from individual terms entered in order from lowest to highest AICc up to limits set by \code{presPerTermInitial} or \code{maxTerms} is met. If \code{FALSE} then the "full" model consists of all terms allowed by \code{quadratic} and \code{interaction}.
#' @param select Logical. If \code{TRUE} (default) then calculate AICc for all possible subsets of models and return the model with the lowest AICc of these. This step if performed \emph{after} model construction (if any).
#' @param quadratic Logical. Used only if \code{construct} is \code{TRUE}. If \code{TRUE} (default) then include quadratic terms in model construction stage for non-factor predictors.
#' @param interaction Logical. Used only if \code{construct} is \code{TRUE}. If \code{TRUE} (default) then include 2-way interaction terms (including interactions between factor predictors).
#' @param method Character: Name of function used to solve the GLM. For "normal" GLMs, this can be \code{'glm.fit'} (default), \code{'brglmFit'} (from the \pkg{brglm2} package), or another function.
#' @param interceptOnly If \code{TRUE} (default) and model selection is enabled, then include an intercept-only model.
#' @param presPerTermInitial Positive integer. Minimum number of presences needed per model term for a term to be included in the model construction stage. Used only is \code{construct} is TRUE.
#' @param presPerTermFinal Positive integer. Minimum number of presence sites per term in initial starting model. Used only if \code{select} is \code{TRUE}.
#' @param maxTerms Maximum number of terms to be used in any model, not including the intercept (default is 8). Used only if \code{construct} is \code{TRUE}.
#' @param w Weights. Any of:
#' \itemize{
#'	\item \code{TRUE}: Causes the total weight of presences to equal the total weight of absences (if \code{family='binomial'})
#' 	\item \code{FALSE}: Each datum is assigned a weight of 1.
#'  \item A numeric vector of weights, one per row in \code{data}.
#' 	\item The name of the column in \code{data} that contains site weights.
#' }
#' @param removeInvalid Logical. If \code{TRUE} (default), remove models that either did not converge or have parameter estimates near the boundaries (usually negative or positive infinity). If you run this function with `construct = TRUE` (i.e., construct a "full" model from the best "small" models), then any small model that either did not converge or had parameters that are near the boundary (usually negative or positive infinity) are removed from consideration as terms in "full" model.
#' @param failIfNoValid Logical. If \code{TRUE} (default), and the "full" model either does not converge or has parameters near the boundary, then the function will fail. If \code{FALSE}, then return \code{NULL} in this case.
#' @param out Character vector. One or more values:
#' \itemize{
#' 	\item	\code{'model'}: Model with the lowest AICc.
#' 	\item	\code{'models'}: All models evaluated, sorted from lowest to highest AICc (lowest is best).
#' 	\item	\code{'tuning'}: Data frame with tuning parameters, one row per model, sorted by AICc.
#' }
#' @param cores Integer >= 1. Number of cores to use when calculating multiple models. Default is 1. If you have issues when \code{cores} > 1, please see the \code{\link{troubleshooting_parallel_operations}} guide.
#' @param verbose Logical. If \code{TRUE} then display progress.
#' @param ... Arguments to pass to \code{glm}.
#'
#' @details
#' This function is designed to find the most parsimonious model given the amount of calibration data that is available to it. `trainGLM()` can work with any data, but has been designed to work specifically as a species distribution model where the response is either binary (default) or abundance. Specifically, it 1) identifies the most parsimonious model (lowest AICc) with 2) optimal flexibility (optimal degrees of freedom in splines) and 3) allows for (but does not require) interaction terms between predictors (if desired). If the defaults are used, the following procedure is applied:
#' \itemize{
#'	\item Constructing a set of simple model terms, each with 1 to 4 degrees of freedom. Terms can be univariate or bilabiate (two-way interactions). Predictors can be continuous or factors. If any simple models has convergence issues or boundary issues (coefficients that approach negative or positive infinity), it is removed.
#'  \item Constructing a series of models, each with one of the terms, then using the models to rank terms by AICc.
#'  \item From the top set of terms, creating a "full" model. The full model will ensure the maximum number of terms is <= `maxTerms`, and that for each term, there are at least `presPerTermFinal` data points.
#'  \item All possible submodels, plus the full model, are evaluated and ranked by AICc.  If a model has convergence or boundary issues, it is removed from the set. The most parsimonious model (lowest AICc) is returned.
#' }
#'
#' @returns The object that is returned depends on the value of the \code{out} argument. It can be a model object, a data frame, a list of models, or a list of all two or more of these. If \code{scale} is \code{TRUE}, any model object will also have an element named \code{$scale}, which contains the means and standard deviations for predictors that are not factors. The data frame reports the AICc for all of the models evaluated, sorted by best to worst. The \code{converged} column indicates whether the model converged ("\code{TRUE}" is good), and the \code{boundary} column whether the model parameters are near the boundary (usually, negative or positive infinity; "\code{FALSE}" is good).
#'
#' @seealso \code{\link[stats]{glm}}
#'
#' @example man/examples/trainXYZ_examples.R
#' 
#' @export
trainGLM <- function(
	data,
	resp = names(data)[1],
	preds = names(data)[2:ncol(data)],
	scale = NA,
	construct = TRUE,
	select = TRUE,
	quadratic = TRUE,
	interaction = TRUE,
	interceptOnly = TRUE,
	method = 'glm.fit',
	presPerTermInitial = 10,
	presPerTermFinal = 10,
	maxTerms = 8,
	w = TRUE,
	family = stats::binomial(),
	removeInvalid = TRUE,
	failIfNoValid = TRUE,
	out = 'model',
	cores = 1,
	verbose = FALSE,
	...
) {

	### for debugging
	#################
	
	if (FALSE) {
	
		resp <- 'presBg'
		
		construct <- TRUE
		select <- TRUE
		quadratic <- TRUE
		interaction <- TRUE
		interceptOnly <- TRUE
		presPerTermInitial <- 10
		presPerTermFinal <- 10
		maxTerms <- 8
		w <- TRUE
		removeInvalid <- TRUE
		failIfNoValid <- TRUE
		scale <- TRUE
		family <- stats::binomial()
		out <- 'model'
		cores <- 1
		verbose <- TRUE
		method <- 'glm.fit'

	}

	###########
	## setup ##
	###########

		# response and predictors
		if (inherits(resp, c('integer', 'numeric'))) resp <- names(data)[resp]
		if (inherits(preds, c('integer', 'numeric'))) preds <- names(data)[preds]

		# weights and scaling
		w <- .calcWeights(w, data = data, resp = resp, family = family)
		if (is.na(scale) || scale) {
			scaleds <- .scalePredictors(scale, preds, data)
			data <- scaleds$data
			scales <- scaleds$scales
		}

	### parallelization
	###################
			
		cores <- if (!construct) {
			1L
		} else {
			min(cores, parallel::detectCores(logical = FALSE))
		}

		paths <- .libPaths() # need to pass this to avoid "object '.doSnowGlobals' not found" error!!!
		if (cores > 1L) {

			`%makeWork%` <- foreach::`%dopar%`
			# cl <- parallel::makeCluster(cores, setup_strategy = 'sequential')
			cl <- parallel::makeCluster(cores)
			parallel::clusterEvalQ(cl, requireNamespace('parallel', quietly=TRUE))
			doParallel::registerDoParallel(cl)
			on.exit(parallel::stopCluster(cl), add=TRUE)

			# `%makeWork%` <- doRNG::`%dorng%`
			# doFuture::registerDoFuture()
			# future::plan(future::multisession(workers = cores))
			# on.exit(future:::ClusterRegistry('stop'), add=TRUE)

		} else {
			`%makeWork%` <- foreach::`%do%`
		}

		mcOptions <- list(preschedule = TRUE, set.seed = TRUE, silent = verbose)

	### make list of candidate model terms
	######################################

		fam <- if (inherits(family, 'family')) {
			family$family
		} else {
			family
		}

		if (fam %in% c('binomial', 'quasibinomial')) {
			n <- if (inherits(data, 'data.table')) {
				.SD <- NULL
				unlist(data[ , lapply(.SD, sum), , .SDcols = resp])
			} else {
				n <- sum(data[ , resp, drop=TRUE])
			}
		} else {
			n <- nrow(data)
		}

		### create vector of terms
		terms <- preds
		factors <- sapply(data[ , preds, drop = FALSE], is.factor)
		if (quadratic) terms <- c(terms, .makeQuadsMarginality(preds = preds, n = n, presPerTermInitial = presPerTermInitial, factors = factors))
		if (interaction) terms <- c(terms, .makeIAsMarginality(preds = preds, n = n, presPerTermInitial = presPerTermInitial))
		
	## term-by-term model construction
	##################################
	if (construct) {

		assess <- foreach::foreach(
			i = seq_along(terms),
			.combine = 'rbind',
			.multicombine = TRUE,
			.inorder = FALSE,
			# .packages = c('parallel', 'doParallel'),
			.export = c('.trainGlmWorker')
		) %makeWork% {
			.trainGlmWorker(
				i = i,
				forms = terms,
				data = data,
				resp = resp,
				family = family,
				method = method,
				w = w,
				insertIntercept = TRUE,
				paths = paths,
				modelOut = FALSE,
				...
			)
		}
	
		if (removeInvalid) {

			bads <- which(!assess$converged | assess$boundary)
			if (length(bads) > 0) {
				assess <- assess[-bads, , drop = FALSE]
				
				if (nrow(assess) == 0) {
					msg <- 'No single-term models converged or all models had parameter estimates near the boundary.'
					if (failIfNoValid) {
						stop(msg)
					} else {
						warning(msg)
						return(NULL)
					}
				}
			}
		}

		assess <- assess[order(assess$AICc), , drop = FALSE]
		rownames(assess) <- NULL

		if (verbose) {
			omnibus::say('Term-by-term evaluation:', pre = 1)
			print(assess)
			utils::flush.console()
		}

		### no selection
		################
		
		# just return model with "best" terms without further selection
		
		if (!select) {
			
			form <- assess$formula[1L]
			numTerms <- length(strsplit(form, ' \\+ ')[[1L]])
			if (nrow(assess) > 1L) {
				i <- 2L
				while (i <= nrow(assess) & n >= numTerms * presPerTermFinal) {
					startForm <- form
					form <- paste0(form, ' + ', assess$formula[i])
					form <- strsplit(form, ' \\+ ')[[1L]]
					form <- unique(form)
					form <- sort(form)
					numTerms <- length(form)
					if (n >= numTerms * presPerTermFinal) {
						form <- paste(form, collapse=' + ')
						i <- i + 1L
					} else {
						form <- startForm
						i <- Inf
					}
				}
			}
			
			thisForm <- paste0(resp, ' ~ 1 + ', form)
			thisForm <- stats::as.formula(thisForm)
			
			mm <- stats::model.matrix(thisForm, data)
			start <- rep(0, ncol(mm))
			
			model <- suppressWarnings(stats::glm(
				formula = thisForm,
				family = family,
				data = data,
				method = method,
				weights = w,
				start = start,
				...
			))
			
			AICc <- AICcmodavg::AICc(model)
			
			tuning <- data.frame(
				model = form,
				converged = model$converged,
				boundary = model$boundary,
				AICc = AICc
			)

			models <- NULL

			if (!tuning$converged | tuning$boundary) {

				msg <- 'The model did not converge and/or estimates are near boundary conditions.'
				if (removeInvalid) {
				
					if (failIfNoValid) {
						stop(msg)
					} else {
						warning(msg)
						return(NULL)
					}
				} else {
					warning(msg)
				}

			}

				
			if (verbose) {

				omnibus::say('Final model (construction from best terms, but no selection):', pre=1)
				print(summary(model))
				utils::flush.console()

			}

		### model selection
		###################
		
		# select best model from all possible subsets of "full" model with best terms
		
		} else {

			### make all possible formulae given constraints
			terms <- assess$formula
			terms <- strsplit(terms, split='\\+')
			terms <- lapply(terms, trimws)
			for (i in seq_along(terms)) {
				if (any(terms[[i]] == '1')) terms[[i]] <- terms[[i]][terms[[i]] != '1']
			}
			lengthTerms <- length(terms)

			form <- terms[[1L]]
			
			# basic full-model formula
			numTerms <- length(form)
			i <- 2L
			while (numTerms <= maxTerms & n / presPerTermInitial >= numTerms & i <= lengthTerms) {

				form <- c(form, terms[[i]])
				form <- unique(form)
				numTerms <- length(form)
				i <- i + 1L
			
			}

			# all possible models: keep only desired quadratics and interactions (and respect marginality)
			if (any(form == '1')) form <- form[form != '1']
			ias <- form[grepl(form, pattern=':')]
			quads <- form[grepl(form, pattern='\\^2')]
			linears <- form[!grepl(form, pattern=':') & !grepl(form, pattern='\\^2')]

			haveQuads <- (length(quads) > 0L)
			haveIAs <- (length(ias) > 0L)

			form <- paste0(resp, ' ~ ', paste(linears, collapse=' + '))
			form <- stats::as.formula(form)
			forms <- statisfactory::makeFormulae(form, quad=haveQuads, ia=haveIAs, maxTerms=maxTerms, returnFx=as.character)

			if (haveQuads) {
				candidateQuads <- .makeQuads(linears)
				verbotenQuads <- candidateQuads[!(candidateQuads %in% quads)]
				if (length(verbotenQuads) > 0L) {
				
					discards <- rep(FALSE, length(forms))
					for (i in seq_along(verbotenQuads)) {
						discards <- discards | grepl(forms, pattern=verbotenQuads[i], fixed=TRUE)
					}
					
					if (any(discards)) forms <- forms[!discards]
				}
			}

			if (haveIAs) {

				candidateIAs <- .makeIAs(linears)
				swapCandidateIAs <- rep(NA_character_, length(candidateIAs))
				for (i in seq_along(candidateIAs)) {
				
					colon <- regexpr(candidateIAs[i], pattern=':')[1L]
					swapCandidateIAs[i] <- paste0(
						substr(candidateIAs[i], colon + 1, nchar(candidateIAs[i])),
						':',
						substr(candidateIAs[i], 1, colon - 1)
					)
				}
				
				verbotenIAs <- setdiff(ias, c(candidateIAs, swapCandidateIAs))
				
				if (length(verbotenIAs) > 0L) {
				
					discards <- rep(FALSE, length(forms))
					for (i in seq_along(verbotenIAs)) {
						discards <- discards | grepl(forms, pattern=verbotenIAs[i], fixed=TRUE)
					}
					
					if (any(discards)) forms <- forms[!discards]
				}
			
			}
			
			lens <- sapply(forms, nchar)
			lenLhs <- nchar(paste0(resp, ' ~ 1 + ')) + 1
			for (i in seq_along(forms)) forms[[i]] <- substr(forms[[i]], lenLhs, lens[i])

			assess <- foreach::foreach(
				i = seq_along(forms),
				.options.multicore = mcOptions,
				.combine = 'c',
				.multicombine = TRUE,
				.inorder = FALSE,
				# .packages = c('parallel', 'doParallel'),
				.export = c('.trainGlmWorker')
			) %makeWork% {
				.trainGlmWorker(
					i = i,
					forms = as.list(forms),
					data = data,
					resp = resp,
					family = family,
					method = method,
					w = w,
					insertIntercept = TRUE,
					paths = paths,
					modelOut = TRUE,
					...
				)
			}

			# compile all possible models and rank
			n <- length(assess)
			tuning <- data.frame(
				model = rep(NA_character_, n),
				converged = rep(NA, n),
				boundary = rep(NA, n),
				AICc = rep(NA_real_, n)
			)

			models <- list()
			for (i in seq_along(assess)) {
				models[[i]] <- assess[[i]]$model
				if (!is.na(scale)) if (scale) models[[i]]$scale <- scales
				tuning$model[i] <- assess[[i]]$formula
				tuning$converged[i] <- assess[[i]]$converged
				tuning$boundary[i] <- assess[[i]]$boundary
				tuning$AICc[i] <- assess[[i]]$AICc
			}
			
			if (removeInvalid) {

				bads <- which(!tuning$converged | tuning$boundary)
				if (length(bads) > 0) {

					tuning <- tuning[-bads, , drop = FALSE]
					models <- models[-bads]

					if (nrow(tuning) == 0) {
						msg <- 'No models converged or all had parameter estimates near the boundary of parameter space.'
						if (failIfNoValid) {
							stop(msg)
						} else {
							warning(msg)
							return(NULL)
						}
					}
				}
			}

			ranks <- order(tuning$AICc)
			models <- models[ranks]
			tuning <- tuning[ranks, , drop=FALSE]
			rownames(tuning) <- NULL
			
			model <- models[[1L]]
			
			if (verbose) {
				omnibus::say('Model-by-model evaluation:', pre=1)
				print(tuning)
				utils::flush.console()
			}
		
		} # if selecting best model from subsets of "full" model

	### if not constructing model term-by-term (selection not possible)
	###################################################################
	} else {

		form <- paste(terms, collapse = ' + ')
		form <- strsplit(form, ' \\+ ')[[1L]]
		form <- unique(form)
		form <- paste(form, collapse = ' + ')
		thisForm <- paste0(resp, ' ~ 1 + ', form)
		thisForm <- stats::as.formula(thisForm)
		
		mm <- stats::model.matrix(thisForm, data)
		start <- rep(0, ncol(mm))
	
		model <- suppressWarnings(stats::glm(
			formula = thisForm,
			family = family,
			data = data,
			method = method,
			weights = w,
			start = start,
			...
		))
		
		AICc <- AICcmodavg::AICc(model)
		
		tuning <- data.frame(
			model = form,
			converged = model$converged,
			boundary = model$boundary,
			AICc = AICc
		)
		
		models <- NULL
		
		if (select) warning('Model selection is not performed when argument `construct` is FALSE.')
		if (!model$converged | model$boundary) {
			
			msg <- 'The model did not converge and/or parameters are near the boundary space.'
			if (removeInvalid) {
				
				if (failIfNoValid) {
					stop(msg)
				} else {
					warning(msg)
					return(NULL)
				}
			} else {
				warning(msg)
			}
		
		}

		if (verbose) {
		
			omnibus::say('Model (no construction or selection):', level=2)
			print(summary(model))
			utils::flush.console()

		}
		
	} # if not constructing model term-by-term

	# if (cores > 1L) parallel::stopCluster(cl)

	### return
	##########

	if (length(out) > 1L) {
		output <- list()
		if ('models' %in% out) output$models <- models
		if ('model' %in% out) output$model <- model
		if ('tuning' %in% out) output$tuning <- tuning
	} else if ('models' %in% out) {
		output <- models
	} else if ('model' %in% out) {
		output <- model
		if (!tuning$converged[1] | tuning$boundary[1]) warning('The top model did not converge and/or had parameter estimates near the boundary.')
	} else if ('tuning' %in% out) {
		output <- tuning
	}
	output
		
}

#################
### train GAM ###
#################

.trainGlmWorker <- function(
	i,
	forms, # formulae (without LHS and maybe without intercept)
	data,
	resp,
	family,
	method,
	w,
	paths,
	insertIntercept, # if TRUE, add "1 +" to the RHS side
	modelOut, # if TRUE, return model *and* data frame with model
	...
) {

	# # so doFuture knows to load these packages are needed
	# if (FALSE) {
		# parallel::splitIndices(nonsense, nonsense)
		# doParallel::registerDoParallel(nonsense)
	# }

	 # need to call this to avoid "object '.doSnowGlobals' not found" error!!!
	.libPaths(paths)

	form <- forms[i]
	if (insertIntercept) {
		form <- if (form == '') {
			'1'
		} else {
			paste('1', form, sep=' + ')
		}
	}
	thisForm <- paste0(resp, ' ~ ', form)
	thisForm <- stats::as.formula(thisForm)
	mm <- stats::model.matrix(thisForm, data)
	start <- rep(0, ncol(mm))

	model <- suppressWarnings(stats::glm(
		formula = stats::as.formula(thisForm),
		data = data,
		family = family,
		weights = w,
		method = method,
		start = start,
		...
	))
	
	AICc <- AICcmodavg::AICc(model)
	
	# out
	if (modelOut) {
		
		out <- list(
			list(
				model = model,
				formula = form,
				converged = model$converged,
				boundary = model$boundary,
				AICc = AICc
			)
		)
		
	} else {
	
		out <- data.frame(
			formula = form,
			converged = model$converged,
			boundary = model$boundary,
			AICc = AICc
		)
	
	}
	out

}

# make vector of quadratic terms respecting marginality
.makeQuadsMarginality <- function(
	preds,					# vector of predictor names
	n,						# sample size
	presPerTermInitial,		# number of presences per term
	factors					# logical: is each predictor a factor?
) {
	
	quads <- character()
	if (n >= 2 * presPerTermInitial) {
		for (i in seq_along(preds)) {
			pred <- preds[i]
			if (!factors[[pred]]) {
				quads <- c(quads, paste0(pred, ' + I(', pred, '^2)'))
			}
		}
	}
	quads

}

# make vector of quadratic terms ONLY
.makeQuads <- function(preds) {
	paste0('I(', preds, '^2)')
}

# make vector of interaction terms respecting marginality
.makeIAsMarginality <- function(preds, n, presPerTermInitial) {
	
	ias <- character()
	if (length(preds) > 1L & n >= 2 * presPerTermInitial) {
		
		nPreds <- length(preds)
		for (countPred1 in 1L:(nPreds - 1L)) { # for each predictor test two-variable terms

			pred1 <- preds[countPred1]

			for (countPred2 in (countPred1 + 1L):length(preds)) { # for each second predictor test two-variable terms

				pred2 <- preds[countPred2]
				ias <- c(ias, paste0(preds[countPred1], ' + ', preds[countPred2], ' + ', preds[countPred1], ':', preds[countPred2]))
				
			} # next second term
			
		} # next first term
	
	} # if more than one term

	ias
}

# make vector of interaction terms ONLY
.makeIAs <- function(preds) {
	
	ias <- character()
	nPreds <- length(preds)
	for (countPred1 in 1L:(nPreds - 1L)) { # for each predictor test two-variable terms
		pred1 <- preds[countPred1]
		for (countPred2 in (countPred1 + 1):nPreds) { # for each second predictor test two-variable terms
			pred2 <- preds[countPred2]
			ias <- c(ias, paste0(preds[countPred1], ':', preds[countPred2]))
		} # next second term
	} # next first term
	ias
	
}

# enmSdmX 1.2.12 2025-03-29
- Fixed bug that sometimes appeared in `coordImprecision()` because output included units :(.  

# enmSdmX 1.2.11 2025-02-19
- Added `responseCurves()` for easy plotting of model response curves.  
- Bug fix: `predictEnmSdm()` no longer fails for GLMs when `newdata` has more columns than necessary.  
- Bug fix: `trainMaxEnt()` now removes over-parameterized models (thank you, ML!).  
- Bug fix: `trainNS()` correctly records the `scale` statistics when argument `scale = TRUE`.  
- Bug fix: `trainByCrossValid()` no longer crashes when trying to train MaxEnt models (thank you, ML!).  

# enmSdmX 1.1.9 2024-11-01
- `trainGAM()` does not include interaction terms if `interaction` is `NULL`, and does not fail when interactions are included and the number of predictors is >2 (thank you, P.T.!).  

# enmSdmX 1.1.8 2024-10-02
- `modelSize()` can now tell size of a `ranger` random forest.

# enmSdmX 1.1.7 2024-08-02
- Clarified mis-leading help in several functions, including all the `trainXYZ()` functions (thank you, PT!).

# enmSdmX 1.1.6 2024-06-06
- Replaced dependency on **MuMIn** with one one **AICcmodavg** for calculation of AICc. Received warning that **MuMIn** was going to be archived on CRAN.

# enmSdmX 1.1.5 2024-05-16
- Added function `trainESM()` for ensembles of small models.
- Added several UTM coordinate reference systems accessible through `getCRS()`.
- Fixed bug in `predictEnmSdm()` for predicting kernel density models from the **ks** package.

# enmSdmX 1.1.3 2023-03-06
- `trainGLM()`,  `trainNS()`, and `predictEnmSdm()` now have options to automatically center and scale predictors. If a GLM or NS model created using `trainGLM()` or `trainSN()` is provided to `predictEnmSdm()`, it will automatically scale the predictors properly.

# enmSdmX 1.1.3 2023-02-02
- Removed dependency on `dismo`, replaced where possible by `predicts`; copied `gbm.step()` and `predict()` method for MaxEnt to `enmSdmX` as a momentary fix; would love a professional solution!
- Added European Datum 1950 (ED50) to coordinate reference systems table
- Added ability to export intermediate values for plotting in `evalContBoyce()`
- Fixed spelling errors in `crss` data table (coordinate reference system names)

# enmSdmX 1.1.2 2023-09-07
- Minor issue fixes with undocumented arguments for non-exported functions
- Bug fix in `squareCellRast()` that occurred on Linux/Fedora

# enmSdmX 1.1.1 2023-06-11
- Backwards incompatible: `trainRF()` uses `ranger` package for random forests (changed from `randomForest` package)
- Backwards incompatible: `geoFold()` uses `complete` clustering method by default (changed from `single`)
- New feature: `trainGLM()` and `trainNS()` can automatically scale predictors
- New feature: Reworked `trainGLM()` to handle cases with large numbers of predictors
- New feature: Added `geoFoldContrast()` for assigning geo-folds to background or absence sites
- Better functionality: `trainRF()` now indicates if the response is binary using a `binary` argument (vs. `family`, which falsely implied more functionality than RFs have)

# enmSdmX 1.0.6 2023-05-22
- Better functionality: Expanded capacity of .calcWeights() (a hidden function) to handle different values for `family`

# enmSdmX 1.0.5 2023-05-12
- new feature: Added help page for troubleshooting running functions that support parallel operation
- Bug fix: `predictEnmSdm()` when using a BRT model and predicting to a `SpatRaster` (thank you, Nikki C!)

# enmSdmX 1.0.4 2023-04-10
- New feature: Users can select clustering method in `geoThin()` and `geoFold()` (thank you, Pascal T!)
- Bug fix: Example in `customCRS()` when GADM server is down
- Bug fix:`geoThin()` which returned input if it was a `data.frame`*
- Bug fix:`geoThin()` which returned a `data.frame` lacking coordinates if input was a `data.frame` (thank you, Pascal T!)

# enmSdmX 1.0.3 2023-03-07
- Bug fix: Removed Fedora issue with external link to `raster` package
- Bug fix: Added `rJava` dependency

# enmSdmX 1.0.2 2023-03-04
- New feature: `getCRS()` (no arguments) now displays `shiny` table of all available CRSs
- Bug fix: Fixed issue in `nearestGeogPoints()` when polygon lay under centroid
- Bug fix: Fixed bug with "table" call of `getCRS()`

# enmSdmX 1.0.1
- New feature: `summarizeByCrossValid()` now summarizes natural spline (NS) models
- Bug fix: Bug experienced by some users using `predictEnmSdm()` and `predictMaxNet()` (Thank you, Nikki!)
- Bug fix: `trainByCrossValid()` using improper call to `evalContBoyce()`
- Bug fix: `extract()` bug in some examples

# enmSdmX 1.0.0
- First release on CRAN

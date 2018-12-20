context("Watershed Object")
library("WatershedTools")

test_that("Creation of a basic Watershed proceeds without error", {
	skip_on_cran()
	gisBase <- "/Applications/GRASS-7.4.1.app/Contents/Resources/"
	testDEM <- raster::raster(system.file("testdata/testDEM.grd", package="WatershedTools"))
	gs <- GrassSession(testDEM, layerName = "dem", gisBase = gisBase)
	gs <- fillDEM("dem", filledDEM = "filledDEM", probs = "problems", gs = gs)
	gs <- accumulate("filledDEM", accumulation = "accum", drainage = "drain",
		gs = gs)
	gs <- extractStream(dem = "filledDEM", accumulation = "accum", qthresh = 0.95,
		outputName = "streamRas", gs = gs)
	streamRas <- GSGetRaster("streamRas", gs)
	drainage <- GSGetRaster("drain", gs)
	accum <- GSGetRaster("accum", gs)
	coords <- sp::coordinates(accum)[which.max(raster::values(accum)),, drop=FALSE]
	streamCrop <- cropToCatchment(coords, streamRaster = streamRas, drainage = "drain", gs = gs)
	expect_error(testWS <- Watershed(streamCrop, drainage), regex=NA)
})
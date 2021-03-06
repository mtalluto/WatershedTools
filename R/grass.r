
#' Produce a [sp::SpatialPixelsDataFrame] from a [raster::RasterLayer]
#'
#' @param x A [raster::RasterLayer] object
#' @param complete.cases Boolean, if TRUE only complete (non-na) rows are returned
#' @return A [sp::SpatialPixelsDataFrame]
#' @keywords internal
rasterToSPDF <- function(x, complete.cases=FALSE)
{
	coords <- sp::coordinates(x)
	gr <- data.frame(cbind(coords, raster::values(x)))
	if(complete.cases)
		gr <- gr[complete.cases(gr),]
	sp::coordinates(gr) <- c(1,2)
	sp::proj4string(gr) <- sp::proj4string(x)
	sp::gridded(gr) <- TRUE
	return(gr)
}


#' Set up a GRASS session
#'
#' @param layer A [raster::raster] object (recommended); or any other object which has `extent()` and `proj4string()` methods defined.
#' @param gisBase character; the location of the GRASS installation (see `details`)
#' @param layerName NA or character; if NA (the default), the layer will not be added to the grass session, otherwise it will be appended with this name.
#' @param home Location to write GRASS settings, `details`.
#' @param gisDbase Location to write GRASS GIS datasets; see `details`.
#' @param location Grass location name
#' @param mapset Grass mapset name
#' @param override Logical;  see `details`
#'
#' @details if `gisBase` is not provided, it can be automatically deduced in some cases.
#' On some systems, you can run `grass74 --config path` from the command line to get this path.
#' 
#' The extent, projection, and resolution of the grass session will be determined by `layer`.
#' 
#' by default `override` will be TRUE if home and gisDbase are set to their defaults, otherwise FALSE. If TRUE, the new session will override any existing grass session (possibly damaging/overwriting existing files). It is an error if override is FALSE and there is an already running session.
#' @return An S3 [GrassSession] object
#' @export
GrassSession <- function(layer, gisBase, layerName = NA, home = tempdir(), gisDbase = home,
	location = 'NSmetabolism', mapset = 'PERMANENT', override)
{
	if(missing(gisBase)) 
		gisBase <- system2("grass74", args=c("--config path"), stdout=TRUE)

	if(missing(override)) {
		if(home == gisDbase  && home == tempdir()) {
			override <- TRUE
		} else override <- FALSE
	}

	gs <- list()
	rgrass7::initGRASS(gisBase, home=home, gisDbase = gisDbase, location = location, 
		mapset = mapset, override = override)
	gs$gisBase <- gisBase
	gs$home <- home
	gs$gisDbase <- gisDbase
	gs$location <- location
	gs$mapset <- mapset

	err <- rgrass7::execGRASS("g.proj", flags = "c", proj4 = sp::proj4string(layer), intern=TRUE)
	gs$proj4string <- sp::proj4string(layer)

	ext <- as.character(as.vector(raster::extent(layer)))
	rasres <- as.character(raster::res(layer))
	rgrass7::execGRASS("g.region", n = ext[4], s = ext[3], e = ext[2], w = ext[1], 
			rows=raster::nrow(layer), cols=raster::ncol(layer), nsres = rasres[2], 
			ewres = rasres[1])
	gs$extent <- raster::extent(layer)
	gs$resolution <- raster::res(layer)

	class(gs) <- c("GrassSession", class(gs))

	if(!is.na(layerName)) gs <- GSAddRaster(layer, layerName, gs)

	return(gs)
}

#' Print method for a [GrassSession] object
#'
#' @param x A [GrassSession] object
#'
#' @export
print.GrassSession <- function(x)
{
	print(rgrass7::gmeta())
}

#' Add a RasterLayer to a grass session and return the modified session
#' @param x A [raster::raster] object or a [sp::SpatialGridDataFrame]
#' @param gs A [GrassSession] object
#' @param layerName character; the name of the layer to add to grass.
#' 
#' @return An S3 [GrassSession] object
#' @export
GSAddRaster <- function(x, layerName, gs, overwrite = TRUE)
{

	if("RasterLayer" %in% class(x)) {
		x <- rasterToSPDF(x)
	}
	flags <- NULL
	if(overwrite)
		flags <- c(flags, "overwrite")
	rgrass7::writeRAST(x, layerName, flags = flags)
	GSAppendRasterName(layerName, gs)
}

#' Add a RasterLayer *name* to a grass session and return the modified session
#' @param x Character; the name of the layer(s) to add
#' @param gs A [GrassSession] object
#' 
#' @return An S3 [GrassSession] object
#' @keywords internal
#' @export
GSAppendRasterName <- function(x, gs) {
	# make sure file exists
	for(layer in x) {
		lnames <- rgrass7::execGRASS("g.list", flags = "quiet", type='raster', mapset = gs$mapset, 
			pattern = layer, intern=TRUE)
		if(length(lnames) == 0)
			stop("tried to add ", x, " to grass list of layers, but no layer exists")
		gs$layers <- c(gs$layers, layer)
	}
	return(gs)
}

#' Read a raster from a grass session
#' @param layer The name of the layer(s) to read
#' @param gs A [GrassSession] object
#' @param file (optional, recommended) Where to store the raster on disk
#' @details If no file is specified, the raster will be stored in memory or as a temporary
#'   file and will be lost at the end of the R sessionl.
#' @return A raster or raster stack
#' @export
GSGetRaster <- function(layer, gs, file)
{
	ras <- sapply(layer, function(x) raster::raster(rgrass7::readRAST(x)))
	if(length(layer) != 1) {
		ras <- raster::stack(ras)
	} else {
		ras <- ras[[1]]
	}
	if(!missing(file) && is.character(file)) 
		ras <- raster::writeRaster(ras, file)
	ras
}


#' Convert a raster to a polygon in grass
#' @param rast Either a rasterlayer or a file name of a raster in grass
#' @param vect Optional layer name to save the polygon
#' @param gs GrassSession to operate on
#' @return If vect is missing, a spatialPolygons object, otherwise NULL (with the side-effect)
#' 		of writing a polygon to the grass session
#' @keywords internal
GSRastToPoly <- function(rast, vect, gs) {
	if(missing(vect))
		vect <- "GSRastToPoly_temp"

	if(!is.character(rast)) {
		gs <- GSAddRaster(rast, "GSRastToPoly_temp_rast", gs)
		rast <- "GSRastToPoly_temp_rast"
	}
	rgrass7::execGRASS("r.to.vect", flags=c("overwrite", "quiet", "s"), 
		input = rast, output = vect, type='area', column = 'one')

	if(rast == "GSRastToPoly_temp_rast")
		gs <- GSClean(rast, gs, 'raster')
	if(vect == "GSRastToPoly_temp") {
		output <- GSGetVector(vect)
		gs <- GSClean(vect, gs, 'vectpor')
		return(output)
	}
}


#' Delete layers from a GrassSession
#' @param layer Layer name to delete
#' @param gs GrassSession to operate on
#' @param type Type of layer, either raster of vector
#' @return Modified grass session
#' @keywords internal
GSClean <- function(layer, gs, type = c('raster', 'vector')) {
	type <- match.arg(type)
	rgrass7::execGRASS("g.remove", flags = c("f", "quiet"), type=type, name=layer)
	if(type == 'raster') {
		i <- grep(layer, gs$layers)
		if(length(i) == 1) gs$layers <- gs$layers[-i]
	}
	return(gs)
}
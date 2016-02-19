#' Convert from Spatial*DataFrame to table.
#'
#' Input can be a \code{\link[sp]{SpatialPolygonsDataFrame}}, \code{\link[sp]{SpatialLinesDataFrame}} or a \code{\link[sp]{SpatialPointsDataFrame}}.
#' @param x \code{\link[sp]{Spatial}} object
#' @param ... ignored
#'
#' @return \code{\link[dplyr]{tbl_df}} data_frame with columns
#' \itemize{
#'  \item SpatialPolygonsDataFrame "object" "part"   "cump"   "hole"   "x"      "y"
#'  \item SpatialLinesDataFrame "object" "part"   "cump"   "x"      "y"
#'  \item SpatialPointsDataFrame  "cump"   "object" "x"      "y"
#' }
#' @export
#'
sptable <- function(x, ...) {
  UseMethod("sptable")
}

#' @export
#' @rdname sptable
sptable.SpatialPolygonsDataFrame <- function(x, ...) {
  mat2d_f(.polysGeom(x, ...))
}

#' @export
#' @rdname sptable
sptable.SpatialLinesDataFrame <- function(x, ...) {
  mat2d_f(.linesGeom(x, ...))
}

#' @export
#' @rdname sptable
sptable.SpatialPointsDataFrame <- function(x, ...) {
  mat2d_f(.pointsGeom(x, ...))
}

## TODO multipoints
#' @importFrom dplyr data_frame
mat2d_f <- function(x) {
  as_data_frame(as.data.frame((x)))
}




#' Convert from dplyr tbl form to Spatial*DataFrame.
#'
#' @param x data_frame as created by \code{\link{sptable}}
#' @param crs projection, defaults to \code{NA_character_}
#' @param ... not used
#'
#' @return Spatial*
#' @export
#' @importFrom dplyr %>% distinct_ as_data_frame
#' @importFrom sp coordinates CRS SpatialPoints SpatialPointsDataFrame Line Lines SpatialLines SpatialLinesDataFrame Polygon Polygons SpatialPolygons SpatialPolygonsDataFrame
spFromTable <- function(x, crs, ...) {
  if (missing(crs)) crs <- NA_character_
  ## raster::geom form
  target <- detectSpClass(x)
  dat <- x %>% distinct_("object") %>% as.data.frame
  dat <- dat[, -match(names(dat), geomnames()[[target]])]
  if (ncol(dat) == 0L) dat$ID <- seq(nrow(dat))

  gom <- switch(target,
         SpatialPolygonsDataFrame = reverse_geomPoly(x, dat, crs),
         SpatialLinesDataFrame = reverse_geomLine(x, dat, crs),
         SpatialPointsDataFrame = reverse_geomPoint(x, dat, crs)
         )
 gom
}

reverse_geomPoly <- function(x, d, proj) {
  objects <- split(x, x$object)
  SpatialPolygonsDataFrame(SpatialPolygons(lapply(objects, loopPartsPoly), proj4string = CRS(proj)), d)
}
loopPartsPoly <- function(a) Polygons(lapply(split(a, a$part), function(b) Polygon(as.matrix(b[, c("x", "y")]), hole = b$hole[1L] == 1)), as.character(a$object[1L]))


reverse_geomLine <- function(x, d, proj) {
  objects <- split(x, x$object)
  SpatialLinesDataFrame(SpatialLines(lapply(objects, loopPartsLine), proj4string = CRS(proj)), d)
}
loopPartsLine<- function(a) Lines(lapply(split(a, a$part), function(b) Polygon(as.matrix(b[, c("x", "y")]))), as.character(a$object[1L]))

reverse_geomPoint <- function(a, d, proj) stop("not implemented")

detectSpClass <- function(x) {
  #names(sptable(wrld_simpl))
  #[1] "object" "part"   "cump"   "hole"   "x"      "y"
  #names(sptable(as(wrld_simpl, "SpatialLinesDataFrame")))
  #"object" "part"   "cump"   "x"      "y"
  #names(sptable(as(as(wrld_simpl, "SpatialLinesDataFrame"), "SpatialPointsDataFrame")))
  # "cump"   "object" "x"      "y"
  gn <-geomnames()
  if (all(gn$SpatialPolygonsDataFrame %in% names(x))) return("SpatialPolygonsDataFrame")
  if (all(gn$SpatialLinesDataFrame %in% names(x))) return("SpatialLinesDataFrame")
  if (all(gn$SpatialPointsDataFrame %in% names(x))) return("SpatialPointsDataFrame")
  stop('cannot create Spatial* object from this input')

}

geomnames <- function() {
  list(SpatialPolygonsDataFrame = c("object", "part", "cump", "hole", "x", "y"),
       SpatialLinesDataFrame = c("object", "part", "cump", "x", "y"),
       SpatialPointsDataFrame = c("cump", "object", "x", "y"))
}

## adapted from raster package R/geom.R
.polysGeom <-   function(x, sepNA=FALSE, ...) {

  nobs <- length(x@polygons)
  objlist <- list()
  cnt <- 0
  if (sepNA) {
    sep <- rep(NA,5)
    for (i in 1:nobs) {
      nsubobs <- length(x@polygons[[i]]@Polygons)
      ps <- lapply(1:nsubobs,
                   function(j)
                     rbind(cbind(j, j+cnt, x@polygons[[i]]@Polygons[[j]]@hole, x@polygons[[i]]@Polygons[[j]]@coords), sep)
      )
      objlist[[i]] <- cbind(i, do.call(rbind, ps))
      cnt <- cnt+nsubobs
    }
  } else {
    for (i in 1:nobs) {
      nsubobs <- length(x@polygons[[i]]@Polygons)
      ps <- lapply(1:nsubobs,
                   function(j)
                     cbind(j, j+cnt, x@polygons[[i]]@Polygons[[j]]@hole, x@polygons[[i]]@Polygons[[j]]@coords)
      )
      objlist[[i]] <- cbind(i, do.call(rbind, ps))
      cnt <- cnt+nsubobs
    }
  }

  obs <- do.call(rbind, objlist)
  colnames(obs) <- c('object', 'part', 'cump', 'hole', 'x', 'y')
  rownames(obs) <- NULL

  if (sepNA) {
    obs[is.na(obs[,2]), ] <- NA
  }
  return( obs )
}




.linesGeom <-  function(x, sepNA=FALSE, ...) {

  nobs <- length(x@lines)
  objlist <- list()
  cnt <- 0
  if (sepNA) {
    sep <- rep(NA, 4)
    for (i in 1:nobs) {
      nsubobj <- length(x@lines[[i]]@Lines)
      ps <- lapply(1:nsubobj,
                   function(j)
                     rbind(cbind(j, j+cnt, x@lines[[i]]@Lines[[j]]@coords), sep)
      )
      objlist[[i]] <- cbind(i, do.call(rbind, ps))
      cnt <- cnt+nsubobj
    }
  } else {
    for (i in 1:nobs) {
      nsubobj <- length(x@lines[[i]]@Lines)
      ps <- lapply(1:nsubobj, function(j) cbind(j, j+cnt, x@lines[[i]]@Lines[[j]]@coords))
      objlist[[i]] <- cbind(i, do.call(rbind, ps))
      cnt <- cnt+nsubobj
    }
  }
  obs <- do.call(rbind, objlist)
  colnames(obs) <- c('object', 'part', 'cump', 'x', 'y')
  rownames(obs) <- NULL

  if (sepNA) {
    obs[is.na(obs[,2]), ] <- NA
  }
  return (obs)
}



.pointsGeom <-  function(x, ...) {
  xy <- coordinates(x)
  ##xy <- cbind(1:nrow(xy), xy)
  if (is.list(x@coords)) {
    br <- rep(seq_along(x@coords), unlist(lapply(x@coords, nrow)))

  } else {
    br <- seq(nrow(xy))


  }
  xy <- cbind(br, br, xy)
  colnames(xy) <- c('cump', 'object', 'x', 'y')
  return(xy)
}
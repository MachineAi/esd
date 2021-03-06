
## https://www.unidata.ucar.edu/software/netcdf/docs/netcdf/CDF-Data-Types.html:
## short: 16-bit signed integers. The short type holds values between -32768 and 32767.

write2ncdf4 <- function(x,...) UseMethod("write2ncdf4")

write2ncdf4.default <- function(x,...) {
}

write2ncdf4.field <- function(x,fname='field.nc',prec='short',scale=0.1,offset=NULL,
                              torg="1970-01-01",missval=-999,verbose=FALSE) {
  if (verbose) print('write2ncdf4.field')

  y <- coredata(x)
  if (is.null(offset)) offset <- mean(y,na.rm=TRUE)
  if (is.null(scale)) scale <- 1
  y <- t(y)
  y[!is.finite(y)] <- missval
  y <- round((y-offset)/scale)
  if (verbose) print(attr(y,'dimensions'))
  dim(y) <- attr(x,'dimensions')

  dimlon <- ncdim_def( "longitude", "degree_east", lon(x) )
  dimlat <- ncdim_def( "latitude", "degree_north", lat(x) )
  if (inherits(index(x),c('numeric','integer')))
      index(x) <- as.Date(paste(index(x),'-01-01',sep=''))
  
  dimtim <- ncdim_def( "time", paste("days since",torg),
                      as.numeric(as.Date(index(x),origin=torg)) )
  x4nc <- ncvar_def(varid(x)[1], unit(x)[1], list(dimlon,dimlat,dimtim), -1, 
                    longname=attr(x,'longname'), prec=prec)
     
     # Create a netCDF file with this variable
  ncnew <- nc_create( fname, x4nc )

  # Write some values to this variable on disk.
  ncvar_put( ncnew, x4nc, round(y) )
  ncvar_put( ncnew, x4nc, round(y) )
  ncatt_put( ncnew, x4nc, "add_offset", offset, prec="float" )
  ncatt_put( ncnew, x4nc, "scale_factor", scale, prec="float" ) 
  ncatt_put( ncnew, x4nc, "_FillValue", missval, prec="float" ) 
  ncatt_put( ncnew, x4nc, "missing_value", missval, prec="float" ) 
  ncatt_put( ncnew, 0, "description", 
             "Saved from esd using write2ncdf4")
  nc_close(ncnew)
}



# https://www.unidata.ucar.edu/software/netcdf/docs/netcdf/CDL-Data-Types.html:
# short: 16-bit signed integers. The short type holds values between -32768 and 32767. 

write2ncdf4.station <- function(x,fname,prec='short',offset=0, missval=-999,
                                scale=0.1,torg='1899-12-31',verbose=FALSE) {
  #require(ncdf4)

  if (!inherits(x,"station")) stop('x argument must be a station object') 
  
  if (verbose) print('write.ncdf')
  
  ## Write a station object as a netCDF file using the short-type combined with add_offsetet and scale_factor
  ## to reduce the size.   
  ## Examine the station object: dimensions and attributes  

  ## Get time 
  nt <- dim(x)[1]
  ns <- dim(x)[2]
  
  ## if (is.null(d)) d <- c(length(x),1)
  if (verbose) print(paste('Number of stations: ',paste(ns)))
  
  atts <- names(attributes(x))
 
  if (verbose) print(atts)
  attr2attr <- is.element(atts,c('station_id','variable','unit','longname','location','country'))
  ##atts <- atts[iattr2ncdf]
  attr2var <- is.element(atts,c('longitude','latitude','altitude'))
  na <- length(atts); la <- rep(0,na)
  attrprec <- rep('character',na)
  attr(x,'quality') <- as.character(attr(x,'quality'))
  if (verbose) print(paste('attributes:', paste(atts, collapse=', '),
                           '; types:',paste(attrprec, collapse=', ')))
  
  y <- t(coredata(x))
  y[!is.finite(y)] <- missval
  y <- round((y - offset)/scale)
  dim(y) <- c(ns,nt)
  
  if (is.null(attr(x,'calendar')))
      attr(x,'calendar') <- 'standard'

  if (!is.na(attr(x,'calendar')))
      calendar <- attr(x,'calendar')
  else calendar <- 'standard'

  if (class(index(x))=='Date')
      time <- julian(index(x)) - julian(as.Date(torg))
  else if (inherits(x,'annual'))
      time <- julian(as.Date(paste(year(x),'01-01',sep='-')))-julian(as.Date(torg))
  
# Attributes with same number of elements as stations are saved as variables
  
# Define the dimensions
  if (verbose) print('Define dimensions')
  if (verbose) print(stid(x))
  dimS <- ncdim_def( name="stid", units="number",vals=c(1:ns))
  dimT <- ncdim_def( name="time", units=paste("days since",torg), vals=time, calendar=calendar)
  
  if (verbose) print('Define variable')

  lon <- lon(x)
  lat <- lat(x)
  alt <- alt(x)
  
  if (verbose) print(paste('create netCDF-file',fname))
     
  if (verbose) {str(y); print(summary(c(y)))}
  latid <- ncvar_def(name="lat",dim=list(dimS), units="degrees_north", missval=missval,longname="latitude", prec=prec,verbose=verbose)

  lonid <- ncvar_def(name="lon",dim=list(dimS), units="degrees_east", missval=missval,longname="longitude", prec=prec,verbose=verbose)
   altid <- ncvar_def(name="alt",dim=list(dimS), units="meters", missval=missval,longname="altitude", prec=prec,verbose=verbose)

  locid <- ncvar_def(name="loc",dim=list(dimS),units="strings",prec="char",longname="location",verbose=verbose)
  
  ncvar <- ncvar_def(name=varid(x)[1],dim=list(dimT,dimS), units=ifelse(unit(x)[1]=="°C", "degC",unit(x)[1]),longname=attr(x,'longname')[1], prec="float",compression=9,verbose=verbose)

  ncid <- nc_create(fname,vars=list(ncvar,lonid,latid,altid,locid)) ## vars)
  ncvar_put( ncid, ncvar, y)
  ncatt_put( ncid, ncvar, 'add_offset',offset,prec='float')
  ncatt_put( ncid, ncvar, 'scale_factor',scale,prec='float')
  ncatt_put( ncid, ncvar, 'missing_value',missval,prec='float')
  ncatt_put( ncid, ncvar, 'location',paste(loc(x),collapse=", "),prec='char')
  ncatt_put( ncid, ncvar, 'country',paste(cntr(x),collapse=", "),prec='character')
  ncvar_put( ncid, lonid, attr(x,"longitude"))
  ncvar_put( ncid, latid, attr(x,"latitude"))
  ncvar_put( ncid, altid, attr(x,"altitude"))
  ncvar_put( ncid, locid, as.array(attr(x,"location")))
  
  ## global attributes
  ncatt_put( ncid, 0, 'title', paste(levels(factor(attr(x,"info"))),collapse="/"))
  ncatt_put( ncid, 0, 'source', paste(levels(factor(attr(x,"source"))),collapse="/"))
  ncatt_put( ncid, 0, 'history', paste(unlist(attr(tmax,"history")),collapse="/"))
  ncatt_put( ncid, 0, 'references', paste(levels(factor(attr(tmax,"reference"))),collapse="/"))
  
  nc_close(ncid)
  if (verbose) print('close')
}


## These small functions are common code that simplify saving data as netCDF 
write2ncdf4.pca <- function(x,fname='esd.pca.nc',prec='short',verbose=FALSE,scale=0.01,offset=0,missval=-99) {
  if (verbose) print('write2ncdf4.pca')
  pcaatts <- names(attributes(x))
  pattern <- attr(x,'pattern')
  pattern[!is.finite(pattern)] <- missval
  dpat <- dim(pattern); attributes(pattern) <- NULL; dpat -> dim(pattern)
  if (verbose) print(pcaatts)
  if (class(index(x))=='Date') index(x) <- year(x) + (month(x)-1)/12
  ## set up the dimensions of the PCA
  dimpca <- ncdim_def( "i_pca", "index", 1:dim(x)[2] )
  dimtim <- ncdim_def( "time_pca", "year", index(x) )
  dimxy <- ncdim_def( "space_pca", "index", 1:dim(pattern)[1] )
  dimsea <- ncdim_def( "season", "index", 1:4 )
  pca <- ncvar_def("pca", "weights", list(dimtim,dimpca), missval, 
                    longname='principal components', prec=prec)
  pat <- ncvar_def("pattern_pca", "weights", list(dimxy,dimpca), missval, 
                    longname='principal component analysis patterns', prec=prec)
  lon <- ncvar_def("longitude", "degree_east", dimxy,missval, 
                    longname='longitude', prec='float')
  lat <- ncvar_def("latitude", "degree_north", dimxy,missval, 
                    longname='latitude', prec='float')
  alt <- ncvar_def("altitude", "m", dimxy,missval, 
                    longname='altitude', prec='float')
  stid <- ncvar_def("station_id", "number", dimxy,missval, 
                    longname='station ID', prec="integer")
#  loc <- ncvar_def("location", "name", dimxy,"NA", 
#                    longname='location name', prec="char")
#  cntr <- ncvar_def("country", "name", dimxy,"NA", 
#                    longname='country name', prec="char")
#  src <- ncvar_def("src", "name", dimxy,"NA", 
#                    longname='source', prec="char")
  lambda <- ncvar_def("lambda", "number", dimpca,missval, 
                    longname='eigenvalues', prec="float")
  if (is.numeric(index(x))) index(x) <- year(x)
  dpca <- dim(pca); attributes(pca) <- NULL; dpca -> dim(pca)
  ncvar_put( nc, pca, round((pca - offset)/scale) )
  ncatt_put( nc, pca, "add_offset", offset, prec="float" )
  ncatt_put( nc, pca, "scale_factor", scale, prec="float" ) 
  ncatt_put( nc, pca, "_FillValue", missval, prec="float" ) 
  ncatt_put( nc, pca, "missing_value", missval, prec="float" ) 
  ncvar_put( nc, pat, round((pattern - offset)/scale) )
  ncatt_put( nc, pat, "add_offset", offset, prec="float" )
  ncatt_put( nc, pat, "scale_factor", scale, prec="float" ) 
  ncatt_put( nc, pat, "_FillValue", missval, prec="float" ) 
  ncatt_put( nc, pat, "missing_value", missval, prec="float" ) 
  ncatt_put( nc, pat, "dimensions_pca", paste(attr(pattern,'dimensions'),collapse=', '), prec="char" ) 
  ncatt_put( nc, pat, "locations", paste(loc(x),collapse=','), prec="char" ) 
  ncatt_put( nc, pat, "country", paste(cntr(x),collapse=','), prec="char" ) 
  ncatt_put( nc, pat, "source", paste(src(x),collapse=','), prec="char" ) 
  ncvar_put( nc, tim, index(x) )
  ncvar_put( nc, lon, lon(x) )
  ncvar_put( nc, lat, lat(x) )
  ncvar_put( nc, alt, alt(x) )
#  ncvar_put( nc, loc, loc(x) )
  ncvar_put( nc, stid, stid(x) )
#  ncvar_put( nc, cntr, cntr(x) )
#  ncvar_put( nc, src, src(x) )
  ncvar_put( nc, lambda, attr(x,'eigenvalues') )
  ncatt_put( nc, pca, "history", paste(attr(x,'history'),collapse=';'), prec="char" )
}

write2ncdf4.eof <- function(x,fname='eof.nc',prec='short',scale=10,offset=NULL,torg="1970-01-01",missval=-999) {
}

  
write2ncdf4.dsensemble <- function(x,fname='esd.dsensemble.nc',prec='short',offset=0,scale=0.1,
                              torg="1970-01-01",missval=-99,verbose=TRUE) {
  ## prec - see http://james.hiebert.name/blog/work/2015/04/18/NetCDF-Scale-Factors/
  if (verbose) print('write2ncdf4.field')
  class.x <- class(x)
  ngcms <- length(x) - 2
  ## Get the two first elements of the list which contain information common to the rest
  info <- x$info
  if (!is.null(x$pca)) pca <- x$pca
  if (!is.null(x$eof)) pca <- x$eof
  lons <- lon(pca)
  lats <- lat(pca)
  
  ## Clear these so that the rest are zoo objects describing the model runs
  x$info <- NULL
  x$pca <- NULL
  x$eof <- NULL
  names.x <- names(x)
  if (verbose) print(names.x)
  
  ## Define the variables and dimensions
  if (verbose) {print('Check index type - set to year'); print(index(x[[1]]))}
  if (is.list(x)) {
    if (class(index(x))=='Date') tim <- year(x[[1]]) + (month(x[[1]])-1)/12 else
                                 tim <- year(x[[1]])
    dimgcm <- dim(x[[1]])
    nloc <- length(x)
  } else {
    if (class(index(x))=='Date') tim <- year(x) + (month(x)-1)/12 else
                                 tim <- year(x)
    dimgcm <- dim(x)
    nloc <- 1
  }
  if (!is.null(pca)) {
    pcaatts <- names(attributes(pca))
    pattern <- attr(pca,'pattern')
    dpat <- dim(pattern)
  } else dpat <- 1
  if (verbose) {print(pcaatts); print(dim(pattern))}
  
  ## Set dimensions  
  dimtim <- ncdim_def( "time", 'year', as.integer(tim) )
  dimens <- ncdim_def( "ensemble_member", 'index', 1:nloc )
  if (!is.null(pca)) {
    if (class(index(pca))=='Date') index(pca) <- year(pca) + (month(pca)-1)/12 else
                                   index(pca) <- year(pca)
    dimpca <- ncdim_def( "i_pca", "index", 1:dimgcm[2] )
    dimtimpca <- ncdim_def( "time_pca", "year", index(pca) )
    if (length(dpat)==2) {
      dimxy <- ncdim_def( "space_pca", "index", 1:dim(pattern)[1] )
    } else {
      dimx <- ncdim_def( "longitude", "degrees_east", lons )
      dimy <- ncdim_def( "latitude", "degrees_north", lats )
    }
  }
  dimsea <- ncdim_def( "season", "index", 1:4 )
  if (verbose) print(tim)
  varlist <- list() # For single-station dsensemble objects
  varlist$gcm <- ncvar_def("gcm", "weights", list(dimtim,dimpca,dimens), missval, 
                           longname='principal components', prec=prec)

  ## set up the dimensions of the PCA
  if (!is.null(pca)) {
    varlist$pca <- ncvar_def("PC", "weights", list(dimtimpca,dimpca), missval, 
                             longname='principal components', prec=prec)
    ## EOFs and PCA have different number of dimensions
    if (length(dpat)==2) {
      if (verbose) print('--- PCA ---')
      varlist$pat <- ncvar_def("pattern", "weights", list(dimxy,dimpca), missval, 
                               longname='principal component analysis patterns', prec=prec)
      varlist$lon <- ncvar_def("longitude", "degree_east", dimxy,missval, 
                               longname='longitude', prec='float')
      varlist$lat <- ncvar_def("latitude", "degree_north", dimxy,missval, 
                               longname='latitude', prec='float')
      varlist$alt <- ncvar_def("altitude", "m", dimxy,missval, 
                               longname='altitude', prec='float')
      varlist$stid <- ncvar_def("station_id", "number", dimxy,"NA", 
                                longname='station ID', prec="char")
      varlist$loc <- ncvar_def("location", "name", dimxy,"NA", 
                               longname='location name', prec="char")
      varlist$cntr <- ncvar_def("country", "name", dimxy,"NA", 
                                longname='country name', prec="char")
      varlist$src <- ncvar_def("src", "name", dimxy,"NA", 
                               longname='source', prec="char")
    } else
    if (length(dpat)==3) {
      if (verbose) print('--- EOF ---')
      varlist$pat <- ncvar_def("pattern", "weights", list(dimx,dimy,dimpca), missval, 
                               longname='principal component analysis patterns', prec=prec)
          }
    varlist$lambda <- ncvar_def("lambda", "number", dimpca,missval, 
                                longname='eigenvalues', prec="float")
  }

  if (verbose) print(names(varlist))
     
  ## Create a netCDF file with this variable
  if (verbose) print('Create netCDF-file')

  ncnew <- nc_create( fname, varlist,verbose=verbose)
  
  if (verbose) print('write pca/eof data')                   
  ## Add the information stored in the list elements as 2D zoo objects
  X <- unlist(lapply(x,function(x) x[1:239,]))
  X <- round((X - offset)/scale)
  if (verbose) print(c(length(X),dim(x[[1]]),length(x)))
  if (verbose) print(table(unlist(lapply(x,dim))))
  dim(X) <- c(dim(x[[1]]),length(x))
  if (verbose) print('write zoo data')     
  ## Write some values to this variable on disk: GCM results
  ncvar_put( ncnew, varlist$gcm, X )
  ncatt_put( ncnew, varlist$gcm, "add_offset", offset, prec="float" )
  ncatt_put( ncnew, varlist$gcm, "scale_factor", scale, prec="float" ) 
  ncatt_put( ncnew, varlist$gcm, "_FillValue", missval, prec="float" ) 
  ncatt_put( ncnew, varlist$gcm, "missing_value", missval, prec="float" )
  ## GCM names
  if (verbose) print('write GCM names')  
  ncatt_put( ncnew, varlist$gcm, "GCM runs", paste(names.x,collapse=','),prec="char" )
  ## PCA/EOF variables:
  if (verbose) print('EOF/PCA variables')
  ncvar_put( ncnew, varlist$pca, round((pca - offset)/scale) )
  ncatt_put( ncnew, varlist$pca, "add_offset", offset, prec="float" )
  ncatt_put( ncnew, varlist$pca, "scale_factor", scale, prec="float" ) 
  ncatt_put( ncnew, varlist$pca, "_FillValue", missval, prec="float" ) 
  ncatt_put( ncnew, varlist$pca, "missing_value", missval, prec="float" ) 
  ncvar_put( ncnew, varlist$pat, round((pattern - offset)/scale) )
  ncatt_put( ncnew, varlist$pat, "add_offset", offset, prec="float" )
  ncatt_put( ncnew, varlist$pat, "scale_factor", scale, prec="float" ) 
  ncatt_put( ncnew, varlist$pat, "_FillValue", missval, prec="float" ) 
  ncatt_put( ncnew, varlist$pat, "missing_value", missval, prec="float" ) 
  ncatt_put( ncnew, varlist$pat, "dimensions_pca", paste(attr(pattern,'dimensions'),collapse=', '), prec="char" )
  ## If the object contains PCAs
  if (length(dpat)==2) {
    if (verbose) print('PCA only variables')
    ncvar_put( ncnew, varlist$lon, lon(x) )
    ncvar_put( ncnew, varlist$lat, lat(x) )
    ncvar_put( ncnew, varlist$alt, alt(x) )
    ncvar_put( ncnew, varlist$loc, loc(x) )
    ncvar_put( ncnew, varlist$stid, as.character(stid(x)) )
    ncvar_put( ncnew, varlist$cntr, cntr(x) )
    ncvar_put( ncnew, varlist$src, src(x) )
    ncvar_put( ncnew, varlist$lambda, attr(pca,'eigenvalues') )
  } else if (length(dpat)==3)
    ncvar_put( ncnew, varlist$lambda, attr(pca,'eigenvalues') )
  if (verbose) print('history')
  ncatt_put( ncnew, varlist$pca, "history", paste(attr(x,'history'),collapse=';'), prec="char" )  
  ## Global attributes:
  ncatt_put( ncnew, 0, "description", "Saved from esd using write2ncdf4.dsensemble")
  ncatt_put( ncnew, 0, "class", paste(class.x,collapse='-'))
  nc_close(ncnew)
  if (verbose) print(paste('Finished sucessfully - file', fname))  
}

## Used to check the contents in netCDF file - to use in retrieve to call retrieve.dsenemble,
## retrieve.eof or retrieve.station rather than the standard form to read field objects.
## Assumes that empty class attribute means a field object
file.class <- function(ncfile,path=NULL,type="ncdf4") {
  
  if (type=='ncdf4') {
    nc <- nc_open(file.path(path,ncfile))
    dimnames <- names(nc$dim)
    class <- ncatt_get(nc,0,'class')
    close.ncdf(nc)
  } else {
    nc <- open.ncdf(file.path(path,ncfile))
    dimnames <- names(nc$dim)
    class <- get.att.ncdf(nc,0,'class')
    close.ncdf(nc)
  }
  attr(class,'dimnames') <- dimnames
  return(class)
}
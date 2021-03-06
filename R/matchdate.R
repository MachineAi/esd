matchdate <- function(x,it,verbose=FALSE) {
  t <- index(x)

  if (inherits(it,'character')) {
    nc <- nchar(it)
    # Simple fix for short date strings
    if ((nc[1]==4) & (length(it)>1)) it <- paste(it,'-01-01',sep='') else
    if ((nc[1]==4) & (length(it)==1))
      it <- c(paste(it,'-01-01',sep=''),paste(it,'-12-31',sep='')) else
    if (nc[1]==7) it <- paste(it,'-01',sep='')
    it <- as.Date(it)
  } 
  if (inherits(it,c('field','station','zoo'))) it <- index(it)
  if (is.logical(it)) it <- (1 <- length(it))[it]

  if (verbose) print(paste('matchdate: t = [',min(t),'-',max(t),
                           '], it= [',min(it),'-',max(it),']'))

  #print(c(t[1],it[1]));   print(c(class(t),class(it)))
  
  # Convert indeces all to 'Date':
  # The time index of x:
  #browser()
  if ( (is.numeric(t)) | (is.integer(t)) |
     ( (is.character(t)) & (nchar(t[1])==4) ) ) t <- as.Date(paste(t,'-01-01',sep='')) 
  if ( (is.character(t)) & (nchar(t[1])==10) )  t <- as.Date(t)

  # The time index to match:
  it0 <- it
  if ( (is.numeric(it)) | (is.integer(it)) |
     ( (is.character(it)) & (nchar(it[1])==4) ) ) it <- as.Date(paste(it,'-01-01',sep='')) 
  if ( (is.character(it)) & (nchar(it[1])==10) )  it <- as.Date(it)
  
  if (verbose) print(c(t[1],it[1],it0[1]))
  
  if (length(it)>2) {
    if (verbose) {print(paste('select',length(it),'dates')); print(it)}
    y <- x[is.element(t,it),]
    ii <- is.element(it,t)
    if (verbose) print(paste(sum(ii),'matching dates'))
    if (sum(ii)==length(index(y))) index(y) <- it0[ii] # REB 2015-01-14: to ensure same index class as it.
    if (verbose) {print('matchdate: index(y)'); print(index(y))}
    #browser()
  } else if (length(it)==2) {
  # Pick an interval
    if (verbose) print(paste('select an interval',it,collapse=' '))
    dates <- range(it)
    y <- window(x,start=dates[1],end=dates[2])
  } else {
  # Pick one date:
    if (verbose) print('one date')
    if (inherits(x,c('day','zoo'))) ii <- is.element(t,it) else
    if (inherits(x,c('month','seasonal')))
      ii <- is.element(year(t)*100+month(t),year(it)*100+month(it)) else
#    if (inherits(x,'annual')) ii <- is.element(year(t),year(it)*100) # REB: bug year(it)*100
    if (inherits(x,'annual')) ii <- is.element(year(t),year(it)) # REB 2015-01-21
    #print(class(x)); print(sum(ii))
    if (sum(ii) > 0) y <- x[ii,] else {
  # Weight the two nearest in time
      if (verbose) print(paste('matchdate: Weight the two nearest in time because no overlaps: sum(ii)=',
                               sum(ii),'t = [',max(t),'-',min(t),'], it= [',
                               max(it),'-',min(it),']'))
      i1 <- t <= it; t1 <- max(t[i1])
      i2 <- t > it; t2 <- min(t[i2])
      dt <- t2 - t1
      if (verbose) print(c(max(t[i1]),min(t[i2]),sum(is.element(t,t1))))
      y1 <- (it-t1)/dt*x[is.element(t,t1),]
      y2 <- (t2 - it)/dt*x[is.element(t,t2),]
      y <- zoo(coredata(y1)+coredata(y2),order.by=it)
    }
  }

  y <- attrcp(x,y)
  if (!is.null(err(x))) {
    if (verbose) print('match date for error')
    attr(y,'standard.error') <- matchdate(err(x),y)
    #str(err(y))
  }
  
  if (!is.null(attr(x,'n.apps'))) {
    attr(y,'n.apps') <- attr(x,'n.apps')
    attr(y,'appendix.1') <- attr(x,'appendix.1')
  }
  nt <- index(y)
  attr(y,'history') <- history.stamp(x)
  #print(index(y)); print(class(index(y)))
  class(y) <- class(x)
  if (inherits(y,'field')) attr(y,'dimensions') <- c(attr(x,'dimensions')[1:2],length(nt))
  if (!is.null(attr(y,'count'))) attr(y,'count') <- c(attr(y,'count')[1:2],length(nt))
  invisible(y) 
}

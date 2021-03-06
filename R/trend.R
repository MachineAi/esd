# R.E. Benestad, met.no, Oslo, Norway 12.04.2013
# rasmus.benestad@met.no
#------------------------------------------------------------------------


trend<-function(x,result="trend",model="y ~ t",...) UseMethod("trend")

trend.default <- function(x,result="trend",model="y ~ t",verbose=FALSE,...) {
  if (verbose) print("trend.default")
  trendx <- data.frame(t=1:length(index(x)),y=x)
  eval(parse(text=paste("xt <- lm(",model,",data=trendx)")))
  y <- switch(result,"trend"=zoo(predict(xt,newdata=trendx),order.by=index(x)),
                     "residual"=zoo(xt$residuals,order.by=index(x)),
                      "coef"=trend.coef(coredata(x)), # REB 2016-07-28
                      "err"=trend.err(coredata(x)),
                      "pval"=trend.pval(coredata(x)))
  attr(y,'history') <- history.stamp(x)
  return(y)
}

trend.one.station <- function(x,result="trend",model="y ~ t",verbose=FALSE,...) {
  if (verbose) print(paste("trend.one.station",result))
  #print(class(index(x)))
  if (class(index(x))=="Date") {
    if (verbose) print("Date index")
    year <- as.numeric( format(index(x), '%Y') ) 
    month <- as.numeric( format(index(x), '%m') )
    day <- as.numeric( format(index(x), '%d') )
    trendx <- data.frame(t=year + (month - 0.5)/12 + (day - 1)/365.25,
                         y=coredata(x))
  } else if ( (class(index(x))=="numeric") |
              (class(index(x))=="integer") ) {
    if (verbose) print("Integer index")
    trendx <- data.frame(t=index(x),y=coredata(x))
              }
  eval(parse(text=paste("xt <- lm(",model,",data=trendx)")))
  if (verbose) str(xt)

  y <- switch(result,"trend"=zoo(predict(xt,newdata=trendx),order.by=index(x)),
                     "residual"=zoo(xt$residuals,order.by=index(x)),
                      "coef"=trend.coef(coredata(x)), # REB 2016-07-28
                      "err"=trend.err(coredata(x)),
                      "pval"=trend.pval(coredata(x)))
  if (verbose) str(y)
  attr(y,'coefficients') <- summary(xt)$coefficients
  #attr(y,'original data') <-  x
  attr(y,'aspect') <- result
  attr(y,'lm') <- xt
  #attr(y,'call') <- match.call()
 if (result %in% c("trend","residual")) y <- attrcp(x,y,ignore='aspect') else {
        attr(y,'location') <- loc(x)
        attr(y,'longitude') <- lon(x)
        attr(y,'latitude') <- lat(x)
        attr(y,'altitude') <- alt(x)
        attr(y,'cntr') <- cntr(x)
        attr(y,'stid') <- stid(x)
        attr(y,'history') <- attr(x,'history')
      }
  attr(y,'history') <- history.stamp(x)
  return(y)
}

trend.station <- function(x,result="trend",model="y ~ t",verbose=FALSE,...) {
  if (verbose) print(paste("trend.station",result))
  # Allow for a set of stations.
  d <- dim(x)
  if (is.null(d)) y <- trend.one.station(x,result=result,model=model,verbose=verbose) else {
      if (result %in% c("trend","residual")) Y <- x*NA else Y <- rep(NA,d[2])
      for (i in 1:d[2]) {
        y <- trend.one.station(x[,i],result=result,model=model,verbose=verbose)
        if (result %in% c("trend","residual"))Y[,i] <- y else Y[i] <- y
      }
      y <- Y
      #nattr <- softattr(x)
      #print("+")
      #for (i in 1:length(nattr))
      #  attr(y,nattr[i]) <- attr(x,nattr[i])
      if (result %in% c("trend","residual")) y <- attrcp(x,y) else {
        attr(y,'location') <- loc(x)
        attr(y,'longitude') <- lon(x)
        attr(y,'latitude') <- lat(x)
        attr(y,'altitude') <- alt(x)
        attr(y,'cntr') <- cntr(x)
        attr(y,'stid') <- stid(x)
        attr(y,'history') <- attr(x,'history')
      }
    }
  #attr(y,'call') <- match.call()
  attr(y,'history') <- history.stamp(x)
  return(y)
}

trend.eof <- function(x,result="trend",model="y ~ t",verbose=FALSE,...) {
  if (verbose) print(paste("trend.eof",result))
  class(x) -> cls
  if (class(index(x))=="Date") {
    year <- as.numeric( format(index(x), '%Y') ) 
    month <- as.numeric( format(index(x), '%m') )
    day <- as.numeric( format(index(x), '%d') )
    t <- year + (month - 0.5)/12 + (day - 1)/365.25
  } else if ( (class(index(x))=="numeric") |
              (class(index(x))=="integer") )
    t=index(x)
  #print("detrend.eof")
  d <- dim(x)
  Y <- x
  #print(dim(y))
  nc <- sum(is.element(strsplit(model,"")[[1]],"t")) + 1
  coefficients <- matrix(rep(NA,nc*d[2]),nc,d[2])
  for (i in 1:d[2]) {
    trendx <- data.frame(t=t,y=coredata(x[,i]))
    eval(parse(text=paste("xt <- lm(",model,",data=trendx)")))
  #print(summary(xt))
    Y[,i] <- switch(result,"trend"=zoo(predict(xt,newdata=trendx),order.by=index(x)),
                           "residual"=zoo(xt$residuals,order.by=index(x)))
    coefficients[,i] <- xt$coefficients
    #xt <- lm(y ~ t,data=trendx)
    #z <- predict(xt); print(length(z))
    #Y[,i] <- xt$residual
    #print(summary(Y[,i]))
  }
  #X <- zoo(Y,order.by=index(x))
  #nattr <- softattr(x)
  #for (i in 1:length(nattr))
  #  attr(Y,nattr[i]) <- attr(x,nattr[i])
  #mostattributes(Y) <- attributes(x)
  attr(Y,'coefficients') <- coefficients
  attr(Y,'lm') <- xt
  attr(Y,'original data') <-  x
  #attr(Y,'call') <- match.call()
  Y <- attrcp(x,Y)
  attr(Y,'history') <- history.stamp(x)
  
  #plot(x[,1]); lines(X[,1],col="red",lty=2)
  return(Y)
}

trend.field <- function(x,result="trend",model="y ~ t",verbose=FALSE,...) {

  gettrend <- function(x,model="y ~ t") {
    #browser()
    #print(match.call()); str(x); print(model)
    #print(table(year))
    trendx <- data.frame(y=x,t=1:length(x))
    eval(parse(text=paste("trendfit <- lm(",model,",data=trendx)")))
    trend <- predict(trendfit,newdata=trendx)
    return(trend)
  }

  if (verbose) print(paste("trend.field",result))
  class(x) -> cls
  
  print("detrend.field")
  d <- dim(x)
  Y <- x
  #print(dim(Y))
#  for (i in 1:d[2]) {
#    #browser()
#    
#    
#    #print(summary(xt))
#    #str(xt)

  t <- index(x)
  datetype <- class(t)

  if ( (datetype=="numeric") |
                ( (datetype=="character") & (nchar(t[1]==4)) ) ) {
    index(x) <- as.Date(paste(t,'-01-01',sep=''))
  }
  year <- as.numeric( format(index(x), '%Y') ) 
  month <- as.numeric( format(index(x), '%m') )
  day <- as.numeric( format(index(x), '%d') )
  t <- year + (month - 0.5)/12 + (day - 1)/365.25
  nt <- length(t)
  
  #print("test"); ttt <- gettrend(x[,1]); plot(ttt,main="test: trend")
  xt <- apply(x,2,gettrend,model)
  trend <- zoo(xt,order.by=index(x))
  #print("residual"); print(dim(x)); print(dim(trend))
  Y <- x - trend
  #print("attributes")
  Y <- attrcp(x,Y,ignore="aspect")
  #print("pattern"); print(nt)
  pattern <- 10*(coredata(trend)[nt,] - coredata(trend)[1,])/(t[nt]-t[1])
  #print("dimensions")
  dim(pattern) <- attr(x,'dimension')[1:2]
  attr(Y,'dimension') <- attr(x,'dimension')
  attr(Y,'pattern') <- pattern
  attr(Y,'aspect') <- result
  attr(Y,'history') <- history.stamp(x)
  if (result=="trend") {
    class(Y) <- c("trend",class(x))
    
  } else {
    class(Y) <- class(x)
  }
  return(Y)
}

trend.zoo <- function(x,result="trend",model="y ~ t",verbose=FALSE,...) {
  if (verbose) print("trend.zoo")
  if (length(dim(x))==2) {
    y <- trend.zoo.multi(x,result=result,model=model,...)
    return(y)
  }
  trendx <- data.frame(t=year(x),y=coredata(x))
  eval(parse(text=paste("xt <- lm(",model,",data=trendx)")))
  y <- switch(result,"trend"=zoo(predict(xt,newdata=trendx),order.by=index(x)),
                     "residual"=zoo(xt$residuals,order.by=index(x)))
  attr(y,'history') <- history.stamp(x)
  if (!is.null(attr(x,'unit'))) unit <- attr(x,'unit') else
                                unit <- 'x'
  attr(y,'lm') <- xt
  attr(y,'unit') <- paste(unit,'/ year')
  return(y)
  invisible(y)
}

trend.zoo.multi <- function(x,result="trend",model="y ~ t",verbose=FALSE,...) {
  if (verbose) print(paste("trend.station.multi",result))
  y <- apply(coredata(x),2,trend,result=result,model=model)
  y <- zoo(y,order.by=index(x))
  return(y)
}

## Compute the linear trend
trend.coef <- function(x,...) {
  t <- 1:length(x)
  model <- lm(x ~ t)
  y <- c(model$coefficients[2]*10)
  names(y) <- c("trend.coefficients")
  return(y)
}

## Compute the linear trend
trend.err <- function(x,...) {
  t <- 1:length(x)
  model <- lm(x ~ t)
  y <- c(summary(model)$coefficients[4]*10)
  names(y) <- c("trend.standard.error")
  return(y)
}


## Compute the p-value of the linear trend 
trend.pval <- function(x,...) {
    t <- 1:length(x)
    model <- lm(x ~ t)
    y <- anova(model)$Pr[1]
    names(y) <- c("trend.pvalue")
    return(y)
}

diagnose <-function(x,...) UseMethod("diagnose")

diagnose.default <- function(x,...) {
}

diagnose.comb <- function(x) {
  n.app <- attr(x,'n.apps')
  cols <- c("black","red","blue","darkgreen","darkred","darblue",
            "grey","green","mangenta","cyan")
  par(bty="n")
  plot(colMeans(x),cex=0.5,pch=19,
       main="Grid box mean value for combined fields")
  for (i in 1:n.app) {
    col <- cols[i%%10+1]
    y <- eval(parse(text=paste("attr(x,'appendix.",i,"')",sep="")))
    points(colMeans(y,na.rm=TRUE),col=col,cex=0.3)
  }
}


diagnose.eof <- function(x,...) {
  if (inherits(x,'comb')) y <- diagnose.comb.eof(x,...) else
                          y <- x
  return(y)
}

diagnose.comb.eof <- function(x,verbose=FALSE) {
  if (verbose) print("diagnose.comb.eof")
  ACF <- function(x) acf(x,plot=FALSE,na.action=na.omit)$acf[2]
  sign <- function(x,y) {z<-x*y; z[z<0] <- -1; z[z>0] <- 1; z}
  
  stopifnot(!missing(x), inherits(x,"eof"),inherits(x,"comb"))
  #print("diagnose.comb.eof")

  # The original field, e.g. reanalyses
  Y <- zoo(coredata(x),order.by=index(x))
  n <- attr(x,'n.apps')
  m <- length(attr(x,'eigenvalues'))
  dm <- rep(NA,n*m); dim(dm) <- c(n,m)
  sr <- dm; ar <- sr
  # The appended fields, e.g. GCM results
  rowname <- rep("GCM",n)
  for ( i in 1:n ) {
    eval(parse(text=paste("z <- attr(x,'appendix.",i,"')",sep="")))
    y <- zoo(coredata(z),order.by=index(z))

    # Extract a common period:
    X <- merge(Y,y,all=FALSE)
    Ym <- apply(coredata(X),2,mean,na.rm=TRUE)
    #print(Ym)
    #plot(Ym)
    Ys <- apply(coredata(X),2,sd,na.rm=TRUE)
    AR <- apply(coredata(X),2,ACF)
    ## KMP 2016-11-02 normalise the difference with the standard deviation
    #dm[i,] <- (Ym[1:m] - Ym[(m+1):(2*m)])
    dm[i,] <- (Ym[1:m] - Ym[(m+1):(2*m)])/Ys[1:m]
    # ratio: GCM/original
    # The problem is when the denominator is close to zero...
    #sr.test <- abs((Ys[(m+1):(2*m)] - Ys[1:m])/Ys[(m+1):(2*m)] )
    ## KMP 2016-11-02 removed abs and made the reference data the denominator
    sr.test <- (Ys[1:m] - Ys[(m+1):(2*m)] )/Ys[1:m]
    sr.test[!is.finite(sr.test)] <- 0
    sr[i,] <- sr.test
    ar[i,] <- 0.5*( 2- abs(AR[(m+1):(2*m)] - AR[1:m]) )*sign(AR[(m+1):(2*m)],AR[1:m])
    if (!is.null(attr(z,'source'))) rowname[i] <- attr(z,'source') else
    if (!is.null(attr(z,'model_id'))) rowname[i] <- attr(z,'model_id') 
  }
  rownames(dm) <- rowname
  rownames(sr) <- rowname
  rownames(ar) <- rowname
  ## KMP 19-11-2015: added abs(dm) because the sign is arbitrary
  diag <- list(mean.diff=dm,sd.ratio=sr,autocorr.ratio=ar,
               common.period=range(index(Y)),sd0=Ys,
               calibrationdata=attr(x,'source'))
  attr(diag,'variable') <- attr(x,'variable')
  attr(diag,'evaluation_period') <- paste(start(Y),end(Y),sep='-')
  #print(summary(diag))
  attr(diag,'history') <- history.stamp(x)
  class(diag) <- c("diagnose","comb","eof","list")
  invisible(diag)
}


diagnose.mvr <- function(x) {
  print("Not finished")
}

diagnose.cca <- function(x) {
  par(bty="n")
  plot(x$r,pch=19,cex=1.5,main="Canonical correlations",
       ylim=c(-1,1),ylab="correlation",xlab="pattern number")
  lines(c(0,length(x$r)),rep(0,2),col="grey")
  grid()
}

diagnose.station <- function(x,main='Data availability',
                            xlab='',ylab='station',
                            sub=src(x),verbose=FALSE,...) {
  if(verbose) print("diagnose.station")
  d <- dim(x)
  if (is.null(d)) {
    z <- diagnose.distr(x,...)
    return(z)
  }
  par(mar=c(5, 4, 4, 5),las=1,xpd=TRUE,cex.lab=0.5,cex.axis=0.5)
  
  image(index(x),1:d[2],coredata(x),
        main=main,xlab=xlab,ylab=ylab,
        sub=sub,...)
  axis(4,at=1:d[2],labels=substr(loc(x),1,6),cex.lab=0.5,col='grey')
  par(xpd=FALSE)
  nyrs <- length(rownames(table(year(x))))
  grid(nx=nyrs,ny=d[2])
}

diagnose.mvr <- function(x) {
  print("Not finished")
}

diagnose.cca <- function(x) {
  par(bty="n")
  plot(x$r,pch=19,cex=1.5,main="Canonical correlations",
       ylim=c(-1,1),ylab="correlation",xlab="pattern number")
  lines(c(0,length(x$r)),rep(0,2),col="grey")
  grid()
}

# Display cross-validation and statistics on the residual
diagnose.ds <- function(x,plot=FALSE,verbose=FALSE,new=TRUE) {
  
  ## the attribute 'evaluation' contains cross-validation
  if (verbose) print("diagnose.ds")
  stopifnot(inherits(x,"ds"))
  if (inherits(x,"pca")) {
    diagnostics <- diagnose.ds.pca(x,plot=plot,verbose=verbose)
    return(diagnostics)
  }
    
  if (!is.null(attr(x,'evaluation'))) xval <- attr(x,'evaluation') else
                                      xval <- crossval(x)
  ## Check the residuals
  y <- as.residual(x)
  z <- as.original.data(x)
  anova <- summary(attr(x,'model'))
  eof <- attr(x,'eof')
  if (inherits(eof,'comb')) bias.diag <- diagnose(eof) else
                            bias.diag <- NULL

  spectrum(coredata(y),plot=FALSE) -> s
  sp <- data.frame(y=log(s$spec),x=log(s$freq))
  if (length(dim(y))==0) {
    beta <- -summary(lm(y ~ x, data=sp))$coefficient[2]
    beta.error <- summary(lm(y ~ x, data=sp))$coefficient[4]
    ar1 <- acf(y,plot=FALSE)$acf[2]
  } else {beta <- NA; beta.error <- NA; ar1 <- NA}
  
  if (plot) {
    ## Timer series of the residual
    if (new) dev.new()
    par(bty="n",mfcol=c(3,2))
    plot(xval,plot.type='single',col=c("blue","red"),
         main='cross-validation',
         sub=paste('correlation=',round(cor(xval)[2,1],2)))

    plot(y,main='contains a trend?')
    lines(trend(y))
    
    ## Auto-correlation of the residual
    ar <- acf(y,plot=TRUE)
    plot(ar$lag,ar$acf,type='b',main='Residual ACF?')

    ## Rsidual correlated with original data?
    plot(coredata(z),coredata(y),main='Residual correlated with original data?')

    #sp <- spectrum(y,plot=FALSE)
    plot(s$freq,s$spec,type='l',main='Residual power-spectrum',log='xy')

    ## Residual normally distributed?
    qqnorm(y,main='Residual normally distributed?')
    qqline(y)

    if  (!is.null(attr(x,'diagnose'))) 
      plot(attr(x,'diagnose'))
  }
  
  diagnostics <- list(residual=y,anova=anova,xval=xval,bias.diag=bias.diag,
                      ar1=ar1,beta=beta, H=(beta+1)/2, beta.error=beta.error)
  return(diagnostics)
}

# Display cross-validation and statistics on the residual
diagnose.ds.pca <- function(x,plot=FALSE,verbose=FALSE,new=TRUE) {

  ## the attribute 'evaluation' contains cross-validation
  if (verbose) print("diagnose.ds.pca")
  if (!is.null(attr(x,'evaluation'))) xval <- attr(x,'evaluation') else
                                      xval <- crossval(x)
  ## Check the residuals
  y <- as.residual(x)
  y <- as.station(y)
  z <- matchdate(as.original.data(x),y)
  anova <- summary(attr(x,'model'))
  eof <- attr(x,'eof')
  if (inherits(eof,'comb')) bias.diag <- diagnose(eof) else
                            bias.diag <- NULL

  w <- coredata(y)
  ok <- apply(w,1,function(x) !any(is.na(x)))
  w <- w[ok,]
  spectrum(w,plot=FALSE) -> s
  sp <- data.frame(y=log(s$spec),x=log(s$freq))
  if (length(dim(y))==0) {
    beta <- -summary(lm(y ~ x, data=sp))$coefficient[2]
    beta.error <- summary(lm(y ~ x, data=sp))$coefficient[4]
    ar1 <- acf(y,plot=FALSE)$acf[2]
  } else {beta <- NA; beta.error <- NA; ar1 <- NA}
  
  if (plot) {
    ## Timer series of the residual
    if (new) dev.new()
    #par(bty="n",mfcol=c(3,2))
    plot(xval,plot.type='single',col=c("blue","red"),
         main='cross-validation',
         sub=paste('correlation=',round(cor(xval)[2,1],2)))

    if (new) dev.new()
    matplot(y,type="p",pch=1,main='contains a trend?')
    matplot(trend(y),type="l",add=TRUE)
    
    ## Auto-correlation of the residual
    if (new) dev.new()
    ar <- acf(w,plot=FALSE)
    matplot(ar$lag,ar$acf,type='b',main='Residual ACF?')

    ## Residual correlated with original data?
    if (new) dev.new()
    matplot(coredata(z),coredata(y),main='Residual correlated with original data?')

    #sp <- spectrum(y,plot=FALSE)
    if (new) dev.new()
    matplot(s$freq,s$spec,type='l',main='Residual power-spectrum',log='xy')

    ## Residual normally distributed?
    if (new) dev.new()
    qqnorm(w,main='Residual normally distributed?')
    qqline(w)

    if  (!is.null(attr(x,'diagnose'))) 
      plot(attr(x,'diagnose'))
  }
  
  diagnostics <- list(residual=y,anova=anova,xval=xval,bias.diag=bias.diag,
                      ar1=ar1,beta=beta, H=(beta+1)/2, beta.error=beta.error)
  return(diagnostics)
}

## # Display cross-validation and statistics on the residual
## diagnose.ds <- function(x,plot=FALSE) {

##   # the attribute 'evaluation' contains cross-validation
##   if (!is.null(attr(x,'evaluation'))) xval <- attr(x,'evaluation') else
##                                       xval <- crossval(x)
##   y <- as.residual(x)
##   z <- as.original.data(x)
  
##   ## Test whether the distribution is normal: the Shapiro-Wilk test of normality. 
##   sw.test <- shapiro.test(coredata(x))
  
##   anova <- summary(attr(x,'model'))
##   eof <- attr(x,'eof')
##   if (inherits(eof,'comb')) bias.diag <- diagnose(eof) else
##                             bias.diag <- NULL

##   spectrum(coredata(y),plot=FALSE) -> s
##   sp <- data.frame(y=log(s$spec),x=log(s$freq))
##   if (length(dim(y))==0) {
##     beta <- -summary(lm(y ~ x, data=sp))$coefficient[2]
##     beta.error <- summary(lm(y ~ x, data=sp))$coefficient[4]
##     ar1 <- acf(y,plot=FALSE)$acf[2]
##   } else {beta <- NA; beta.error <- NA; ar1 <- NA}
  
##   if (plot) {
##     plot(xval)

##     dev.new()
##     par(bty="n",mfcol=c(3,2))
##     plot(y)

##     acf(y)

##     browse()
##     plot(z,y)
##     spectrum(y)

##     qqnorm(y)
##     qqline(y)

##     if  (!is.null(attr(x,'diagnose'))) 
##       plot(attr(x,'diagnose'))
##   }
  
##   diagnostics <- list(residual=y,anova=anova,xval=xval,bias.diag=bias.diag,sw.test=sw.test,
##                       ar1=ar1,beta=beta, H=(beta+1)/2, beta.error=beta.error)
##   return(diagnostics)
## }

## diagnose.dsensemble <- function(x,plot=TRUE,type='target',...) {
##   # Trend-evaluation: rank
##   # Counts outside 90% confidence: binomial distrib. & prob.
##   stopifnot(!missing(x),inherits(x,"dsensemble"))
##   z <- x
##   # Remove the results with no valid data:
##   n <- apply(z,2,FUN=nv)
##   browser()
##   z <- subset(z,is=(1:length(n))[n > 0])
  
##   d <- dim(z)
##   t <- index(z)
##   y <- attr(x,'station')
  
##   # statistics: past trends
  
##   i1 <- is.element(year(y)*100 + month(y),year(z)*100 + month(z))
##   i2 <- is.element(year(z)*100 + month(z),year(y)*100 + month(y))
##   obs <- data.frame(y=y[i1],t=year(y)[i1])
##   #print(summary(obs)); print(sum(i1)); print(sum(i2)); browser()
##   deltaobs <- lm(y ~ t,data=obs)$coefficients[2]*10  # deg C/decade
##   deltagcm <- rep(NA,d[2])
##   for (j in 1:d[2]) {
##     gcm <- data.frame(y=z[i2,j],t=year(z)[i2])
##     deltagcm[j] <- lm(y ~ t,data=gcm)$coefficients[2]*10  # deg C/decade
##   }
##   robs <- round(100*sum(deltaobs < deltagcm)/d[2])
##   #print(deltaobs); print(deltagcm); print(order(c(deltaobs,deltagcm))[1])

##   # apply to extract mean and sd from the selected objects:
##   mu <- apply(coredata(z),1,mean,na.rm=TRUE)
##   si <- apply(coredata(z),1,sd,na.rm=TRUE)
##   q05 <- qnorm(0.05,mean=mu,sd=si)
##   q95 <- qnorm(0.95,mean=mu,sd=si)
##   # number of points outside conf. int. (binom)
##   above <- y[i1] > q95[i2]
##   below <- y[i1] < q05[i2]
##   #browser()
##   outside <- sum(above) + sum(below)
##   N <- sum(i1)
  
##   if (plot) {
##     x <- -round(200*(0.5-pbinom(outside,size=N,prob=0.1)),2)
##     y <- -round(200*(0.5-pnorm(deltaobs,mean=mean(deltagcm),sd=sd(deltagcm))),2)
##     #print(c(x,y))
    
##     par(bty="n",xaxt="n",yaxt="n")
##     plot(c(-100,100),c(-100,100),type="n",ylab="standard deviation",xlab="trend")
    
##     bcol=c("grey95","grey40")
##     for (i in 1:10) {
##       r <- (11-i)*10
##       polygon(r*cos(pi*seq(0,2,length=360)),
##               r*sin(pi*seq(0,2,length=360)),
##               col=bcol[i %% 2 + 1],border="grey15")
##     }
##     for (i in seq(0,90,by=1))
##       points(x,y,pch=19,cex=2 - i/50,col=rgb(i/90,0,0))
##   }
##   diag <- list(robs=robs,deltaobs=deltaobs,deltagcm=deltagcm,
##                outside=outside,above=above,below=below,
##                y=y[i1],N=N,i1=i1,
##                mu=zoo(mu,order.by=index(x)),
##                si=zoo(si,order.by=index(x)),
##                q05=zoo(q05,order.by=index(x)),
##                q95=zoo(q95,order.by=index(x)))
##   attr(diag,'history') <- history.stamp(x)

##   invisible(diag)
## }


diagnose.distr <- function(x,main=NULL,
                           xlab='mean',ylab=expression(q[p]),
                           sub=src(x),probs=0.95,plot=TRUE) {
  x0 <- x
  if (is.T(x)) {
    y <- anomaly(x)
    djf <- subset(y,it='djf')
    mam <- subset(y,it='mam')
    jja <- subset(y,it='jja')
    son <- subset(y,it='son')
    m.djf <- aggregate(djf,year,FUN='mean',na.rm=TRUE)
    q.djf <- aggregate(djf,year,FUN='quantile',probs=probs,na.rm=TRUE)
    m.mam <- aggregate(mam,year,FUN='mean',na.rm=TRUE)
    q.mam <- aggregate(mam,year,FUN='quantile',probs=probs,na.rm=TRUE)
    m.jja <- aggregate(jja,year,FUN='mean',na.rm=TRUE)
    q.jja <- aggregate(jja,year,FUN='quantile',probs=probs,na.rm=TRUE)
    m.son <- aggregate(son,year,FUN='mean',na.rm=TRUE)
    q.son <- aggregate(son,year,FUN='quantile',probs=probs,na.rm=TRUE)

    x <- c(coredata(m.djf),coredata(m.mam),coredata(m.jja),coredata(m.son))
    y <- c(coredata(q.djf),coredata(q.mam),coredata(q.jja),coredata(q.son))
    col <- c(rep(rgb(0.2,0.2,0.6,0.3,length(m.djf))),
             rep(rgb(0.1,0.6,0.1,0.3,length(m.mam))),
             rep(rgb(0.7,0.7,0.1,0.3,length(m.jja))),
             rep(rgb(0.7,0.5,0.5,0.3,length(m.son))))
    par(bty='n')
    r <- cor.test(x,y)
    if (is.null(main)) main <- paste(loc(x0),'T(2m): mean v.s. quantile')
    model.djf <- lm(coredata(q.djf) ~ coredata(m.djf))
    model.mam <- lm(coredata(q.mam) ~ coredata(m.mam))
    model.jja <- lm(coredata(q.jja) ~ coredata(m.jja))
    model.son <- lm(coredata(q.son) ~ coredata(m.son))
    signf <- c(rep(summary(model.djf)$coefficients[8] < 0.05,length(m.djf)),
               rep(summary(model.mam)$coefficients[8] < 0.05,length(m.mam)),
               rep(summary(model.jja)$coefficients[8] < 0.05,length(m.jja)),
               rep(summary(model.son)$coefficients[8] < 0.05,length(m.son)))

    if (plot) {
      plot(x,y,main=main,xlab=xlab,ylab=ylab,col=col,pch=19,
           sub=paste('Anomaly: p=',probs,'; r=',round(r$estimate,3),' [',
                     round(r$conf.int[1],3),', ',round(r$conf.int[1],3),']',sep=''))

      abline(model.djf,col=rgb(0.2,0.2,0.6))
      abline(model.mam,col=rgb(0.1,0.6,0.1))
      abline(model.jja,col=rgb(0.7,0.7,0.1))
      abline(model.son,col=rgb(0.7,0.5,0.5))
      grid()
      points(x[signf],y[signf])
      legend(min(x),max(y),c(paste('DJF',round(model.djf$coefficients[2],3)),
                             paste('MAM',round(model.mam$coefficients[2],3)),
                             paste('JJA',round(model.jja$coefficients[2],3)),
                             paste('SON',round(model.son$coefficients[2],3))),pch=19,
               col=c(rgb(0.2,0.2,0.6),rgb(0.1,0.6,0.1),
                     rgb(0.7,0.7,0.1),rgb(0.7,0.5,0.5)),bty='n')
      text(max(x),min(y),expression(q[p]==mu + sigma*sqrt(2)*erf^-1 *(2*p - 1)),
           pos=2,col='grey')
    }
    invisible(list(DJF=model.djf,MAM=model.mam,JJA=model.jja,SON=model.son))
  }
}



diagnose.dsensemble <- function(x,plot=TRUE,type='target',xrange=NULL,
                                yrange=NULL,main=NULL,map.show=TRUE,
                                map.type="points",verbose=FALSE,...) {
  if (verbose) print('diagnose.dsensemble')
  # Trend-evaluation: rank
  # Counts outside 90% confidence: binomial distrib. & prob.
  stopifnot(!missing(x),inherits(x,"dsensemble"))
  
  
  if (inherits(x,"pca") | inherits(x,"list")) {
    diag <- diagnose.dsensemble.list(x,plot=plot,map.show=map.show,
                                     main=main,xrange=xrange,yrange=yrange,
                                     verbose=verbose,...)
    invisible(diag)
  } else {
  if (is.null(attr(x,'station'))) {
    if (verbose) print('Found no station data - premature exit')
    return()
  }
 
  z <- x
  d <- dim(z)
  t <- index(z)
  y <- attr(x,'station')
  
  ## REB 2017-11-07 Set the index to the year if the data is annual or only one per year
  if ( inherits(y,'annual') | (length(rownames(table(month(x))))==1) ){
    if (verbose) print('set the time index to years')
    index(z) <- year(z)
    index(y) <- year(y)
  }
  ## Use the same dates
  yz <- merge( zoo(y), zoo(z),all=FALSE )
  #plot(yz)
  
  # statistics: past trends
#  i1 <- is.element(year(y)*100 + month(y),year(z)*100 + month(z))
#  i2 <- is.element(year(z)*100 + month(z),year(y)*100 + month(y))
#  obs <- data.frame(y=y[i1],t=year(y)[i1])
  obs <- data.frame(y=c(yz[,1]),t=year(yz))
  if (verbose) print(summary(obs))
  if (sum(is.finite(obs$y))==0) {
    print('diagnose.dsensemble: problem detected - no valid station data'); print(match.call())
    return(NULL)
  }
  deltaobs <- round(lm(y ~ t,data=obs)$coefficients[2]*10,2)  # deg C/decade
#  deltagcm <- rep(NA,d[2])
#  if (verbose) print(dim(deltagcm))
#  for (j in 1:d[2]) {
#    gcm <- data.frame(y=c(yz[,j+1]),t=year(yz))
#    deltagcm[j] <- round(lm(y ~ t,data=gcm)$coefficients[2]*10,2)  # deg C/decade
#  }
  ## REB 2016-11-07: faster and more efficient code than for-loop.
  deltagcm <- c(apply(coredata(yz)[,-1],2,FUN='trend.coef'))
  robs <- round(100*sum(deltaobs < deltagcm)/d[2])
  if(verbose) {print(deltaobs); print(deltagcm); print(order(c(deltaobs,deltagcm))[1])}
  
  # apply to extract mean and sd from the selected objects:
  mu <- apply(coredata(yz[-1]),1,mean,na.rm=TRUE)
  si <- apply(coredata(yz[-1]),1,sd,na.rm=TRUE)
  q05 <- qnorm(0.05,mean=mu,sd=si)
  q95 <- qnorm(0.95,mean=mu,sd=si)
  # number of points outside conf. int. (binom)
  above <- yz[,1] > q95
  below <- yz[,1] < q05
  outside <- sum(above,na.rm=TRUE) + sum(below,na.rm=TRUE)
  N <- sum(is.finite(yz[,1]),na.rm=TRUE)

  # add plot title
  if(is.null(main)) main <- attr(x,"variable")

  if (verbose) print('make list object')
  diag <- list(z=z,robs=robs,deltaobs=deltaobs,deltagcm=deltagcm,
               outside=outside,above=above,below=below,
               y=yz[,1],N=N,xrange=xrange,yrange=yrange,
               mu=zoo(mu,order.by=index(x)),
               si=zoo(si,order.by=index(x)),
               q05=zoo(q05,order.by=index(x)),
               q95=zoo(q95,order.by=index(x)))
  attr(diag,'history') <- history.stamp(x)
  class(diag) <- c('diagnose','dsensembles','list')
  if (plot) plot(diag,map.show=map.show,map.type=map.type,
                 main=main,verbose=verbose)
  if (verbose) print(paste('exit diagnose.dsensemble: N=',N,'obs.change=',deltaobs,
                           'simulated change in [',min(deltagcm),',',max(deltagcm),']'))
  invisible(diag)
  }
}

diagnose.dsensemble.list <- function(x,plot=FALSE,is=NULL,ip=NULL,
                 map.show=TRUE,alpha=0.6,xrange=NULL,yrange=NULL,
                 main=NULL,verbose=FALSE,new=TRUE,...) {
  X <- x
  if (verbose) print('diagnose.dsensemble.list')
  stopifnot(inherits(X,"dsensemble") & inherits(X,"list"))
  if (inherits(X,"pca")) X <- as.station(X,is=is,ip=ip,verbose=verbose)
  gcms <- attr(X[[1]],"model_id")
  if (verbose) print("Compare variance and trends")
  outside <- matrix(NA,length(X))
  deltagcm <- matrix(NA,length(X),length(gcms))
  deltaobs <- matrix(NA,length(X))
  N <- matrix(NA,length(X))
  for (i in 1:length(X)) {
    if (verbose) print(loc(X[[i]]))
    di <- diagnose(X[[i]],plot=FALSE,verbose=verbose)
    outside[i] <- di$outside
    deltaobs[i] <- di$deltaobs
    deltagcm[i,] <- di$deltagcm
    N[i] <- di$N
  }
  d <- list(outside=outside,deltaobs=deltaobs,deltagcm=deltagcm,
            N=di$N,location=names(X))

  if(is.null(main)) main <- attr(X,"variable")
  if(plot) {
    if(verbose) print("target plot") 
    if (new) dev.new()
    par(bty="n",fig=c(0.05,0.95,0,0.95),mgp=c(2,1,.5),xpd=TRUE)
    plot(c(-100,100),c(-100,100),type="n",
         axes=FALSE,ylab="",xlab="",main=main)
    mtext("trend",side=1,line=1.5,cex=par("cex"))
    mtext("standard deviation",side=2,line=2,cex=par("cex"))
    u <- par("usr")
    dx <- (u[2]-u[1])/20
    dy <- (u[4]-u[3])/20
    arrows(u[1]+dx,u[3],u[2]-dx,u[3],
         lwd=0.75,length=0.1,angle=20,code=2,xpd=NA)
    arrows(u[2]-dx,u[3],u[1]+dx,u[3],
         lwd=0.75,length=0.1,angle=20,code=2,xpd=NA)
    arrows(u[1],u[4]-dy,u[1],u[3]+dy,
         lwd=0.75,length=0.1,angle=20,code=2,xpd=NA)
    arrows(u[1],u[3]+dy,u[1],u[4]-dy,
         lwd=0.75,length=0.1,angle=20,code=2,xpd=NA)
    mtext("ensemble > obs",side=1,line=0,adj=0,cex=par("cex")*0.75)
    mtext("ensemble < obs",side=1,line=0,adj=1,cex=par("cex")*0.75)
    mtext("ensemble > obs",side=2,line=0.5,adj=0,cex=par("cex")*0.75)
    mtext("ensemble < obs",side=2,line=0.5,adj=1,cex=par("cex")*0.75)  
    bcol=c("grey95","grey40")
    for (i in 1:10) {
      ri <- (11-i)*10
      polygon(ri*cos(pi*seq(0,2,length=360)),
              ri*sin(pi*seq(0,2,length=360)),
              col=bcol[i %% 2 + 1],border="grey15")
    }
    xlon <- sapply(X,lon)
    xlat <- sapply(X,lat)
    nx <- (xlon-min(xlon))/diff(range(xlon))
    ny <- (xlat-min(xlat))/diff(range(xlat))
    if(all(is.finite(nx)) & all(is.finite(ny))) {
      col <- rgb(1-ny,nx,ny,alpha)
    } else {
      col <- adjustcolor(col="blue",alpha.f=alpha)
    }
    if(is.null(xrange)) xrange <- c(min(xlon)-1,max(xlon)+1)
    if(is.null(yrange)) yrange <- c(min(xlat)-1,max(xlat)+1)
    x <- -round(200*(0.5-pnorm(deltaobs,mean=mean(deltagcm),
                               sd=sd(deltagcm))),2)
    y <- -round(200*(0.5-pbinom(outside,size=N,prob=0.1)),2)
    points(x,y,pch=21,cex=2*par("cex"),col='black',bg=col)
    if(map.show) {
      data(geoborders)
      lon <- geoborders$x
      lat <- geoborders$y
      ok <- lon>min(xrange) & lon<max(xrange) &
          lat>min(yrange) & lat<max(yrange)
      lon2 <- attr(geoborders,"borders")$x
      lat2 <- attr(geoborders,"borders")$y
      ok2 <- lon2>min(xrange) & lon2<max(xrange) &
           lat2>min(yrange) & lat2<max(yrange)
      par(fig=c(0.8,0.97,0.8,0.97),new=TRUE, mar=c(0,0,0,0),
        cex.axis=0.75*par("cex"),xpd=NA,col.main="grey",bty="n")
      plot(lon[ok],lat[ok],lwd=1,col="black",type='l',
         xlab=NA,ylab=NA,axes=FALSE,xlim=xrange,ylim=yrange)
      axis(1,mgp=c(3,.5,0))
      axis(2,mgp=c(2,.5,0))
      lines(lon2[ok2],lat2[ok2],col = "pink",lwd=1)
      points(xlon,xlat,pch=21,cex=1,col='Grey',bg=col,lwd=0.5)
    }
  }
  invisible(d)
}

diagnose.matrix <- function(x,xlim=NULL,ylim=NULL,verbose=FALSE,...) {
  if (verbose) print('diagnose.matrix')
  plot.diagnose.matrix(x,xlim=xlim,ylim=ylim,verbose=verbose)
}

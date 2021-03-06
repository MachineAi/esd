\name{summary.dsensemble}
\alias{summary.dsensemble}
\alias{summary.station}
\alias{summary.ds}
\alias{summary.eof}
\alias{summary.cca}

%- Also NEED an '\alias' for EACH other topic documented here.
\title{Summary showing summary of objects
%%  ~~function to do ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
summary.dsensemble(x, years = seq(1990, 2090, by = 20))
summary.station(x)
summary.ds(x)
summary.eof(x)
summary.cca(x)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{x}{
%%     ~~Describe \code{x} here~~
}
  \item{years}{
%%     ~~Describe \code{years} here~~
}
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of 'comp1'}
%%  \item{comp2 }{Description of 'comp2'}
%% ...
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
%%  ~~who you are~~
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or do  help(data=index)  for the standard data sets.

## The function is currently defined as
function (x, years = seq(1990, 2090, by = 20)) 
{
    x0 <- subset(x, it = 0)
    djf <- subset(x, it = "djf")
    mam <- subset(x, it = "mam")
    jja <- subset(x, it = "jja")
    son <- subset(x, it = "son")
    tab <- rep("", length(years) + 1)
    tab[1] <- paste(loc(x), "  Annual, DFJ, MAM, JJA, SON")
    i <- 1
    for (yr in years) {
        i <- i + 1
        tab[i] <- paste(years[i - 1], ":    ", round(mean(coredata(subset(x0, 
            it = years[i - 1]))), 2), " [", round(quantile(subset(x0, 
            it = years[i - 1]), 0.05), 2), ", ", round(quantile(subset(x0, 
            it = years[i - 1]), 0.95), , 2), "],  ", round(mean(coredata(subset(djf, 
            it = years[i - 1]))), 2), " [", round(quantile(subset(djf, 
            it = years[i - 1]), 0.05), 2), ", ", round(quantile(subset(djf, 
            it = years[i - 1]), 0.95), 2), "],  ", round(mean(coredata(subset(mam, 
            it = years[i - 1]))), 2), " [", round(quantile(subset(mam, 
            it = years[i - 1]), 0.05), 2), ", ", round(quantile(subset(mam, 
            it = years[i - 1]), 0.95), 2), "],  ", round(mean(coredata(subset(jja, 
            it = years[i - 1]))), 2), " [", round(quantile(subset(jja, 
            it = years[i - 1]), 0.05), 2), ", ", round(quantile(subset(jja, 
            it = years[i - 1]), 0.95), 2), "],  ", round(mean(coredata(subset(son, 
            it = years[i - 1]))), 2), " [", round(quantile(subset(son, 
            it = years[i - 1]), 0.05), 2), ", ", round(quantile(subset(son, 
            it = years[i - 1]), 0.95), 2), "]", sep = "")
    }
    tab
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line

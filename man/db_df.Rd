% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/db_df.r
\name{db_df}
\alias{db_df}
\alias{db_df.Spatial}
\alias{db_df.list}
\title{Nested tables without recursion :)}
\usage{
db_df(x, ...)

\method{db_df}{list}(x, ...)

\method{db_df}{Spatial}(x, ...)
}
\arguments{
\item{x}{Spatial object}

\item{...}{ignored}
}
\value{
For Spatial, a data frame with columns
\itemize{
 \item \code{object_} object ID \code{integer}
 \item \code{branch_}  global branch ID \code{integer}
 \item \code{island_}  ring status island or hole? \code{logical}
}

nested tables
}
\description{
Nested tables without recursion :)
}


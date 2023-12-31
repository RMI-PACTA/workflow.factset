% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_fund_data.R
\name{get_fund_data}
\alias{get_fund_data}
\title{Get the fund data from the FactSet database and prepare the
\code{factset_fund_data} tibble}
\usage{
get_fund_data(conn, data_timestamp)
}
\arguments{
\item{conn}{databse connection}

\item{data_timestamp}{A single string specifying the desired date for the
data in the form "2021-12-31"}
}
\value{
A tibble properly prepared to be saved as the \code{factset_fund_data.rds}
output file
}
\description{
Get the fund data from the FactSet database and prepare the
\code{factset_fund_data} tibble
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pacta_sector_override_mapping.R
\docType{data}
\name{pacta_sector_override_mapping}
\alias{pacta_sector_override_mapping}
\title{Manually mantained PACTA Sector override mapping
Use the \code{entity_proper_name} to match the company name in the FactSet
database.
For each company, the \code{pacta_sector} column contains the sector that
should be used in the PACTA analysis.
The \code{entity_id_md5} column contains the md5 hash of the entity_id, which
is used to disambiguate the company in the FactSet database in the case of
multiple companies with the same \code{entity_proper_name}.}
\format{
An object of class \code{tbl_df} (inherits from \code{tbl}, \code{data.frame}) with 480 rows and 3 columns.
}
\usage{
pacta_sector_override_mapping
}
\description{
To generate values for the \code{entity_id_md5} column, use the following code:
\verb{digest::digest(<entity_id>, algo = "md5", serialize = FALSE)}'.
}
\keyword{internal}

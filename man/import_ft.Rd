% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/file_io.R
\name{import_ft}
\alias{import_ft}
\title{Import Fieldtrip files}
\usage{
import_ft(file_name, participant_id = NULL, recording = NULL, verbose = TRUE)
}
\arguments{
\item{file_name}{Name of file to be imported.}

\item{participant_id}{Identifier for the participant.}

\item{recording}{Name of the recording. By default, the filename will be
used.}

\item{verbose}{Informative messages printed to console. Defaults to TRUE.}
}
\value{
An object of class \code{eeg_data}, \code{eeg_epochs}, or
\code{eeg_tfr}, depending on the type of input data.
}
\description{
Fieldtrip is a Matlab package for EEG/MEG processing and analysis.
}
\examples{
\dontrun{import_ft("fieldtrip_test.mat")}
}
\author{
Matt Craddock \email{matt@mattcraddock.com}
}

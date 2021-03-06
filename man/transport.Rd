% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/hydrology.r
\name{transport}
\alias{transport}
\title{Runs a transport-reaction model}
\usage{
transport(
  ws,
  initial,
  lateral,
  times,
  method = c("euler", "lsoda"),
  dt = 1,
  rxn = NULL,
  rxnParams = list()
)
}
\arguments{
\item{ws}{A [Watershed] object}

\item{initial}{A vector of initial conditions}

\item{lateral}{Vector of values of the state variable for lateral input for each pixel}

\item{times}{The times at which to compute the state variable}

\item{method}{The integration method to use; default is euler}

\item{dt}{The size of the time step for integration (euler method only)}

\item{rxn}{A function giving the time derivative of the reaction component}

\item{rxnParams}{A list of parameters to pass to `rxn`}
}
\value{
A state variable matrix (with one column per time step)
}
\description{
Runs a transport-reaction model
}
\details{
Because the appropriate time step will vary based on the units and the specific
   problem, the recommended approach is to first try a single run using lsoda (perhaps on
   a small subset), then run euler at varying time steps to find the dt that produces
   acceptable results.

If used, `rxn` must be a function taking `t` (the current time) and `y` 
  (the state of the system) as its first few arguments. Other arguments can be added by 
  name via the `rxnParams` argument.
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RcppExports.R
\name{dCdt_transport_cpp}
\alias{dCdt_transport_cpp}
\title{Compute a concentration derivative for an entire river network}
\usage{
dCdt_transport_cpp(t, y, adjacencyQ, qout, qin, lateral, csArea, dx)
}
\arguments{
\item{t}{the time step}

\item{y}{the state vector}

\item{adjacencyQ}{A 3-column matrix giving the rows and columns of the non-zero entries of 
the adjacency matrix (columns 1 and 2) and the discharge value (column 3)}

\item{qout}{A vector of output discharge}

\item{qin}{A vector of input discharge}

\item{lateral}{A vector giving concentraion of lateral input}

\item{csArea}{Cross Sectional area of each site}

\item{dx}{Length of each site}
}
\description{
Compute a concentration derivative for an entire river network
}

\name{SparseArraySeed-class}
\docType{class}

\alias{class:SparseArraySeed}
\alias{SparseArraySeed-class}
\alias{SparseArraySeed}

\alias{nzindex}
\alias{nzindex,SparseArraySeed-method}
\alias{nzdata}
\alias{nzdata,SparseArraySeed-method}
\alias{dimnames,SparseArraySeed-method}
\alias{dimnames<-,SparseArraySeed,ANY-method}
\alias{sparsity}
\alias{sparsity,SparseArraySeed-method}

\alias{dense2sparse}
\alias{sparse2dense}

\alias{is_sparse<-}
\alias{is_sparse,ANY-method}
\alias{extract_sparse_array}

\alias{is_sparse,SparseArraySeed-method}
\alias{extract_sparse_array,SparseArraySeed-method}
\alias{extract_array,SparseArraySeed-method}

\alias{as.array.SparseArraySeed}
\alias{as.array,SparseArraySeed-method}
\alias{as.matrix.SparseArraySeed}
\alias{as.matrix,SparseArraySeed-method}

\alias{coerce,ANY,SparseArraySeed-method}

\alias{coerce,SparseArraySeed,sparseMatrix-method}
\alias{coerce,dgCMatrix,SparseArraySeed-method}
\alias{coerce,lgCMatrix,SparseArraySeed-method}

\alias{is_sparse,dgCMatrix-method}
\alias{is_sparse,lgCMatrix-method}
\alias{extract_sparse_array,dgCMatrix-method}
\alias{extract_sparse_array,lgCMatrix-method}

\alias{aperm.SparseArraySeed}
\alias{aperm,SparseArraySeed-method}

\title{SparseArraySeed objects}

\description{
  SparseArraySeed objects are used internally to support block processing
  of array-like objects.
}

\usage{
## Constructor function:
SparseArraySeed(dim, nzindex=NULL, nzdata=NULL, dimnames=NULL, check=TRUE)

## Getters (in addition to dim(), length(), and dimnames()):
nzindex(x)
nzdata(x)
sparsity(x)

## Two low-level utilities:
dense2sparse(x)
sparse2dense(sas)
}

\arguments{
  \item{dim}{
    The dimensions (specified as an integer vector) of the
    SparseArraySeed object to create.
  }
  \item{nzindex}{
    A matrix containing the array indices of the nonzero data.

    This must be an integer matrix like one returned by
    \code{base::\link[base]{arrayInd}}, that is, with \code{length(dim)}
    columns and where each row is an n-uplet representing an \emph{array index}.
  }
  \item{nzdata}{
    A vector of length \code{nrow(nzindex)} containing the nonzero data.
  }
  \item{dimnames}{
    The \emph{dimnames} of the object to be created. Must be \code{NULL} or
    a list of length the number of dimensions. Each list element must be
    either \code{NULL} or a character vector along the corresponding dimension.
  }
  \item{check}{
    Should the object be validated upon construction?
  }
  \item{x}{
    A SparseArraySeed object for the \code{nzindex}, \code{nzdata}, and
    \code{sparsity} getters.

    An array-like object for \code{dense2sparse}.
  }
  \item{sas}{
    A SparseArraySeed object.
  }
}

\value{
  \itemize{
    \item For \code{SparseArraySeed()}: A SparseArraySeed instance.

    \item For \code{nzindex()}: The matrix containing the array indices of the
          nonzero data.

    \item For \code{nzdata()}: The vector of nonzero data.

    \item For \code{sparsity()}: The number of zero-valued elements
          in the implicit array divided by the total number of array
          elements (a.k.a. the length of the array).

    \item For \code{dense2sparse()}: A SparseArraySeed instance.

    \item For \code{sparse2dense()}: An ordinary array.
  }
}

\seealso{
  \itemize{
    \item \link{SparseArraySeed-utils} for native operations on
          SparseArraySeed objects.

    \item The \code{\link{read_block}} function.

    \item \code{\link{blockApply}} and family for convenient block
          processing of an array-like object.

    \item \code{\link{extract_array}}.

    \item \link{DelayedArray} objects.

    \item \code{\link[base]{arrayInd}} in the \pkg{base} package.

    \item \link[base]{array} objects in base R.
  }
}

\examples{
## ---------------------------------------------------------------------
## EXAMPLE 1
## ---------------------------------------------------------------------
dim1 <- 5:3
nzindex1 <- Lindex2Mindex(sample(60, 8), 5:3)
nzdata1 <- 11.11 * seq_len(nrow(nzindex1))
sas1 <- SparseArraySeed(dim1, nzindex1, nzdata1)

dim(sas1)        # the dimensions of the implicit array
length(sas1)     # the length of the implicit array
nzindex(sas1)
nzdata(sas1)
type(sas1)
sparsity(sas1)

sparse2dense(sas1)
as.array(sas1)   # same as sparse2dense(sas1)

\dontrun{
as.matrix(sas1)  # error!
}
## ---------------------------------------------------------------------
## EXAMPLE 2
## ---------------------------------------------------------------------
m2 <- matrix(c(5:-2, rep.int(c(0L, 99L), 11)), ncol=6)
sas2 <- dense2sparse(m2)
class(sas2)
dim(sas2)
length(sas2)
nzindex(sas2)
nzdata(sas2)
type(sas2)
sparsity(sas2)

stopifnot(identical(sparse2dense(sas2), m2))

as.matrix(sas2)  # same as sparse2dense(sas2)

t(sas2)
stopifnot(identical(as.matrix(t(sas2)), t(as.matrix(sas2))))

## ---------------------------------------------------------------------
## COERCION FROM/TO dgCMatrix OR lgCMatrix OBJECTS
## ---------------------------------------------------------------------
## dgCMatrix and lgCMatrix objects are defined in the Matrix package.

M2 <- as(sas2, "dgCMatrix")
stopifnot(identical(M2, as(m2, "dgCMatrix")))

sas2b <- as(M2, "SparseArraySeed")
## 'sas2b' is the same as 'sas2' except that 'nzdata(sas2b)' has
## type "double" instead of "integer":
stopifnot(all.equal(sas2b, sas2))
typeof(nzdata(sas2b))  # double
typeof(nzdata(sas2))   # integer

m3 <- m2 == 99  # logical matrix
sas3 <- dense2sparse(m3)
class(sas3)
type(sas3)
M3 <- as(sas3, "lgCMatrix")
stopifnot(identical(M3, as(m3, "lgCMatrix")))

sas3b <- as(M3, "SparseArraySeed")
stopifnot(identical(sas3, sas3b))

## ---------------------------------------------------------------------
## SEED CONTRACT
## ---------------------------------------------------------------------
## SparseArraySeed objects comply with the "seed contract".
## In particular they support extract_array():
extract_array(sas1, list(c(5, 3:2, 5), NULL, 3))

## See '?extract_array' for more information about the "seed contract".

## This means that they can be wrapped in a DelayedArray object:
A1 <- DelayedArray(sas1)
A1

## A big very sparse DelayedMatrix object:
nzindex4 <- cbind(sample(25000, 600000, replace=TRUE),
                  sample(195000, 600000, replace=TRUE))
nzdata4 <- runif(600000)
sas4 <- SparseArraySeed(c(25000, 195000), nzindex4, nzdata4)
sparsity(sas4)

M4 <- DelayedArray(sas4)
M4
colSums(M4[ , 1:20])
}
\keyword{classes}
\keyword{methods}

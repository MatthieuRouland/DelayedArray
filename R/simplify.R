### =========================================================================
### Simplify a tree of delayed operations
### -------------------------------------------------------------------------
###


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### simplify()
###

.normarg_incremental <- function(incremental)
{
    if (!isTRUEorFALSE(incremental))
        stop("'incremental' must be TRUE or FALSE")
    incremental
}

setGeneric("simplify", signature="x",
    function(x, incremental=FALSE) standardGeneric("simplify")
)

setMethod("simplify", "ANY",
    function(x, incremental=FALSE)
    {
        .normarg_incremental(incremental)
        x
    }
)

setMethod("simplify", "DelayedSubset",
    function(x, incremental=FALSE)
    {
        if (!.normarg_incremental(incremental))
            x@seed <- simplify(x@seed)
        x1 <- x@seed
        if (is_noop(x))
            return(x1)
        if (is(x1, "DelayedSubset")) {
            ## ACTION: merge ops + remove if no-op.
            x1 <- subset_DelayedSubset(x1, x@index)
            if (is_noop(x1))
                return(x1@seed)
            return(x1)
        }
        if (is(x1, "DelayedAperm")) {
            ## ACTION: swap ops.
            index2 <- project_index_on_seed(x@index, x1)
            x2 <- new_DelayedSubset(x1@seed, index2)
            x2 <- simplify(x2, incremental=TRUE)
            x1 <- BiocGenerics:::replaceSlots(x1, seed=x2, check=FALSE)
            return(x1)
        }
        if (is(x1, "DelayedUnaryIsoOpStack")) {
            ## ACTION: swap ops.
            x2 <- x
            x2@seed <- x1@seed
            x2 <- simplify(x2, incremental=TRUE)
            x1 <- BiocGenerics:::replaceSlots(x1, seed=x2, check=FALSE)
            return(x1)
        }
        if (is(x1, "DelayedUnaryIsoOpWithArgs")) {
            ## ACTION: swap ops.
            x2 <- x
            x2@seed <- x1@seed
            x2 <- simplify(x2, incremental=TRUE)
            Largs <- subset_args(x1@Largs, x1@Lalong, x@index)
            Rargs <- subset_args(x1@Rargs, x1@Ralong, x@index)
            x1 <- BiocGenerics:::replaceSlots(x1, seed=x2,
                                                  Largs=Largs,
                                                  Rargs=Rargs,
                                                  check=FALSE)
            return(x1)
        }
        if (is(x1, "DelayedSubassign")) {
            ## ACTION: swap ops.
            x1 <- subset_DelayedSubassign(x1, x@index)
            x1@seed <- simplify(x1@seed, incremental=TRUE)
            x1@Rvalue <- simplify(x1@Rvalue, incremental=TRUE)
            return(x1)
        }
        if (is(x1, "DelayedDimnames")) {
            ## ACTION: swap ops.
            x2 <- x
            x2@seed <- x1@seed
            x2 <- simplify(x2, incremental=TRUE)
            x1 <- new_DelayedDimnames(x2, dimnames(x))
            return(x1)
        }
        x
    }
)

setMethod("simplify", "DelayedAperm",
    function(x, incremental=FALSE)
    {
        if (!.normarg_incremental(incremental))
            x@seed <- simplify(x@seed)
        x1 <- x@seed
        if (is_noop(x))
            return(x1)
        if (is(x1, "DelayedAperm")) {
            ## ACTION: merge ops + remove if no-op.
            x1@perm <- x1@perm[x@perm]
            if (is_noop(x1))
                return(x1@seed)
            return(simplify(x1, incremental=TRUE))
        }
        if (is(x1, "DelayedUnaryIsoOpStack")) {
            ## ACTION: swap ops.
            x@seed <- x1@seed
            x1@seed <- simplify(x, incremental=TRUE)
            return(x1)
        }
        if (is(x1, "DelayedUnaryIsoOpWithArgs")) {
            perm0 <- x@perm[!is.na(x@perm)]
            set_Lalong_to_NA <- !(x1@Lalong %in% perm0)
            set_Ralong_to_NA <- !(x1@Ralong %in% perm0)
            if (all(set_Lalong_to_NA) && all(set_Ralong_to_NA)) {
                ## ACTION: swap ops.
                x1@Lalong[set_Lalong_to_NA] <- NA_integer_
                x1@Ralong[set_Ralong_to_NA] <- NA_integer_
                x@seed <- x1@seed
                x1@seed <- simplify(x, incremental=TRUE)
                return(x1)
            }
        }
        if (is(x1, "DelayedDimnames")) {
            ## ACTION: swap ops.
            x2 <- x
            x2@seed <- x1@seed
            x2 <- simplify(x2, incremental=TRUE)
            x1 <- new_DelayedDimnames(x2, dimnames(x))
            return(x1)
        }
        x
    }
)

setMethod("simplify", "DelayedUnaryIsoOpStack",
    function(x, incremental=FALSE)
    {
        if (!.normarg_incremental(incremental))
            x@seed <- simplify(x@seed)
        x1 <- x@seed
        if (is(x1, "DelayedUnaryIsoOpStack")) {
            ## ACTION: merge ops.
            x1@OPS <- c(x1@OPS, x@OPS)
            return(x1)
        }
        if (is(x1, "DelayedDimnames")) {
            ## ACTION: swap ops.
            x@seed <- x1@seed
            x1@seed <- simplify(x, incremental=TRUE)
            return(x1)
        }
        x
    }
)

setMethod("simplify", "DelayedUnaryIsoOpWithArgs",
    function(x, incremental=FALSE)
    {
        if (!.normarg_incremental(incremental))
            x@seed <- simplify(x@seed)
        x1 <- x@seed
        if (is(x1, "DelayedDimnames")) {
            ## ACTION: swap ops.
            x@seed <- x1@seed
            x1@seed <- simplify(x, incremental=TRUE)
            return(x1)
        }
        x
    }
)

setMethod("simplify", "DelayedSubassign",
    function(x, incremental=FALSE)
    {
        if (!.normarg_incremental(incremental)) {
            x@seed <- simplify(x@seed)
            x@Rvalue <- simplify(x@Rvalue)
        }
        x1 <- x@seed
        if (is_noop(x))
            return(x1)
        if (all(x@.nogap) && !is.null(dim(x@Rvalue))) {
            ## "Full replacement" case with an array-like object on the right.
            ## 'x' represents a subassignment that replaces all the array
            ## elements in the left value. This is a degenerate case of
            ## subassignment where we never need to extract any array element
            ## from 'x@seed'.
            if (all(S4Vectors:::sapply_isNULL(x@Lindex))) {
                ## "Filling" case (a special case of "Full replacement") with
                ## an array-like object on the right.
                ## ACTION: replace DelayedSubassign op with right value.
                x1 <- x@Rvalue
            } else {
                ## ACTION: replace DelayedSubassign op with a subset of
                ## right value.
                index <- vector("list", length=length(x@Lindex))
                Mindex <- make_Mindex(index, x)
                x1 <- new_DelayedSubset(x@Rvalue, Mindex)
                x1 <- simplify(x1, incremental=TRUE)
            }
            ## Propagate dimnames of left value.
            x <- new_DelayedDimnames(x1, dimnames(x@seed))
            x <- simplify(x, incremental=TRUE)
            return(x)
        }
        Rvalue <- x@Rvalue
        if (is(Rvalue, "DelayedDimnames")) {
            ## ACTION: remove DelayedDimnames op from right value.
            x@Rvalue <- Rvalue@seed
        }
        if (is(x1, "DelayedDimnames")) {
            ## ACTION: swap ops.
            x@seed <- x1@seed
            x1@seed <- x
            return(x1)
        }
        x
    }
)

setMethod("simplify", "DelayedDimnames",
    function(x, incremental=FALSE)
    {
        if (!.normarg_incremental(incremental))
            x@seed <- simplify(x@seed)
        x1 <- x@seed
        if (is_noop(x))
            return(x1)
        if (is(x1, "DelayedDimnames")) {
            ## ACTION: merge ops + remove if no-op.
            x <- new_DelayedDimnames(x1@seed, dimnames(x))
            if (is_noop(x))
                return(x@seed)
            return(x)
        }
        x
    }
)

setMethod("simplify", "DelayedNaryIsoOp",
    function(x, incremental=FALSE)
    {
        if (!.normarg_incremental(incremental))
            x@seeds <- lapply(x@seeds, simplify)
        x
    }
)

setMethod("simplify", "DelayedAbind",
    function(x, incremental=FALSE)
    {
        if (!.normarg_incremental(incremental))
            x@seeds <- lapply(x@seeds, simplify)
        if (is_noop(x))
            return(x@seeds[[1L]])
        x
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### isPristine()
###
### A pristine DelayedArray object is an object that carries no delayed
### operation. Note that an object that carries delayed operations that
### do nothing (e.g. A + 0) is not considered pristine.
###

isPristine <- function(x, ignore.dimnames=FALSE)
{
    if (!is(x, "DelayedArray"))
        stop(wmsg("'x' must be a DelayedArray object"))
    if (!isTRUEorFALSE(ignore.dimnames))
        stop(wmsg("'ignore.dimnames' should be TRUE or FALSE"))
    if (ignore.dimnames && is(x@seed, "DelayedDimnames"))
        x@seed <- x@seed@seed  # drop DelayedDimnames op
    !is(x@seed, "DelayedOp")
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### contentIsPristine()
###

### Return FALSE if the tree contains delayed operations that modify
### the "original array values" (i.e. the values contained in the seeds).
### The value-modifying nodes are:
###   - DelayedUnaryIsoOpStack, DelayedUnaryIsoOpWithArgs, and
###     DelayedNaryIsoOp nodes;
###   - DelayedSubassign nodes that are not no-ops.
contentIsPristine <- function(x)
{
    if (!is.list(x) || is.array(x)) {
        if (!is(x, "DelayedOp"))
            return(TRUE)
        if (is(x, "DelayedUnaryIsoOpStack") ||
            is(x, "DelayedUnaryIsoOpWithArgs") ||
            is(x, "DelayedNaryIsoOp"))
            return(FALSE)
        if (is(x, "DelayedUnaryOp")) {
            if (is(x, "DelayedSubassign") && !is_noop(x))
                return(FALSE)
            x <- list(x@seed)
        } else {
            x <- x@seeds
        }
    }
    nchildren <- length(x)
    for (i in seq_len(nchildren)) {
        if (!contentIsPristine(x[[i]]))
            return(FALSE)
    }
    TRUE
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### netSubsetAndAperm()
###
### Only supported if nseed() == 1
###

### Remove DelayedUnaryIsoOp nodes from a linear tree.
### Raise an error if the tree is not linear.
.remove_unary_iso_ops <- function(x)
{
    if (!is(x, "DelayedOp"))
        return(x)
    if (is(x, "DelayedNaryOp")) {
        ## Tree is not linear.
        stop(wmsg("netSubsetAndAperm() ",
                  IS_NOT_SUPOORTED_IF_MULTIPLE_SEEDS))
    }
    x1 <- .remove_unary_iso_ops(x@seed)
    if (is(x, "DelayedUnaryIsoOp")) {
        x <- x1
    } else {
        x@seed <- x1
    }
    x
}

setGeneric("netSubsetAndAperm", signature="x",
    function(x, as.DelayedOp=FALSE) standardGeneric("netSubsetAndAperm")
)

setMethod("netSubsetAndAperm", "ANY",
    function(x, as.DelayedOp=FALSE)
    {
        if (!isTRUEorFALSE(as.DelayedOp))
            stop("'as.DelayedOp' must be TRUE or FALSE")
        reduced <- simplify(.remove_unary_iso_ops(x))
        if (!is(reduced, "DelayedAperm"))
            reduced <- new_DelayedAperm(reduced)
        x1 <- reduced@seed
        if (!is(x1, "DelayedSubset"))
            reduced@seed <- new_DelayedSubset(x1)
        if (as.DelayedOp)
            return(reduced)
        ans <- reduced@seed@index
        if (!is_noop(reduced))
            attr(ans, "dimmap") <- reduced@perm
        ans
    }
)


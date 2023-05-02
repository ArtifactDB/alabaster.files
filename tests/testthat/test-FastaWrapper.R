# Test that the FASTA wrappers are working correctly.
# library(alabaster.files); library(testthat); source("test-FastaWrapper.R")

library(alabaster.base)
library(S4Vectors)
fl <- tempfile(fileext=".fa")
contents <- c(">FOO\nactgcgacgagcatcacgacgactacagcag")
writeLines(con=fl, contents)

test_that("FASTA wrapper works correctly", {
    wrapped <- FastaWrapper(fl)
    expect_output(show(wrapped), "FastaWrapper")
    metadata(wrapped)$foo <- "YAY"

    # Staging the FastaWrapper.
    dir <- tempfile()
    info <- stageObject(wrapped, dir, "my_fa")
    invisible(.writeMetadata(info, dir))
    expect_true("my_fa/file.fa" %in% list.files(dir, recursive=TRUE))

    # Loading it back again:
    meta <- acquireMetadata(dir, "my_fa/file.fa")
    roundtrip <- loadObject(meta, dir)
    expect_s4_class(roundtrip, "FastaWrapper")
    expect_identical(file.size(path(roundtrip)), file.size(fl))
    expect_identical(metadata(roundtrip), list(foo="YAY"))
})

test_that("FASTA wrapper works correctly with compression", {
    comp <- paste0(fl, ".gz")
    writeLines(con=gzfile(comp), contents)

    # Correctly auto-detected.
    wrapped <- FastaWrapper(comp)
    expect_identical(compression(wrapped), "gzip")

    # Goes through a roundtrip correctly.
    dir <- tempfile()
    info <- stageObject(wrapped, dir, "my_fa")
    expect_true("my_fa/file.fa.gz" %in% list.files(dir, recursive=TRUE))
    roundtrip <- loadObject(info, dir)
    expect_identical(compression(roundtrip), "gzip")

    # Works for bgzip as well.
    wrapped <- FastaWrapper(comp, compression="bgzip")
    expect_identical(compression(wrapped), "bgzip")
})

test_that("FASTA wrapper with index works correctly", {
    comp <- Rsamtools::bgzip(fl)
    index.file <- Rsamtools::indexFa(comp, format="fa")

    wrapped <- FastaWrapper(comp, index=index.file)
    expect_output(show(wrapped), "index:")
    expect_s4_class(index(wrapped), "FaidxWrapper")

    # Staging the FastaWrapper.
    dir <- tempfile()
    info <- stageObject(wrapped, dir, "my_fa")
    invisible(.writeMetadata(info, dir))
    expect_true("my_fa/index/file.fa.bgz.fai" %in% list.files(dir, recursive=TRUE))

    # Loading it back again:
    meta <- acquireMetadata(dir, "my_fa/file.fa.bgz")
    roundtrip <- loadObject(meta, dir)
    expect_s4_class(index(roundtrip), "FaidxWrapper")
    expect_identical(file.size(path(index(roundtrip))), file.size(index.file))
})
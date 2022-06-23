options(warn = -1)
options("encoding" = "UTF-8")

# Libs loading ----

cat("Loading libs...\n")
suppressPackageStartupMessages({
    if (!(require(tidyverse))) install.packages("tidyverse")
    if (!(require(optparse))) install.packages("optparse")
    if (!(require(jsonlite))) install.packages("jsonlite")
    library(readxl)
    library(readr)
    library(optparse)
    library(dplyr)
    library(jsonlite)
})
cat("Libraries are loaded\n")

# Loading script file with helpful functions ----

# All realisation is in helpful_func
source("helpful_func.R", encoding = "UTF-8")

# Parse params ----
option_list <- list(
    make_option(
        c("-f", "--filepath"),
        type = "character",
        default = NULL, # nolint
        help = "Full filepath to excel import data file", # nolint
        metavar = "character"
    ),
    make_option(
        c("-d", "--dir"),
        type = "character",
        default = "./excel_import_data", # nolint
        help = "Dir with import excel files", # nolint
        metavar = "character"
    ),
    make_option(
        c("-j", "--jsontype"),
        type = "character",
        default = "nested", # nolint
        help = "0 - flat json, 1 - nested", # nolint
        metavar = "character"
    ),
    make_option(
        c("-o", "--output"),
        type = "character",
        default = "output.json", # nolint
        help = "Output filename", # nolint
        metavar = "character"
    )
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

filepath <- parse_filepath(opt)

# Load data ----

answers <- parse_answers(filepath)

# Analyze data ----

# Calc good answers, z-value and cut z-value
answers <- suppressMessages(analyze_answers(answers))


# Reorganise to save in JSON ----

answers_for_json <- suppressMessages(adapt_df_to_JSON(answers))


if (opt$jsontype == "nested") {
    answers_for_json <- suppressMessages(create_nested_df(answers_for_json))
}

# Saving ----

write(enc2utf8(prettify(toJSON(answers_for_json))), opt$output)

cat("Done!\n")

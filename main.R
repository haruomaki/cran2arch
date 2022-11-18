message("Initializing...")
library(tidyr)
library(dplyr) |> suppressMessages()
library(stringr)

# package <- "glmnet"
package <- "ggplot2"
# package <- "gg"
package <- commandArgs(trailingOnly = TRUE)[1]

# db <- as_tibble(available.packages())
if (!file.exists("/tmp/cran2archdb.rds")) {
    message("Retrieving package databases '/tmp/cran2archdb.rds' ...")
    saveRDS(tools::CRAN_package_db(), "/tmp/cran2archdb.rds")
}
db <- readRDS("/tmp/cran2archdb.rds") |> as_tibble()
db_line <- db |> filter(Package == !!package)
if (nrow(db_line) == 0) {
    message(str_c("error: package '", package, "' was not found."))
    quit(status = 1)
}

message("----------------")
# db |> select(Package, LinkingTo) |> filter(!is.na(LinkingTo)) |> View()

# db |>
#     filter(Package == "styler") |>
#     select(Depends, Imports, LinkingTo)
# deps <- tools::package_dependencies("ggplot2")
# deps
# d <- db |> filter(Package == "tableone")
# d <- db |> filter(Package == "tidyverse")
# d <- db |> filter(Package == "ggplot2")
# l <- d$Imports |>
#     str_remove_all("\\n") |>
#     str_remove_all(" ") |>
#     str_split(",")
# # str_split(",", simplify = TRUE)
# l

# l |> map_chr(~ str_remove(., "\\(.*\\)$"))
# l[5] |> str_extract("(?<=\\().*(?=\\)$)") # 括弧の中身を取り出す



# Splits one string into a vector. Empty string results NULL.
str_split_one <- function(string, pattern) {
    if (string == "") {
        NULL
    } else {
        str_split(string, ",")[[1]]
    }
}

parse_versioning <- function(x) {
    package <- str_remove(x, "\\(.*\\)$")
    v_expr <- str_extract(x, "(?<=\\().*(?=\\)$)") # extracts inside the parens
    sign <- str_remove(v_expr, "[0-9.-]+$")
    version <- str_extract(v_expr, "[0-9.-]+$")
    tibble(package, sign, version)
}

parse_dependency <- function(x) {
    # if (is.na(x)) x <- "" # NA -> ""
    x |>
        replace_na("") |> # NA -> ""
        str_remove_all("\\n") |>
        str_remove_all(" ") |>
        str_split_one() |> # "" -> NULL
        parse_versioning()
}

# parse_dependency("hi, ui")
# parse_dependency("")
# parse_dependency(NA)
# assertthat::are_equal(
#     parse_versioning("mypkg(>=0.1.0)"),
#     tibble(
#         package = "mypkg",
#         sign = ">=",
#         version = "0.1.0"
#     )
# )


tbl_Depends <- parse_dependency(db_line$Depends)
tbl_Imports <- parse_dependency(db_line$Imports)
tbl_LinkingTo <- parse_dependency(db_line$LinkingTo)
tbl_Suggests <- parse_dependency(db_line$Suggests)
# tbl_Depends
# tbl_Imports
# tbl_LinkingTo
# tbl_Suggests

pkgbuild_pkgdeps <- str_remove_all(db_line$Title, "\n") # Long descriptions may contain \n.
tbl_pkgbuild_depends <- bind_rows(tbl_Depends, tbl_Imports, tbl_LinkingTo) |> unique()
tbl_pkgbuild_optdepends <- tbl_Suggests
# tbl_pkgbuild_depends

# for (i in 1:nrow(tbl_pkgbuild_depends)) {
#     pkg <- tbl_pkgbuild_depends[i, ]
#     package = pkg$package,
#     sign = if (is.na(pkg$sign)) ""
#     cat(str_c("'", pkg$package, pkg$sign, "'\n"))
# }

# pacman -Fl r | grep -Po '(?<=usr/lib/R/library/)[^/]+(?=/$)' | sed 's/[^ ]\+/"&"/g' | tr '\n' ',' | sed 's/,$/\n/' | sed 's/.*/c(&)/'
builtin_packages <- c("KernSmooth", "MASS", "Matrix", "base", "boot", "class", "cluster", "codetools", "compiler", "datasets", "foreign", "grDevices", "graphics", "grid", "lattice", "methods", "mgcv", "nlme", "nnet", "parallel", "rpart", "spatial", "splines", "stats", "stats4", "survival", "tcltk", "tools", "translations", "utils")

make_pkgbuild_vars <- function(var, tbl) {
    master <- tbl |>
        filter(!package %in% builtin_packages) |>
        mutate(across(, ~ replace_na(., ""))) |>
        mutate(pkg = if_else(package == "R", "r", str_c("r-", str_to_lower(package)))) |>
        mutate(with_ver = str_c("    '", pkg, sign, version, "'"))
    c(str_glue("{var}=("), master$with_ver, ")") |> str_c(collapse = "\n")
}


template <- readLines("PKGBUILD.template")
pkgbuild <- ""

for (line in template) {
    new <- switch(line,
        "_cranname=" = str_glue("_cranname={db_line$Package}"),
        "_cranver=" = str_glue("_cranver={db_line$Version}"),
        "pkgdesc=" = str_glue("pkgdesc=\"{pkgbuild_pkgdeps}\""),
        "license=" = str_glue("license=('{db_line$License}')"),
        "depends=" = make_pkgbuild_vars("depends", tbl_pkgbuild_depends),
        "optdepends=" = make_pkgbuild_vars("optdepends", tbl_pkgbuild_optdepends),
        line
    )
    pkgbuild <- str_c(pkgbuild, new, "\n")
}

cat(pkgbuild)

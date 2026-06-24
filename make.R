#' fellow-gis: Research compendium for extracting spatial metrics around sampling sites
#'
#' @description
#' extract land cover and climate metrics around smapling sites
#'
#' @author Romain Frelat
#' @date 24 June 2026

## Install Dependencies (listed in DESCRIPTION) ----
# rdeps::add_deps() # update automatically the list of dependencies

if (!("remotes" %in% installed.packages())) {
  install.packages("remotes")
}

remotes::install_deps(upgrade = "never")

## Load Project Addins (R Functions)
devtools::load_all()

## Run Project ---------------------------------------

##
# 1 Get land cover percentage
source("analysis/01_get_GLC_FCS30D.R")

##
# 2 Get climate metrics
# to be defined

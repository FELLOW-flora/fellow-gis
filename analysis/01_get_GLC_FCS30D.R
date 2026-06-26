# Script to get land cover information around a buffer
#
# input:
#   raw-data/GLC_FCS30D_19852022/
#     tiles from https://doi.org/10.5281/zenodo.8239305
#
# output:
#   derived-data/GLC_FCS30D_frac.csv
#
#
devtools::load_all()

data_folder <- here::here("data", "raw-data", "GLC_FCS30D_19852022")
outfolder <- here::here("data", "derived-data")
buffer_dist <- 1000 #1km

df <- read.csv("data/raw-data/site_summary_year.csv", row.names = 1)
pts <- vect(df, geom = c("X", "Y"), crs = "EPSG:4326")

glc_year <- c(seq(1985, 2000, 5), 2001:2022)
glc_rast <- c(
  rep(paste0("GLC_FCS30D_19852000_XXXX_5years_V1.1.tif"), 3),
  rep(paste0("GLC_FCS30D_20002022_XXXX_Annual_V1.1.tif"), 23)
)

df_out <- list()
# for testing sample(1:nrow(df), 10)
for (i in 1:nrow(df)) {
  # create the buffer
  bi <- buffer(pts[i], buffer_dist)
  # find the corresponding tile
  # based on coordinates
  tilei <- find_tiles(bi)
  # based on year
  yri <- which.maxneg(glc_year - df$year[i])
  if (length(tilei) > 1) {
    # takes a long time to merge two tiles ...
    # so better to extract values on the two tiles separetely
    filei <- sapply(tilei, function(x) gsub("XXXX", x, glc_rast[yri]))
    multiri <- lapply(file.path(data_folder, filei), terra::rast)
    if (nlyr(multiri[[1]]) == 23) {
      multiri[[1]] <- subset(multiri[[1]], yri - 3)
      multiri[[2]] <- subset(multiri[[2]], yri - 3)
    } else {
      multiri[[1]] <- subset(multiri[[1]], yri)
      multiri[[2]] <- subset(multiri[[2]], yri)
    }
    e1 <- exactextractr::exact_extract(
      multiri[[1]],
      sf::st_as_sf(bi),
      fun = c("frac", "count"),
      coverage_area = TRUE,
      progress = FALSE
    )
    e2 <- exactextractr::exact_extract(
      multiri[[2]],
      sf::st_as_sf(bi),
      fun = c("frac", "count"),
      coverage_area = TRUE,
      progress = FALSE
    )
    em <- dplyr::bind_rows(list(e1, e2))
    em[is.na(em)] <- 0
    ei <- (em[, grepl("frac_", names(em))] * em$count) / sum(em$count)
    ei <- colSums(ei)
  } else {
    # get the corresponding raster tile
    filei <- gsub("XXXX", tilei, glc_rast[yri])
    # load the raster
    ri <- rast(file.path(data_folder, filei))
    if (nlyr(ri) == 23) {
      names(ri) <- 2000:2022
      layi <- subset(ri, yri - 3)
    } else {
      names(ri) <- seq(1985, 1995, 5)
      layi <- subset(ri, yri)
    }
    ei <- exactextractr::exact_extract(
      layi,
      sf::st_as_sf(bi),
      fun = "frac",
      progress = FALSE
    )
  }
  df_out[[i]] <- ei
}

df_out <- dplyr::bind_rows(df_out)
df_out[is.na(df_out)] <- 0

write.csv(
  cbind(df, df_out),
  file.path(outfolder, "GLC_FCS30D_frac.csv"),
  row.names = FALSE
)

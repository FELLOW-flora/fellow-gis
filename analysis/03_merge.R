# Script to get merge all indicators
#
# input:
#   derived-data/GLC_FCS30D_frac.csv
#     from analysis/01_get_GLC_FCS30D.R
#   derived-data/Easyclimate_Last10years.csv
#     from analysis/02_get_eayclimate.R
#
# output:
#   derived-data/Landscape_metrics_FELLOW.csv
#   figure/Corr_Landscape_metrics.png

devtools::load_all()

data_folder <- here::here("data", "raw-data")
outfolder <- here::here("data", "derived-data")
fig_folder <- here::here("figure")
df <- read.csv(file.path(data_folder, "site_summary_year.csv"), row.names = 1)

# 1. simplify the land cover values and calculate ---------
#   percentage cover of crops (10,11,12,20)
#   percentage cover of grasslands (130)
#   percentage cover of woody natural habitats (50-122)
#   percentage cover of human made classes (190,200,201,202)
#   shanon diversity of land use cover (considering all categories also crops)

lulc <- read.csv(file.path(outfolder, "GLC_FCS30D_frac.csv"))
lulc <- lulc[!names(lulc) %in% names(df)]
lulc <- lulc[!names(lulc) %in% "frac_0"]

codeC <- gsub("frac_", "", names(lulc))

# set how to group the categories
crop_cat <- c("10", "11", "12", "20")
grass_cat <- "130"
woody_cat <- as.character(50:122)
human_cat <- "190"

land_cover <- data.frame(
  "frac_crop" = rowSums(lulc[, codeC %in% crop_cat]),
  "frac_grassland" = lulc[, codeC %in% grass_cat],
  "frac_woody" = rowSums(lulc[, codeC %in% woody_cat]),
  "frac_humanmade" = lulc[, codeC %in% human_cat]
)
land_cover <- round(land_cover * 100, 3)

grpC <- as.numeric(codeC) %/% 10
df_gp <- t(rowsum(t(lulc), grpC, na.rm = TRUE))

# grpC2 <- cut(
#   as.numeric(codeC),
#   breaks = c(0, 30, 125, 135, 160, 189, 195, 205, 2030, 255)
# )
# df_gp2 <- t(rowsum(t(lulc), grpC2, na.rm = TRUE))

shannon <- data.frame(
  "shannon_C35" = vegan::diversity(lulc, "shannon"),
  "shannon_C15" = vegan::diversity(df_gp, "shannon")
)

shannon <- round(shannon, 4)

# 2. merge and add the climate variables ---------
clim <- read.csv(file.path(outfolder, "Easyclimate_Last10years.csv"))

df_out <- cbind(df, land_cover, shannon, clim[, !names(clim) %in% names(df)])


# 3. export -----------------------------------
write.csv(
  df_out,
  file.path(outfolder, "Landscape_metrics_FELLOW.csv"),
  row.names = FALSE
)

# make a quick explorations of the correlation
ind <- df_out[, !names(df_out) %in% names(df)]
names(ind) <- gsub("_", "\n", names(ind))
png(
  file = file.path(fig_folder, "Corr_Landscape_metrics.png"),
  width = 1600,
  height = 1600,
  res = 200
)
pairs(
  ind,
  lower.panel = panel.smooth,
  upper.panel = panel.cor
)
dev.off()

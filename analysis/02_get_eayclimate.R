# Script to get climate information on a time period
#
# input:
#   easyclimate from VeruGHub/easyclimate
#   make sure to install the latest version on Github:
#     remotes::install_github("VeruGHub/easyclimate")
#
# output:
#   derived-data/Easyclimate_Last10years.csv
#

devtools::load_all()

# make sure to install the latest version with
# remotes::install_github("VeruGHub/easyclimate")

outfolder <- here::here("data", "derived-data")
df <- read.csv("data/raw-data/site_summary_year.csv", row.names = 1)

pts <- terra::vect(df, geom = c("X", "Y"), crs = "EPSG:4326")

time_period <- 9

df_out <- c()
# for testing sample(1:nrow(df), 10)
for (i in 1:nrow(df)) {
  # data not available for 2025 yet
  yri <- ifelse(pts[i]$year == 2025, 2024, pts[i]$year)
  # set the time period
  pi <- paste0(yri - time_period, "-01:", yri, "-12")
  # get monthly data
  monthly <- easyclimate::get_monthly_climate(
    pts[i],
    period = pi,
    climatic_var = c("Prcp", "Tavg")
  )
  # detect spring and summer values
  summer <- substr(monthly$date, 6, 8) %in% c("07", "08", "09")
  spring <- substr(monthly$date, 6, 8) %in% c("04", "05", "06")
  # calculate metrics
  outi <- data.frame(
    "mean_average_temperature" = mean(monthly$Tavg),
    "mean_average_precipitation" = sum(monthly$Prcp) / (time_period + 1),
    "mean_summer_temperature" = mean(monthly$Tavg[summer]),
    "mean_spring_precipitation" = sum(monthly$Prcp[spring]) / (time_period + 1)
  )
  # merge with previous results
  df_out <- rbind(df_out, c(df[i, ], outi))
}

write.csv(
  df_out,
  file.path(outfolder, "Easyclimate_Last10years.csv"),
  row.names = FALSE
)

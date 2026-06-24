# Suite of functions to fin the correspoding GLC_FCS30 tile
find_tiles <- function(buff) {
  coo <- crds(as.polygons(ext(buff)))
  tiles <- unique(apply(coo, 1, find_tile))
  return(tiles)
}


find_tile <- function(
  coo,
  xseq = c(-5, 0, 5, 10),
  xlab = c("W5", "E0", "E5", "E10"),
  yseq = seq(40, 50, by = 5),
  ylab = paste0("N", seq(45, 55, by = 5))
) {
  return(paste0(
    xlab[which.maxneg(xseq - as.numeric(coo[1]))],
    ylab[which.maxneg(yseq - as.numeric(coo[2]))]
  ))
}


which.maxneg <- function(x) {
  if (sum(x <= 0) >= 1) {
    return(match(max(x[x <= 0]), x))
  } else {
    return(NA)
  }
}

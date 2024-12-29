#Title: Floodable cadaster
#Description: Downloads French cadaster data and check if a plot face flooding risk using flooding maps

# Loading Libraries ----------
library(utils)
library(tidyverse)
library(here)
library(data.table)
library(sf)
library(parallel)

# Define the import function ----------
import_cadasters <- function(dep_num){
  
  #Cadaster datasets are split by department
  #Therefore, I implemented parallelization at the department level.
  
  comp_intersects <- function(CADASTER_DF, FLOOD_ZONE_DF){
    intersects_ls <- st_intersects(CADASTER_DF, FLOOD_ZONE_DF)
    intersects_bool <- lengths(intersects_ls) > 0
    return(intersects_bool)
  } #This checks if a vector of plots (here points) intersect with a flood zone
  
  folder_name <- here("data", "interim", paste0("cadaster", dep_num))
  
  url <- paste0("https://files.data.gouv.fr/cadastre/etalab-cadastre/2020-01-01/shp/departements/", dep_num, "/cadastre-", dep_num, "-parcelles-shp.zip")
  
  destfile <- here("data", "interim", paste0("cadaster", dep_num, ".zip"))
  
  download.file(url, destfile)
  
  unzip(destfile, exdir = folder_name)
  
  CADASTER_DF  <- sf::read_sf(folder_name)
  
  CADASTER_DF <- CADASTER_DF |>  
    mutate(dep = dep_num) |>
    st_centroid() |>
    st_transform(crs=2154)
  
  for(code in flood_codes) {
    col_name <- paste0("floodable", code)
    CADASTER_DF[[col_name]] <- comp_intersects(CADASTER_DF, flood_zones[[code]])
  }
  
  st_write(CADASTER_DF, here("data", "interim", "fr_cadaster2020_departments", paste0("cadaster_dep", dep_num, ".gpkg")))
  #This can later be used for dataviz purposes 
  
  unlink(destfile)
  unlink(folder_name, recursive = TRUE)
  
  return(CADASTER_DF) 
}

# Execute in parallel ----------
cl <- makeCluster(8)

clusterEvalQ(cl, {
  library(utils)
  library(tidyverse)
  library(here)
  library(data.table)
  library(sf)
  
  flood_files <- c(
    "N_INONDABLE_01_01.gpkg",
    "N_INONDABLE_01_02.gpkg",
    "N_INONDABLE_01_04.gpkg",
    "N_INONDABLE_03_01.gpkg",
    "N_INONDABLE_03_02.gpkg",
    "N_INONDABLE_03_04.gpkg"
  )
  
  flood_codes <- c("0101", "0102", "0104", "0301", "0302", "0304")
  
  flood_zones <- setNames(
    lapply(flood_files, function(file) {
      st_read(here("data", "external", "fr_GeoRisques", file), quiet = TRUE)
    }),
    flood_codes
  )
  
})

dep_ls <- c(str_pad(string=1:95, width=2, side="left", pad="0")[-20], "2A", "2B")

cadaster_ls <- parLapply(cl, dep_ls, import_cadasters)

stopCluster(cl)

# RBind results and export to Arrow ----------
CADASTER_DF <- rbindlist(cadaster_ls) 

CADASTER_DT <- setDT(CADASTER_DF)[, "geometry" := NULL]

attributes(CADASTER_DT)$sf_column <- NULL

arrow::write_feather(CADASTER_DT,  here("data", "interim", "fr_cadaster2020.feather"), compression = "zstd")

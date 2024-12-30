#Title: Preparatory manipulations for DataViz
#Description: Create geopackages for a IDF dataViz

#Loading Libraries ----------
library(tidyverse)
library(here)
library(data.table)
library(sf)

#Set Environmental Variables -------
set.seed(54194)

#The Pantheon Cross... (centering for IDF)
center_x <- 651000 
center_y <- 6860000 

bbox <- st_bbox(c(xmin = center_x-24e3, ymin = center_y-18e3, xmax =center_x+24e3, ymax = center_y+20e3), crs = 2154) |>
  st_as_sfc() #used for filtering

#Custom functions ----------
st_import93 <- function(path){
  st_read(path) |> st_transform(crs = 2154)
}

bbox_filter <- function(data_sf, filtering_box){
  return(data_sf[st_intersects(data_sf, filtering_box, sparse = FALSE), ])
}

weighted_sampling <- function(data, p1 = 0.03, p2 = 0.05){
  data$uniform <- runif(nrow(data))
  data <- data |> filter(uniform < 0.015 | (uniform < 0.025 & floodable0102))
  return(data)
}

#Import Paris Region Shapefile ----------
PARIS_SF <- st_import93(here("data", "external", "fr_shapeParis")) |>
  filter(code_insee %in% c("75","92","93","94", "78", "77", "95", "91"))

#Lapply over Ile-de-France region ----------
lambda_fun <- function(dep_num){
  data_sf <- here("data", "interim", "fr_cadaster2020_departments", paste0("cadaster_dep", dep_num, ".gpkg")) |>
    st_import93()
  return(data_sf)
}

CADASTER_SF <- lapply(c("75", "77", "78", "91", "92", "93", "94", "95"), lambda_fun) |> 
  rbindlist() |> 
  st_as_sf() |>
  bbox_filter(bbox) |> 
  weighted_sampling()

#Flood Layers ----------
FLOOD14_DF <- st_import93(here("data", "external", "fr_geoRisques","n_inondable_01_04.gpkg")) |> bbox_filter(bbox)
FLOOD12_DF <- st_import93(here("data", "external", "fr_geoRisques","n_inondable_01_02.gpkg")) |> bbox_filter(bbox)
FLOOD11_DF <- st_import93(here("data", "external", "fr_geoRisques","n_inondable_01_01.gpkg")) |> bbox_filter(bbox)

#Geopackage Exports ----------
st_write(PARIS_SF, here("results_building", "fr_paris_dataviz", "idf_departments.gpkg"))
st_write(CADASTER_SF, here("results_building", "fr_paris_dataviz", "idf_cadaster_sample.gpkg"))
st_write(FLOOD14_DF, here("results_building", "fr_paris_dataviz", "idf_flood14.gpkg"))
st_write(FLOOD12_DF, here("results_building", "fr_paris_dataviz", "idf_flood12.gpkg"))
st_write(FLOOD11_DF, here("results_building", "fr_paris_dataviz", "idf_flood11.gpkg"))
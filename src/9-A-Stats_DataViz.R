#Title: Descriptive Statistics and DataViz
#Description: Create a few descriptive statistics about regression dataset.
#             Create a DataViz describing the methodology from script 2-B.

#Loading Libraries ----------
library(tidyverse)
library(here)
library(data.table)
library(arrow)
library(sf)

#Set Environmental Variables -------
##The Pantheon Cross... -------
center_x <- 651000 
center_y <- 6860000 

#Load Datasets ----------
UKDATA_DF <- read_feather(here("results_building", "uk_regression_ready.feather"))
FRDATA_DF <- read_feather(here("results_building", "fr_regression_ready.feather"))
PARIS_SF <- st_read(here("results_building", "fr_paris_dataviz", "idf_departments.gpkg"))
CADASTER_SF <-st_read(here("results_building", "fr_paris_dataviz", "idf_cadaster_sample.gpkg"))
FLOOD14_DF <-st_read(here("results_building", "fr_paris_dataviz", "idf_flood14.gpkg"))
FLOOD12_DF <-st_read(here("results_building", "fr_paris_dataviz", "idf_flood12.gpkg"))
FLOOD11_DF <-st_read(here("results_building", "fr_paris_dataviz", "idf_flood11.gpkg"))

#Descriptive Statistics ----------



#DataViz ----------
paris_plot <- ggplot(PARIS_SF)+
  geom_sf(alpha=1, fill=NA, linewidth=.75)+
  geom_sf(data= FLOOD14_DF, aes(fill = "3-lpf"), alpha=.8)+
  geom_sf(data= FLOOD12_DF, aes(fill = "2-mpf"), alpha=.8)+
  geom_sf(data= FLOOD11_DF, aes(fill = "1-hpf"), alpha=.8)+
  geom_sf(data = CADASTER_SF, aes(color=floodable0102), shape=4, size=1, alpha=.9)+
  scale_fill_manual(
    values = c("3-lpf" = "#B0E0E6", "2-mpf" = "#87CEEB", "1-hpf" = "#4682B4"),
    name = "Flooding Probability",
    labels = c("High Probability Flood", "Medium Probability Flood","Low Probability Flood")
  )+ 
  scale_color_manual(
    values = c("#8DA48E", "#FF6347"),
    name = "Floodable Plots",
    labels = c("Low/No Risk", "Moderate/High Risk")
  )+ 
  coord_sf(
    xlim = c(center_x-17e3, center_x+22e3),  # Latitude range (North)
    ylim = c(center_y-15.5e3, center_y+17.5e3)     # Longitude range (East)
  )+
  theme_minimal()+
  theme(legend.position = "right", panel.grid.major = element_blank())

ggsave(here("results_analysis", "floodable_paris.jpeg"), paris_plot, width = 11, height=7.5)

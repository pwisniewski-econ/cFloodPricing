#Title: Descriptive Statistics and DataViz
#Description: Create a few descriptive statistics about regression dataset.
#             Create a DataViz describing the methodology from script 2-B.

#Loading Libraries ----------
library(tidyverse)
library(here)
library(data.table)
library(arrow)
library(sf)
library(showtext)
font_add(family = "Times", regular = "ressources/Times-New-Roman.otf")
showtext_auto()
showtext_opts(dpi = 300)

#Set Environmental Variables -------
##The Pantheon Cross... -------
center_x <- 651000 
center_y <- 6860000 

#Load Datasets ----------
UKDATA_DF <- read_feather(here("results_building", "uk_regression_ready.feather")) |> setDT()
FRDATA_DF <- read_feather(here("results_building", "fr_regression_ready.feather")) |> setDT()
PARIS_SF <- st_read(here("results_building", "fr_paris_dataviz", "idf_departments.gpkg"))
CADASTER_SF <-st_read(here("results_building", "fr_paris_dataviz", "idf_cadaster_sample.gpkg"))
FLOOD14_DF <-st_read(here("results_building", "fr_paris_dataviz", "idf_flood14.gpkg"))
FLOOD12_DF <-st_read(here("results_building", "fr_paris_dataviz", "idf_flood12.gpkg"))
FLOOD11_DF <-st_read(here("results_building", "fr_paris_dataviz", "idf_flood11.gpkg"))

#Descriptive Statistics ----------
DESC_DF <- FRDATA_DF[, "country" := "France"] |> 
  select(-floodable_riverOnly) |>
  rbind(UKDATA_DF[, "country" := "United Kingdom"]) |>
  group_by(country) |>
  summarise(
    n_observations = length(price),
    prop_floodable = sum(floodable)/n_observations,
    prop_floodableH = sum(floodable_highOnly)/n_observations,
    prop_houses = sum(property_type=="House")/n_observations,
    median_price = median(price),
    median_floor_area = median(floor_area),
    mean_rooms = mean(n_rooms)
  ) |>
  mutate(
    median_price_eur = if_else(country=="United Kingdom", median_price*.877, median_price),
  ) |>
  select(-median_price)

fwrite(DESC_DF, here("results_analysis", "descriptive_statistics.csv"))

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
  theme(panel.grid.major = element_blank(), 
        text = element_text(family = "Times", size = 12), 
        legend.position = "bottom", 
        legend.title = element_text(size = 12), 
        legend.box="vertical", 
        plot.margin = margin(0,7,0,0),
        legend.margin = margin(0,0,0,0))

ggsave(here("results_analysis", "floodable_paris.jpg"), paris_plot, width = 8, height=7.5)

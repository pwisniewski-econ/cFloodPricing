#Title: Merging Cadaster and DVF
#Description: Merge Price Paid with EPC and RoFRS

#Loading Libraries ----------
library(tidyverse)
library(here)
library(data.table)
library(arrow)

#Load datasets ----------
RoFRS_DF <- read_feather(here("data", "imported", "uk_RoFRS.feather"))
PRICE_PAID_DF <- read_feather(here("data", "imported", "uk_pricepaid2019.feather")) 
EPC_DF <- read_feather(here("data", "interim", "uk_epc_certificates.feather")) 
EPC_DF <- EPC_DF[order(-lodgement_date), .SD[1], by=.(uprn)] 
#Only keep the most up-to-date certificate for each house

#Merge and filter fo regressions ----------
PP_flood <- RoFRS_DF[PRICE_PAID_DF, on=.(uprn)]

PP_flood <- EPC_DF[PP_flood, on=.(uprn)]

PP_flood <- PP_flood |>
  replace_na(list(floodable = FALSE, floodable_highOnly = FALSE))

PP_flood <- PP_flood[, "property_type" := fifelse(property_type=="Flat", "Flat", "House") |> as.factor()]

PP_flood <- PP_flood[ppd_cat=="A"] |> 
  select(price, property_type, floor_area=total_floor_area, n_rooms = number_habitable_rooms, town, starts_with("floodable")) |>
  remove_missing() #We loose arround 20% of our data, mostly due to issues with uprn matching

#Export to Arrow ----------
write_feather(PP_flood, here("results_building", "uk_regression_ready.feather"), compression = "zstd")
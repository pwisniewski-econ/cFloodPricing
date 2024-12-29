#Title: Importing RoFRS
#Description: Imports and clean RoFRS dataset for flooding risks.

#Loading Libraries ----------
library(tidyverse)
library(here)
library(data.table)
library(arrow)

#Read and standardize the RoFRS dataset ----------
RoFRS_DF <- fread(here("data", "external","uk_RoFRS","RoFRS_Property_v202312.csv"), integer64 = "character")

names(RoFRS_DF) <- names(RoFRS_DF) |> tolower()

RoFRS_DF <- RoFRS_DF |>
  mutate(
    floodable = if_else(nafra_flc%in%c("High", "Medium", "Low"), T, F), #Medium definition
    floodable_highOnly = if_else(nafra_flc%in%c("High"), T, F), #Most restrictive definition
  ) |>
  select(uprn, floodable, floodable_highOnly)

#Export to Arrow ----------
write_feather(RoFRS_DF, here("data", "imported", "uk_RoFRS.feather"), compression = "zstd")
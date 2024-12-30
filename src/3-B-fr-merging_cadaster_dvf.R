#Title: Merging Cadaster and DVF
#Description: Adds information from previously computed cadaster data to DVF.
#             Outputs a regression ready dataset.

# Loading Libraries ----------
library(tidyverse)
library(here)
library(data.table)
library(arrow)

# Load cadaster/flooding data ----------
CADASTER_DT <- arrow::open_dataset(here("data", "interim", "fr_cadaster2020.feather"), format="arrow") |>
  select(commune, prefixe, section, numero_cad = numero, starts_with("floodable")) |>
  collect() |>
  setDT()

# Load DVF data ----------
DVF2019 <- arrow::open_dataset(here("data", "imported", "fr_dvf2019.feather"), format="arrow") |>
  mutate(
    prefixe = if_else(is.na(prefixe_de_section), "000", NA_character_),
    section = as.character(section), 
    numero_cad = as.character(no_plan)
  ) |>
  collect() |>
  mutate(
    commune = paste0(code_departement, str_pad(as.character(code_commune), 3, "left", "0"))
  ) |>
  setDT()

# Filtering and joining ----------
REG_DF <- CADASTER_DT[
  DVF2019,
  on = .(commune, prefixe, section, numero_cad),
  nomatch = NULL
]

# Note: ~50% of data is excluded here, mostly commercial real estate but also many missing values for surface area
REG_DF <- REG_DF[
  nature_mutation == "Vente" &
  type_local %in% c("Maison", "Appartement") &
  surface_reelle_bati > 0 &
  !is.na(type_local) &
  !is.na(nombre_pieces_principales) &
  valeur_fonciere > 0
] 

REG_DF[, "floodable" := fifelse(floodable0102==T|floodable0302==T, T, F)]
REG_DF[, "floodable_highOnly" := fifelse(floodable0101==T|floodable0301==T, T, F)]
REG_DF[, "floodable_riverOnly" := floodable0102]
REG_DF[, "type_local" := fifelse(type_local=="Maison", "House", "Flat")]


REG_DF <- REG_DF |> 
  select(price = valeur_fonciere, floor_area = surface_reelle_bati, n_rooms = nombre_pieces_principales,
         property_type = type_local, town = commune,  floodable, floodable_highOnly, floodable_riverOnly)

# Export to Arrow ----------
write_feather(as.data.frame(REG_DF), here("results_building", "fr_regression_ready.feather"), compression = "zstd")

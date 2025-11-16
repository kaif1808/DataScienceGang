# 01_data_loading.R
#
# Purpose: This module loads all source tables required for the Olympic medal prediction pipeline
# and performs initial data preparation by converting CSV files to tibbles.
#
# Inputs:
# - pre_medal.csv: Olympic windows data (macroeconomic indicators aggregated by country and Olympic year)
# - data/Olympic_Medal_Tally_History.csv: Historical Olympic medal tallies by country and year
# - 2024olympics/medals_total.csv: Paris 2024 Olympic medal tallies
# - 2024olympics/nocs.csv: List of all participating countries in Paris 2024 Olympics
#
# Outputs: The following tibbles are assigned to the global environment:
# - olympic_windows: Olympic windows data as a tibble
# - medals: Historical medal tallies as a tibble
# - paris_medals_raw: Paris 2024 medal tallies as a tibble
# - paris_nocs: Paris 2024 participating countries as a tibble
#
# Usage: Source this script at the beginning of the data cleaning pipeline to load and prepare
# the raw data for subsequent processing modules.

# Load required libraries
library(data.table)
library(dplyr)
library(readr)

# -----------------------------------------------------------------------------
# Load source tables ----------------------------------------------------------
# -----------------------------------------------------------------------------

olympic_windows <- fread("../data/pre_medal.csv") |> as_tibble()
medals <- fread("../data/Olympic_Medal_Tally_History.csv") |> as_tibble()
paris_medals_raw <- fread("../2024olympics/medals_total.csv") |> as_tibble()
paris_nocs <- fread("../2024olympics/nocs.csv") |> as_tibble()  # All participating countries
rm(list=ls()) 

library(readxl)

#Inflation data
inflation_data <- read_excel("API_FP.CPI.TOTL.ZG_DS2_en_excel_v2_156755.xls", sheet = "Data") 
inflation_data <- inflation_data[-c(1:2), ] 
colnames(inflation_data) <- as.character(inflation_data[1, ])
inflation_data <- inflation_data[-1, ]
year_cols <- colnames(inflation_data)[5:ncol(inflation_data)]
inflation_data[year_cols] <- lapply(inflation_data[year_cols], as.numeric)
inflation_data_wide <- inflation_data[, -c(2,4:36)] 

library(tidyverse)

# Pivot the data to long format
inflation_long <- inflation_data_wide %>%
  pivot_longer(
    cols = `1992`:`2024`,  # or whatever your year range is
    names_to = "Year",
    values_to = "Inflation_Rate"
  ) %>%
  mutate(Year = as.numeric(Year))

#Population data

population_data <- read_excel("API_SP.POP.TOTL_DS2_en_excel_v2_130162.xls", sheet = "Data") 
population_data <- population_data[-c(1:2), ] 
colnames(population_data) <- as.character(population_data[1, ])
population_data <- population_data[-1, ]
year_cols <- colnames(population_data)[5:ncol(population_data)]
population_data[year_cols] <- lapply(population_data[year_cols], as.numeric)
population_data_wide <- population_data[, -c(2,4:36)] 

# Pivot the data to long format
population_long <- population_data_wide %>%
  pivot_longer(
    cols = `1992`:`2024`,  # or whatever your year range is
    names_to = "Year",
    values_to = "Population"
  ) %>%
  mutate(Year = as.numeric(Year))

#Female labour force participation 

female_data <- read_excel("API_SL.TLF.CACT.FE.NE.ZS_DS2_en_excel_v2_126783.xls", sheet = "Data") 
female_data <- female_data[-c(1:2), ] 
colnames(female_data) <- as.character(female_data[1, ])
female_data <- female_data[-1, ]
year_cols <- colnames(female_data)[5:ncol(female_data)]
female_data[year_cols] <- lapply(female_data[year_cols], as.numeric)
female_data_wide <- female_data[, -c(2,4:36)] 

# Pivot the data to long format
female_long <- female_data_wide %>%
  pivot_longer(
    cols = `1992`:`2024`,  # or whatever your year range is
    names_to = "Year",
    values_to = "Labour_Force_Female"
  ) %>%
  mutate(Year = as.numeric(Year))

#Unemployment 

unemployment_data <- read_excel("API_SL.UEM.TOTL.ZS_DS2_en_excel_v2_129065.xls", sheet = "Data") 
unemployment_data <- unemployment_data[-c(1:2), ] 
colnames(unemployment_data) <- as.character(unemployment_data[1, ])
unemployment_data <- unemployment_data[-1, ]
year_cols <- colnames(unemployment_data)[5:ncol(unemployment_data)]
unemployment_data[year_cols] <- lapply(unemployment_data[year_cols], as.numeric)
unemployment_data_wide <- unemployment_data[, -c(2,4:36)] 

# Pivot the data to long format
unemployment_long <- unemployment_data_wide %>%
  pivot_longer(
    cols = `1992`:`2024`,  # or whatever your year range is
    names_to = "Year",
    values_to = "Unemployment_Rate"
  ) %>%
  mutate(Year = as.numeric(Year))

# Government Spending

spending_data <- read_excel("API_NE.CON.GOVT.CD_DS2_en_excel_v2_124919.xls", sheet = "Data") 
spending_data <- spending_data[-c(1:2), ] 
colnames(spending_data) <- as.character(spending_data[1, ])
spending_data <- spending_data[-1, ]
year_cols <- colnames(spending_data)[5:ncol(spending_data)]
spending_data[year_cols] <- lapply(spending_data[year_cols], as.numeric)
spending_data_wide <- spending_data[, -c(2,4:36)] 

# Pivot the data to long format
spending_long <- spending_data_wide %>%
  pivot_longer(
    cols = `1992`:`2024`,  # or whatever your year range is
    names_to = "Year",
    values_to = "Government_Spending"
  ) %>%
  mutate(Year = as.numeric(Year))

#GDP per capita

GDP_data <- read_excel("API_NY.GDP.PCAP.CD_DS2_en_excel_v2_130121.xls", sheet = "Data") 
GDP_data <- GDP_data[-c(1:2), ] 
colnames(GDP_data) <- as.character(GDP_data[1, ])
GDP_data <- GDP_data[-1, ]
year_cols <- colnames(GDP_data)[5:ncol(GDP_data)]
GDP_data[year_cols] <- lapply(GDP_data[year_cols], as.numeric)
GDP_data_wide <- GDP_data[, -c(2,4:36)] 

# Pivot the data to long format
GDP_long <- GDP_data_wide %>%
  pivot_longer(
    cols = `1992`:`2024`,  # or whatever your year range is
    names_to = "Year",
    values_to = "GDP_per_capita"
  ) %>%
  mutate(Year = as.numeric(Year))

# Preparing for merge
inflation_long <- inflation_long[,-2] 
population_long <- population_long[,-2] 
female_long <- female_long[,-2] 
unemployment_long <- unemployment_long[,-2] 
spending_long <- spending_long[,-2] 
GDP_long <- GDP_long[,-2] 

# Merging all datasets

# Method 2: Chain multiple left_joins
combined_data <- inflation_long %>%
  left_join(population_long, by = c("Country Name", "Year")) %>%
  left_join(female_long, by = c("Country Name", "Year")) %>%
  left_join(unemployment_long, by = c("Country Name", "Year")) %>%
  left_join(spending_long, by = c("Country Name", "Year")) %>%
  left_join(GDP_long, by = c("Country Name", "Year"))

write_csv(combined_data, "combined_data.csv")




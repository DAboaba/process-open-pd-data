# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for this script ----
pacman::p_load(magrittr, purrr, tibble, readxl, yaml, stringr)

# Load necessary functions for this script ----
source(file.path("R", "get_dept_data_functions.R"))

get_nypd_data <- function(start_year, end_year, app_token){
    get_nypd_crime_data(start_year, end_year, app_token = app_token)
}

get_nypd_crime_data <- function(start_year,
                                end_year,
                                date_col = "cmplnt_fr_dt",
                                app_token){
    message("Getting New York Police Department Crime Data")
    read_multi_year_socrata_data(
        api_endpoint_link = "https://data.cityofnewyork.us/resource/qgea-i56i.csv",
        years = start_year:end_year,
        date_col = date_col,
        app_token = app_token) %>%
        map_dfr(~mutate(.x, housing_psa = as.character(housing_psa))) %>%
        as_tibble()
}

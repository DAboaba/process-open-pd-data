# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for this script ----
pacman::p_load(magrittr, tibble, dplyr)

# Load necessary functions for this script ----
source(file.path("R", "get_dept_data_functions.R"))

get_cpd_data <- function(start_year, end_year, app_token){
    get_cpd_crime_data(start_year, end_year, app_token = app_token)
}

get_cpd_crime_data <- function(start_year,
                               end_year,
                               date_col = "date",
                               app_token){
    message("Getting Chicago Police Department Crime Data")
    read_multi_year_socrata_data(
        api_endpoint_link = "https://data.cityofchicago.org/resource/crimes.csv",
        years = start_year:end_year,
        date_col = date_col,
        app_token = app_token) %>%
        as_tibble()
}


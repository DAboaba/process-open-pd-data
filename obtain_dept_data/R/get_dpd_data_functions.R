# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for this script ----
pacman::p_load(magrittr, tibble)

# Load necessary functions for this script ----
source(file.path("R", "get_dept_data_functions.R"))

get_dpd_data <- function(start_year, end_year, app_token){
    get_dpd_crime_data(start_year, end_year, app_token = app_token)
}

get_dpd_crime_data <- function(start_year,
                               end_year,
                               date_col = "date1",
                               app_token){
    message("Getting Dallas Police Department Crime Data")
    read_multi_year_socrata_data(
        api_endpoint_link = "https://www.dallasopendata.com/resource/qv6i-rri7.csv",
        years = start_year:end_year,
        date_col = date_col,
        app_token = app_token) %>%
        data.table::rbindlist() %>%
        as_tibble()
}


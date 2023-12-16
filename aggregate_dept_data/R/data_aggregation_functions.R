# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for this script ----
pacman::p_load(purrr, dplyr)

bind_dept_data <- function(dept_data_list, cols_to_select){
    map_dfr(dept_data_list,
            select,
            all_of(cols_to_select))
}

aggregate_to_district_month_level <- function(dataframe){
    col_names <- dataframe %>% colnames()
    ind_col_names <- col_names[col_names %>% str_detect(".ind")]
    new_ind_col_names <- ind_col_names %>% str_remove(".ind")
    new_col_names <- col_names %>% str_remove(".ind")
    colnames(dataframe) <- new_col_names

    dataframe %>%
        group_by(dept, district, inc.year, inc.month) %>%
        summarise(across(all_of(new_ind_col_names),
                         sum,
                         .names = "total.{.col}s")) %>%
        ungroup()
}


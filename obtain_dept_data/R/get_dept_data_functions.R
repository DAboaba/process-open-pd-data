# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for this script ----
pacman::p_load(magrittr, dplyr, furrr, RSocrata)

get_data_multiple_dpts <- function(vec_dept_names,
                                   start_year,
                                   end_year,
                                   app_token,
                                   out_dir){
    data_list <- list()

    for (i in 1:length(vec_dept_names)){

        output_file_path <- file.path(out_dir,
                                      paste0(vec_dept_names[i],
                                             "_data", ".feather"))

        if (!file.exists(output_file_path)) {
            data_list[[vec_dept_names[i]]] <- get_dept_data(
                dept_name = vec_dept_names[i],
                start_year = start_year,
                end_year = end_year,
                app_token = app_token)
        } else {
            print('Data already exists, not redownloading.')
        }

    }

    data_list

}

get_dept_data <- function(dept_name, start_year, end_year, app_token){
    dept_data <- match.fun(paste0("get_", dept_name, "_data"))(
        start_year = start_year,
        end_year = end_year,
        app_token = app_token)

    dept_data
}

read_multi_year_socrata_data <- function(api_endpoint_link,
                                         years,
                                         date_col,
                                         app_token){
    years <- as.numeric(years)
    num_workers <- length(years)
    plan(multisession, workers = num_workers)

    mapping_fn <- "future_map_dfr"
    result <- try(match.fun(mapping_fn)(.x = years,
                                        .f = read_full_year_socrata_data,
                                        api_endpoint_link = api_endpoint_link,
                                        date_col = date_col,
                                        app_token = app_token))

    if("try-error" %in% class(result)){mapping_fn <- "future_map"}

    match.fun(mapping_fn)(.x = years,
                          .f = read_full_year_socrata_data,
                          api_endpoint_link = api_endpoint_link,
                          date_col = date_col,
                          app_token = app_token)
}


read_full_year_socrata_data <- function(api_endpoint_link,
                                        year,
                                        date_col,
                                        app_token){

    start_date <- paste0(year, "-01-01")
    end_date <- paste0(year, "-12-31")


    message("\n",
            "Retrieving socrata data from ",
            start_date,
            " to ",
            end_date,
            "\n")

    start_date <- paste0("'", start_date, "'")
    end_date <- paste0("'", end_date, "'")

    read.socrata(paste0(api_endpoint_link,
                        "?$where=",
                        date_col,
                        " ",
                        "between ",
                        start_date,
                        " ",
                        "and",
                        " ",
                        end_date),
                 app_token = token)
}

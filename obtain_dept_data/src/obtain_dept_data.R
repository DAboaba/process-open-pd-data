# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for task ----
pacman::p_load(yaml, here, purrr, feather, magrittr, lubridate)

# Load general and/or task specific functions ----
source(file.path("..", "R", "general_functions.R"))
source(file.path("R", "get_nypd_data_functions.R"))
source(file.path("R", "get_cpd_data_functions.R"))
source(file.path("R", "get_lapd_data_functions.R"))
source(file.path("R", "get_dpd_data_functions.R"))
source(file.path("R", "get_ppd_data_functions.R"))
source(file.path("R", "get_phxpd_data_functions.R"))
source(file.path("R", "get_mpd_data_functions.R"))
source(file.path("R", "get_hpd_data_functions.R"))

# Check for existence of and/or create task output directory ----
task_output_dir <- file.path("output")
check_create_dir(task_output_dir)

# Read in config file specifying unique decisions made for this task ----
task_config <- yaml::read_yaml(file.path("hand", "config.yaml"))

token <- task_config$app_token
dpts <- task_config$departments

# Get data on multiple departments ----
dpt_data_list <- get_data_multiple_dpts(vec_dept_names = dpts,
                                        start_year = 2016,
                                        end_year = 2019,
                                        app_token = token,
                                        out_dir = task_output_dir)

# Write out data for multiple departments ----
walk2(
    dpt_data_list,
    file.path(task_output_dir, paste0(names(dpt_data_list), "_data", ".feather")),
    write_feather
)


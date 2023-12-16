# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for task ----
pacman::p_load(yaml, here, purrr, feather, magrittr, lubridate)

# Load general and/or task specific functions ----
source(file.path("..", "R", "general_functions.R"))
source(file.path("R", "data_aggregation_functions.R"))

# Check for existence of and/or create task output directory ----
task_output_dir <- file.path("output")
check_create_dir(task_output_dir)

# Read in config file specifying unique decisions made for this task ----
task_config <- yaml::read_yaml(file.path("hand", "config.yaml"))

# Specify previous task directories ----
previous_task_dir <- here(task_config$previous_task_name)
task_input_dir <- file.path(previous_task_dir, "output")

# Specify departments ----
dpts <- task_config$departments

# Specify path of input files ----
task_input_files_path <- file.path(
    task_input_dir,
    paste0("clnd_", dpts, "_data", ".feather")
)

# Read in department data from previous task ----
clnd_dpt_data_list <- map(task_input_files_path, read_feather)
names(clnd_dpt_data_list) <- dpts

# Specify columns to keep and bind data across different departments ----
cols_wanted <- task_config$common_columns

# Bind data from different departments into single data frame
dpt_data_unified <- bind_dept_data(dept_data_list = clnd_dpt_data_list,
                                   cols_wanted)

# Aggregate unified data to district month level ----
dpt_data_dml <- aggregate_to_district_month_level(dpt_data_unified)

# Write out bound and aggregated data ----
write_feather(dpt_data_unified,
              file.path(task_output_dir, "dept_data_unified.feather"))

write_feather(dpt_data_dml,
              file.path(task_output_dir, "dept_data_d_m_level.feather"))

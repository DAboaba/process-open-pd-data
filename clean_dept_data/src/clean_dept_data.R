# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for task ----
pacman::p_load(yaml, here, purrr, feather)

# Load general and/or task specific functions ----
source(file.path("..", "R", "general_functions.R"))
source(file.path("R", "clean_dept_data_functions.R"))

# Check for existence of and/or create task output directory ----
task_output_dir <- file.path("output")
check_create_dir(task_output_dir)

# Read in config file specifying unique decisions made for this task ----
task_config <- yaml::read_yaml(file.path("hand", "config.yaml"))

# Specify previous task directories ----
previous_task_dir <- here(task_config$previous_task_name)
task_input_dir <- file.path(previous_task_dir, "output")

# Specify token and departments ----
dpts <- task_config$departments

# Specify path of input files ----
task_input_files_path <- file.path(
    task_input_dir,
    paste0(dpts, "_data", ".feather")
)

# Read in department data from previous task ----
dpts_data_list <- map(task_input_files_path, read_feather)
names(dpts_data_list) <- dpts

# Clean data for multiple departments ----
clnd_dpt_data_list <- clean_data_multiple_dpts(dpts_data_list)

# Write out cleaned data for multiple departments ----
walk2(
    clnd_dpt_data_list,
    file.path(task_output_dir, paste0("clnd_", dpts, "_data", ".feather")),
    write_feather
)

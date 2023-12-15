# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for this script ----
pacman::p_load(yaml, magrittr, dplyr, janitor, stringr)

check_create_dir <- function(dir_path) {
    if (!dir.exists(dir_path)) {
        dir.create(dir_path)
    }
}

# Change a dataset's column names to snake case with "_" replaced by "."
clean_column_names <- function(dataframe){
    dataframe %<>%
        clean_names()
    c_names <- colnames(dataframe)
    c_names <- str_replace_all(c_names, "_", ".")
    colnames(dataframe) <- c_names
    dataframe
}

# Recode a column with a corresponding yaml codebook file
recode_column_with_codebook <- function(df,
                                        var_to_use,
                                        var_result) {

    # Begin to build path for correct yaml file by using supplied data source
    path <- file.path("hand", "codebooks")

    # Complete path to correct yaml file by appending variable name and .yaml
    path <- paste0(path, "/", var_to_use, ".yaml")

    # Read yaml data stored at generated path into temp_codebook
    temp_codebook <- yaml::read_yaml(path)

    # Convert temp_codebook from list into a named vector
    level_values <- unlist(temp_codebook)

    # Store level names in level_names object
    level_names <- names(level_values)

    # Strip names from original named vector that temp_codebook was converted to
    names(level_values) <- NULL

    # Convert variable to a factor and supply the correct levels and lables
    df %>%
        mutate(
            {{ var_result }} :=
                factor(
                    .data[[var_to_use]],
                    levels = level_names,
                    labels = level_values
                )
        )
}

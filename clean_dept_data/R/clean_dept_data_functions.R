# Ensure pacman is installed before attempting to use it ----
if (!require("pacman")) install.packages("pacman"); library(pacman)

# Load necessary packages for this script ----
pacman::p_load(purrr, dplyr, magrittr, tidyr, readxl, yaml, RSocrata, tibble,
               sf, lubridate, lwgeom, readr)

clean_data_multiple_dpts <- function(named_list_dept_data){
    dept_names <- names(named_list_dept_data)
    map2(.x = named_list_dept_data,
         .y = dept_names,
         .f = clean_dept_data)
}


clean_dept_data <- function(dept_data, dept_name){
    cleaned_dept_data <- match.fun(paste0("clean_", dept_name, "_data"))(
        dataf = dept_data)
    # code to ensure no extra rows have been added by cleaning the dataframe
    stopifnot(nrow(dept_data) >= nrow(cleaned_dept_data))
    if(nrow(dept_data) > nrow(cleaned_dept_data)){
        message("cleaned dept data smaller than original data")
    }else{
        message("cleaned dept data same size as original data")
    }
    cleaned_dept_data
}

clean_nypd_data <- function(dataf){
    clean_dept_data_basic(dataf, "nypd", "addr_pct_cd", "cmplnt_fr_dt")
}

clean_cpd_data <- function(dataf){
    clean_dept_data_basic(dataf, "cpd", "district", "date")
}

clean_lapd_data <- function(dataf){
    clean_dept_data_basic(dataf, "lapd", "area", "date_occ")
}

clean_dpd_data <- function(dataf){
    clean_dept_data_basic(dataf, "dpd", "division", "date1")
}

clean_dept_data_basic <- function(dataf, dept_name, district_col_analogue,
                                  date_col){
    message("Cleaning ", str_to_upper(dept_name), " Data")
    dataf %>%
        create_crime_indicators(dept_name = dept_name) %>%
        create_district_col(district_col_analogue = district_col_analogue) %>%
        create_date_components_cols(date_col) %>%
        create_dept_col(dept_name = dept_name) %>%
        clean_column_names()
}

create_crime_indicators <- function(dataframe, dept_name){
    dataframe %>%
        mutate(crime.ind = 1) %>%
        create_index_indicator(dept_name = dept_name) %>%
        create_p1_vio_indicator(dept_name = dept_name) %>%
        create_homicide_indicator(dept_name = dept_name)
}


create_index_indicator <- function(dataframe, dept_name) {
    match.fun(paste0("create_index_indicator", "_", dept_name))(
        dataframe = dataframe)
}

create_p1_vio_indicator <- function(dataframe, dept_name){
    match.fun(paste0("create_p1_vio_indicator", "_", dept_name))(
        dataframe = dataframe)
}

create_homicide_indicator <- function(dataframe, dept_name) {
    match.fun(paste0("create_homicide_indicator", "_", dept_name))(
        dataframe = dataframe)
}

create_district_col <- function(dataframe,
                                district_col_analogue,
                                clean = FALSE){
    dataframe %<>%
        mutate(district = toupper(str_replace_all(as.character(.data[[district_col_analogue]]),
                                                  ' ', '')))
    if(clean){
        dataframe %<>%
            mutate(district = substring(district_col_analogue, 1, 2))
    }

    dataframe

}


create_date_components_cols <- function(dataframe,
                                        date_col){

    if (is.POSIXct(dataframe[[date_col]]) |
        is.Date(is.POSIXct(dataframe[[date_col]]))) {
        dataframe %<>%
            mutate(inc.year = year(.data[[date_col]]),
                   inc.month = month(.data[[date_col]]),
                   inc.day = day(.data[[date_col]]))
    } else {
        dataframe %<>%
            mutate(date_formatted = as.Date(.data[[date_col]])) %>%
            separate(col = date_formatted,
                     into = paste0("inc.", c("year", "month", "day")),
                     sep = "-",
                     remove = FALSE)
    }
    dataframe %>%
        mutate(across(starts_with("inc."), as.numeric))

}

create_dept_col <- function(dataframe, dept_name){
    dataframe %>%
        mutate(dept = dept_name)
}

# index indicator functions ----
# Homicide, rape, robbery, aggravated assault, burglary, larceny-theft, motor vehicle theft

create_index_indicator_nypd <- function(dataframe,
                                        rpt_code_col = "ofns_desc") {
    index_codes <- c("MURDER & NON-NEGL. MANSLAUGHTER",
                     "RAPE",
                     "ROBBERY",
                     "FELONY ASSAULT",
                     "BURGLARY",
                     "GRAND LARCENY",
                     "PETIT LARCENY",
                     "GRAND LARCENY OF MOTOR VEHICLE",
                     "ARSON")

    dataframe %>%
        mutate(index.crime = .data[[rpt_code_col]] %in% index_codes,
               index.crime.ind = as.numeric(index.crime))
}

create_index_indicator_cpd <- function(dataframe,
                                       rpt_code_col = "iucr") {

    # open data linking IUCR (Illinois UCR) codes to UCR codes
    read.socrata("https://data.cityofchicago.org/resource/c7ck-438e.csv") %>%
        as_tibble() %>%
        # Index offenses are offenses that are collected by the FBI's UCR program
        filter(index_code == "I") %>%
        mutate(primary_description = str_to_lower(primary_description)) %>%
        # need to explicitly filter this
        select(iucr, primary_description, index_code) %>%
        # Make sure rows are unique (i.e. mapping is one-to-one)
        distinct() %>%
        mutate(iucr = if_else(str_length(iucr) == 3, paste0("0", iucr), iucr)) %>%
        # right_join to cpd data
        right_join(dataframe, by = {{rpt_code_col}}) %>%
        mutate(index.crime = !if_any(.cols = c(primary_description, index_code),
                                     is.na),
               index.crime.ind = as.numeric(index.crime)) %>%
        select(-c(primary_description, index_code))
}

create_index_indicator_lapd <- function(dataframe,
                                        rpt_code_col = "crm_cd_1") {
    index_codes <- c(
        110, 113, # homicide
        121, 122, 815, 820, 821, # rape
        210, 220, # robbery
        230, 231, 235, 236, 250, 251, 761, 926, # assault
        310, 320, # burglary
        510, 520, # motor vehicle theft
        # larceny
        ## btfv
        330, 331, 410, 420, 421,
        ## personal theft
        350, 351, 352, 353, 450, 451, 452, 453,
        ## other theft
        341, 343, 345, 440, 441, 442, 443, 444, 445, 470, 471, 472, 473, 474, 475,
        480, 485, 487, 491,
        648 # arson
    )

    # crime code 1 is the primary and most serious crime but it is sometimes
    # missing
    if (rpt_code_col == "crm_cd_1"){
        dataframe %<>%
            mutate(crm_cd_1 = if_else(is.na(crm_cd_1), crm_cd, crm_cd_1))
    }

    dataframe %>%
        mutate(index.crime = .data[[rpt_code_col]] %in% index_codes,
               index.crime.ind = as.numeric(index.crime))
}

create_index_indicator_dpd <- function(dataframe,
                                       rpt_code_col = "ucrcode") {
    # File does not include rape
    ucr_index_codes <-  c(
        '110', # murder
        '300', # robbery
        '400', # aggravated assault
        '511', '512', '521', '522', '531', '532', # burglary
        '610', '620', '630',' 640', '650', '680', '690', # theft
        '710', '720', '730', # motor vehicle theft
        # arson
        '911', '912', '921', '922', '932', '951', '952', '961',
        '962', '971', '972', '981', '982', '990'
    )

    nibrs_index_codes <- c(
        '09A', # murder & non-negligent manslaughter
        '120', # robbery business/individual
        '100', '13A', '520', # aggravated assault fv/nfv and weapon law violations
        '220', # burglary - business/residence
        paste0('23', c('A', 'B', 'C', 'E', 'H', 'G')), # theft/motor vehicle theft
        '240', # unauthorized use of a motor vehicle
        '200' # arson
    )

    dataframe %>%
        mutate(index.crime = .data[[rpt_code_col]] %in% ucr_index_codes,
               index.crime = if_else(year1 == 2019,
                                     nibrs_code %in% nibrs_index_codes,
                                     index.crime),
               index.crime.ind = as.numeric(index.crime))
}


create_p1_vio_indicator_cpd <- function(dataframe,
                                        rpt_code_col = "iucr"){

    # although cpd data comes with primary type AND description columns, but for
    # various reasons (miscodin, etc), by themselves they are not sufficient to
    # distinguish part 1 violent crimes instead we use another open data source
    # that links Illinois UCR (IUCR) codes to the FBI's codes


    # open data linking IUCR codes to UCR codes
    read.socrata("https://data.cityofchicago.org/resource/c7ck-438e.csv") %>%
        as_tibble() %>%
        # Index offenses are offenses that are collected by the FBI's UCR program
        filter(index_code == "I") %>%
        mutate(primary_description = str_to_lower(primary_description)) %>%
        # Only keep mapping from IUCR to Part 1 violent crimes (not very clear
        # which of assault and/or battery should be included but 2017 report
        # suggests battery is included)
        filter(primary_description %in% c("homicide", "crim sexual assault",
                                          "assault", "battery", "robbery")) %>%
        select(iucr, primary_description, index_code) %>%
        # Make sure rows are unique (i.e. mapping is one-to-one)
        distinct() %>%
        mutate(iucr = if_else(str_length(iucr) == 3, paste0("0", iucr), iucr)) %>%
        # right_join to cpd data
        right_join(dataframe, by = {{rpt_code_col}}) %>%
        mutate(p1.vio.crime = !if_any(.cols = c(primary_description, index_code),
                                      is.na),
               p1.vio.crime.ind = as.numeric(p1.vio.crime)) %>%
        select(-c(primary_description, index_code))
}


create_p1_vio_indicator_lapd <- function(dataframe,
                                         rpt_code_col = "crm_cd_1"){

    # Online PDF linking COMPSTAT codes to UCR codes (from which config was drawn)
    # https://data.lacity.org/api/views/63jg-8b9z/files
    # /fff2caac-94b0-4ae5-9ca5-d235b19e3c44?download=true&filename=UCR
    # -COMPSTAT062618.pdf

    p1_vio_codes <- c(
        110, # homicide
        121, 122, 815, 820, 821, # rape
        210, 220, # robbery
        230, 231, 235, 236, 250, 251, 761, 926 # assault
    )

    # crime code 1 is the primary and most serious crime but it is sometimes
    # missing
    if (rpt_code_col == "crm_cd_1"){
        dataframe %<>%
            mutate(crm_cd_1 = if_else(is.na(crm_cd_1), crm_cd, crm_cd_1))
    }

    dataframe %>%
        mutate(p1.vio.crime.ind = .data[[rpt_code_col]] %in% p1_vio_codes,
               p1.vio.crime.ind = as.numeric(p1.vio.crime.ind))
}

create_p1_vio_indicator_dpd <- function(dataframe,
                                        rpt_code_col = "ucrcode"){

    # File does not include rape
    ucr_p1_vio_codes <- c('110', # murder
                          '300', # robbery
                          '400' # aggravated assault
    )

    nibrs_p1_vio_codes <- c(
        '09A', # murder & nonnegligent manslaughter
        '120', # robbery business/individual
        '100', '13A', '520' # aggravated assault fv/nfv and weapon law violations
    )

    dataframe %>%
        mutate(p1.vio.crime = .data[[rpt_code_col]] %in% ucr_p1_vio_codes,
               p1.vio.crime = if_else(year1 == 2019,
                                      nibrs_code %in% nibrs_p1_vio_codes,
                                      p1.vio.crime),
               p1.vio.crime.ind = as.numeric(p1.vio.crime))
}

# homicide indicator functions ----

create_homicide_indicator_nypd <- function(dataframe,
                                           rpt_code_col = "ofns_desc"){
    homicide_codes <- "MURDER & NON-NEGL. MANSLAUGHTER"

    dataframe %>%
        mutate(homicide = .data[[rpt_code_col]] %in% homicide_codes,
               homicide.ind = as.numeric(homicide))
}

create_homicide_indicator_cpd <- function(dataframe,
                                          rpt_code_col = "iucr"){

    # although cpd data comes with primary type AND description columns, but for
    # various reasons (miscodin, etc), by themselves they are not sufficient to
    # distinguish part 1 violent crimes instead we use another open data source
    # that links Illinois UCR (IUCR) codes to the FBI's codes


    # open data linking IUCR codes to UCR codes
    read.socrata("https://data.cityofchicago.org/resource/c7ck-438e.csv") %>%
        as_tibble() %>%
        # Index offenses are offenses that are collected by the FBI's UCR program
        filter(index_code == "I") %>%
        mutate(primary_description = str_to_lower(primary_description)) %>%
        # Only keep mapping from IUCR to Part 1 violent crimes (not very clear
        # which of assault and/or battery should be included but 2017 report
        # suggests battery is included)
        filter(primary_description %in% c("homicide")) %>%
        select(iucr, primary_description, index_code) %>%
        # Make sure rows are unique (i.e. mapping is one-to-one)
        distinct() %>%
        mutate(iucr = if_else(str_length(iucr) == 3, paste0("0", iucr), iucr)) %>%
        # right_join to cpd data
        right_join(dataframe, by = {{rpt_code_col}}) %>%
        mutate(homicide = !if_any(.cols = c(primary_description, index_code),
                                  is.na),
               homicide.ind = as.numeric(homicide)) %>%
        select(-c(primary_description, index_code))
}

create_homicide_indicator_lapd <- function(dataframe,
                                           rpt_code_col = "crm_cd_1"){

    homicide_codes <- 110

    # crime code 1 is the primary and most serious crime but it is sometimes
    # missing
    if (rpt_code_col == "crm_cd_1"){
        dataframe %<>%
            mutate(crm_cd_1 = if_else(is.na(crm_cd_1), crm_cd, crm_cd_1))
    }

    dataframe %>%
        mutate(homicide = .data[[rpt_code_col]] %in% homicide_codes,
               homicide.ind = as.numeric(homicide))
}

create_homicide_indicator_dpd <- function(dataframe,
                                          rpt_code_col = "ucrcode"){
    ucr_homicide_codes <-  "110"

    nibrs_homicide_codes <- "09A"

    dataframe %>%
        mutate(homicide = .data[[rpt_code_col]] %in% ucr_homicide_codes,
               homicide = if_else(year1 == 2019,
                                  nibrs_code %in% nibrs_homicide_codes,
                                  homicide),
               homicide.ind = as.numeric(homicide))
}

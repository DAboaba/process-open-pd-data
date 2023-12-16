## POLICING RELATED RCTs

**To clone the repo**:
    
1. `cd desired_directory`

2.  `git clone` the SSH clone url

**To run the code on your local machine**:
    
1. Get an application token from "https://support.socrata.com/hc/en-us/articles/210138558-Generating-an-App-Token"

2. Enter the application token on line 2 of `get_dept_data/hand/config.yaml`next to 'app_token:'

3. Set your working directory to the root of the project folder
        - In Rstudio console: `setwd("../policing_related_rcts")`

4. Confirm your working directory is at the root of the project directory
        - In Rstudio console: `getwd()`

5. Singular task(s)
- Manually
- In Rstudio console, `setwd("task-name"); source("src/task-name.r")`

Right now the tasks should be run in the following order:

    - get_dept_data
    - clean_dept_data
    - aggregate_dept_data
    - run_power_calculations

**How to add/use data for another department**:
    
*Assuming you are adding data for the philadelphia police department and abbreviating the department name to ppd*
    
To get data for another police department:
    
1. Add "ppd" to the list of departments in get_dept_data/hand/config.yaml

2. Copy and rename one of the get_dept_data/R/get_x_data_functions.R files as get_ppd_data_functions.R

3. Rename and edit `get_x_data()` and `get_x_crime_data()` in get_ppd_data_functions.R as needed to make sure you're getting the right data

4. Add `source(file.path("R", "get_ppd_data_functions.R"))` to get_dept_data/src/get_dept_data.R

To clean data for another police department: 

1. Add "ppd" to the list of departments in clean_dept_data/hand/config.yaml

2. Copy, rename, and edit `clean_x_data()` and `create_p1_vio_indicator_x()` to `clean_ppd_data()` and `create_p1_vio_indicator_ppd()` in clean_dept_data_functions.R.

To include data for another police department in aggregation:

1. Add "ppd" to the list of departments in aggregate_dept_data/hand/config.yaml

**To commit to this repo**: 

1. Please first read https://chris.beams.io/posts/git-commit/

**Brief notes to better understand quirks of the different datasets discovered while cleaning and helpful when creating crime indicators**:

1. NYPD

 - has two fields that can be used to create crime indicators - `pd_cd` and `ofns_desc`
 - rather than using `pd_cd`, we use the much simpler (and more conservative) `ofns_desc`
 
2. CPD

 - we use a dataset from Chicago's open data portal linking Illinois UCR codes to FBI UCR codes

3. LAPD

- we use the `crm_cd_1` field and, in cases where it is missing, the `crm_cd` field

4. DPD

- we focus on codes belonging to part 1
- the one exception is our inclusion of all arson codes regardless of part designation
- all ucr data is missing for 2019, so used the list of ucrcodes we created to come up with a list of nibrs codes that are roughly equivalent




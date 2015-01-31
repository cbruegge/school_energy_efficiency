
ssc install psmatch2, replace

set seed 1234

global dirpath="~/workspace/energy_efficient_schools"

local file_suffix = "_chris"

use "${dirpath}/data_schoolyear/schools_comparison`file_suffix'.dta", clear

* Load My Programs ----------------------------------------
do "${dirpath}/propensity_score_matching/code/blocked_psmatch2.do"
do "${dirpath}/propensity_score_matching/code/define_summary_stat_matrix.do"
do "${dirpath}/propensity_score_matching/code/matrix_to_table.do"
do "${dirpath}/propensity_score_matching/code/save_psmatch2_table.do"


* Misc School Vars ----------------------------------------

gen stata_open_date = date(opendate,"YMD")
gen school_age = (date("$S_DATE","DMY") - stata_open_date) / 365
gen school_age2 = school_age^2

gen elementary = regexm(soctype,"Elem")
gen middle = regexm(soctype,"Middle") | regexm(soctype,"Junior")
gen high = regexm(soctype,"^High") 
gen k12 = regexm(soctype,"K-12")
gen other = 1 - (elementary + middle + high + k12)

replace enr_total = enr_total / 1000

bys cds_code : gen school_obs = _n

* Variable Locals ----------------------------------------
local age_vars = "median_age_male median_age_female"
local race_vars = "pct_black pct_hispanic pct_AmIndian pct_asian pct_other pct_mixed"
local school_race_vars = "PCT_AA PCT_AI PCT_AS PCT_FI PCT_HI PCT_PI PCT_WH PCT_MR"
local commute_vars = "pct_pub_trans pct_walk_bike pct_work_at_home"
local male_edu_vars = "pct_hs_male pct_associates_male pct_bachelors_male pct_masters_male pct_doctorate_male"
local female_edu_vars = "pct_hs_female pct_associates_female pct_bachelors_female pct_masters_female pct_doctorate_female"
local edu_vars = "pct_hs pct_associates pct_bachelors pct_masters pct_doctorate"
local school_edu_vars = "NOT_HSG HSG SOME_COL COL_GRAD GRAD_SCH"
local social_vars = "pct_single_mom"
local income_vars = "poverty_rate ln_pc_inc "
local seasonal_max_min_t = "winter_max winter_min spring_max spring_min summer_max summer_min fall_max fall_min"
local seasonal_ave_t = "winter_ave spring_ave summer_ave fall_ave"
local seasonal_cdd_hdd = "winter_cdd winter_hdd spring_cdd spring_hdd summer_cdd summer_hdd fall_cdd fall_hdd"
local annual_cdd_hdd = "hdd cdd"
local school_vars = "enr_total API_BASE school_age school_age2 elementary middle high k12"

local matchvars = "`school_vars' `income_vars'"
local balance_check_vars = "`matchvars' `school_race_vars' `seasonal_max_min_t' `annual_cdd_hdd'"

* 1:1 with replacement

cap drop no_group
gen no_group = 1


blocked_psmatch2, treatvar("upgraded") matchvars("`matchvars'") ///
										balancevars("`balance_check_vars'") ///
										groupvar("no_group") ///
										psmatch_options("neighbor(1)")

define_summary_stat_matrix, balancevars("`balance_check_vars'") ///
										outmatrix("no_group")


* 1:1 with reaplcement - block on climate zone

blocked_psmatch2, treatvar("upgraded") matchvars("`matchvars'") ///
										balancevars("`balance_check_vars'") ///
										groupvar("ca_climate_zone_id") ///
										psmatch_options("neighbor(1)")

define_summary_stat_matrix, balancevars("`balance_check_vars'") ///
										outmatrix("climate_zone")


* 1:1 with replacement - block on congressional district
blocked_psmatch2, treatvar("upgraded") matchvars("`matchvars'") ///
										balancevars("`balance_check_vars'") ///
										groupvar("us_house_of_reps_dist_id") ///
										psmatch_options("neighbor(1)")

define_summary_stat_matrix, balancevars("`balance_check_vars'") ///
										outmatrix("congressional_dist")



* Output Matricies to Table
matrix_to_table, balancevars("`balance_check_vars'") ///
										model_names("no_group climate_zone congressional_dist") ///
										output_file("${dirpath}/data_census/tables/psmatch2_all_models.txt")





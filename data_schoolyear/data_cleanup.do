********************************************************************************
* CLEAN UP OF SCHOOL-YEAR CHARACTERISTICS
********************************************************************************

* Main objective
* - Merge school characteristics with updgrade status
* - Merging variable: cds_code (double)

* Set drive
global dirpath="~/workspace/energy_efficient_schools"

local use_bg_weights = 0
local bg_weights = "linear_weight" /*hyperbolic_weight, linear_weight, exponential_weight */
 
* School characteristics -------------------------------------------------------
insheet using "${dirpath}/data_schoolyear/pubschls.txt", clear double
rename cdscode cds_code
format cds_code %16.0g
sort cds_code
save "${dirpath}/data_schoolyear/pubschls.dta", replace


* Academic Performance Index (API) ---------------------------------------------
clear
gen cds_code = 0
save "${dirpath}/data_schoolyear/api_btx.dta", replace

foreach y in "09" "10" "11" "12" {
#delimit ;
qui
infix 	double cds_code 	1-14 
		str RTYPE 	15-15
		STYPE 		16-16
		str CHARTER 19-19
		str SNAME	20-59
		API_BASE 	117-121
		ACS_K3		524-528
		ACS_46		529-533
		ACS_CORE	534-538
		ENROLL		609-615
		PCT_RESP	539-543
		NOT_HSG		544-548
		HSG			549-553
		SOME_COL	554-558
		COL_GRAD	559-563
		GRAD_SCH	564-568
		PCT_AA		439-443
		PCT_AI		444-448
		PCT_AS		449-453
		PCT_FI		454-458
		PCT_HI		459-463
		PCT_PI		464-468
		PCT_WH		469-473
		PCT_MR		474-478
	using "${dirpath}/data_schoolyear/api`y'btx.txt", clear;
#delimit cr
gen year = 2000 + real("`y'")
append using "${dirpath}/data_schoolyear/api_btx.dta"
save "${dirpath}/data_schoolyear/api_btx.dta", replace
}

label var ENROLL	"Enrollment at Year Start"
label var API_BASE	"API Base"
label var ACS_K3	"Average Class Size (Grades K-3)"
label var ACS_46	"Average Class Size (Grades 4-6)"
label var ACS_CORE	"Number of Core Academic Courses"
label var ENROLL 	"Number of Students Enrolled for Grades 2-11"
label var PCT_RESP	"Percent of Student Answer with Parent Education Level"
label var NOT_HSG	"Parent Education Level: Percent Not High School Graduate"
label var HSG		"Parent Education Level: Percent High School Graduate"
label var SOME_COL	"Parent Education Level: Percent Some College"
label var COL_GRAD	"Parent Education Level: Percent College Graduate"
label var GRAD_SCH	"Parent Education Level: Percent Graduate School"
label var PCT_AA	"Percent Black or African American"
label var PCT_AI	"Percent American Indian"
label var PCT_AS	"Percent Asian"
label var PCT_FI	"Percent Filipino"
label var PCT_HI	"Percent Hispanic or Latino"
label var PCT_PI	"Percent Native Hawaiian/Pacific Islander"
label var PCT_WH	"Percent White"
label var PCT_MR	"Percent Two or More Races"

drop if RTYPE == "X"
format cds_code %16.0g
sort cds_code year
save "${dirpath}/data_schoolyear/api_btx.dta", replace


* Enrollment -------------------------------------------------------------------
clear
gen cds_code = 0
save "${dirpath}/data_schoolyear/enrollment.dta", replace

foreach y in "09" "10" "11" "12" {

insheet using "${dirpath}/data_schoolyear/Enrollment`y'.txt", clear double

collapse (sum) kdgn-adult, by(cds_code county district school)

gen year = 2000 + real("`y'")

append using "${dirpath}/data_schoolyear/enrollment.dta"
save "${dirpath}/data_schoolyear/enrollment.dta", replace

}

sort cds_code year
save "${dirpath}/data_schoolyear/enrollment.dta", replace


* Graduates K-12 ---------------------------------------------------------------
clear
gen cds_code = 0
save "${dirpath}/data_schoolyear/graduates.dta", replace

foreach y in "09" "10" "11" "12" {

insheet using "${dirpath}/data_schoolyear/Graduates12.txt", clear double
destring cohortstud-gedcompleterr, replace force

rename cds cds_code
rename cohortstudents students
rename cohortgraduates graduates
rename cohortgraduat~e graduaterate
rename cohortdropouts dropouts
rename cohortdropout~e dropoutrate
rename specialeducat special
rename specialedcomp~e specialrate
rename stillenrolled stillen
rename stillenrolled~e stillenrate
rename gedcompleter ged
rename gedcompleterr~e gedrate

gen year = 2000 + real("`y'")

append using "${dirpath}/data_schoolyear/graduates.dta"
save "${dirpath}/data_schoolyear/graduates.dta", replace
}

format cds_code %16.0g
sort cds_code year
save "${dirpath}/data_schoolyear/graduates.dta", replace


* Census Demographics ----------------------------------------------------------
insheet using "${dirpath}/data_census/data/census_acs_2007_2011_bg/bg_demographics.txt", clear
rename geoid10 st_cnty_tct_blkgrp 
format st_cnty_tct_blkgrp %16.0g
destring b* c*, replace ignore(",")
include "${dirpath}/data_census/code/clean_census.do" // rename variables
drop b* c*
save "${dirpath}/data_census/data/bg_demographics.dta", replace

* School - Block Group Crosswalk File
insheet using "${dirpath}/data_census/data/gis_output/school_lat_long_bg.csv", clear
format cds_code %16.0f

duplicates tag cds_code, gen(dup)
tab dup

gen st_cnty_tct_blkgrp = substr(geo_id,-11,11)
destring st_cnty_tct_blkgrp, replace
keep if st_cnty_tct_blkgrp ~= .
keep cds_code st_cnty_tct_blkgrp
format st_cnty_tct_blkgrp %16.0f

merge m:1 st_cnty_tct_blkgrp using "${dirpath}/data_census/data/bg_demographics.dta", gen(merge_demographics)
tab merge_demographics
keep if merge_demographics == 3
drop merge_demographics
save "${dirpath}/data_census/data/school_join_bg_demographics.dta", replace

* Fixed Effects ----------------------------------------------------------------
insheet using "${dirpath}/data_census/data/gis_output/school_join_ca_cd_upper.csv", clear
rename sldu ca_house_of_reps_id
keep cds_code ca_house_of_reps_id
save "${dirpath}/data_census/data/school_join_ca_cd_upper.dta", replace

insheet using "${dirpath}/data_census/data/gis_output/school_join_ca_climate_zone.csv", clear
rename cz ca_climate_zone_id
keep cds_code ca_climate_zone_id
save "${dirpath}/data_census/data/school_join_ca_climate_zone.dta", replace

insheet using "${dirpath}/data_census/data/gis_output/school_join_cd.csv", clear
rename cd111fp us_house_of_reps_dist_id
keep cds_code us_house_of_reps_dist_id
save "${dirpath}/data_census/data/school_join_cd.dta", replace

* Weather ---------------------------------------------------------------------
use "${dirpath}/data_weather/all_stns_monthavg_max_min_hdd_cdd.dta", clear
gen winter =  month < 4
gen spring = month >= 4 & month < 7
gen summer = month >= 7 & month < 10
gen fall = month >= 10 

foreach season of varlist winter spring summer fall {
	tempvar helper_ave helper_min helper_max helper_cdd helper_hdd
	bys stn_call : egen helper_ave = mean(temp_f) if `season' == 1
	bys stn_call : egen helper_min = mean(max_t) if `season' == 1
	bys stn_call : egen helper_max = mean(min_t) if `season' == 1
	bys stn_call : egen helper_cdd = total(cdd) if `season' == 1
	bys stn_call : egen helper_hdd = total(hdd) if `season' == 1
	bys stn_call : egen `season'_ave = mean(helper_ave)
	bys stn_call : egen `season'_max = mean(helper_max)
	bys stn_call : egen `season'_min = mean(helper_min)
	bys stn_call : egen `season'_cdd = mean(helper_cdd)
	bys stn_call : egen `season'_hdd = mean(helper_hdd)
	drop helper_*

} 

collapse (first) stn_county stn_lat stn_lon winter_* spring_* summer_* fall_*, by(stn_call)
gen hdd = winter_hdd + spring_hdd + summer_hdd + fall_hdd
gen cdd = winter_cdd + spring_cdd + summer_hdd + fall_hdd

save "${dirpath}/data_weather/cleaned_weather.dta", replace

* Put files together -----------------------------------------------------------

use "${dirpath}/data_schoolyear/pubschls.dta", clear


sort cds_code
merge 1:m cds_code using "${dirpath}/data_schoolyear/enrollment.dta"
tab _merge
drop _merge

sort cds_code year
merge 1:1 cds_code year using "${dirpath}/data_schoolyear/graduates.dta"
tab _merge
drop _merge

sort cds_code year
merge m:1 cds_code using "${dirpath}/data_schoolyear/schools_pge_territory.dta"
tab _merge
gen pge_territory=1 if _merge==3 | _merge==2
replace pge_territory=0 if pge_territory==.
gen merge_pub_pge = _merge
drop _merge

sort cds_code year
merge 1:1 cds_code year using "${dirpath}/data_schoolyear/api_btx.dta"
tab _merge
gen merge_pubpge_btx = _merge
drop _merge

*merge with upgrade
sort cds_code
merge m:1 cds_code using "${dirpath}/data_schoolyear/schools with and without upgrades.dta"
tab _merge
gen sample_pge = 0 if pge_territory==1 & upgrade == .
replace sample_pge = 1 if pge_territory==1 & upgrade != .
drop _merge

*merge with census block group demographics
sort cds_code
if `use_bg_weights' == 1 {
	merge m:1 cds_code using "${dirpath}/data_census/data/bg_demographics_`bg_weights'.dta" 
	tab _merge
	drop _merge
}
else {
	merge m:1 cds_code using "${dirpath}/data_census/data/school_join_bg_demographics.dta"
	tab _merge
	drop _merge
}



*merge with climate zones for fixed Effects
sort cds_code
merge m:1 cds_code using "${dirpath}/data_census/data/school_join_ca_climate_zone.dta"
tab _merge
drop _merge

*merge with state and us house of representative districts
sort cds_code
merge m:1 cds_code using "${dirpath}/data_census/data/school_join_ca_cd_upper.dta"
tab _merge
drop _merge

sort cds_code
merge m:1 cds_code using "${dirpath}/data_census/data/school_join_cd.dta"
tab _merge
drop _merge

*merge with weather data using geographic proximity
geonear cds_code latitude longitude using "${dirpath}/data_weather/cleaned_weather.dta", n(stn_call stn_lat stn_lon) genstub(stn_call)
merge m:1 stn_call using "${dirpath}/data_weather/cleaned_weather.dta", gen(merge_weather)

save "${dirpath}/data_schoolyear/schools_comparison.dta", replace


* Preliminary summary stats ----------------------------------------------------

use "${dirpath}/data_schoolyear/schools_comparison.dta", clear

//comparisons
capture file close myfile
file open myfile using "${dirpath}/data_schoolyear/table_schools_comparion.txt", write replace	
file write myfile "Category" _tab "No Upgrade" _tab "Upgrade"  _tab "difference" _n
qui foreach var of varlist latitude longitude API_BASE ACS* ENROLL PCT_RESP NOT_HSG HSG SOME_COL COL_GRAD PCT_AA-PCT_MR {
	local lablocal: var label `var'
	file write myfile "`lablocal'" _tab
	summ `var' if upgrade == 0
	file write myfile " " %4.1f (r(mean)) _tab
	summ `var' if upgrade == 1
	file write myfile " " %4.1f (r(mean)) _tab
	ttest `var', by(upgrade)
	file write myfile " " %4.1f (r(mu_1)-r(mu_2))
	if (abs(r(p))<0.01) {
		file write myfile "***"
	}
	else if (abs(r(p))<0.05) {
		file write myfile "**"
	} 
	else if (abs(r(p))<0.1) {
		file write myfile "*"	
	}
	file write myfile " " _n
	file write myfile " " _tab
	summ `var' if upgrade == 0, det
	file write myfile " [" %4.1f (r(p25)) ", "  %4.1f (r(p75)) "]" _tab
	summ `var' if upgrade == 1, det
	file write myfile " [" %4.1f (r(p25)) ", "  %4.1f (r(p75)) "]" _tab
	file write myfile " " _n		
}
file close myfile

//comparisons
capture file close myfile
file open myfile using "${dirpath}/data_schoolyear/table_schools_sample.txt", write replace	
file write myfile "Category" _tab "Matched Meter" _tab "Unmatched Meter" _tab "Difference" _n
qui foreach var of varlist latitude longitude API_BASE ACS* ENROLL PCT_RESP NOT_HSG HSG SOME_COL COL_GRAD PCT_AA-PCT_MR {
	local lablocal: var label `var'
	file write myfile "`lablocal'" _tab
	summ `var' if pge_territory==1 & upgrade != .
	file write myfile " " %4.1f (r(mean)) _tab
	summ `var' if pge_territory==1 & upgrade == .
	file write myfile " " %4.1f (r(mean)) _tab
	ttest `var', by(sample_pge)
	file write myfile " " %4.1f (r(mu_1)-r(mu_2))
	if (abs(r(p))<0.01) {
		file write myfile "***"
	}
	else if (abs(r(p))<0.05) {
		file write myfile "**"
	} 
	else if (abs(r(p))<0.1) {
		file write myfile "*"	
	}
	file write myfile " " _n
	file write myfile " " _tab
	summ `var' if upgrade == 0, det
	file write myfile " [" %4.1f (r(p25)) ", "  %4.1f (r(p75)) "]" _tab
	summ `var' if upgrade == 1, det
	file write myfile " [" %4.1f (r(p25)) ", "  %4.1f (r(p75)) "]" _tab
	file write myfile " " _n	
}
file close myfile

reg ENROLL upgrade##c.year
twoway (lpolyci ENROLL year if upgrade == 1) (lpolyci ENROLL year if upgrade == 0), ///
	title("Enrollment trends by treatment") subtitle("Grades 2-11") ///
	legend(order(2 "Upgrade" 3 "No Upgrade")) graphregion(color(white)) ///
	note("Trends not statistically different using simple regression.")
graph export enrollment_trends.pdf, replace

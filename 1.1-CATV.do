/*********************************************************
******         read in CATV data     ***********
*********************************************************/
* dataset with count of CATV systems and for 1953 onwards number of channels carried on CATV
local cutOff_month = `1'

*prep original files for QGIS use and process QGIS output
* To run this from scratch: need to geocode the locations of CATV in QGIS
* do ../code/1.1 - QGIS.do

insheet using ../PrepFactbooks/CATV/Lookup_CATV_county.csv, clear
* drop Alaska
drop if countyfips == .
save ../temp/Lookup_CATV_county,  replace

insheet using ../PrepFactbooks/CATV/ALLRepeater.csv, clear
merge m:1 locationid using ../temp/Lookup_CATV_county
drop if state == "Alaska"
drop _m
rename countyfips countyfips2000
* date of launch
replace year = 1954 if year == 1945
g CATV_date = date(beganservice,"MDY", 1999)
g CATV_date2 = date(beganservice,"DMY", 1999)
replace CATV_date = CATV_date2 if CATV_date == .
g D_helper = subinstr(beganservice,"/00/","/",.) if CATV_date == .
g D2 =  monthly(D_helper,"MY", 1999)
replace CATV_date = dofm(D2) if CATV_date == .
g D_helper2 = subinstr(D_helper,"00/","",.) if CATV_date == .
destring D_helper2, replace force
replace CATV_date = dofy(D_helper2) if CATV_date == .
drop D_helper D2 D_helper2
format CATV_date %td
* Use most frequent date if multiple dates reported
bys countyfips: egen CATV_launch = mode(CATV_date), minmode
bys countyfips: egen CATV_firstObserved = min(year)
format CATV_launch %td

* drop CATV if operational for less than 8 months in the year
drop if month(CATV_launch) >= `cutOff_month' & month(CATV_launch)!=. & year == year(CATV_launch)

*generate year when CATV has been operational for at least 8 months
g year_CATV = year(CATV_launch)
*replace year_CATV = year_CATV+1 if month(CATV_launch) >= `cutOff_month'
*replace year_CATV = CATV_firstObserved if year_CATV == .

* generate datasets with start date of CATV systems by county
* Information on channels carried only available in 1953.
* Number of active systems potentially unreliable as data sometimes lists multiple cities for a single system
keep state city year_CATV countyfips stations year locationid
split stations, parse(",") g(station)
drop stations
preserve
g CATV_count = 1
collapse (min) year_CATV (sum) CATV_count , by(year countyfips)
save ../temp/CATV_perCounty, replace
restore

*add years prior to data collection
g position = _n
preserve
g CATV_count = 1
drop if year_CATV>1951
duplicates drop locationid year_CATV, force
* generate data between first year with CATV and first year of data. Assumes that system wasn't switched off in interim period
g dup = 1952-year_CATV
expand dup
drop year
bys year_CATV position:  g year = year_CATV + _n - 1
collapse (first) year_CATV (sum) CATV_count , by(year countyfips)
append using "../temp/CATV_perCounty.dta"
*keep countyfips state city year year_CATV CATV_count
reshape wide CATV_count  , i(countyfips ) j(year)
save ../output/CATV_perCounty, replace
restore

* generate variable with broadcasted channels
reshape long station  , i(position) j(count) string
drop if station ==""
duplicates drop station year countyfips, force
keep year countyfips station
bys county year: g stat_rank = _n
bys county year: g CATV_ChannelCount = _N
save ../output/CATV_channels, replace
reshape wide station  , i(countyfips year) j(stat_rank)
drop station*
reshape wide CATV*  , i(countyfips ) j(year)
merge 1:1 countyfips using ../output/CATV_perCounty
drop _merge
save ../output/CATV_perCounty_`cutOff_month', replace



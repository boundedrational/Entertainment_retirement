/*************************************************/
/*************************************************/
/****************  TV exposure  ***************/
/*************************************************/
/*************************************************/




/**************** Version Controll ******************************/

shell "/usr/local/git/bin/git" --git-dir "$do_path/.git" --work-tree "$do_path/." commit -a -m "version $datum"


clear


/*********************************************************
*************         Preparation File     ***************
*********************************************************/

global datum = subinstr(c(current_date)," ","",.)




/*********************************************************
******         read in DMA data     		**********
*********************************************************/

** Gentzkow provides crosswalk for TV areas (DMAs) to counties
use "$input_path/Gentzkow data/xwalk DMA county/22720-0003-Data.dta", clear
g countyfips=STATEFP+CNTYFP
destring countyfips, replace
keep countyfips DMAINDE* STATE
save ../temp/xwalk_DMAtoCounty, replace

* xwalk 1990 cty to 2000 counties (following Dorn)
g countyfips2000 = countyfips
label var countyfips2000 "FIPS in 2000"

* disappearing counties
drop if  countyfips2000 == 30113 |  countyfips ==  51780 | countyfips == 51560
* new counties in 2000 - treat them as the counties they emerged from
expand 2 if    countyfips == 8013 , g(dup)
replace countyfips2000 = 12086 if  countyfips ==  12025
replace countyfips2000 = 8014 if  countyfips == 8013 & dup == 1
drop dup
save ../temp/xwalk_cty90cty00, replace


** Gentzkow data on TV introduction.
** Earliest TV in DMA
use "$input_path/Gentzkow data/TV station Diffusion DMA/22720-0001-Data.dta", clear
//variable for TV intro in CZ
gen date2 = date(DATE, "DMY")
format date2 %td
keep  DMAINDEX TVYEAR STATION date2
duplicates drop DMAINDEX, force
save ../temp/DMATVdate, replace

**TV households
use "$input_path/Gentzkow data/TV set County Diffusion/22720-0002-Data.dta", clear
g countyfips=STATEFP+CNTYFP
destring countyfips, replace
keep countyfips YEAR TVHH TOTALHH
rename YEAR year
save ../temp/ALlyearTV, replace

/*********************************************************
******         read in ITM signal strength     ***********
*********************************************************/

**
**
**		DEFINE SIGNAL THRESHOLD
**
**

local threshold = -50
** query output
cd "$input_path"
foreach year in  48 49 50 51 52 53 {
	cd "$input_path"
	import delimited using ../PrepFactbooks/19`year'/query-out.txt	, clear
	g ITM_signal = (10*log(v17 * 1000 / 4 / 3.14) + 10*log(10)*13 )  / log(10) - v1 - 54.2
	g ITM_station = (ITM_signal>`threshold')
	rename v14 countyfips2000
	keep countyfips ITM_signal ITM_station
	collapse (max) ITM_signal (sum) ITM_station , by(countyfips)
	g year = 1900 + `year'

	merge 1:1 countyfips2000 using ../temp/xwalk_cty90cty00
	** 25 counties in AL & HI. No DMA info, hence drop them
	drop if _m!=3
	save "$temp_path/signal`year'", replace
}

foreach year in 54 55 56 57{
	foreach subfolder in I II III {
		cd "$input_path"
		  capture confirm file ../PrepFactbooks/19`year'/`subfolder'/query-out.txt
		  if _rc==0 {
		   	import delimited using ../PrepFactbooks/19`year'/`subfolder'/query-out.txt	, clear
		   	g ITM_signal = (10*log(v14 * 1000 / 4 / 3.14) + 10*log(10)*13 )  / log(10) - v1 - 54.2
		   	g ITM_station = (ITM_signal>`threshold')
		   	rename v11 countyfips2000
		   	keep countyfips ITM_signal ITM_station
		   	collapse (max) ITM_signal (sum) ITM_station , by(countyfips)
		   	g year = 1900 + `year'

		   	merge 1:1 countyfips2000 using ../temp/xwalk_cty90cty00
		   	** 25 counties in AL & HI. No DMA info, hence drop them
		   	drop if _m!=3
		   	save "$temp_path/signal`year'_`subfolder'", replace

		   }
		  else {
		    display "The file 19`year'/`subfolder'/query-out.txt does not exist"
		  }
	}
}

foreach year in   54 55 56 57 {
	use "$temp_path/signal`year'_I"
	foreach subfolder in II III {
		cap append "$temp_path/signal`year'_`subfolder'"
	}
	save "$temp_path/signal`year'", replace
}



use  "$temp_path/signal48", clear
foreach year in  49 50 51 52 53 54 55 56 57 {
	append using "$temp_path/signal`year'"
}
save "$temp_path/ITMTVdate", replace

/*

. tab year

       year |      Freq.     Percent        Cum.
------------+-----------------------------------
       1948 |      3,118       10.01       10.01
       1949 |      3,118       10.01       20.02
       1950 |      3,118       10.01       30.03
       1951 |      3,118       10.01       40.05
       1952 |      3,118       10.01       50.06
       1953 |      3,118       10.01       60.07
       1954 |      3,109        9.98       70.05
       1955 |      3,109        9.98       80.03
       1956 |      3,109        9.98       90.02
       1957 |      3,109        9.98      100.00
------------+-----------------------------------
      Total |     31,144      100.00
*/

/*********************************************************
******         merge DMA and ITM data     		**********
*********************************************************/

use  ../temp/ITMTVdate, clear

drop _m
merge m:1 DMAINDEX using ../temp/DMATVdate
/*

Result                           # of obs.
-----------------------------------------
not matched                             1
    from master                         0  (_merge==1)
    from using                          1  (_merge==2) DMA 161 in Gentzkow data, but no county assigned to it

matched                             31,144  (_merge==3)
-----------------------------------------
*/
drop if _m!=3
drop _merge
** county split implies there are two observations for a 1990 county
duplicates drop year countyfips, force
merge 1:m year countyfips using ../temp/ALlyearTV
** virginia cities w/o TV data (and a few other cty)
/*
          |              _merge
      year | master on  using onl  matched ( |     Total
-----------+---------------------------------+----------
      1948 |     3,117          0          0 |     3,117 no TV ownership
      1949 |     3,117          0          0 |     3,117 no TV ownership
      1950 |        27          1      3,090 |     3,118  FIGURE THIS OUT?!?!?
      1951 |     3,117          0          0 |     3,117 no TV ownership
      1952 |     3,117          0          0 |     3,117 no TV ownership
      1953 |     1,296          0      1,821 |     3,117
      1954 |       657          0      2,451 |     3,108
      1955 |       382          0      2,726 |     3,108
      1956 |        74          0      3,034 |     3,108
      1957 |        45          0      3,063 |     3,108
      1958 |         0      2,759          0 |     2,759 no TV signal
      1959 |         0      3,057          0 |     3,057
      1960 |         0      3,089          0 |     3,089
-----------+---------------------------------+----------
     Total |    14,949      8,906     16,185 |    40,040

*/
* drop missed match
levelsof countyfips if _m!=3  & year == 1950, local(miss_match)
foreach location of local miss_match{
	drop if countyfips == `location'
}
** Define TV expoure
g DMA_access = year >= TVYEAR & TVYEAR!=.
g ITM_access = ITM_station>0 & ITM_station!=.

** TV OWNERSHIP
g tvhh = TVHH / TOTALHH
** missing counties are without tv signal according to magazine
g TVHH_with0 = tvhh
replace TVHH_with0 = 0 if year > 1952 & year<1958 & TVHH_with0 == .
drop _m
save ../temp/TVaccess, replace

** analysis
reghdfe TVHH_with0 DMA_access ITM_access, absorb(year countyfips2000)
reghdfe TVHH_with0 DMA_access ITM_station, absorb(year countyfips2000)
reghdfe TVHH_with0 DMA_access ITM_signal, absorb(year countyfips2000)
reghdfe tvhh DMA_access ITM_access, absorb(year countyfips2000)
reghdfe TVHH_with0 DMA_access ITM_access if year!=1950, absorb(year countyfips2000)

areg TVHH_with0 i.year , absorb(countyfips2000)
predict residulas, resid

/*********************************************************
******         read in voting data     		**********
*********************************************************/

import excel using "$data/lookup/CTY&STATE_ICPSR_FIPS.xls", firstrow clear
drop in 1
keep State County STATEICP STATEFIPS County Countycod FIPScty
order State County STATEICP STATEFIPS County Countycod FIPScty
*drop indian reservations
drop if FIPScty >900
g countyfips = STATEFIPS *1000  + FIPScty
save $data/lookup/CTY&STATE_ICPSR_FIPS, replace


** ICPSR 3
use  "../input/voting ICPSR 3/00013-0003-Data.dta", clear
g countyfip = int(V5/10)
rename V2 state

** ICPSR 8611
local turnout "V384 V392 V401 V408 V417 V427 V433 V442 V451 V457 V467 V476 V482 V489 V497 V503 V510 V520 V526 V535 V545 V551 V558 V566 V572 V579 V585 V592 V598 V603 V608 V613 V618 V623 V628 V633 V638 V643 V648 V653 V658 V663 V669 V674 V679 V684 V689"
use  V1-V3 `turnout' using "../input/Replication/ICPSR_08611/DS0001/08611-0001-Data.dta", clear
* convert ICPSR to FIPS
rename V3 Countycod
rename V1 STATEICP
merge 1:1 STATEICP Countycod using $data/lookup/CTY&STATE_ICPSR_FIPS
/*
Result                           # of obs.
-----------------------------------------
not matched                           216
    from master                       190  (_merge==1)
    from using                         26  (_merge==2)

matched                             3,203  (_merge==3)
-----------------------------------------
*/

drop if _m!=3
drop _m
foreach v of local turnout {
   local x : variable label `v'
   local name_sub = substr("`x'",6,1)
   local year_sub = substr("`x'",1,4)
   di "vote_`name_sub'`year_sub'"
   rename `v' vote_`name_sub'`year_sub'
}
reshape long vote_C vote_P, i(countyfips) j(year)
merge 1:m countyfips year using ../temp/TVaccess
/*
Result                           # of obs.
-----------------------------------------
not matched                        97,409
    from master                    78,719  (_merge==1)
    from using                     18,690  (_merge==2)

matched                            20,574  (_merge==3)
-----------------------------------------
*/
replace ITM_station = 0 if year<1940
replace DMA_access = 0 if year<1940

reghdfe vote_P DMA_access ITM_station, absorb(year countyfips)
reghdfe vote_C DMA_access ITM_station, absorb(year countyfips)

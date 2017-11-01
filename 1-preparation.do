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
*define groups of counties by TV year ranges
g TVyearGroups = 1 if year(date2)< 1945 & year(date2)>1930
replace TVyearGroups = 2 if year(date2)< 1952 & year(date2)>1944
replace TVyearGroups = 3 if year(date2)< 1970 & year(date2)>1951
label def TVGroup 1 "First TV pre 1945" 2 "First TV 1945-1951" 3 "First TV 1952+"
label value TVyearGroups TVGroup

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
foreach year in  48 49 50 51 52 53 54 55 56 57 58 59 60 {
	cd "$input_path"
	import delimited using ../PrepFactbooks/19`year'/query-out.txt	, clear
	if `year' > 53 {
		g ITM_signal = (10*log(v14 * 1000 / 4 / 3.14) + 10*log(10)*13 )  / log(10) - v1 - 54.2
		g ITM_station = (ITM_signal>`threshold')
		rename v11 countyfips2000
    rename v12 Station
    rename v13 city_str
	}
	if `year' <= 53 {
	g ITM_signal = (10*log(v17 * 1000 / 4 / 3.14) + 10*log(10)*13 )  / log(10) - v1 - 54.2
	g ITM_station = (ITM_signal>`threshold')
	rename v14 countyfips2000
  rename v15 Station
  rename v16 city_str
	}
  g Channel = substr(city_str,-2,2)
  g str_len = strlen(city_str)
  g City = substr(city_str,1,str_len-2)
  destring Channel, replace
  replace City = trim(City)
  if `year' == 48 {
    save ../temp/data48, replace
  }
	keep countyfips ITM_signal ITM_station

	collapse (max) ITM_signal (sum) ITM_station , by(countyfips)
	g year = 1900 + `year'

	merge 1:1 countyfips2000 using ../temp/xwalk_cty90cty00
	** 25 counties in AL & HI. No DMA info, hence drop them
	drop if _m!=3
	save "$temp_path/signal`year'", replace
}
/*
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
*/

/*********************************************************
******         infer pre 1948 TV data       **********
*********************************************************/

import excel using ../PrepFactbooks/1948/FB48.xlsx, clear firstrow
g start_year = 1900 + StartYear
replace start_year = start_year + 1 if StartMonth>3
keep City Station Channel start_year
g TV47 = (start_year<=1947)
g TV46 = (start_year<=1946)
drop if start_year == 1949
replace City = trim(City)
rename City City_xlsx
rename Channel Channel_xlsx

merge 1:m Station  using ../temp/data48

foreach year in 46 47 {
  preserve
  drop if TV`year'!=1
  keep countyfips ITM_signal ITM_station start_year
  g TVYEAR_ITM = start_year if ITM_signal> - 50 & ITM_signal != .
  collapse (max) ITM_signal (min) TVYEAR_ITM (sum) ITM_station , by(countyfips)
  g year = 1900 + `year'
  merge 1:1 countyfips2000 using ../temp/xwalk_cty90cty00
  ** 25 counties in AL & HI. No DMA info, hence drop them
  drop if _m!=3
  save "$temp_path/signal`year'", replace
  restore
}


use  "$temp_path/signal48", clear
foreach year in 46 47 49 50 51 52 53 54 55 56 57 58 59 60 {
	append using "$temp_path/signal`year'"
}
xtset countyfips2000 year

* generate year of first TV station
g Hyear = year if ITM_station>0 & ITM_station!=.
replace Hyear = TVYEAR_ITM if TVYEAR_ITM!=.
bys countyfips: egen H2 = min(Hyear)
g date_ITM = H2
replace TVYEAR_ITM = date_ITM
replace TVYEAR_ITM = 1946 if date_ITM < 1946
replace TVYEAR_ITM = 1960 if date_ITM == . & ITM_station == 0

drop H2 Hyear

*define groups of counties by TV year ranges
g TVyearGroups_ITM = 1 if date_ITM< 1945 & date_ITM>1930
replace TVyearGroups_ITM = 2 if date_ITM< 1952 & date_ITM>1944
replace TVyearGroups_ITM = 3 if date_ITM< 1970 & date_ITM>1951
replace TVyearGroups_ITM = 3 if TVYEAR_ITM == 1960
label value TVyearGroups TVGroup


save "$temp_path/ITMTVdate", replace

/*

. tab year

              year |      Freq.     Percent        Cum.
       ------------+-----------------------------------
              1948 |      3,118        7.70        7.70
              1949 |      3,118        7.70       15.41
              1950 |      3,118        7.70       23.11
              1951 |      3,118        7.70       30.82
              1952 |      3,118        7.70       38.52
              1953 |      3,118        7.70       46.23
              1954 |      3,109        7.68       53.91
              1955 |      3,109        7.68       61.59
              1956 |      3,109        7.68       69.27
              1957 |      3,109        7.68       76.95
              1958 |      3,109        7.68       84.64
              1959 |      3,109        7.68       92.32
              1960 |      3,109        7.68      100.00
       ------------+-----------------------------------
             Total |     40,471      100.00

*/



/*********************************************************
******         merge DMA and ITM data     		**********
*********************************************************/

** ITM data
use  ../temp/ITMTVdate, clear
drop _m

** add ID for DMA
merge m:1 DMAINDEX using ../temp/DMATVdate
/*

Result                           # of obs.
 -----------------------------------------
 not matched                             1
     from master                         0  (_merge==1)
     from using                          1  (_merge==2)

 matched                            40,471  (_merge==3)
 -----------------------------------------

*/
drop if _m!=3
drop _merge
** county split implies there are two observations for a 1990 county
duplicates drop year countyfips, force

** add GS TV household data
merge 1:m year countyfips using ../temp/ALlyearTV

** virginia cities w/o TV data (and a few other cty)
/*

. tab year _m


           |              _merge
      year | master on  using onl  matched ( |     Total
-----------+---------------------------------+----------
      1946 |     3,117          0          0 |     3,117
      1947 |     3,117          0          0 |     3,117
      1948 |     3,117          0          0 |     3,117 no ownership data
      1949 |     3,117          0          0 |     3,117 no ownership data
      1950 |        27          1      3,090 |     3,118 FIGURE THIS OUT?!?!?
      1951 |     3,117          0          0 |     3,117 no ownership data
      1952 |     3,117          0          0 |     3,117 no ownership data
      1953 |     1,296          0      1,821 |     3,117
      1954 |       657          0      2,451 |     3,108
      1955 |       382          0      2,726 |     3,108
      1956 |        74          0      3,034 |     3,108
      1957 |        45          0      3,063 |     3,108
      1958 |       349          0      2,759 |     3,108
      1959 |        51          0      3,057 |     3,108
      1960 |        20          1      3,088 |     3,109 FIGURE THIS OUT?!?!?
-----------+---------------------------------+----------
     Total |    15,369          2     25,089 |    40,460


1960 _m==1 additionally to 1950: countyfips 2000, 6003, 8079, 30111, 48261, 48269, 48301

*/
* drop missed match
levelsof countyfips if _m!=3  & year == 1950, local(miss_match)
foreach location of local miss_match{
	drop if countyfips == `location'
}
drop _m

**
** TV signal
**

** Define TV expoure
g DMA_access = year >= TVYEAR & TVYEAR!=.
g ITM_access = ITM_station>0 & ITM_station!=.


**
** TV OWNERSHIP
**
g tvhh = TVHH / TOTALHH

** missing counties are without tv signal according to magazine
g TVHH_with0 = tvhh
replace TVHH_with0 = 0 if year > 1952 & year<1958 & TVHH_with0 == .
replace ITM_station = 0 if year<1940
replace DMA_access = 0 if year<1940

save ../output/TVaccess, replace

use ../output/TVaccess, clear
keep TVYEAR TVYEAR_ITM date_ITM date2 ITM_signal ITM_station DMA_access ITM_access year countyfips  TVyearGroups TVyearGroups_ITM

reshape wide ITM_signal ITM_station DMA_access ITM_access , j(year) i(countyfips)
save ../output/TVwide, replace

/*********************************************************
******         read in voting data     		**********
*********************************************************/

* Is turnout relative to voters or population? Latter is what G&S use

import excel using "$data/lookup/CTY&STATE_ICPSR_FIPS.xls", firstrow clear
drop in 1
keep State County STATEICP STATEFIPS County Countycod FIPScty
order State County STATEICP STATEFIPS County Countycod FIPScty
*drop indian reservations
drop if FIPScty >900
g countyfips = STATEFIPS *1000  + FIPScty
save $data/lookup/CTY&STATE_ICPSR_FIPS, replace


** ICPSR 3
use  "../input/Replication/voting ICPSR 3/00013-0003-Data.dta", clear
g countyfip = int(V5/10)
rename V2 state

** ICPSR 8611
local turnout "V327 V335 V349 V356 V369 V377 V384 V392 V401 V408 V417 V427 V433 V442 V451 V457 V467 V476 V482 V489 V497 V503 V510 V520 V526 V535 V545 V551 V558 V566 V572 V579 V585 V592 V598 V603 V608 V613 V618 V623 V628 V633 V638 V643 V648 V653 V658 V663 V669 V674 V679 V684 V689"
local total_vote "V320 V326 V334 V341 V348 V355 V362 V368 V376 V383 V391 V400 V407 V416 V426 V432 V441 V450 V456 V466 V475 V481 V488 V496 V502 V509 V519 V525 V534 V544 V550 V557 V565 V571 V578 V584 V591 V597 V602 V607 V612 V617 V622 V627 V632 V637 V642 V647 V652 V657 V662 V668 V673 V678 V683 V688"
local DEM_REP "V317 V322 V324 V328 V330 V336 V343 V345 V350 V352 V357 V364 V370 V372 V378 V385 V387 V393 V395 V402 V409 V411 V418 V420 V428 V434 V436 V443 V445 V452 V458 V460 V468 V470 V477 V483 V490 V498 V504 V511 V513 V521 V527 V529 V536 V538 V546 V552 V559 V567 V569 V573 V580 V582 V586 V589 V593 V599 V604 V609 V614 V619 V624 V629 V634 V639 V644 V649 V654 V659 V664 V670 V675 V680 V685 V318 V323 V329 V331 V337 V344 V351 V358 V365 V371 V373 V379 V386 V394 V396 V403 V410 V412 V419 V421 V429 V435 V437 V444 V453 V459 V461 V469 V471 V478 V484 V491 V492 V499 V505 V512 V514 V522 V528 V530 V537 V539 V547 V548 V553 V560 V561 V568 V574 V575 V581 V587 V594 V600 V605 V610 V615 V620 V625 V630 V635 V640 V645 V650 V655 V660 V665 V671 V676 V681 V686"
use  V1-V3 `turnout' `DEM_REP' `total_vote' using "../input/Replication/ICPSR_08611/DS0001/08611-0001-Data.dta", clear
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
*rename variables
foreach v of local turnout {
   local x : variable label `v'
   local name_sub = substr("`x'",6,1)
   local year_sub = substr("`x'",1,4)
   di "vote_`name_sub'`year_sub'"
   rename `v' vote_`name_sub'`year_sub'
}
foreach v of local total_vote {
   local x : variable label `v'
   local name_sub = substr("`x'",6,1)
   local year_sub = substr("`x'",1,4)
   di "TotalVotes_`name_sub'`year_sub'"
   rename `v' TotalVotes_`name_sub'`year_sub'
}
foreach v of local DEM_REP {
   local x : variable label `v'
   local name_sub = substr("`x'",6,9)
   local year_sub = substr("`x'",1,4)
   local name_sub = subinstr("`name_sub'"," ","_",.)
   local name_sub = subinstr("`name_sub'","-","2",.)

   di "vote_`name_sub'`year_sub'"
   rename `v' vote_`name_sub'`year_sub'
}
drop vote_PRES* vote_CONG_DEM2* vote_CONG_REP2* TotalVotes_P*
reshape long vote_C TotalVotes_C vote_P vote_CONG_REP_ vote_CONG_DEM_  , i(countyfips) j(year)

* missings are coded as strange values (around 999.9), also set participation > 100%
foreach var in vote_C vote_P vote_CONG_REP_ vote_CONG_DEM_  {
	replace `var' = . if `var'>101
}
*sanity check
g sanity = (vote_CONG_REP_+vote_CONG_DEM_<101)
foreach var in vote_CONG_REP_ vote_CONG_DEM_  {
		replace `var' = . if sanity == 0
}
g REP_DEM_gap = vote_CONG_REP_ - vote_CONG_DEM_
replace REP_DEM_gap = REP_DEM_gap * -1 if REP_DEM_gap<0

*G&S restrict sample to counties with participation data in majority of years between 1940-1972
bys countyf: g missing_years = sum(vote_C==.) if year > 1939
g GS_sample = (missing_years<8)
replace GS_sample = 1 if missing_years == . & year > 1939
unique countyfips if GS_sample==1
* should have 3081 counties, but get 3203 counties here. Once matching to TV data have 3083 matched counties

* dummy indicating years with presidential elections
g presidential_year = (vote_P!=.)

** reference participation (1940)
bys countyfips: egen helper = max(vote_C) if year == 1940
bys countyfips: egen  ref_participation= max(helper)

keep year TotalVotes_C countyfip vote_C presidential_year GS_sample REP_DEM_gap ref_participation
save ../output/vote_data, replace

/*********************************************************
******         controls    		**********
*********************************************************/

* 1950 Census data - county info:
* pop per mile^2, % urban,  median age, % high school, census regions, median inc
use fips area totpop highschool  urban  medage medinc using ../input/Replication/demo_50, clear
rename fips countyfips
g lpop = ln(totpop)
g ppl_sqm = totpop / area
foreach var of varlist lpop highschool  urban  medage medinc ppl_sqm  {
	rename `var' `var'_50
}
keep countyfips  highschool  urban  medage ppl_sqm lpop medinc
save ../temp/census1950, replace

* add % white, census region
use fips region1 totpop nwmtot fbwmtot nwftot fbwftot pctnonw using "../input/Replication/1950 Census/DS0035/02896-0035-Data.dta", clear
rename fips countyfips
g share_NW_50 = 1-(nwmtot+ fbwmtot +nwftot+ fbwftot)/totpop
keep countyfips  share_NW region1
* some missing countyfips
drop if countyfips == .
merge 1:1 countyfips using ../temp/census1950
drop if _m!=3
drop _m
save ../temp/census1950, replace

* 1960 data:
* ln pop, median income
use fips totpop medinc  highschool pcturban area medage using ../input/Replication/demo_60, clear
g lpop = ln(totpop)
g ppl_sqm = totpop / area
rename fips countyfips
rename pcturban urban
keep countyfips lpop medinc highschool  urban  medage medinc ppl_sqm
foreach var of varlist lpop highschool  urban  medage medinc ppl_sqm  {
	rename `var' `var'_60
}
save ../temp/census1960, replace

*  % non-white
use fips  totpop whtot using "../input/Replication/1960 Census/DS0038/02896-0038-Data.dta", clear
rename fips countyfips
g share_NW_60 = 1-whtot/totpop
keep countyfips  share_NW
* some missing countyfips
drop if countyfips == .
merge 1:1 countyfips using ../temp/census1960
* drop states
drop if _m!=3
drop _m
save ../temp/census1960, replace

merge 1:1  countyfips using ../temp/census1950
/*



Result                           # of obs.
-----------------------------------------
not matched                            37
    from master                        30  (_merge==1)
    from using                          7  (_merge==2)

matched                             3,103  (_merge==3)
-----------------------------------------



*/

drop if _m!=3
drop _m

foreach var in lpop medinc highschool  urban  medage ppl_sqm share_NW {
  local diff_`var' = (`var'_60 - `var'_50)/10
  forvalue year = 51/59 {
    g `var'_`year' = `diff_`var'' * (`year'-50) + `var'_50
  }
  forvalue year = 61/72 {
    g `var'_`year' = `diff_`var'' * (`year'-50) + `var'_50
  }
  forvalue year = 40/49 {
    g `var'_`year' = `diff_`var'' * (`year'-50) + `var'_50
  }
}
reshape long lpop_ medinc_ highschool_  urban_  medage_ ppl_sqm_ share_NW_ , i(countyfips) j(year)
replace year = year + 1900
** Dataset with demographics for 3,103 counties
save ../output/controls, replace


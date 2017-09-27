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
foreach year in  49  51 52 53{
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

/*
** signal map file
cd "$input_path"
foreach year in 48 49 50 51 52{
	import delimited using ../PrepFactbooks/19`year'/ITM`year'_MaxSignal.csv	, clear

	* xwalk cty to DMA
	cap rename fips countyfips
	* data in ITM is in 2000 counties
	rename countyfips countyfips2000
	merge 1:1 countyfips2000 using ../temp/xwalk_cty90cty00

	if `year' == 50{
		replace maxsignal ="." if maxsignal=="NA"
		destring maxsignal, replace
	}
	* get rid of Alaska and Hawaii
	drop if state == "AK" | state == "HI"


	g year = 1900 + `year'

	g TV_signal = (maxsignal>`threshold') & maxsignal!=.
	save "$temp_path/signal`year'", replace
}
*/

use  "$temp_path/signal49", clear
foreach year in  51 52 53 {
	append using "$temp_path/signal`year'"
}
save "$temp_path/ITMTVdate", replace


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

matched                             9,860  (_merge==3)
-----------------------------------------
*/
drop if _m!=3
drop _merge
** county split implies there are two observations for a 1990 county
duplicates drop year countyfips, force
merge 1:m year countyfips using ../temp/ALlyearTV
** virginia cities w/o TV data (and a few other cty)
g GSyear = year(date2)
g tvhh = TVHH / TOTALHH

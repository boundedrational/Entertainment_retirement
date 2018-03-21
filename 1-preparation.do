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
******         CPS - SSA data         **********
*********************************************************/
/*
*Autor
local raw_data "data.s9039.txt"
*local dict "s9039.dct"
local dict "s9039.dct"

cd ${data}/CPS73-SSA/Autor
infile using `dict', using (`raw_data') clear
save matched_data, replace

*IPUMS ADF
cd ${data}/CPS73-SSA/IPUMS
do cps_00017.do
save adf, replace
*/
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

reshape wide  TVHH TOTALHH  , i(countyfips) j(year)
save ../temp/ALlyearTV, replace

/*********************************************************
******         read in ITM signal strength     ***********
*********************************************************/

**    DEFINE SIGNAL THRESHOLD
local sig_threshold = -50
local cutOff_month = 0
local frequency_prob = "signal9090"

do "../code/1.1 - ITM.do" `sig_threshold' `cutOff_month' `frequency_prob'

local sig_threshold = -50
local cutOff_month = 4
local frequency_prob = "signal5050"

do "../code/1.1 - ITM.do" `sig_threshold' `cutOff_month' `frequency_prob'

local sig_threshold = -80
local cutOff_month = 4
local frequency_prob = "signal9090"

do "../code/1.1 - ITM.do" `sig_threshold' `cutOff_month' `frequency_prob'
local sig_threshold = -20
local cutOff_month = 4
local frequency_prob = "signal9090"
do "../code/1.1 - ITM.do" `sig_threshold' `cutOff_month' `frequency_prob'

local sig_threshold = -50
local cutOff_month = 9
local frequency_prob = "signal9090"
do "../code/1.1 - ITM.do" `sig_threshold' `cutOff_month' `frequency_prob'

local sig_threshold = -50
local cutOff_month = 4
local frequency_prob = "signal9090"
do "../code/1.1 - ITM.do" `sig_threshold' `cutOff_month' `frequency_prob'

local sig_threshold = -60
local cutOff_month = 9
local frequency_prob = "signal9090"
do "../code/1.1 - ITM.do" `sig_threshold' `cutOff_month' `frequency_prob'

/*********************************************************
******         merge DMA and ITM data     		**********
*********************************************************/

** ITM data
* generates datasets with TV information for each county. Several specifications are run

foreach spec in  signal90909-50 signal90900-50 signal50504-50 signal90904-80 signal90904-20 signal90904-50 {
  *local spec signal90909-50
  import delimited  using ../output/TVsignal_ITM_`spec', clear case(preserve)
  ** add ID for DMA
  merge m:1 DMAINDEX using ../temp/DMATVdate
  /*

  Result                           # of obs.
  -----------------------------------------
  not matched                             5
      from master                         0  (_merge==1)
      from using                          5  (_merge==2) Hawaii & Alaska

  matched                             3,049  (_merge==3)
  -----------------------------------------

  */
  drop if _m!=3
  drop _merge

  ** county split implies there are two observations for a 1990 county
  drop if countyfips2000 == 8014
  *duplicates drop year countyfips, force

  ** add GS TV household data
  merge 1:1 countyfips using ../temp/ALlyearTV

  ** virginia cities w/o TV data (and a few other cty)
  /*
  Result                           # of obs.
  -----------------------------------------
  not matched                            75
      from master                        14  (_merge==1) 4012 32510 35006  and virginia cities
      from using                         61  (_merge==2) some of the counties that get TV after 1960 and a few others

  matched                             3,034  (_merge==3)
  -----------------------------------------

  */
  replace TVYEAR_ITM = 1960 if _m == 2
  rename _m ownershipData_merge

  **
  ** TV signal
  **

  reshape long ITM_signal LoS_station ITM_station CATV_ChannelCount CATV_count TVHH TOTALHH    , i(countyfips) j(year)
  ** Define TV expoure
  g DMA_access = year >= TVYEAR & TVYEAR!=.
  g ITM_access = ITM_station>0 & ITM_station!=.
  replace ITM_access = 1 if CATV_count >0 & CATV_count!=.

  * fill in missing observations
  foreach var in LoS_station ITM_station {
    replace `var' = 0 if `var' ==.
  }
  /*
  **
  ** TV OWNERSHIP
  **
  g tvhh = TVHH / TOTALHH

  ** missing counties are without tv signal according to magazine
  g TVHH_with0 = tvhh
  replace TVHH_with0 = 0 if year > 1952 & year<1958 & TVHH_with0 == . & no_ownershipData==3
  */
  save ../output/TVaccess, replace
  use ../output/TVaccess, clear
  keep TVYEAR TVYEAR_ITM  ITM_signal ITM_station DMA_access ITM_access LoS_station CATV_* year countyfips  TVyearGroups TVyearGroups_ITM

  reshape wide ITM_signal ITM_station DMA_access ITM_access LoS CATV*, j(year) i(countyfips)
  save ../output/TVwide_`spec', replace
  outsheet using ../output/TVwide_`spec'.csv, comma replace

}

/*********************************************************
******         read in voting data     		**********
*********************************************************/

do "../code/1.1 - voting.do"

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
g share_NW_50 =( 1-(nwmtot+ fbwmtot +nwftot+ fbwftot)/totpop) * 100
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
g share_NW_60 = (1-whtot/totpop) * 100
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


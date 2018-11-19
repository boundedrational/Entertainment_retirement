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
******         Census: county LF outcomes         *****
*********************************************************/

do "../code/1.1 - Census cty outcomes.do"

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
******         load time use data         **********
*********************************************************/

do "../code/1.1 - AHTUS_new.do"

* graph leisure and tv time
 egen leisure = rowtotal(act_*)
 egen ageGroups = cut(age), at(16(5)61 100)

 collapse (mean) leisure tv [pw=xtimewt], by(sample ageGroups)

replace leisure = leisure/60
replace tv = tv/60
label var tv "TV"
label var leisure "leisure hours"

 twoway line leisure tv sample

 * growth in leisure time
 g nontv_leisure = leisure - tv
 g tv_helper = tv if sample == 1965
 egen tv65 = max(tv_helper)
 g non_helper = non if sample == 1965
 egen nonL65 = max(non_helper)
 g tv_growth = tv-tv65
g nontv_growth = nontv_leisure - nonL65
g shareTV = tv / leisure
label var tv_growth "TV"
label var nontv_growth "Non TV leisure"
label var shareTV "% watching TV"


twoway  (line  leisure sample) (line shareTV sample, yaxis(2)) if sample!=1998 & ageGroups>21, ytitle(daily leisure hours) xtitle(year)  by(ageGroups)
graph export ../output/timeuse.pdf, replace

*twoway line tv_growth nontv_growth sample if sample>1965, ytitle({&Delta} daily leisure hours) xtitle(year) 
graph export ../output/delta_timeuse.pdf, replace

* notes("Source: AHTUS time use data. In 1965 on average 92 minutes are spent watching TV and 152 on non-TV leisure activities. Non TV leisure include In home free time activities, Media and computing (excludes TV), out of home free time activity, sports and outdoors. Weights are used to calculate averages.")

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
******         Translator       **********
*********************************************************/
* independent of cut-off month, can define data here

do "../code/1.1-translator.do"


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

local sig_threshold = -60
local cutOff_month = 9
local frequency_prob = "signal9090"
do "../code/1.1 - ITM.do" `sig_threshold' `cutOff_month' `frequency_prob'

local sig_threshold = -50
local cutOff_month = 4
local frequency_prob = "signal9090"
do "../code/1.1 - ITM.do" `sig_threshold' `cutOff_month' `frequency_prob'

local sig_threshold = -50
local cutOff_month = 9
local frequency_prob = "signal9090"
do "../code/1.1 - ITM.do" `sig_threshold' `cutOff_month' `frequency_prob'


/*********************************************************
******         merge DMA and ITM data     		**********
*********************************************************/

** ITM data
* generates datasets with TV information for each county. Several specifications are run

foreach spec in  signal90909-50 signal90900-50 signal50504-50 signal90904-80 signal90904-20 signal90904-50 signal90909-60 {
  *local spec signal90909-50
  import delimited  using ../output/TVsignal_ITM_`spec', clear case(preserve)
  ** add ID for DMA
  merge m:1 DMAINDEX using ../temp/DMATVdate
  
  /* Result                           # of obs.
  -----------------------------------------
  not matched                             1
      from master                         0  (_merge==1)
      from using                          1  (_merge==2)

  matched                             3,118  (_merge==3)
  -----------------------------------------
  */


  drop if _m!=3
  drop _merge

  ** county split implies there are two observations for a 1990 county
  drop if countyfips2000 == 8014
  *duplicates drop year countyfips, force

  ** add GS TV household data
  merge 1:1 countyfips using ../temp/ALlyearTV

  
  /*  Result                           # of obs.
     -----------------------------------------
     not matched                            24
         from master                        23  (_merge==1)
         from using                          1  (_merge==2)

     matched                             3,094  (_merge==3)
     -----------------------------------------
  */
 
  rename _m ownershipData_merge

  **
  ** TV signal
  **

  reshape long ITM_signal LoS_station LoS_Uniqstation ITM_station ITM_Uniqstation CATV_ChannelCount CATV_count translator_count TVHH TOTALHH   ITM_VHFstation , i(countyfips) j(year)
  
  ** Define TV expoure
  g DMA_access = year >= TVYEAR & TVYEAR!=.
  g ITM_access = ITM_station>0 & ITM_station!=.
  replace ITM_access = 1 if CATV_count >0 & CATV_count!=.
  replace ITM_access = 1 if translator_count >0 & translator_count!=.

  * fill in missing observations
  foreach var in LoS_station LoS_Uniqstation ITM_station ITM_Uniqstation ITM_VHFstation {
    replace `var' = 0 if `var' ==.
  }

  save ../output/TVaccess, replace
  use ../output/TVaccess, clear
  keep TVYEAR TVYEAR_ITM  ITM_signal ITM_station ITM_Uniqstation DMA_access ITM_access LoS_Uniqstation LoS_station CATV_* translator_* year countyfips  TVyearGroups TVyearGroups_ITM ITM_VHFstation

  reshape wide ITM_signal ITM_station ITM_Uniqstation ITM_VHFstation DMA_access ITM_access LoS_Uniqstation LoS_station CATV* translator_* , j(year) i(countyfips)
  save ../output/TVwide_`spec', replace
  outsheet using ../output/TVwide_`spec'.csv, comma replace

}

/**************************************************     merge forzen antenna to later outcomes
*************************************************/
* use height from factbook (above ground)
import delimited using ../PrepFactbooks/CreatePanel/ITM_out_panel.csv  , clear
keep station height citychannel freq power startdate state signal9090 translat translong
* find home state & county
bys station height citychannel freq power startdate: egen max_sig = max(signal9090)
drop if max_sig != signal9090
duplicates drop _all, force
g id_ITM = _n
g strlen = strlen(citychannel)
g city= substr(citychannel,1,strlen-2)
g channel = substr(citychannel,-2,.)
destring channel, replace
save ../temp/tv_heightMerge, replace

* find closest antenna to CPs
insheet using "/Users/felixkoenig/OneDrive - London School of Economics/TV expansion/build/input/freelancer/CPs/Television Factbook 1949/Copy of TV construction permits and applications 1950.csv", delimiter(;) clear
drop if cp=="yes"
keep v1 state city channel visual aural height v20 v21
g id_cp = _n
rename height heightAAT
cross using ../temp/tv_heightMerge
* calculate distance
geodist translat translong v20 v21, gen(d)
bys id_cp: egen close_stat= min(d)
drop if round(d, 0.001) != round(close_stat, 0.001)
duplicates drop id_cp, force
keep v20 v21 channel visuala height id_cp height

outsheet using ../output/frozen_CPwithheight.csv, comma replace

/*********************************************************
******        generate "freeze" placebo treatment       **********
*********************************************************/
do "../code/1.1-frozen stations.do"

/*********************************************************
******  agregate frozen stations at MSA level         ****
*********************************************************/
* use county-MSA crosswalk from superstar project (build/code/1.1-geo)

!cp "/Users/felixkoenig/OneDrive - London School of Economics/TV expansion/build/temp/aggregateITMatSSAlevel.dta" "$input_path/" 
local spec signal90909-50

use ../output/freeze_treatment, clear
rename fips countyfips2000
* fix mismatch between 2000 (ITM) counties and 1970 (MSA counties)
* use freeze info of absorbing counties for these cases
drop if countyfips2000 == 4012 
drop if countyfips2000 == 35006 
drop if countyfips2000 == 51683 
drop if countyfips2000 == 51685
drop if countyfips2000 == 51735 

* added freeze issues (no signal data but do have freeze data)
drop if countyfips2000 == 8014
replace countyfips2000 = 12025  if countyfips2000==12086

*
* Define affected by freeze
* exclude areas that already have TV signal in 1952
*
rename countyfips2000 countyfips
merge 1:m  countyfips using ../output/TVwide_`spec'
drop _m
drop if countyfips == 4012 
drop if countyfips == 35006 
drop if countyfips == 51683 
drop if countyfips == 51685
drop if countyfips == 51735 
rename  countyfips countyfips_ITM

* check if freeze was biting in 1952
g freeze_noTV = freeze_treatment if ITM_access1952==0
replace freeze_noTV = 0  if ITM_access1952==1
*
* aggregate at MSA level
*
merge 1:m countyfips_ITM using "../input/aggregateITMatSSAlevel"
* drop Alaska and Hawaii (9 counties)
drop if _m==1
* if not frozen data is missing in using
replace freeze_treatment = 0 if freeze_treatment == .
replace freeze_noTV = 0 if freeze_noTV == .


collapse (mean) freeze_treatment freeze_noTV freeze_station [fw = int(weight)], by(statefip smsaa)

save ../output/frozen_msa, replace


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

/*
********************************************************
******  merge Census CTY and TV data         ****
*********************************************************/
* county ITM data
use ../output/TVwide_signal90909-50, clear
keep countyfips ITM_signal1950-ITM_access1950 ITM_signal1960-ITM_access1960 TVYEAR_ITM TVYEAR
reshape long  ITM_signal ITM_station ITM_Uniqstation ITM_VHFstation DMA_access ITM_access LoS_Uniqstation LoS_station CATV_ChannelCount  CATV_count  translator_count , j(year) i(countyfips)

* treatment is the sum of stations and CATV systems
egen total_stations = rowtotal(ITM_station CATV_count translator_count)
egen total_VHFstations = rowtotal(ITM_VHFstation CATV_count translator_count)
egen total_Uniqstations = rowtotal(ITM_Uniqstation CATV_count translator_count)


rename countyfips fips
merge 1:1 year fips using ../temp/Census4070
/*
_m = 2 in 1940 & 1970 (no TV info)
_m = 1 are 36 fips without outcome data (mismatch in cty definition)
Result                           # of obs.
-----------------------------------------
not matched                         6,236
    from master                        72  (_merge==1)
    from using                      6,164  (_merge==2) 

matched                             6,164  (_merge==3)
-----------------------------------------
*/
drop if _m==1
g tv_inc70 = total_stations
replace tv_inc70 = 10  if year==1970
replace tv_inc70 = 10  if tv_inc70>10 & tv_inc70!=.

keep year fips name noemp nilf nilf_men nilf_fem  empop clfpop lfpop lfs_men total_stations total_Uniqstations total_VHFstations TVYEAR_ITM  ITM_signal totpop tv_inc70 pcturban medage  highschool LoS_station LoS_Uniqstation


* add MSA identifiers
rename fips countyfips_ITM
 
reshape wide  name noemp nilf nilf_men nilf_fem  empop clfpop lfpop lfs_men total_stations total_Uniqstations total_VHFstations LoS_station  LoS_Uniqstation TVYEAR_ITM  ITM_signal totpop tv_inc70 pcturban medage  highschool , i(countyfips_ITM) j(year)

merge 1:m countyfips_ITM using "../input/aggregateITMatSSAlevel"
*_m==1 is Hawaii
*_m==2 unmatched counties over time?
/*
Result                           # of obs.
-----------------------------------------
not matched                            30
    from master                         4  (_merge==1)
    from using                         26  (_merge==2)

matched                             3,111  (_merge==3)
-----------------------------------------
*/
* some counties straddle MSAs, identify unique places
bys countyfips_ITM: g unique=_n==1
g ID_unique = _n
reshape long  name noemp nilf nilf_men nilf_fem empop clfpop lfpop lfs_men total_stations total_Uniqstations total_VHFstations LoS_station  LoS_Uniqstation TVYEAR_ITM  ITM_signal totpop tv_inc70 pcturban medage  highschool , i(ID_unique) j(year)
drop _m


*state
rename  countyfips_ITM fips
g state = int(fips/1000)
* drop Hawaii
drop if state==15

g msa2= smsaa
replace msa2 = 999  if smsaa==.
egen Treat_level = group(statefip msa2)


* weight
* weight for split counties
g msa_weight = share_msa if smsaa!=.
replace  msa_weight = 1 if smsaa==.
*population in 1940 is used as weight
bys fips: g helper = totpop if year ==1940
bys fips: egen pop40 = max(helper)
drop helper

save "../output/cty_itm.dta", replace

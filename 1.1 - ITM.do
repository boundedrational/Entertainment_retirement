

**
**
*** ITM signal data
**
**


/*-------------------------
  1.
-------------------------*/

**    DEFINE SIGNAL THRESHOLD
local sig_threshold = `1'
local cutOff_month = `2'
local frequency_prob = "`3'"


* from panel CSV file
cd "$input_path"
import delimited using ../PrepFactbooks/CreatePanel/ITM_out_panel.csv  , clear





* generate TV start year from different date formats
destring startmonth startday startyear, replace force
g TVDATE_ITM = mdy(startmonth, startday, startyear)
g D2 =  ym( startyear, startmonth)
replace TVDATE_ITM = dofm(D2) if TVDATE_ITM == .
format TVDATE_ITM %td

* drop TV stations that are set up after month-cutoff date
drop if month(TVDATE_ITM) >= `cutOff_month' & year(TVDATE_ITM)>=year & TVDATE_ITM != .

* some stations report different start dates across years. Use a uniform one. We chose the later of the reported dates.
bys station: egen TVDATE_ITMmax = max(TVDATE_ITM)
replace TVDATE_ITM = TVDATE_ITMmax

* Drop again after change in ITM date
drop if month(TVDATE_ITM) >= `cutOff_month' & year(TVDATE_ITM)>=year & TVDATE_ITM != .


* Year of start of stations
g station_start_year = year(TVDATE_ITM)

* define county where channel originates
* based on county centroid closest to antenna
bys citychannel year: egen closest_dist = min(distance)
bys citychannel year: g helper = fips if closest_dist==distance
bys citychannel year: egen origin_ctyFIPS = mean(helper)
drop helper closest_dist

* separate columns that include both channel and city
g channel = substr(citychannel,-2,2)
g str_len = strlen(citychannel)
g city = substr(citychannel,1,str_len-2)
destring channel, replace
replace city = trim(city)

* Lign of Sight
* adds receiving antenna and transmitter radius. Receiving antenna at 10m above sea-level.
* LoS ignores intercepting terrain and here also height of transmittor due to terrain
cap destring height, replace force
g LoS_station = (distance < (4.12 * sqrt(height) +4.12 * sqrt(10)) ) if height!=. & distance!=.
g LoS_dis = (4.12 * sqrt(height) +4.12 * sqrt(10) ) if height!=. & distance!=.
* discount frequencies that are used by two antennas
rename `frequency_prob' ITM_signal
bys channel year fips LoS_station: egen channel_rank_los = rank(ITM_signal*-1)
g LoS_Uniqstation = (distance < (4.12 * sqrt(height) +4.12 * sqrt(10)) ) if height!=. & distance!=. & channel_rank_los==1


* ITM station
* discount frequencies that are used by two antennas
bys channel year fips: egen channel_rank = rank(ITM_signal*-1)


g ITM_station = (ITM_signal>`sig_threshold' & ITM_signal!=.)

g ITM_Uniqstation = (ITM_signal>`sig_threshold' & ITM_signal!=. & channel_rank==1)
*only count VHF stations
g ITM_VHFstation = (ITM_signal>`sig_threshold' & ITM_signal!=. & channel<14 & channel_rank==1)

rename fips countyfips2000


* only keep locations with a channel (don't have all counties in the data in the first place)
* drop if ITM_station == 0 & LoS_station == 0



*dataset at cty - year - channel level
keep  countyfips2000 county  station channel city   ITM_station ITM_Uniqstation LoS_Uniqstation ITM_signal LoS_station year station_start_year TVDATE_ITM ITM_VHFstation origin_ctyFIPS
save ../temp/TVsignal_ITM_channel_`1'`2'`3', replace

*build dataset at cty - year level
use ../temp/TVsignal_ITM_channel_`1'`2'`3', clear
keep  countyfips  ITM_signal ITM_station ITM_Uniqstation LoS_Uniqstation LoS_station year  station_start_year ITM_VHFstation channel 
collapse  (max) ITM_signal (min)  station_start_year (sum) ITM_station ITM_Uniqstation  ITM_VHFstation LoS_station LoS_Uniqstation, by(countyfips year)

save "$temp_path/signal", replace




/*********************************************************
******         infer pre 1948 TV data       **********
*********************************************************/

* identify stations operating pre 1948
use ../temp/TVsignal_ITM_channel_`1'`2'`3', clear
keep if station_start_year < 1948
drop if year != 1948
* TV dummies
g TV47 = (station_start_year<=1947)
g TV46 = (station_start_year<=1946)

foreach year in 46 47 {
  preserve
  drop if TV`year'!=1
  keep countyfips ITM_signal ITM_station ITM_Uniqstation TVDATE_ITM LoS_Uniqstation LoS_station station_start_year
  collapse (max) ITM_signal (min) station_start_year   (sum) LoS_station LoS_Uniqstation ITM_station ITM_Uniqstation, by(countyfips)
  drop if LoS_station == 0 & ITM_station == 0
  g year = 1900 + `year'
  *merge 1:1 countyfips2000 using ../temp/xwalk_cty90cty00
  *drop if _m!=3
  *drop _m
  save "$temp_path/signal`year'", replace
  restore
}
* merge pre 48 stations with current data
use  "$temp_path/signal46", clear
append using "$temp_path/signal47"
append using "$temp_path/signal"

save ../temp/ITMTVdate, replace

/*********************************************************
******         CATV       **********
*********************************************************/

do "../code/1.1-CATV.do" "`cutOff_month'"



/*********************************************************
****** Define ITM TV data (county year level)   **********
*********************************************************/
use ../temp/ITMTVdate, clear

*Treatment year is first year we observe signal. Since data starts in 1946, use station launch date for counties that already have signal in 1946
bys countyfips: egen TVYEAR_ITM = min(year) if ITM_station>0
replace TVYEAR_ITM = station_start_year if TVYEAR_ITM == 1946
drop station_start_year
* replace generates multiple start dates in same county
bys countyfips: egen mTV = min(TVYEAR_ITM)
drop TVYEAR_ITM
rename mTV TVYEAR_ITM

reshape wide ITM_station ITM_Uniqstation LoS_Uniqstation ITM_signal LoS_station ITM_VHFstation  , i(countyfips2000) j(year)


* add CATV data
* split county makes merge between 1990 and 2000 counties tricky
*drop if countyfips2000 == 8014
merge 1:1 countyfips2000 using ../output/CATV_perCounty_`cutOff_month'
drop _m

rename countyfips2000 countyfips1990
merge 1:1 countyfips1990 using ../temp/translator_perCounty
rename  countyfips1990 countyfips2000
/*    Result                           # of obs.
    -----------------------------------------
    not matched                         3,011
        from master                     3,011  (_merge==1)
        from using                          0  (_merge==2)

    matched                                95  (_merge==3)
    -----------------------------------------
*/

reshape long  ITM_signal LoS_station LoS_Uniqstation ITM_station ITM_Uniqstation ITM_VHFstation translator_count CATV_ChannelCount CATV_count  , i(countyfips2000) j(year)

* replace TV year with CATV
replace TVYEAR_ITM = year_CATV if year_CATV < TVYEAR_ITM
replace TVYEAR_ITM = year_translator if year_translator < TVYEAR_ITM


*define groups of counties by TV year ranges
g TVyearGroups_ITM = 1 if TVYEAR_ITM< 1945 & TVYEAR_ITM>1930
replace TVyearGroups_ITM = 2 if TVYEAR_ITM< 1952 & TVYEAR_ITM>1944
replace TVyearGroups_ITM = 3 if TVYEAR_ITM< 1970 & TVYEAR_ITM>1951
label def TVGroup 1 "First TV pre 1945" 2 "First TV 1945-1951" 3 "First TV 1952+"
label value TVyearGroups TVGroup

replace TVYEAR_ITM = 1946  if TVYEAR_ITM<1946


* drop locations that never get TV
drop if TVYEAR_ITM == .
*replace TVYEAR_ITM = 1960 if date_ITM == . & ITM_station == 0


keep countyfips2000 year  TVYEAR_ITM TVyearGroups ITM_signal ITM_station ITM_Uniqstation ITM_VHFstation LoS* CATV* translator*

  reshape wide  ITM_station ITM_Uniqstation ITM_VHFstation ITM_signal LoS_station LoS_Uniqstation CATV_ChannelCount CATV_count translator*, i(countyfips) j(year)
  merge m:1 countyfips2000 using ../temp/xwalk_cty90cty00
  /*
  * drop all empty counties
  Result                           # of obs.
  -----------------------------------------
  not matched                            69
      from master                         0  (_merge==1)
      from using                         69  (_merge==2) county without ITM data

  matched                             3,049  (_merge==3)
  -----------------------------------------
*/
replace TVYEAR_ITM = . if _m == 2

* drop if _m!=3
  drop _m STATE
label var countyfips2000 "county FIPS (2000)"
label var countyfips "county FIPS (1990)"
order countyfip* DMAINDEX DMAINDEX2 TVyearGroups_ITM TVYEAR_ITM
*save "$temp_path/ITMTVdate", replace

erase "$temp_path/ITMTVdate.dta"
outsheet  using ../output/TVsignal_ITM_`frequency_prob'`cutOff_month'`sig_threshold'.csv , comma replace



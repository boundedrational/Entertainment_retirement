* freeze stations

*
* affected counties
*

cd "$input_path"
import delimited using ../PrepFactbooks/FreezeStations/ITMFreeze_MaxSignal.csv  , clear

g freeze_treatment = (maxsignal>-50)
keep if freeze_treatment == 1

keep fips freeze_treatment
g freeze_year = 1949

save  ../output/freeze_treatment, replace

*
* intensity of freeze
*
cd "$input_path"
import delimited using ../PrepFactbooks/FreezeStations/ITMFreeze_out.csv  , clear
keep if signal9090>-50
g freeze_station = 1
g channel = substr(citychannel,-2,2)
destring channel, replace
g freeze_VHFstation = 1 if channel<13

collapse (sum) freeze_station freeze_VHFstation, by(fips)

merge 1:1 fips using  ../output/freeze_treatment
drop _m
save  ../output/freeze_treatment, replace

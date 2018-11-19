*******
*******
*******			Prepares files to process in QGIS
*******
*******

*
* CATV
*

clear
tempfile temp    /* create a temporary file */
gen X = 1
save `temp',replace
forvalue year = 1952/1960 {

	import excel using ../PrepFactbooks/CATV/`year'.xlsx, firstrow clear allstring
	append using "`temp'"
	save `temp', replace
}
drop X
sort State City Year
* get rid of empty fields & typos
drop if Year == ""
replace City = trim(City)
replace State = trim(State)
replace State = "West Virginia" if State == "West Birginia"
replace City = "Kingsport" if State == "Tennessee" & City == ""
* generate location identifier to merge in counties after QGIS processing
egen locationID = group(City State)
export delimited using ../PrepFactbooks/CATV/ALLRepeater.csv, replace

* get rid of duplicate regions
duplicates drop locationID, force
* save for QGIS processing
export delimited using ../QGIS/CATV/Repeater.csv, replace

** process in QGIS
* 1. Geocode using open maps
* 1.1. Manually Lookup places not found by API
* 2. load 1990 county shape file
* 3. Match location of CATV to county

insheet  using ../QGIS/CATV/CATV_county.csv, clear delimiter(";")
* Fix miss coded places
replace f1 = 08065 if city == "Climax" & state == "Colorado"
replace f1 = 08045 if city == "Glenwood" & state == "Colorado"
* places with geocode in water will be missed. Add manually
set obs `=_N+1'
local end = _N
replace locationid = 352  in `end'
replace f1 = 12087 if locationid == 352
set obs `=_N+1'
local end = _N
replace locationid = 494  in `end'
replace f1 = 41041 if locationid == 494


keep state city f1 statef locationid addrlocat
rename f1 countyfips
export delimited using ../PrepFactbooks/CATV/Lookup_CATV_county.csv,  replace

*
* Translator
*

clear
tempfile temp    /* create a temporary file */
gen X = 1
save `temp',replace
forvalue year = 1957/1960 {

	import excel using ../PrepFactbooks/Translators/`year'.xlsx, firstrow clear allstring
	cap g Year = "`year'"
	append using "`temp'"
	save `temp', replace
}
drop X
sort State City Year
* drop non operational translators
keep if InOperation == "1" | OnAir == "1"

* get rid of empty fields & typos
drop if Year == ""
replace City = trim(City)
replace State = trim(State)
replace State = "Oregon" if State == "Oregan"
*replace City = "Kingsport" if State == "Tennessee" & City == ""
* generate location identifier to merge in counties after QGIS processing

egen locationID = group(City State)
export delimited using ../PrepFactbooks/Translators/ALLTranlators.csv, replace

* get rid of duplicate regions
duplicates drop locationID, force
* save for QGIS processing
export delimited using ../QGIS/Translators/Translator.csv, replace

** process in QGIS
* 1. Geocode using open maps
* 1.1. Manually Lookup places not found by API
* 2. load 1990 county shape file
* 3. Match location of CATV to county


insheet  using ../QGIS/Translators/Translator_cty90.csv, clear delimiter(",")
g countyfips = state*100 + county/10
keep addrtype countyfips year city channel station inputchan cpgra  station nhgisnam statenam
rename addrtype locationid

* places with geocode in water will be missed. Add manually
set obs `=_N+1'
local end = _N
replace locationid = 7  in `end'
replace countyfips = 4015 if locationid == 7
set obs `=_N+1'
local end = _N
replace locationid = 11  in `end'
replace countyfips = 6045 if locationid == 11
set obs `=_N+1'
local end = _N
replace locationid = 79  in `end'
replace countyfips = 32013 if locationid == 79
set obs `=_N+1'
local end = _N
replace locationid = 51  in `end'
replace countyfips = 36087 if locationid == 51
set obs `=_N+1'
local end = _N
replace locationid = 55  in `end'
replace countyfips = 36007 if locationid == 55
set obs `=_N+1'
local end = _N
replace locationid = 12  in `end'
replace countyfips = 41011 if locationid == 12
set obs `=_N+1'
local end = _N
replace locationid = 13  in `end'
replace countyfips = 41001 if locationid == 13
set obs `=_N+1'
local end = _N
replace locationid = 14  in `end'
replace countyfips = 41001 if locationid == 14
set obs `=_N+1'
local end = _N
replace locationid = 76  in `end'
replace countyfips = 41001 if locationid == 76
set obs `=_N+1'
local end = _N
replace locationid = 78  in `end'
replace countyfips = 42025 if locationid == 78
set obs `=_N+1'
local end = _N
replace locationid = 32  in `end'
replace countyfips = 49027 if locationid == 32
set obs `=_N+1'
local end = _N
replace locationid = 41  in `end'
replace countyfips = 49027 if locationid == 41
set obs `=_N+1'
local end = _N
replace locationid = 58  in `end'
replace countyfips = 56023 if locationid == 58
keep locationid countyfips
export delimited using ../PrepFactbooks/Translators/Lookup_Translator_county.csv,  replace
save ../temp/Lookup_Translator_county,  replace


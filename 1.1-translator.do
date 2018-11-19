
insheet using ../PrepFactbooks/Translators/ALLTranlators.csv, clear
merge m:1 locationid using ../temp/Lookup_Translator_county

drop _m
rename countyfips countyfips1990

g translator_count = 1
collapse (sum) translator_count , by(year countyfips)
bys countyfips: egen year_translator = min(year)
reshape wide translator_count  , i(countyfips ) j(year)

save ../temp/translator_perCounty, replace

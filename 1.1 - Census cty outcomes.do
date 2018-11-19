* This file creates a panel dataset at the county level. It includes laborforce participation by county, age group and year. As well as employment

use "../input/CensusCovariates/CensusMaster", clear

* keep only balanced sample
bys fips: g balance = (_N==4)
drop if balance !=1
drop balance

* employment rate

* male labor force rate (1940 is 14 +, 1950 general, 1960 civilian)
g lfsPct_m14 = pctmlf 
replace lfsPct_m14 = pctlfm  if year == 1950
replace lfsPct_m14 = pctclfm  if year == 1960

* unified lfp
g lfs_men = mlfp
g lfs_wom = flfp

* out of lfs status
g nilf_men = (1-lfs_men)*100
g nilf_fem = (1-lfs_wom)*100

g nilf = (1-lfpop)*100
g noemp = (1-empop)*100

label var noemp "non-employed/population"
label var nilf "NILF rate"
label var nilf_men "NILF rate (men)"

local controls "pcturban medage  highschool"

keep fips name noemp nilf nilf_men nilf_fem year empop clf_e lf_e clfpop lfpop  flfp lfs_men  lfsPct_m14 highschool pcturban totpop `controls'

save ../temp/Census4070, replace
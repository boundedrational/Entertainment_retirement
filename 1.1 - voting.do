** voting data
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
drop if Countycod == 9999

merge 1:1 STATEICP Countycod using $data/lookup/CTY&STATE_ICPSR_FIPS
/*
Result                           # of obs.
    -----------------------------------------
    not matched                           200
        from master                       174  (_merge==1)
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
replace TotalVotes_C = . if TotalVotes_C == 9999999

*sanity check
g sanity = (vote_CONG_REP_+vote_CONG_DEM_<102)
replace sanity = 0 if (vote_CONG_REP_+vote_CONG_DEM_==0)

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
replace presidential_year = 1 if year == 1908
replace presidential_year = 1 if year == 1904
replace presidential_year = 1 if year == 1900

** reference participation (1940)
bys countyfips: egen helper = max(vote_C) if year == 1940
bys countyfips: egen  ref_participation= max(helper)

** replace missings as mean of variable
g ref_participation_missing = (ref_participation == .)
g REP_DEM_gap_missing = (REP_DEM_gap == .)
foreach var in REP_DEM_gap ref_participation {
  egen `var'_bar = mean(`var')
  replace `var' = `var'_bar  if `var' == .
  drop `var'_bar
}


keep year TotalVotes_C countyfip vote_C presidential_year GS_sample REP_DEM_gap ref_participation ref_participation_missing REP_DEM_gap_missing
save ../output/vote_data, replace

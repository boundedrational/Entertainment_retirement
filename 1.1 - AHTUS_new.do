* NOTE: You need to set the Stata working directory to the path
* where the data file is located.

set more off
cd "${temp_path}"


clear
quietly infix                    ///
  int     sample        1-4      ///
  double  ident         5-13     ///
  byte    age           14-15    ///
  byte    sex           16-17    ///
  byte    civstat       18-19    ///
  byte    cohab         20-21    ///
  byte    educ          22-23    ///
  double  recwght       24-39    ///
  byte    ethnic2       40-41    ///
  double  infltwt       42-57    ///
  double  xtimewt       58-73    ///
  byte    state         74-75    ///
  byte    regionc       76-77    ///
  byte    empstat       78-79    ///
  byte    incomeqt      80-81    ///
  byte    wkhrs         82-83    ///
  byte    occup         84-85    ///
  byte    retired       86-87    ///
  int     act_inhome    88-91    ///
  int     act_media     92-95    ///
  int     act_outhome   96-99    ///
  int     act_physical  100-103  ///
  int     tv            104-107  ///
  using `"../input/time use/ahtus_00002.dat"'


format ident        %9.0f
format recwght      %16.0f
format infltwt      %16.0f
format xtimewt      %16.0f

label var sample       `"Sample"'
label var ident        `"Identifier"'
label var age          `"Age"'
label var sex          `"Sex"'
label var civstat      `"Marital status"'
label var cohab        `"Cohabiting partner status"'
label var educ         `"Education"'
label var recwght      `"Recommended sample (day) weight removing low quality diaries and missing age or "'
label var ethnic2      `"Ethnic group (general)"'
label var infltwt      `"RECWGHT inflated to national population"'
label var xtimewt      `"RECWGHT limited to states in all samples"'
label var state        `"State"'
label var regionc      `"Census region"'
label var empstat      `"Employment status"'
label var incomeqt     `"Household income (approximate quartiles)"'
label var wkhrs        `"Number of hours worked per week"'
label var occup        `"Occupation"'
label var retired      `"Retired status"'
label var act_inhome   `"ACT: In home free time leisure"'
label var act_media    `"ACT: Media and computing"'
label var act_outhome  `"ACT: Out of home free time and leisure"'
label var act_physical `"ACT: Sports, exercise, and outdoor activities"'
label var tv           `"TV WATCHING"'

label define age_lbl -8 `"Missing or dirty on the case record"'
label define age_lbl 00 `"0"', add
label define age_lbl 01 `"1"', add
label define age_lbl 02 `"2"', add
label define age_lbl 03 `"3"', add
label define age_lbl 04 `"4"', add
label define age_lbl 05 `"5"', add
label define age_lbl 06 `"6"', add
label define age_lbl 07 `"7"', add
label define age_lbl 08 `"8"', add
label define age_lbl 09 `"9"', add
label define age_lbl 10 `"10"', add
label define age_lbl 11 `"11"', add
label define age_lbl 12 `"12"', add
label define age_lbl 13 `"13"', add
label define age_lbl 14 `"14"', add
label define age_lbl 15 `"15"', add
label define age_lbl 16 `"16"', add
label define age_lbl 17 `"17"', add
label define age_lbl 18 `"18"', add
label define age_lbl 19 `"19"', add
label define age_lbl 20 `"20"', add
label define age_lbl 21 `"21"', add
label define age_lbl 22 `"22"', add
label define age_lbl 23 `"23"', add
label define age_lbl 24 `"24"', add
label define age_lbl 25 `"25"', add
label define age_lbl 26 `"26"', add
label define age_lbl 27 `"27"', add
label define age_lbl 28 `"28"', add
label define age_lbl 29 `"29"', add
label define age_lbl 30 `"30"', add
label define age_lbl 31 `"31"', add
label define age_lbl 32 `"32"', add
label define age_lbl 33 `"33"', add
label define age_lbl 34 `"34"', add
label define age_lbl 35 `"35"', add
label define age_lbl 36 `"36"', add
label define age_lbl 37 `"37"', add
label define age_lbl 38 `"38"', add
label define age_lbl 39 `"39"', add
label define age_lbl 40 `"40"', add
label define age_lbl 41 `"41"', add
label define age_lbl 42 `"42"', add
label define age_lbl 43 `"43"', add
label define age_lbl 44 `"44"', add
label define age_lbl 45 `"45"', add
label define age_lbl 46 `"46"', add
label define age_lbl 47 `"47"', add
label define age_lbl 48 `"48"', add
label define age_lbl 49 `"49"', add
label define age_lbl 50 `"50"', add
label define age_lbl 51 `"51"', add
label define age_lbl 52 `"52"', add
label define age_lbl 53 `"53"', add
label define age_lbl 54 `"54"', add
label define age_lbl 55 `"55"', add
label define age_lbl 56 `"56"', add
label define age_lbl 57 `"57"', add
label define age_lbl 58 `"58"', add
label define age_lbl 59 `"59"', add
label define age_lbl 60 `"60"', add
label define age_lbl 61 `"61"', add
label define age_lbl 62 `"62"', add
label define age_lbl 63 `"63"', add
label define age_lbl 64 `"64"', add
label define age_lbl 65 `"65"', add
label define age_lbl 66 `"66"', add
label define age_lbl 67 `"67"', add
label define age_lbl 68 `"68"', add
label define age_lbl 69 `"69"', add
label define age_lbl 70 `"70"', add
label define age_lbl 71 `"71"', add
label define age_lbl 72 `"72"', add
label define age_lbl 73 `"73"', add
label define age_lbl 74 `"74"', add
label define age_lbl 75 `"75"', add
label define age_lbl 76 `"76"', add
label define age_lbl 77 `"77"', add
label define age_lbl 78 `"78"', add
label define age_lbl 79 `"79"', add
label define age_lbl 80 `"80"', add
label define age_lbl 81 `"81"', add
label define age_lbl 82 `"82"', add
label define age_lbl 83 `"83"', add
label define age_lbl 84 `"84"', add
label define age_lbl 85 `"85"', add
label define age_lbl 86 `"86"', add
label define age_lbl 87 `"87"', add
label define age_lbl 88 `"88"', add
label define age_lbl 89 `"89"', add
label define age_lbl 90 `"90"', add
label define age_lbl 91 `"91"', add
label define age_lbl 92 `"92"', add
label define age_lbl 93 `"93"', add
label define age_lbl 94 `"94"', add
label values age age_lbl

label define sex_lbl -8 `"Missing or dirty on case record"'
label define sex_lbl 01 `"Male"', add
label define sex_lbl 02 `"Female"', add
label values sex sex_lbl

label define civstat_lbl -8 `"Missing or dirty on the case record"'
label define civstat_lbl 01 `"Married"', add
label define civstat_lbl 02 `"Separated, divorced"', add
label define civstat_lbl 03 `"Widowed"', add
label define civstat_lbl 04 `"Never married"', add
label values civstat civstat_lbl

label define cohab_lbl -7 `"Not applicable or refusal"'
label define cohab_lbl -8 `"Missing or dirty on the case record"', add
label define cohab_lbl 00 `"No"', add
label define cohab_lbl 01 `"Yes"', add
label values cohab cohab_lbl

label define educ_lbl -8 `"Missing or dirty on the case record"'
label define educ_lbl 01 `"0 - 8th Grade"', add
label define educ_lbl 02 `"9 - 11th Grade"', add
label define educ_lbl 03 `"High School Graduate"', add
label define educ_lbl 04 `"Some College"', add
label define educ_lbl 05 `"College Graduate"', add
label define educ_lbl 06 `"Post College"', add
label define educ_lbl 09 `"NIU"', add
label values educ educ_lbl

label define ethnic2_lbl -8 `"Missing or dirty on case record"'
label define ethnic2_lbl 01 `"White"', add
label define ethnic2_lbl 02 `"Black"', add
label define ethnic2_lbl 03 `"Some other race"', add
label define ethnic2_lbl 09 `"NIU"', add
label values ethnic2 ethnic2_lbl

label define state_lbl -9 `"Not Available"'
label define state_lbl -8 `"Missing or dirty on the case record"', add
label define state_lbl 01 `"Alabama"', add
label define state_lbl 02 `"Alaska"', add
label define state_lbl 03 `"Arizona"', add
label define state_lbl 04 `"Arkansas"', add
label define state_lbl 05 `"California"', add
label define state_lbl 06 `"Colorado"', add
label define state_lbl 07 `"Connecticut"', add
label define state_lbl 08 `"Delaware"', add
label define state_lbl 09 `"District of Columbia"', add
label define state_lbl 10 `"Florida"', add
label define state_lbl 11 `"Georgia"', add
label define state_lbl 12 `"Hawaii"', add
label define state_lbl 13 `"Idaho"', add
label define state_lbl 14 `"Illinois"', add
label define state_lbl 15 `"Indiana"', add
label define state_lbl 16 `"Iowa"', add
label define state_lbl 17 `"Kansas"', add
label define state_lbl 18 `"Kentucky"', add
label define state_lbl 19 `"Louisiana"', add
label define state_lbl 20 `"Maine"', add
label define state_lbl 21 `"Maryland"', add
label define state_lbl 22 `"Massachusetts"', add
label define state_lbl 23 `"Michigan"', add
label define state_lbl 24 `"Minnesota"', add
label define state_lbl 25 `"Mississippi"', add
label define state_lbl 26 `"Missouri"', add
label define state_lbl 27 `"Montana"', add
label define state_lbl 28 `"Nebraska"', add
label define state_lbl 29 `"Nevada"', add
label define state_lbl 30 `"New Hampshire"', add
label define state_lbl 31 `"New Jersey"', add
label define state_lbl 32 `"New Mexico"', add
label define state_lbl 33 `"New York"', add
label define state_lbl 34 `"North carolina"', add
label define state_lbl 35 `"North Dakota"', add
label define state_lbl 36 `"Ohio"', add
label define state_lbl 37 `"Oklahoma"', add
label define state_lbl 38 `"Oregon"', add
label define state_lbl 39 `"Pennsylvania"', add
label define state_lbl 40 `"Rhode Island"', add
label define state_lbl 41 `"South Carolina"', add
label define state_lbl 42 `"South Dakota"', add
label define state_lbl 43 `"Tennessee"', add
label define state_lbl 44 `"Texas"', add
label define state_lbl 45 `"Utah"', add
label define state_lbl 46 `"Vermont"', add
label define state_lbl 47 `"Virginia"', add
label define state_lbl 48 `"Washington"', add
label define state_lbl 49 `"West Virginia"', add
label define state_lbl 50 `"Wisconsin"', add
label define state_lbl 51 `"Wyoming"', add
label values state state_lbl

label define regionc_lbl -8 `"Missing or dirty on the case record"'
label define regionc_lbl 01 `"Northeast"', add
label define regionc_lbl 02 `"Midwest"', add
label define regionc_lbl 03 `"South"', add
label define regionc_lbl 04 `"West"', add
label define regionc_lbl 09 `"NIU"', add
label values regionc regionc_lbl

label define empstat_lbl -8 `"Missing or dirty on the case record"'
label define empstat_lbl 01 `"Full-time"', add
label define empstat_lbl 02 `"Part-time"', add
label define empstat_lbl 03 `"Not employed"', add
label define empstat_lbl 04 `"Working, hours unknown"', add
label values empstat empstat_lbl

label define incomeqt_lbl -8 `"Missing or dirty on case record"'
label define incomeqt_lbl 01 `"Lowest quartile"', add
label define incomeqt_lbl 02 `"Second lowest quartile"', add
label define incomeqt_lbl 03 `"Second highest quartile"', add
label define incomeqt_lbl 04 `"Highest quartile"', add
label values incomeqt incomeqt_lbl

label define wkhrs_lbl -8 `"Missing or dirty on the case record"'
label define wkhrs_lbl -7 `"Not applicable"', add
label define wkhrs_lbl -3 `"Routed out in the 1992-94 survey"', add
label define wkhrs_lbl -4 `"0 to 10 hours"', add
label define wkhrs_lbl 61 `"Between 61-80 hours"', add
label define wkhrs_lbl 81 `"More than 80 hours"', add
label values wkhrs wkhrs_lbl

label define occup_lbl -8 `"Missing or dirty on case record"'
label define occup_lbl -7 `"Not working"', add
label define occup_lbl 01 `"Management"', add
label define occup_lbl 02 `"Finance accounts"', add
label define occup_lbl 03 `"Science"', add
label define occup_lbl 04 `"Engineer, architect"', add
label define occup_lbl 05 `"Community and Social services"', add
label define occup_lbl 06 `"Legal profession"', add
label define occup_lbl 07 `"Education"', add
label define occup_lbl 08 `"Health professions"', add
label define occup_lbl 09 `"Other professions"', add
label define occup_lbl 10 `"Health support"', add
label define occup_lbl 11 `"Protective service"', add
label define occup_lbl 12 `"Sales"', add
label define occup_lbl 13 `"Office, admin"', add
label define occup_lbl 14 `"Farming, forestry"', add
label define occup_lbl 15 `"Services"', add
label define occup_lbl 16 `"Construction, production"', add
label define occup_lbl 17 `"Self-employed non-professional"', add
label values occup occup_lbl

label define retired_lbl -9 `"Not available"'
label define retired_lbl -8 `"Missing or dirty on case record"', add
label define retired_lbl -3 `"Routed out 92-94"', add
label define retired_lbl 00 `"No"', add
label define retired_lbl 01 `"Yes"', add
label define retired_lbl 09 `"NIU"', add
label values retired retired_lbl




/*************************************************/
/*************************************************/
/****************  TV exposure  ***************/
/*************************************************/
/*************************************************/




clear
graph set print logo off

graph set print tmargin 1
graph set print lmargin 1
set more off, perm
set emptycells drop

clear
clear matrix
set matsize 800

set varabbrev on

/*********************************************************
*************         Master File     ********************
*********************************************************

**********************************
**Change paths********************
**********************************/

if regexm(c(os),"Mac") == 1 {
	global root "/Users/felixkoenig/Google Drive/TV exposure"
	global data "/Users/felixkoenig/Documents/LSE/research-projects/DATA"

    }
else if regexm(c(os),"Windows") == 1 {
    global root "build"
}
global do_path "$root/build/code"
 global input_path "$root/build/input"
 global temp_path "$root/build/temp"
 global output_path "$root/build/output"
 global log_path "$root/build/log"
 global datum = subinstr(c(current_date)," ","",.)
cd "$input_path"
/**************** Version Controll ******************************/

shell "/usr/local/git/bin/git" --git-dir "$do_path/.git" --work-tree "$do_path/." commit -a -m "version $datum"


**********************************
**Run Do-Files********************
**********************************


cd "$log_path"
cap log close
log using preparation${datum}, replace text

cd "$do_path"
do 1-preparation
cap log close

	cd "$log_path"
cap log close
log using regressions${datum}.txt, replace

cd "$do_path"
do 2-regressions
cap log close
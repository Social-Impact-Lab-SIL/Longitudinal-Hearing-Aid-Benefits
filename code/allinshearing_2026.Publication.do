/* 
Paper: Longitudinal Growth of Mandated Hearing Aid Benefits in the United States, 2008-2023

Authors: Serena Phillips & Austin Landini

Description: Code merges ACS data with state-level hearing aid policy data, and uses survey weights to calculate national shares of population within each age group under each type of insurance and hearing aid coverage status. Stacked line graphs are generated for each age group showing these trends over time.

Last updated: 9/16/2026

Update note: Using latest version of hearing aid core file and IPUMS
*/


/*Windows mounted
cd "\\vast.rde.missouri.edu\mp94p-lab\Phillips\hearing_aids\paper3\Working\newpaths"
sysdir set PLUS "\\vast.rde.missouri.edu\mp94p-lab\StataUserPackages"
*/

/*Hellbender */
cd "/cluster/VAST/mp94p-lab/Phillips/hearing_aids/paper3/Working/publication"
global lab "/cluster/VAST/mp94p-lab"
sysdir set PLUS "/cluster/VAST/mp94p-lab/StataUserPackages"


set linesize 255
global today="$S_DATE"
capture log using "allhearing_${today}.log", replace

************************************************************************************************************
*Set up MEPS file
*MEPS data exported from this website: https://datatools.ahrq.gov/meps-ic
*Private Sector, State> Employees> Percent enrollees in self-insured plans at establishments that offer health insurance
************************************************************************************************************

import excel "${lab}/Phillips/hearing_aids/paper3/meps_2008_2023.xlsx", sheet("Data_relevant") firstrow clear
rename Year year
rename State statename
rename MeasureValues selfins
label var selfins "Percent enrollees in self-insured plans at establishments that offer health insurance (state/year)"
merge m:1 statename using "${lab}/reusable_files/Working/state_names_fips.dta"
drop _merge statename stateabbrev
order state year selfins

gen fullyins=(100-selfins)
label var fullyins "% enrollees in fully-insured plans"

replace selfins =selfins/100
replace fullyins = fullyins /100

sort state year
compress
save "meps.dta", replace


************************************************************************************************************
/*Set up hearing aid policy file containing private & Medicaid hearing aid mandates
so that 1 obs = 1 state/year and years and limited to our study period
*/
************************************************************************************************************
use "${lab}/reusable_files/hearing_aid_core/hearingaidpolicy_2026.03.dta", clear

keep state year quarter aud_mcaid_mand  aud_priv_mand  aud_priv_agemax
numlabel, add

collapse (mean) aud_mcaid_mand aud_priv_mand aud_priv_agemax , by( state year)
keep if year>2007 & year<2024

*Fix Medicaid - 
rename aud_mcaid_mand mcaid_mand0


*Fix Private
rename aud_priv_mand priv_mand0
*ta aud_priv_agemax, missing /*wonky age after averaging to quarter level- fix for Maine*/
*ta state year if aud_priv_agemax==38.25
replace aud_priv_agemax=18 if state==23 & year==2019
rename aud_priv_agemax priv_agemax

sort state year
compress
save "mand.dta", replace

**********************
***Appendix Table 2***
**********************
*keep if quarter == 1
*collapse (max) aud_priv_mand aud_mcaid_mand, by(state year)
tostring state, gen(statefips) format(%02.0f)
gen Division= "."
replace Division = "New England" if inlist(statefips, "09", "23", "25", "33", "44", "50")
replace Division = "Middle Atlantic" if inlist(statefips, "34", "36", "42")
replace Division = "East North Central" if inlist(statefips, "17", "18", "26", "39", "55")
replace Division = "West North Central" if inlist(statefips, "19", "31", "20", "27", "29", "38", "46")
replace Division = "South Atlantic" if inlist(statefips, "10", "11", "12", "13", "24", "37", "45", "51", "54")
replace Division = "East South Central" if inlist(statefips, "01", "21", "28", "47")
replace Division = "West South Central" if inlist(statefips, "05", "22", "40", "48")
replace Division = "Mountain" if inlist(statefips, "04", "08", "16", "30", "32", "35", "49", "56")
replace Division = "Pacific" if inlist(statefips, "02", "06", "15", "41", "53")

gen Region = "Northeast" if inlist(Division, "New England", "Middle Atlantic")
replace Region = "Midwest" if inlist(Division, "East North Central", "West North Central")
replace Region = "South" if inlist(Division, "South Atlantic", "East South Central", "West South Central")
replace Region = "West" if inlist(Division, "Mountain", "Pacific")

keep if year == 2008 | year == 2023 
gen aud_mcaid_mand = 0
replace aud_mcaid_mand = 1 if mcaid_mand0 == 1 
gen aud_priv_mand = 0
replace aud_priv_mand = 1 if priv_mand0 == 1 

sort Region statefips year

bys Region year: egen region_mcaid_mand = sum(aud_mcaid_mand)
bys Region year: egen region_priv_mand = sum(aud_priv_mand)


/*
distinct state if year == 2008 & Region == "Northeast" & priv_mand0 > 0
distinct state if year == 2023 & Region == "Northeast" & priv_mand0 > 0

distinct state if year == 2008 & Region == "Northeast" & mcaid_mand0 > 0
distinct state if year == 2023 & Region == "Northeast" & mcaid_mand0 > 0

distinct state if year == 2008 & Region == "Midwest" & priv_mand0 > 0
distinct state if year == 2023 & Region == "Midwest" & priv_mand0 > 0

distinct state if year == 2008 & Region == "Midwest" & mcaid_mand0 > 0
distinct state if year == 2023 & Region == "Midwest" & mcaid_mand0 > 0

distinct state if year == 2008 & Region == "South" & priv_mand0 > 0
distinct state if year == 2023 & Region == "South" & priv_mand0 > 0

distinct state if year == 2008 & Region == "South" & mcaid_mand0 > 0
distinct state if year == 2023 & Region == "South" & mcaid_mand0 > 0

distinct state if year == 2008 & Region == "West" & priv_mand0 > 0
distinct state if year == 2023 & Region == "West" & priv_mand0 > 0

distinct state if year == 2008 & Region == "West" & mcaid_mand0 > 0
distinct state if year == 2023 & Region == "West" & mcaid_mand0 > 0
*/

************************************************************************************************************
*Grab what we need from ACS data
************************************************************************************************************
*Downloaded from https://usa.ipums.org/usa/
use "${lab}/reusable_files/IPUMS_USA/usa_00026.dta", clear
gen tag = 1
bys serial year: egen hhrespondents = sum(tag)
keep year serial statefip perwt age hcovany hcovpriv hinsemp hinspur hinstri hcovpub hinscaid hinscare hinsva hinsihs offpov hhincome inctot ownershp /*Adding Austin's table variables here as of 7/16/2026*/ offpov inctot hhincome ownershp educ empstat race racwht hispan hhrespondents

*insurance variable starts in 2008
drop if year<2008
rename statefip state

*Merge Medicaid and private mandates - from core file
merge m:1 year state using "mand.dta"
drop _merge

gen long id = _n 
isid id

*age category variables
gen agegrp=1 if age <18 & !missing(age)
replace agegrp=2 if age>=18 & age<65
replace agegrp=3 if age>64 & !missing(age)
label define agegrp 1 "Youth <18" 2 "Adults 18-64" 3 "Age 65+"
label var agegrp "Age group"
label values agegrp agegrp
numlabel, add

*Be careful - IPUMS USA coding is weird where 1 = NO - Recode
label define binary 0 "No" 1 "Yes"
foreach x in   hcovany hcovpriv hinsemp hinspur hinstri hcovpub hinscaid hinscare hinsva hinsihs {
	replace `x'=0 if `x'==1
	replace `x'=1 if `x'==2
	label values `x' binary
}


*Make a new version of private insurance WITHOUT tricare
gen private=0
replace private=1 if hinsemp==1| hinspur==1
label var private "Private insurace: Employer or purchased ONLY" 

/*Private mandate indicator set up. (We'll worry about making these indicators mutually exclusive later) 
So far priv_mand0 = is there a mandate in place relevant to this person's state and year
privmand = is there a mandate in place relevant to this person's state and year AND AGE AND INSURANCE */
gen privmand=0
label var privmand "Private mandate indicator: age, & insurance status"
replace privmand=priv_mand0 if private==1 & ( age<=priv_agemax) & !missing(age) &  !missing(priv_agemax) /*There are no minimum ages*/

*Maine has >18 year olds as of 9/19/2019. 
*Note: IL & CT are the other states that have a second adoption date for a different age group. But those 2 have January adoption dates so we don't need to worry about partial year for a specific age group - indicator can just be 1 for everyone. 
replace privmand=1-((9-1)/12) if year==2019 & state==23 & age>=19 & !missing(age) & private==1


/*Medicaid mandate indicator set up */
*Everyone < age 21 is covered
gen mcaidmand=0
replace mcaidmand=mcaid_mand0 if hinscaid==1 /*All adults with Medicaid*/
replace mcaidmand=1 if hinscaid==1  & age<21 /*All people through age 20 with Medicaid are covered nationally */


*Merge in MEPS & deal with self vs fully insured issue for private mandates
merge m:1 year state using "meps.dta"
drop _merge

*Let's take privmand which accounts for the fraction of the year a mandate was in place for the age/state/year, and make 2 new indicators where 1 is the proportion of self-insured and 1 is the proportion of fully insured. So now each person living under private insurance mandate starts counting for 2 types of people - a fraction of them towards covered and a fraction towards not covered private folks.

gen privfull=privmand*fullyins
label var privfull "Under applicable private mandate, fully-insured plans"

gen privself=privmand*selfins
label var privself "Under applicable private mandate, self-insured plans"

save "pregrouping_${today}.dta", replace
**********************************************
**********************************************
/*Define our insurance groups and apply 
insurance hierarchies for each age group, 
one at a time.*/
**********************************************
**********************************************

**********************************************
**********************************************
**********************************************
/* <18 and 18-64 groups */
**********************************************
**********************************************
**********************************************

keep if agegrp==1| agegrp==2

***Group: uninsured - should have no overlap with anyone except IHS. IPUMS USA considers IHS uninsured but we don't.
gen h_unins=0 if hcovany==1|hinsihs==1
replace h_unins=1 if hcovany==0 & hinsihs!=1

***Group: VA
gen h_va=0
replace h_va=1 if hinsva==1 

***Group: private insurance covered OR TRICARE - we set up fully insured indicator already - trumps almost everything except VA. This'll be a fraction.
gen h_privfull=privfull
replace h_privfull=1 if hinstri==1
replace privself=0  if hinstri==1 /*If someone has Tricare, they are a full "1" for full, becuase they shouldn't also count towards self-insured */
replace h_privfull=0 if h_va==1

*ta h_privfull h_va, missing

***Group:  Medicaid covered - we set this up already. Replace with 0 if privately or VA or TRICARE insured and covered to make mutually exclusive.
gen h_mcaidmand=mcaidmand
replace h_mcaidmand=0 if  h_va==1|hinstri==1

/*Take care of complicated cases where people have both private & Medicaid.
What happens if they have both for the full year?
Private fully insured takes precedence. For the private self-insured portion: all of it should go to Medicaid covered instead of private not covered.

What happens when mandates go into effect partway through the year? 
If a private mandate goes into effect partway through the year and they ARE covered under Medicaid, the rest of the year should = covered by Medicaid. PLUS the self-insured part of the private part of the year should count towards covered by Medicaid group. Sum these 2.
If a private mandate goes into effect partway through the year and they ARE NOT covered under Medicaid, then: Part of the year w/o priv = Private not covered. Part of the year with private - fully insured piece gets full dibs again for that piece of the year, and the self-insured piece goes to private not covered.
If a Medicaid mandate goes into effect partway through the year and they ARE covered under private, the fully insured piece gets first dibs - Mcaid going into effect doesn't matter to them. PART of the self-insured piece should go under Medicaid covered by mandate (* part of the year that Medicaid is in effect) and PART of the self-insured piece should go under private no mandate (* rest of the year where Medicaid is not in effect).
If a Medicaid mandate goes into effect partway through the year and they ARE NOT covered under private, then part of the year = covered by Medicaid mandate and the rest of the year = private not covered.
*/
*There's no year where both Mcaid and private go into effect partyway through the year.


*Private & Medicaid folks where both are in place the full year. The self-insured private portion of the person needs to go here and NOT in the private not covered bucket because Medicaid covered trumps private not covered in the hierarchy.
replace h_mcaidmand =privself if (privmand==1 &  mcaidmand==1) /*both full year, no frac*/ & hinscaid==1 &  private==1 & h_va==0 & hinstri==0

*If a private mandate goes into effect partway through the year and they ARE covered under Medicaid the full year, the rest of the year before the private mandate goes into effect should = covered by Medicaid. PLUS the self-insured part of the private part of the year should count towards covered by Medicaid group. Sum these 2.
replace h_mcaidmand = (1-privmand) + privself if (privmand>0 & privmand<1 &  mcaidmand==1) /*Mcaid full year cov, Priv fraction*/ & hinscaid==1 &  private==1  & h_va==0 & hinstri==0

*If a Medicaid mandate goes into effect partway through the year and they ARE covered under private, the fully insured piece takes precedence the whole period. For that year, PART of the private self-insured piece should go under Medicaid covered by mandate (* part of the year that Medicaid is in effect) and PART of the self-insured piece should go under private no mandate (* rest of the year where Medicaid is not in effect).
replace h_mcaidmand = privself*mcaidmand if (privmand==1 &  mcaidmand>0 & mcaidmand<1) & hinscaid==1 &  private==1 & h_va==0 & hinstri==0

***Group: private insurance not covered (whether because of self-insured or not living in the right state or the right age) PLUS IHS. Includes:
/*1) Private not covered because living in the wrong place/ age
2) Self-insured private not covered
3) IHS not covered - ONLY in this category if they aren't also in the first 2.

Value should be 1 (or fraction if partial year) for privately insured people not under any mandate. Should be 0 for: 1) people with other insurance types, and 2) people with private insurance with a mandate. Let's go through all the permutations/ scenarios:
*/
gen privnomand=0

*Private not covered and no Medicaid coverage at all
replace privnomand=1 if privmand==0 &  h_mcaidmand==0 & private==1 & h_va==0 & hinstri==0
*Private insurance only & full year adoption
replace privnomand=privself if h_mcaidmand==0 & private==1 & h_va==0 & privmand==1 & hinstri==0
*Private insurance only & partial year adoption
replace privnomand=privself + (1-privmand) if h_mcaidmand==0 & private==1 & h_va==0 & hinstri==0 & privmand>0 &  privmand<1 

/*Sort out folks with both private & Medicaid insurance*/
*What happens if they have both priv & mcaid coverage for the full year? Private fully insured = first dibs. For the self-insured portion, all of it should go to Medicaid covered instead of private not covered. Nothing to do here.

*If a private mandate goes into effect partway through the year and they ARE covered under Medicaid, nothing goes here - Medicaid group & private fully-insured coverage group take precedence.

*If a private mandate goes into effect partway through the year and they ARE NOT covered under Medicaid, then: Part of the year w/o priv = Private not covered. Part of the year with private - fully insured piece takes precedence for that piece of the year, and the self-insured piece goes to private not covered.
replace privnomand=(1-privmand)+privself if (privmand>0 & privmand<1 & mcaidmand==0) & hinscaid==1 & private==1 & h_va==0& hinstri==0 

*If a Medicaid mandate goes into effect partway through the year and they ARE covered under private, the fully insured piece takes precedence. PART of the self-insured piece should go under Medicaid covered by mandate (* part of the year that Medicaid is in effect) and PART of the self-insured piece should go under private no mandate (* rest of the year where Medicaid is not in effect).
replace privnomand=(1-mcaidmand)*privself if (privmand==1 & mcaidmand>0 & mcaidmand<1) & hinscaid==1 & private==1 & h_va==0& hinstri==0 

*If a Medicaid mandate goes into effect partway through the year and they ARE NOT covered under private, then part of the year = covered by Medicaid mandate and the rest of the year = private not covered.
replace privnomand=1-mcaidmand if (privmand==0 & mcaidmand>0 & mcaidmand<1) & hinscaid==1 & private==1 & h_va==0& hinstri==0 

*Folks with IHS  only. We don't care if they have Medicare too, or Medicaid too if not covered by it. We do not want to them to have Mcaid covereage, private insurance at all, or VA or TRICARE to be eligible to be part of this group.
gen ihs_nc=0
replace ihs_nc=1 if hinsihs==1 & h_va==0 & h_mcaidmand==0 & private==0  & hinstri==0
*What if they have Medicaid for part of the year? Then a fraction of year goes towards Medicaid covered and the other fraction towards private no mandate
replace ihs_nc=1-mcaidmand if hinsihs==1 & h_va==0  & hinstri==0 & h_mcaidmand>0 & h_mcaidmand<1 & private==0
label var ihs_nc "IHS (no private at all, no HA cov through other ins)"


*Check
gen h_privnocov=privnomand+ihs_nc
label var h_privnocov "Private, not covered (privnomand+ihs_nc)"
*ta h_privnocov, missing


***Group: Medicaid insurance not covered. 
gen h_mcaidnomand=0
*Let's take care of Folks in this group who don't also have private. Also can't have Tricare, VA, or IHS because they'd go into the other categories.
*Full year adoption
replace h_mcaidnomand=1 if h_mcaidmand==0 & hinscaid==1 & private==0 & h_va==0 & hinstri==0 & ihs_nc==0
*partial year adoption
replace h_mcaidnomand =1-h_mcaidmand if h_mcaidmand>0 & h_mcaidmand<1 & hinscaid==1 & private==0  & h_va==0  & hinstri==0 & ihs_nc==0
label var  h_mcaidnomand "Medicaid no mandate, not part of previous group"



***Group: h_medicare - only counts towards this group if not a part of any other group.
gen h_medicare=0
replace h_medicare=1 if hinscare==1 & private==0 & hinscaid==0 & h_va==0 & hinstri==0 & ihs_nc==0



*Final check of all groups
set linesize 255
*listsome year state age mcaid_mand0 priv_mand0 priv_agemax h_unins h_va h_privfull h_mcaidmand h_privnocov h_mcaidnomand h_medicare private hinstri hinscaid hinscare hinsva hinsihs privnomand   ihs_nc, random
egen totcheck=rowtotal(h_unins h_va h_privfull h_mcaidmand h_privnocov h_mcaidnomand h_medicare)
*ta totcheck, missing /*We want this to about total 1 */


compress
save "Youngeracsindicators_${today}.dta", replace

/*Now I will get the population percentages for each group, by collapsing using survey weights from ACS*/
svyset [pweight=perwt]
***Appendix Table 1 for under 18 and 18-64 groups***
gen coverage=h_privfull+h_mcaidmand+h_va
bys agegrp year: sum coverage [aweight = perwt]
bys agegrp year: ci means coverage [aweight = perwt]
bys year: ci means h_mcaidmand [aweight=perwt]
bys agegrp year: ci means h_mcaidmand [aweight = perwt]
drop coverage 




foreach agegrp in 1 2 {
	preserve
	collapse (mean)  h_unins h_va h_privfull h_mcaidmand h_privnocov h_mcaidnomand h_medicare [pweight=perwt] if agegrp==`agegrp', by(year)

	*check - should add up to 100% more or less
	egen rowtotal=rowtotal(h_unins h_va h_privfull h_mcaidmand h_privnocov h_mcaidnomand h_medicare)
	*li year rowtotal	
	save age`agegrp'.dta, replace
	restore
}



/*Make the graphs for each dataset*/
foreach agegrp in 1 2  {
	if "`agegrp'"=="1" {
		local title="Youth <18"
	}
	else  {
		local title="Age 18-64"
	}
	
	display "AGE GROUP `agegrp'"
	use age`agegrp'.dta, clear
*We need to add them up to get the lines cumulative to display stacked in the correct order. Multiply by 100 to get whole number percentages
gen h_va_0=100*(h_va)
gen h_privfull_1=100*(h_privfull+h_va)
gen h_mcaidmand_2= 100*(h_privfull+h_mcaidmand+h_va)
gen h_privnocov_3 = 100*(h_privnocov+h_privfull+h_mcaidmand+h_va)
gen h_mcaidnomand_5=100*(h_privnocov+h_privfull+h_mcaidmand+h_mcaidnomand+h_va)
gen h_medicare_6=100*(h_privnocov+h_privfull+h_mcaidmand+h_mcaidnomand+h_medicare+h_va)
gen h_unins_7=100*(h_privnocov+h_privfull+h_mcaidmand+h_mcaidnomand+h_medicare+h_unins+h_va)

label var h_va_0 "Veterans' Administration"
label var h_privfull_1 "Private, fully-insured with age-eligible HA mandate; or Tricare"
label var h_mcaidmand_2 "Medicaid, with age-eligible HA policy"
label var h_privnocov_3  "Private, no HA mandate (age-ineligible, ERISA, or none); or IHS"
label var h_mcaidnomand_5 "Medicaid, without HA policy"
label var h_medicare_6 "Medicare"
label var h_unins_7 "Uninsured"

gen coverage=h_privfull+h_mcaidmand+h_va
label var coverage "Combined: covered by private mandate, Medicaid, VA, or Tricare"

*Raw values
display "`title'"
li year h_va h_privfull h_mcaidmand h_privnocov h_mcaidnomand h_medicare h_unins rowtotal coverage

save "collapsed`agegrp'_${today}.dta", replace
}


/*Make 18-64 graph */
use "collapsed2_${today}.dta", clear


*greyscale
twoway (area h_unins_7 h_medicare_6 h_mcaidnomand_5 h_privnocov_3 h_mcaidmand_2 h_privfull_1 h_va_0 year, graphregion(color(white)) xlabel(,grid glstyle(dot)) ylabel(,grid glstyle(dot)) /*title("Age 18-64")*/ ytitle("Percent") ylabel(0(10)100) xtitle("Year")  xscale(titlegap(*2)) xlabel(2008(1)2023) color(gs2 gs7 gs10 gs13 gs16 gs17 gs18 )) ///
		(function y = 0, range(2008 2023) color(black) lstyle(dot)) 		/*horizontal lines. y= line location. range= length of line based on x axis values */ ///
		(function y = 10, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 20, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 30, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 40, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 50, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 60, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 70, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 80, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 90, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 100, range(2008 2023) color(black) lstyle(dot)) ///
		(scatteri 0 2008 100 2008, recast(line) color(black) lstyle(dot)) /*scatteri manually type in Y value and X value of each point, then recast connects them*/ ///
		(scatteri 0 2009 100 2009, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2010 100 2010, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2011 100 2011, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2012 100 2012, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2013 100 2013, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2014 100 2014, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2015 100 2015, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2016 100 2016, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2017 100 2017, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2018 100 2018, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2019 100 2019, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2020 100 2020, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2021 100 2021, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2022 100 2022, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2023 100 2023, recast(line) color(black) lstyle(dot)), legend(order (1 2 3 4 5 6 7) position(6))
graph save "mandins2_g_${today}", replace
graph export "mandins2_g_${today}.jpg", as(jpg) replace

*color
twoway (area h_unins_7 h_medicare_6 h_mcaidnomand_5 h_privnocov_3 h_mcaidmand_2 h_privfull_1 h_va_0 year, graphregion(color(white)) xlabel(,grid glstyle(dot)) ylabel(,grid glstyle(dot)) /*title("Age 18-64")*/ ytitle("Percent") ylabel(0(10)100) xtitle("Year")  xscale(titlegap(*2)) xlabel(2008(1)2023) color(lavender purple blue green yellow red brown )) ///
		(function y = 0, range(2008 2023) color(black) lstyle(dot)) 		/*horizontal lines. y= line location. range= length of line based on x axis values */ ///
		(function y = 10, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 20, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 30, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 40, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 50, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 60, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 70, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 80, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 90, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 100, range(2008 2023) color(black) lstyle(dot)) ///
		(scatteri 0 2008 100 2008, recast(line) color(black) lstyle(dot)) /*scatteri manually type in Y value and X value of each point, then recast connects them*/ ///
		(scatteri 0 2009 100 2009, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2010 100 2010, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2011 100 2011, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2012 100 2012, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2013 100 2013, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2014 100 2014, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2015 100 2015, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2016 100 2016, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2017 100 2017, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2018 100 2018, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2019 100 2019, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2020 100 2020, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2021 100 2021, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2022 100 2022, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2023 100 2023, recast(line) color(black) lstyle(dot)), legend(order (1 2 3 4 5 6 7) position(6))
graph save "mandins2_c_${today}", replace
graph export "mandins2_c_${today}.jpg", as(jpg) replace




/*Make Youth <18 graph without Medicaid h_uninsured group */
use "collapsed1_${today}.dta", clear
*greyscale
twoway (area h_unins_7 h_medicare_6  h_privnocov_3 h_mcaidmand_2 h_privfull_1 h_va_0 year, graphregion(color(white)) xlabel(,grid glstyle(dot)) ylabel(,grid glstyle(dot))  /*title("Youth <18")*/ ytitle("Percent") ylabel(0(10)100) xtitle("Year")  xscale(titlegap(*2)) xlabel(2008(1)2023) color(gs2 gs7 gs13 gs16 gs17 gs18 )) ///
		(function y = 0, range(2008 2023) color(black) lstyle(dot)) 		/*horizontal lines. y= line location. range= length of line based on x axis values */ ///
		(function y = 10, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 20, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 30, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 40, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 50, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 60, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 70, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 80, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 90, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 100, range(2008 2023) color(black) lstyle(dot)) ///
		(scatteri 0 2008 100 2008, recast(line) color(black) lstyle(dot)) /*scatteri manually type in Y value and X value of each point, then recast connects them*/ ///
		(scatteri 0 2009 100 2009, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2010 100 2010, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2011 100 2011, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2012 100 2012, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2013 100 2013, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2014 100 2014, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2015 100 2015, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2016 100 2016, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2017 100 2017, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2018 100 2018, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2019 100 2019, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2020 100 2020, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2021 100 2021, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2022 100 2022, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2023 100 2023, recast(line) color(black) lstyle(dot)), legend(order (1 2 3 4 5 6) position(6))
graph save "mandins1_g_few_${today}", replace
graph export "mandins1_g_few_${today}.jpg", as(jpg) replace

*color
twoway (area h_unins_7 h_medicare_6 h_privnocov_3 h_mcaidmand_2 h_privfull_1 h_va_0  year, graphregion(color(white)) xlabel(,grid glstyle(dot)) ylabel(,grid glstyle(dot)) /*title("Youth <18")*/ ytitle("Percent") xtitle("Year") ylabel(0(10)100) xscale(titlegap(*2)) xlabel(2008(1)2023) color(lavender purple green yellow red brown ))  ///
		(function y = 0, range(2008 2023) color(black) lstyle(dot)) 		/*horizontal lines. y= line location. range= length of line based on x axis values */ ///
		(function y = 10, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 20, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 30, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 40, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 50, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 60, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 70, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 80, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 90, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 100, range(2008 2023) color(black) lstyle(dot)) ///
		(scatteri 0 2008 100 2008, recast(line) color(black) lstyle(dot)) /*scatteri manually type in Y value and X value of each point, then recast connects them*/ ///
		(scatteri 0 2009 100 2009, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2010 100 2010, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2011 100 2011, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2012 100 2012, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2013 100 2013, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2014 100 2014, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2015 100 2015, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2016 100 2016, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2017 100 2017, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2018 100 2018, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2019 100 2019, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2020 100 2020, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2021 100 2021, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2022 100 2022, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2023 100 2023, recast(line) color(black) lstyle(dot)), legend(order (1 2 3 4 5 6) position(6))
	
		
graph save "mandins1_c_few_${today}", replace
graph export "mandins1_c_few_${today}.jpg", as(jpg) replace



*********************************************
/* age 65+ group */
use "pregrouping_${today}.dta", clear

keep if agegrp==3


*Tricare people should contribute a full 1 towards either Medicare + private or Private groups - so shouldn't also contribute a fraction anywhere else*/
replace privself=0  if hinstri==1 /*If someone has Tricare, they are a full 1 for full, shouldn't also count towards self */

*there are no folks who ONLY have Medicaid + Private but no Medicare, so we don't have to worry about that scenario

***Group: uninsured - should have no overlap with anyone except IHS. IPUMS USA considers IHS uninsured but we don't.
gen h_unins=0 if hcovany==1|hinsihs==1
replace h_unins=1 if hcovany==0 & hinsihs!=1

***Group: VA
gen h_va=0
replace h_va=1 if hinsva==1 

***Group:  Medicaid covered - we set this up already. replace with 0 if privately or VA insured and covered to make mutually exclusive.
gen h_mcaidmand=mcaidmand
replace h_mcaidmand=0 if  h_va==1


***Group: Medicare + supplemental private (doesn't matter if the private covers HA or not). This could also be Medicare + TRICARE
gen h_mcarepriv=0
replace h_mcarepriv=1 if  hinscare==1 & (private==1 | hinstri==1 )& h_mcaidmand==0 & h_va==0
replace h_mcarepriv=1-h_mcaidmand if hinscare==1 & (private==1 | hinstri==1 ) & hinscaid==1 & h_mcaidmand>0 & h_mcaidmand<1 & h_va==0  /*partial year Medicaid adoption for dual eligibles that also have supplemental private where part of the year has Medicaid HA coverage */


***Group: h_mcare with no supplemental private (doesn't matter what else they have - just something else other than previous sections. So they can have just Medicare, Medicare + IHS, Medicare + Medicaid that does not cover HA. They cannot have Medicare + private, or Medicare _+tricare, or VA, or Medicaid that covers HA.)
gen h_mcare=0
replace h_mcare=1 if hinscare==1 & private==0 & h_mcaidmand==0 & h_va==0 & hinstri==0
replace h_mcare=1-h_mcaidmand if hinscare==1 & private==0 & hinstri==0 & hinscaid==1 & h_mcaidmand>0 & h_mcaidmand<1 & h_va==0  /*partial year Medicaid adoption for dual eligibles where part of the year has Medicaid HA coverage */


***Group: private insurance covered - set up fully insured indicator already. This'll be a fraction UNLESS Tricare, which is now also in this category
gen h_privfull=privfull
replace  h_privfull=1 if hinstri==1 & h_va==0 & hinscare==0 & h_mcaidmand==0 /*Shouldn't be in the private covered group if they have VA, Medicare, or Medicaid*/
replace h_privfull=0 if h_va==1 | hinscare==1| h_mcaidmand==1 /*I don't have to worry about anyone having only Mcaid and private coverage because they don't exist without Medicare too */


***Group: private insurance not covered (whether because of self-insured or not living in the right state of the right age) PLUS IHS. NO LONGER INCLUDES TRICARE here This is tricky!! Let's take it 1 component at a time - we will need the 3 components to be mutually exclusive (or can be in 1st 2 groups if it adds up to <=1) so we can sum them...we can't just "or" them all into a single indicator because the fractions are complicated.
/*1) Private not covered because living in the wrong place
2) Self-insured private not covered
3) IHS not covered - ONLY in this category if they aren't also in the first 2.
*/

*private insurance not covered - should be 1 (or fraction if partial year) for privately insured people not under any mandate. Should be 0 for: 1) people with other insurance types, and 2) people with private insurance with a mandate. Let's go through all the permutations/ scenarios
gen privnomand=0

*Folks with just private, or private and no Medicaid coverage at all
replace privnomand=1 if privmand==0 &  h_mcaidmand==0 & private==1 & h_va==0 & hinscare==0 & hinstri==0
*Private insurance only & full year adoption
replace privnomand=privself if h_mcaidmand==0 & private==1 & h_va==0 & privmand==1 & hinscare==0 & hinstri==0
*Private insurance only & partial year adoption
replace privnomand=privself + (1-privmand) if h_mcaidmand==0 & private==1 & h_va==0 & privmand>0 &  privmand<1 & hinscare==0 & hinstri==0


*Folks with IHS  only. We don't care if they have Medicare too, or Medicaid too if not covered by it. We do not want to them to have Mcaid covereage, private insurance at all, or VA or TRICARE
gen ihs_nc=0
replace ihs_nc=1 if hinsihs==1 & h_va==0 & h_mcaidmand==0 & private==0 & hinscare==0 & hinstri==0

label var ihs_nc "IHS (no other ins)"

*Can we add them up? Check - makes sense?
gen h_privnocov=privnomand+ihs_nc
label var h_privnocov "Private, not covered (privnomand+ihs_nc)"


***Group: Medicaid insurance not covered. Should be a very small group at this point, since previous groups already include everyone with: VA, uninsured, Medicare, private insurance, IHS, Tricare. So really the only folks left are people with Medicaid only who aren't covered.
gen h_mcaidnomand=0
*Full year adoption
replace h_mcaidnomand=1 if h_mcaidmand==0 & hinscaid==1 & private==0 & h_va==0 & hinsihs==0 & hinscare==0 & hinstri==0

label var  h_mcaidnomand "Medicaid no mandate, not part of previous group"



*Final check of all groups
egen totcheck=rowtotal(  h_unins h_va h_mcaidmand h_mcarepriv h_mcare h_privfull h_privnocov h_mcaidnomand)
*ta totcheck, missing /*We want this to about total 1 */
set linesize 255
*listsome year state age mcaid_mand0 priv_mand0 privmand priv_agemax  h_va h_mcaidmand h_mcarepriv h_mcare h_privfull h_privnocov h_mcaidnomand private hinstri hinscaid hinscare hinsva hinsihs privnomand  h_unins, random
assert totcheck>.99 & !missing(totcheck) 

save "olderacsindicators_${today}.dta", replace



/*Now I will get the population percentages, by collapsing*/
svyset [pweight=perwt]
***After the fact, gen SE for our collapsed sum stats***
gen coverage=h_privfull+h_mcaidmand+h_va
bys agegrp year: sum coverage [aweight = perwt]
bys agegrp year: ci means coverage [aweight = perwt]
drop coverage 
bys year: ci means h_mcaidmand [aweight=perwt]
bys agegrp year: ci means h_mcaidmand [aweight = perwt]
collapse (mean)  h_unins h_va h_mcaidmand h_mcarepriv h_mcare  h_privfull h_privnocov h_mcaidnomand [pweight=perwt] if agegrp==3, by(year)
	
	*check - should add up to 100% more or less
	egen rowtotal=rowtotal( h_unins h_va h_mcaidmand h_mcarepriv h_mcare  h_privfull h_privnocov h_mcaidnomand)
	*li year rowtotal	
	save age3.dta, replace


*Order of lines: Private covered, Medicaid covered, private not covered because of state, private not covered because self-insured, Medicaid not covered, medicare, h_uninsured
*We need to add them up to get the lines cumulative. Let's also multiply by 100 to get whole number percentages
gen h_va_0=100*(h_va)
gen h_privfull_1=100*(h_privfull+h_va)
gen h_mcaidmand_2= 100*(h_privfull+h_mcaidmand+h_va)
gen h_privnocov_3 = 100*(h_privnocov+h_privfull+h_mcaidmand+h_va)
gen h_mcaidnomand_4=100*(h_privnocov+h_privfull+h_mcaidmand+h_mcaidnomand+h_va)
gen h_mcare_5=100*(h_privnocov+h_privfull+h_mcaidmand+h_mcaidnomand+h_mcare+h_va)
gen h_mcarepriv_6 =100*(h_privnocov+h_privfull+h_mcaidmand+h_mcaidnomand+h_mcare+h_mcarepriv+h_va)
gen h_unins_7=100*(h_privnocov+h_privfull+h_mcaidmand+h_mcaidnomand+h_mcare+h_mcarepriv+h_unins+h_va)

label var h_va_0 "Veterans' Administration"
label var h_privfull_1 "Private, fully-insured with age-eligible HA mandate; or Tricare"
label var h_mcaidmand_2 "Medicaid, with age-eligible HA policy"
label var h_privnocov_3  "Private, no HA mandate (age-ineligible, ERISA, or none); or IHS"
label var h_mcaidnomand_4 "Medicaid, without HA policy"
label var h_mcare_5 "Medicare w/out supplemental private nor Tricare"
label var h_mcarepriv_6 "Medicare + supplemental private or Tricare"
label var h_unins_7 "Uninsured"


gen coverage=h_privfull+h_mcaidmand+h_va
label var coverage "Combined: covered by private mandate, Medicaid mandate, VA, Tricare"

*greyscale
twoway (area h_unins_7 h_mcarepriv_6 h_mcare_5 h_mcaidnomand_4 h_privnocov_3 h_mcaidmand_2 h_privfull_1 h_va_0  year, graphregion(color(white))  xlabel(,grid glstyle(dot)) ylabel(,grid glstyle(dot) )  /* title("Age 65+")*/ ytitle("Percent") ylabel(0(20)100) xtitle("Year")  xscale(titlegap(*2)) xlabel(2008(1)2023) color(gs2 gs4 gs7 gs10 gs13 gs16 gs17 gs18 )) ///
		(function y = 0, range(2008 2023) color(black) lstyle(dot)) 		/*horizontal lines. y= line location. range= length of line based on x axis values */ ///
		(function y = 10, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 20, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 30, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 40, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 50, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 60, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 70, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 80, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 90, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 100, range(2008 2023) color(black) lstyle(dot)) ///
		(scatteri 0 2008 100 2008, recast(line) color(black) lstyle(dot)) /*scatteri manually type in Y value and X value of each point, then recast connects them*/ ///
		(scatteri 0 2009 100 2009, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2010 100 2010, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2011 100 2011, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2012 100 2012, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2013 100 2013, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2014 100 2014, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2015 100 2015, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2016 100 2016, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2017 100 2017, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2018 100 2018, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2019 100 2019, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2020 100 2020, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2021 100 2021, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2022 100 2022, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2023 100 2023, recast(line) color(black) lstyle(dot)), legend(margin(l=0.5) order (1 2 3 4 5 6 7 8) position(6))
graph save "mandins3_g_${today}", replace
graph export "mandins3_g_${today}.jpg", as(jpg) replace

*color
twoway (area h_unins_7 h_mcarepriv_6 h_mcare_5 h_mcaidnomand_4 h_privnocov_3 h_mcaidmand_2 h_privfull_1 h_va_0  year, graphregion(color(white))  xlabel(,grid glstyle(dot)) ylabel(,grid glstyle(dot) )   /*title("Age 65+")*/ ytitle("Percent") ylabel(0(10)100) xtitle("Year")  xscale(titlegap(*2)) xlabel(2008(1)2023) color(lavender orange purple blue green yellow red brown)) ///
		(function y = 0, range(2008 2023) color(black) lstyle(dot)) 		/*horizontal lines. y= line location. range= length of line based on x axis values */ ///
		(function y = 10, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 20, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 30, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 40, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 50, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 60, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 70, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 80, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 90, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 100, range(2008 2023) color(black) lstyle(dot)) ///
		(scatteri 0 2008 100 2008, recast(line) color(black) lstyle(dot)) /*scatteri manually type in Y value and X value of each point, then recast connects them*/ ///
		(scatteri 0 2009 100 2009, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2010 100 2010, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2011 100 2011, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2012 100 2012, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2013 100 2013, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2014 100 2014, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2015 100 2015, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2016 100 2016, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2017 100 2017, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2018 100 2018, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2019 100 2019, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2020 100 2020, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2021 100 2021, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2022 100 2022, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2023 100 2023, recast(line) color(black) lstyle(dot)) , legend(margin(l=0.5) order (1 2 3 4 5 6 7 8) position(6)) 
graph save "mandins3_c_${today}", replace
graph export "mandins3_c_${today}.jpg", as(jpg) replace


*color, trying to get y axis to be less squished
twoway (area h_unins_7 h_mcarepriv_6 h_mcare_5 h_mcaidnomand_4 h_privnocov_3 h_mcaidmand_2 h_privfull_1 h_va_0  year, graphregion(color(white))  xlabel(,grid glstyle(dot)) ylabel(,grid glstyle(dot) )   /*title("Age 65+")*/ ytitle("Percent") ylabel(0(10)100) xtitle("Year")  xscale(titlegap(*2)) xlabel(2008(1)2023) color(lavender orange purple blue green yellow red brown)) ///
		(function y = 0, range(2008 2023) color(black) lstyle(dot)) 		/*horizontal lines. y= line location. range= length of line based on x axis values */ ///
		(function y = 10, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 20, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 30, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 40, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 50, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 60, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 70, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 80, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 90, range(2008 2023) color(black) lstyle(dot)) ///
		(function y = 100, range(2008 2023) color(black) lstyle(dot)) ///
		(scatteri 0 2008 100 2008, recast(line) color(black) lstyle(dot)) /*scatteri manually type in Y value and X value of each point, then recast connects them*/ ///
		(scatteri 0 2009 100 2009, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2010 100 2010, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2011 100 2011, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2012 100 2012, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2013 100 2013, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2014 100 2014, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2015 100 2015, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2016 100 2016, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2017 100 2017, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2018 100 2018, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2019 100 2019, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2020 100 2020, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2021 100 2021, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2022 100 2022, recast(line) color(black) lstyle(dot)) ///
		(scatteri 0 2023 100 2023, recast(line) color(black) lstyle(dot)), /*leg(off)*/  legend(margin(l=0.5) order (1 2 3 4 5 6 7 8) position(6)) 
graph save "mandins3_c_ns_${today}", replace
graph export "mandins3_c_ns_${today}.jpg", as(jpg) replace


*Raw values
display "Age 65+"
li year h_va h_privfull h_mcaidmand h_privnocov h_mcaidnomand h_mcare h_mcarepriv h_unins rowtotal coverage

save "collapsed3_${today}.dta", replace

/*
****************************************************************
***Table 3, uses an append of age1, age2 and age3 into ageall***
****************************************************************

***Request from Mike to study interaction term***
***UPDATE THIS PATH ?? 
use "${lab}/Phillips/hearing_aids/paper3/Working/ageall.dta", clear
***There are three age groups, and three age group vars each using a different group as the reference***
***agegroup: 1= under 18, 2 = 18-64, 3 = over 65
***agegroup1: 1 = over 65, 2 = 18-64, 3 = under 18
***agegroup2: 1= 18-64, 2 = 65 and over, 3 = 18-64
label var agegroup "1= under 18, 2 = 18-64, 3 = over 65"
label var agegroup1 "1 = over 65, 2 = 18-64, 3 = under 18"
label var agegroup2 "= 18-64, 2 = 65 and over, 3 = 18-64"
reg coverage i.agegroup1##c.year, robust


*************
***Table 4***
*************

use "${lab}/reusable_files/IPUMS_USA/usa_00026.dta", clear
keep if year == 2023

gen agegroup = 1 if age < 18
replace agegroup = 2 if inrange(age, 18, 64)
replace agegroup = 3 if age >= 65


* --- Excel output ---

putexcel set "HearingDemogNew.xlsx", sheet("TableNew") replace open

putexcel C1 = "Under 18"  G1 = "Adult 18-64"  K1 = "Over 65"

putexcel A2 = "Variable"   B2 = "measure"                                        ///
    C2 = "no coverage"  D2 = "coverage"  E2 = "difference"  F2 = "pr(diff=0)"   ///
    G2 = "no coverage"  H2 = "coverage"  I2 = "difference"  J2 = "pr(diff=0)"   ///
    K2 = "no coverage"  L2 = "coverage"  M2 = "difference"  N2 = "pr(diff=0)"

putexcel A3  = "In Poverty (%)"              B3  = "mean"  B4  = "s.e."  B5  = "n"
putexcel A6  = "Annual Personal Income ($)"
putexcel A7  = "<100% FPL"                   B7  = "mean"  B8  = "s.e."  B9  = "n"
putexcel A10 = ">=100% FPL"                  B10 = "mean"  B11 = "s.e."  B12 = "n"
putexcel A13 = "Annual Household Income($)"
putexcel A14 = "<100% FPL"                   B14 = "mean"  B15 = "s.e."  B16 = "n"
putexcel A17 = ">=100% FPL"                  B17 = "mean"  B18 = "s.e."  B19 = "n"
putexcel A20 = "Homeowner (%)"
putexcel A21 = "<100% FPL"                   B21 = "mean"  B22 = "s.e."  B23 = "n"
putexcel A24 = ">=100% FPL"                  B24 = "mean"  B25 = "s.e."  B26 = "n"

putexcel A27 = "Note: Poverty defined by the U.S. Census Bureau official poverty measure for the year 2023."

* --- Fill statistics ---
* Column layout per age group:  no_cov | cov | diff | pval
*   Under 18:    C  D  E  F   (base col = 3)
*   Adult 18-64: G  H  I  J   (base col = 7)
*   Over 65:     K  L  M  N   (base col = 11)

local colnames "A B C D E F G H I J K L M N"

forval ag = 1/3 {

    local bc = cond(`ag'==1, 3, cond(`ag'==2, 7, 11))
    local cn : word `bc'      of `colnames'   // no coverage
    local cc : word `=`bc'+1' of `colnames'   // coverage
    local cd : word `=`bc'+2' of `colnames'   // difference
    local cp : word `=`bc'+3' of `colnames'   // p-value

    * ---------------------------------------------------------------
    * In Poverty (%)  all observations, no poverty stratification
    * ---------------------------------------------------------------
    preserve
    drop if offpov == 9

    qui sum offpov if agegroup==`ag' & hcovany==1
    putexcel `cn'3 = (`r(mean)' * 100)
    putexcel `cn'4 = ("(" + string(`r(sd)' / sqrt(`r(N)') * 100, "%10.4g") + ")")
    putexcel `cn'5 = (`r(N)')

    qui sum offpov if agegroup==`ag' & hcovany==2
    putexcel `cc'3 = (`r(mean)' * 100)
    putexcel `cc'4 = ("(" + string(`r(sd)' / sqrt(`r(N)') * 100, "%10.4g") + ")")
    putexcel `cc'5 = (`r(N)')

    qui ttest offpov if agegroup==`ag', by(hcovany)
    putexcel `cd'3 = ((`r(mu_1)' - `r(mu_2)') * 100)
    putexcel `cp'3 = (`r(p)')

    restore

    * ---------------------------------------------------------------
    * Annual Personal Income  stratified by poverty
    * ---------------------------------------------------------------
    preserve
    drop if inctot < 0 | inctot == 9999999
    drop if offpov == 9

    foreach pov in 1 0 {                          // 1 = <100% FPL, 0 = >=100% FPL
        local row = cond(`pov'==1, 7, 10)
        local row1 = `row' + 1
        local row2 = `row' + 2

        qui sum inctot if agegroup==`ag' & hcovany==1 & offpov==`pov'
        putexcel `cn'`row'  = (`r(mean)')
        putexcel `cn'`row1' = ("(" + string(`r(sd)' / sqrt(`r(N)'), "%10.4g") + ")")
        putexcel `cn'`row2' = (`r(N)')

        qui sum inctot if agegroup==`ag' & hcovany==2 & offpov==`pov'
        putexcel `cc'`row'  = (`r(mean)')
        putexcel `cc'`row1' = ("(" + string(`r(sd)' / sqrt(`r(N)'), "%10.4g") + ")")
        putexcel `cc'`row2' = (`r(N)')

        qui ttest inctot if agegroup==`ag' & offpov==`pov', by(hcovany)
        putexcel `cd'`row' = (`r(mu_1)' - `r(mu_2)')
        putexcel `cp'`row' = (`r(p)')
    }

    restore

    * ---------------------------------------------------------------
    * Annual Household Income stratified by poverty
    * ---------------------------------------------------------------
    preserve
    drop if hhincome == 9999999
    drop if offpov == 9

    foreach pov in 1 0 {
        local row = cond(`pov'==1, 14, 17)
        local row1 = `row' + 1
        local row2 = `row' + 2

        qui sum hhincome if agegroup==`ag' & hcovany==1 & offpov==`pov'
        putexcel `cn'`row'  = (`r(mean)')
        putexcel `cn'`row1' = ("(" + string(`r(sd)' / sqrt(`r(N)'), "%10.4g") + ")")
        putexcel `cn'`row2' = (`r(N)')

        qui sum hhincome if agegroup==`ag' & hcovany==2 & offpov==`pov'
        putexcel `cc'`row'  = (`r(mean)')
        putexcel `cc'`row1' = ("(" + string(`r(sd)' / sqrt(`r(N)'), "%10.4g") + ")")
        putexcel `cc'`row2' = (`r(N)')

        qui ttest hhincome if agegroup==`ag' & offpov==`pov', by(hcovany)
        putexcel `cd'`row' = (`r(mu_1)' - `r(mu_2)')
        putexcel `cp'`row' = (`r(p)')
    }

    restore

    * ---------------------------------------------------------------
    * Homeowner (%)  stratified by poverty
    * ---------------------------------------------------------------
    preserve
    drop if ownershp == 0
    gen homeowner = (ownershp == 1)
    drop if offpov == 9

    foreach pov in 1 0 {
        local row = cond(`pov'==1, 21, 24)
        local row1 = `row' + 1
        local row2 = `row' + 2

        qui sum homeowner if agegroup==`ag' & hcovany==1 & offpov==`pov'
        putexcel `cn'`row'  = (`r(mean)' * 100)
        putexcel `cn'`row1' = ("(" + string(`r(sd)' / sqrt(`r(N)') * 100, "%10.4g") + ")")
        putexcel `cn'`row2' = (`r(N)')

        qui sum homeowner if agegroup==`ag' & hcovany==2 & offpov==`pov'
        putexcel `cc'`row'  = (`r(mean)' * 100)
        putexcel `cc'`row1' = ("(" + string(`r(sd)' / sqrt(`r(N)') * 100, "%10.4g") + ")")
        putexcel `cc'`row2' = (`r(N)')

        qui ttest homeowner if agegroup==`ag' & offpov==`pov', by(hcovany)
        putexcel `cd'`row' = ((`r(mu_1)' - `r(mu_2)') * 100)
        putexcel `cp'`row' = (`r(p)')
    }

    restore
}

putexcel close


*/

***Tables 3 and 4 are at the individual respondent level, using a coverage_bin variable which sets a randomized seed to change fractional coverage to 0/1 from a random draw based on its value***
use "Youngeracsindicators_${today}.dta", replace
append using "olderacsindicators_${today}.dta"

gen coverage = h_privfull + h_mcaidmand + h_va

/*
***Rounding Method for dealing with nonbinary coverage
foreach v in h_privfull h_mcaidmand h_va {
	gen `v'_rnd = `v'
	replace `v'_rnd = 0 if `v' < .5
	replace `v'_rnd = 1 if `v' >= .5
}

gen coverage_rnd=h_privfull_rnd+h_mcaidmand_rnd+h_va_rnd
*/

***Mike's suggested approach: coverage = 0 or 1 if respondent value does, for those in between, assign 0 or 1 with probability based on their value in coverage
sort id
set seed 12345678

gen coverage_bin = 1 if coverage == 1 
replace coverage_bin = 0 if coverage == 0
tab coverage_bin, missing
**Approx 5.72% have values in between and are missing
replace coverage_bin = (runiform() < coverage) if coverage > 0 & coverage < 1

**Verify the imputation
tab coverage coverage_bin if coverage > 0 & coverage < 1


svyset [pweight=perwt]

***Note since we svyset, cannot reg robust. SE are survey robust***
*svy: reg coverage_bin i.agegrp##c.year

***Redefine age group as we had it so that oldest are the comparison group

gen agegroup1 = 1 if agegrp == 3
replace agegroup1 = 2 if agegrp == 1
replace agegroup1 = 3 if agegrp == 2

bys agegroup1 year: sum coverage_bin

***Automate the output of Table 3 into excel***
* 1. Run your regression
gen year_c = year - 2008
replace coverage_bin = coverage_bin*100
*svy: regress coverage_bin i.agegroup1##c.year_c

tab empstat
replace empstat = 4 if empstat == 0
tab educ
replace educ = 12 if educ == 0
tab empstat 
tab educ 
tab race
tab hispan
gen hispanic = 0
replace hispanic = 1 if hispan > 0

*svy: reg coverage_bin i.agegroup1##c.year_c i.race i.hispanic i.educ i.empstat i.state 


gen race1 = "1. White" if race == 1
replace race1 = "2. Black" if race == 2
replace race1 = "3. Native" if race == 3
replace race1 = "4. Asian" if inrange(race, 4, 6)
replace race1 = "5. Other" if race >= 7
tab race1

gen educ1 = "1. Less than HS" if inrange(educ, 1, 5)
replace educ1 = "2. High School" if educ == 6
replace educ1 = "3. Some College" if inrange(educ, 7,8)
replace educ1 = "4. Bachelor or More" if  inrange(educ, 10, 11)
replace educ1 = "5. Missing" if educ == 12
tab educ1
encode educ1, gen(educ2)
encode race1, gen(race2)


svy: reg coverage_bin i.agegroup1##c.year_c i.race2 i.hispanic i.educ2 i.empstat i.state

**CI of difference between youth and adult**

*svy: reg coverage_bin i.agegrp##c.year_c i.race2 i.hispanic i.educ2 i.empstat i.state 
* 2. Set up the file
capture putexcel close
putexcel set "Table3New{today}.xlsx", sheet("Table") replace
putexcel A1 = "Variable" B1 = "²" C1 = "[95% Conf. Interval]" D1 = "Std. Err." E1 = "P>|t|"

* 3. Get the results matrix
matrix results = r(table)
local col_names : colnames results

* 4. Loop through columns and write ONLY your variables of interest
local row = 2
foreach col of local col_names {
    
    * OPTION: Skip state fixed effects, interactions, and controls
    * (Modify this condition based on the exact names of your key variables)
    if strpos("`col'", "state") > 0 | strpos("`col'", "educ") > 0 | strpos("`col'", "race") > 0 | strpos("`col'", "agegroup1") > 0 {
        continue
    }
    
    * Extract stats
    local b  = results[1, "`col'"]
    local se = results[2, "`col'"]
    local p  = results[4, "`col'"]
    local lb = results[5, "`col'"]
    local ub = results[6, "`col'"]
    
    * Format CI string
    local ci_string = "[" + string(`lb', "%9.3f") + ", " + string(`ub', "%9.3f") + "]"
    
    * Write to Excel
    putexcel A`row' = "`col'"
    putexcel B`row' = (`b')
    putexcel C`row' = ("`ci_string'")
    putexcel D`row' = (`se')
    
    * Handle P-value with manual string formatting
    if `p' < 0.001 {
        putexcel E`row' = "<.001"
    }
    else {
        local p_fmt = string(`p', "%9.3f")
        putexcel E`row' = ("`p_fmt'")
    }
    
    local row = `row' + 1
}

putexcel close

***Revised Table 4***
**Continuing to use the appended younger and older indicators file from before***
keep if year == 2023
tab agegrp 

/*
bys coverage_bin agegrp: sum offpov [aweight = perwt] if offpov!= 9

forvalues a = 1/3 {
svy, subpop(if agegrp==`a'): regress offpov i.coverage_bin if offpov != 9
}

bys coverage_bin agegrp: sum hhincome [aweight = perwt] if offpov == 0 & inrange(hhincome, 0, 9999998)

forvalues a = 1/3 {
svy, subpop(if agegrp==`a'): regress hhincome i.coverage_bin if offpov == 0 & inrange(hhincome, 0, 9999998)
}

bys coverage_bin agegrp: sum hhincome [aweight = perwt] if offpov == 1 & inrange(hhincome, 0, 9999998)

forvalues a = 1/3 {
svy, subpop(if agegrp==`a'): regress hhincome i.coverage_bin if offpov == 1 & inrange(hhincome, 0, 9999998)
}

gen homeowner = (ownershp == 1)
***ACS codes as 0 = missing, 1 = owner, 2 = renter***
replace homeowner = . if ownershp == 0

bys coverage_bin agegrp: sum homeowner [aweight = perwt] if offpov == 0 

forvalues a = 1/3 {
svy, subpop(if agegrp==`a'): regress homeowner i.coverage_bin if offpov == 0
}

bys coverage_bin agegrp: sum homeowner [aweight = perwt] if offpov == 1

forvalues a = 1/3 {
svy, subpop(if agegrp==`a'): regress homeowner i.coverage_bin if offpov == 1
}

***Automate the placement of Table 4 into excel***
capture putexcel close
putexcel set "RevisedTable4.xlsx", sheet("Table4") replace

*------------------------------------------------------------
* Headers
*------------------------------------------------------------
putexcel A2="Variable" B2="Measure" ///
    C2="No Mandate" D2="With Mandate" E2="Diff" F2="P-val" ///
    G2="No Mandate" H2="With Mandate" I2="Diff" J2="P-val" ///
    K2="No Mandate" L2="With Mandate" M2="Diff" N2="P-val"

local row = 3

foreach var in offpov hhincome_0 hhincome_1 home_0 home_1 {

    *-----------------------------------------
    * Labels and analysis conditions
    *-----------------------------------------
    if "`var'"=="offpov" {
        local label "Poverty Status"
        local outcome offpov
        local sample "offpov!=9"
    }

    if "`var'"=="hhincome_0" {
        local label "HH Income (In Poverty)"
        local outcome hhincome
        local sample "offpov==1 & inrange(hhincome,0,9999998)"
    }

    if "`var'"=="hhincome_1" {
        local label "HH Income (Not In Poverty)"
        local outcome hhincome
        local sample "offpov==0 & inrange(hhincome,0,9999998)"
    }

    if "`var'"=="home_0" {
        local label "Homeowner (In Poverty)"
        local outcome homeowner
        local sample "offpov==1 & !missing(homeowner)"
    }

    if "`var'"=="home_1" {
        local label "Homeowner (Not In Poverty)"
        local outcome homeowner
        local sample "offpov==0 & !missing(homeowner)"
    }

    putexcel A`row' = "`label'"

    putexcel ///
        B`row'="Mean" ///
        B`=`row'+1'="S.E." ///
        B`=`row'+2'="N"

    *-----------------------------------------
    * Age groups
    *-----------------------------------------
    forvalues a=1/3 {

        quietly svy, subpop(if agegrp==`a'): ///
            regress `outcome' i.coverage_bin if `sample'

        * Covariance matrix
        matrix V = e(V)

        * Means
        local mean0 = _b[_cons]
        local mean1 = _b[_cons] + _b[1.coverage_bin]

        * Standard errors
        local se0 = _se[_cons]

        local var1 = ///
            V[1,1] + ///
            V[2,2] + ///
            2*V[1,2]

        local se1 = sqrt(`var1')

        * Difference
        local diff = _b[1.coverage_bin]

        quietly test 1.coverage_bin
        local p = r(p)

        * Sample sizes (unweighted)
        quietly count if agegrp==`a' & coverage_bin==0 & `sample'
        local n0 = r(N)

        quietly count if agegrp==`a' & coverage_bin==1 & `sample'
        local n1 = r(N)

        * Excel columns
        local c1 : word `a' of C G K
        local c2 : word `a' of D H L
        local c3 : word `a' of E I M
        local c4 : word `a' of F J N

        local r1 = `row' + 1
        local r2 = `row' + 2

        * Means
        putexcel `c1'`row' = (`mean0')
        putexcel `c2'`row' = (`mean1')
        putexcel `c3'`row' = (`diff')
        putexcel `c4'`row' = (`p')

        * Standard errors
        putexcel `c1'`r1' = (`se0')
        putexcel `c2'`r1' = (`se1')

        * Sample sizes
        putexcel `c1'`r2' = (`n0')
        putexcel `c2'`r2' = (`n1')
    }

    local row = `row' + 3
}

display "Finished exporting RevisedTable4.xlsx"
replace coverage_bin = 1 if coverage_bin == 100
*/

***Suggested Revision by Mike:***
gen homeowner = (ownershp == 1)
***ACS codes as 0 = missing, 1 = owner, 2 = renter***
replace homeowner = . if ownershp == 0

bys agegrp: sum coverage_bin if offpov == 1
bys agegrp: ci means coverage_bin if offpov == 1
bys agegrp: sum coverage_bin if offpov == 0
bys agegrp: ci means coverage_bin if offpov == 0
bys agegrp: tab offpov coverage_bin if offpov != 9, chi2 
bys agegrp: sum coverage_bin if homeowner == 1
bys agegrp: ci means coverage_bin if homeowner == 1
bys agegrp: sum coverage_bin if homeowner == 0
bys agegrp: ci means coverage_bin if homeowner == 0
bys agegrp: tab homeowner coverage_bin if homeowner != ., chi2

log close 

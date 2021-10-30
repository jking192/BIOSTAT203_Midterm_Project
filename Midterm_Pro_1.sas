libname MID "/home/u59566911/sasuser.v94/Biostats_203A/Midterm";

PROC IMPORT OUT = MID.Data
	DATAFILE="/home/u59566911/sasuser.v94/Biostats_203A/Midterm/United_States_COVID-19_Cases_and_Deaths_by_State_over_Time.csv"
	DBMS=CSV REPLACE;
	GETNAMES=YES;
	DATAROW= 2;
RUN;

PROC IMPORT OUT = MID.Data2
	DATAFILE="/home/u59566911/sasuser.v94/Biostats_203A/Midterm/COVID-19_Vaccinations_in_the_United_States_County.csv"
	DBMS=CSV REPLACE;
	GETNAMES=YES;
	DATAROW= 2;
RUN;
PROC CONTENTS DATA=MID.Data; RUN;
PROC print data = mid.data (obs = 5);
proc sort DATA= mid.data;
   by submission_date;
RUN;
PROC CONTENTS DATA=MID.Data2; RUN;
PROC print data = mid.data2 (obs = 5);
proc sort DATA= mid.data2;
   by date;
RUN;

proc sql;
	create table test as
	select state, put(submission_date,yymmd5.) as month, SUM(tot_cases) as total_cases,
	SUM (conf_cases) as confirmed_cases, 
	SUM (prob_cases) as probable_cases, SUM (new_case) as new_cases,
	SUM (pnew_case) as probable_new_cases, SUM (tot_death) as total_deaths, SUM (conf_death) as confirmed_deaths,
	SUM (prob_death) as probable_deaths, SUM (new_death) as new_deaths, 
	SUM (pnew_death) as probable_new_deaths
	from MID.Data
	group by state, month;
quit;

proc sql;
	create table test2 as
	select Recip_state, put(date,yymmd5.) as month, SUM(Series_Complete_Yes) as fully_vaccinated,
	SUM (Series_Complete_12plus) as fully_vaccinated_12plus, SUM (Series_Complete_18plus) as fully_vaccinated_18plus,
	SUM(Series_Complete_65plus) as fullY_vaccinated_65plus, SUM(Administered_Dose1_Recip) as one_dose, SUM (Administered_Dose1_Recip_12Plus) as one_dose_12plus,
	SUM (Administered_Dose1_Recip_18Plus) as one_dose_18plus, SUM (Administered_Dose1_Recip_65Plus) as one_dose_65plus
	from MID.Data2
	group by recip_state, month;
quit;
data mid.final_table;
	set test;
	if confirmed_cases = . then confirmed_cases = 0;
	if probable_cases = . then probable_cases = 0;
	if confirmed_deaths = . then confirmed_deaths = 0;
	if probable_deaths = . then probable_deaths = 0;
run;	
    
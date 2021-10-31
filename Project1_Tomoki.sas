libname MID "/home/u59569301/Biostat203A/Prj1";

PROC IMPORT OUT = MID.case_data
	DATAFILE="/home/u59569301/Biostat203A/Prj1/United_States_COVID-19_Cases_and_Deaths_by_State_over_Time_add_pop.csv"
	DBMS=CSV REPLACE;
	GETNAMES=YES;
	DATAROW= 2;
RUN;

PROC IMPORT OUT = MID.Vacc_data
	DATAFILE="/home/u59569301/Biostat203A/Prj1/COVID-19_Vaccinations_in_the_United_States_County.csv"
	DBMS=CSV REPLACE;
	GETNAMES=YES;
	DATAROW= 2;
RUN;

PROC CONTENTS DATA=MID.case_data; RUN;
/*PROC print data = MID.case_data (obs = 5);*/
proc sort DATA= MID.case_data;
   by submission_date;
RUN;

PROC CONTENTS DATA=MID.vacc_data; RUN;
/*PROC print data = mid.vacc_data (obs = 5);*/
proc sort DATA= mid.vacc_data;
   by date;
RUN;

proc sql;
	create table test as
	select state, put(submission_date,yymmd5.) as month, SUM(tot_cases) as total_cases,
	SUM (conf_cases) as confirmed_cases, 
	SUM (prob_cases) as probable_cases, SUM (new_case) as new_cases,
	SUM (pnew_case) as probable_new_cases, SUM (tot_death) as total_deaths, SUM (conf_death) as confirmed_deaths,
	SUM (prob_death) as probable_deaths, SUM (new_death) as new_deaths, 
	SUM (pnew_death) as probable_new_deaths,
	AVG (population) as population
	from MID.case_data
	group by state, month;
quit;

proc sql;
	create table test2 as
	select Recip_state, put(date,yymmd5.) as month, SUM(Series_Complete_Yes) as fully_vaccinated,
	SUM (Series_Complete_12plus) as fully_vaccinated_12plus, SUM (Series_Complete_18plus) as fully_vaccinated_18plus,
	SUM(Series_Complete_65plus) as fullY_vaccinated_65plus, SUM(Administered_Dose1_Recip) as one_dose, SUM (Administered_Dose1_Recip_12Plus) as one_dose_12plus,
	SUM (Administered_Dose1_Recip_18Plus) as one_dose_18plus, SUM (Administered_Dose1_Recip_65Plus) as one_dose_65plus
	from MID.vacc_data
	group by recip_state, month;
quit;

data mid.case_sum_table;
	set test;
	if confirmed_cases = . then confirmed_cases = 0;
	if probable_cases = . then probable_cases = 0;
	if confirmed_deaths = . then confirmed_deaths = 0;
	if probable_deaths = . then probable_deaths = 0;
run;

data mid.vacc_sum_table;
	set test2;
run;

data MID.merge_table;
	merge mid.case_sum_table
	 	 mid.vacc_sum_table (rename = (recip_state=state));
 	/*format case_to_vacc 2.;*/
	by state month;
run;

data MID.merge_table;
	set MID.merge_table;
run;

PROC CONTENTS DATA=MID.merge_table; RUN;

proc sgplot data = mid.merge_table;
	where fully_vaccinated is not missing;
	vbox fully_vaccinated / category=month;
run;
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

proc print data = MID.vacc_data;
where recip_state = "HI";
RUN;

data mid.case_data_edit;
  set mid.case_data;
  if submission_date < =22553 then
  last_day = intnx('month', submission_date,0,'E');
  else last_day = 22581;
  format last_day MMDDYY10.;
RUN;  

proc sql;
   create table final as
   select state, 
   put (submission_date,yymmd5.) as month, 
   tot_cases as total_cases, tot_death as total_deaths
   from mid.case_data_edit
   where submission_date = last_day
   order by state, month;
quit;   

/*proc sql;
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
quit;*/

proc sql;
	create table test as
	select state, put(submission_date,yymmd5.) as month,
		AVG (population) as population,
	 	SUM (new_case) as new_cases,
	 	SUM (new_death) as new_deaths
	from MID.case_Data
	group by state, month;
quit;

data mid.first_table;
     merge test final;
     by state month;
run;   

data mid.vacc_data_edit;
  set mid.vacc_data;
  if date < =22553 then
  last_day = intnx('month', date,0,'E');
  else last_day = 22581;
  format last_day MMDDYY10.;
RUN;   

proc sql;
   create table test2 as
   select Recip_state as state, put(date,yymmd5.) as month, 
 SUM(Series_Complete_Yes) as fully_vaccinated,
	SUM (Series_Complete_12plus) as fully_vaccinated_12plus, SUM (Series_Complete_18plus) as fully_vaccinated_18plus,
	SUM(Series_Complete_65plus) as fully_vaccinated_65plus, SUM(Administered_Dose1_Recip) as one_dose, SUM (Administered_Dose1_Recip_12Plus) as one_dose_12plus,
	SUM (Administered_Dose1_Recip_18Plus) as one_dose_18plus, SUM (Administered_Dose1_Recip_65Plus) as one_dose_65plus
   from mid.vacc_data_edit
   where date = last_day
   group by state, month;
quit;  

PROC IMPORT OUT = MID.abbrev
	DATAFILE="/home/u59569301/Biostat203A/Prj1/State_Abbreviation.csv"
	DBMS=CSV REPLACE;
	GETNAMES=YES;
	DATAROW= 2;
RUN;

PROC IMPORT OUT = MID.data3
	DATAFILE="/home/u59569301/Biostat203A/Prj1/Provisional_COVID-19_Deaths__Distribution_of_Deaths_by_Race_and_Hispanic_Origin.csv"
	DBMS=CSV REPLACE;
	GETNAMES=YES;
	DATAROW= 2;
RUN;

proc sql;
 	delete from MID.data3
 	where month =. or state = "United States";
quit;

PROC CONTENTS DATA=MID.Data3; RUN;
proc sort Data = mid.data3;
    by state;
run;
proc sort Data = mid.abbrev;
    by state;
run;        
data mid.table_3;
  merge mid.data3 mid.abbrev;
  by State;
run;

data mid.table_3_interim;
    set mid.table_3;
    date = mdy (month,1,year);
   drop state;
   *rename "Non-Hispanic White"n=white;
run;
proc sql;
    create table test as
    select "Non-Hispanic White"n
    from mid.table_3_interim;
quit;
proc sql;
    create table mid.table_3_final as
    select Postal as state, put (date, yymmd5.) as month, Indicator, "Non-Hispanic White"n as white, "Non-Hispanic Black or African Am"n as african_american,
    "Non-Hispanic American Indian or"n as native_american, 'Non-Hispanic Asian'n as asian,
    'Non-Hispanic Native Hawaiian or'n as native_Hawaiian, 'Non Hispanic more than one race'n as multiracial,
    'Hispanic or Latino'n as Hispanic_or_Latino
    from mid.table_3_interim
    order by state, month;
quit;
    
proc sql;
 	delete from MID.table_3_final
 	where state is missing or white is not missing;
quit;

proc print data= mid.table_3_final; 

data mid.second_table;
	set test2;
run;

data MID.merge_table;
	merge mid.first_table
	 	  mid.second_table; /*(rename = (recip_state=state));*/
 	/*format case_to_vacc 2.;*/
	by state month;
run;

data MID.merge_table;
	merge MID.merge_table
	 	  mid.table_3_final; /*(rename = (recip_state=state));*/
 	/*format case_to_vacc 2.;*/
	by state month;
run;

PROC CONTENTS DATA=MID.merge_table; RUN;
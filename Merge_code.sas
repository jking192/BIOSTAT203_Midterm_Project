libname MID "/home/u59569301/Biostat203A/Prj1";
*Import datasets;
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

*Ensure totals are shown as end-of-month totals except for October since data used was as of October 28th;
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

*Include population variable and sum new cases by month;
proc sql;
	create table test as
	select state, put(submission_date,yymmd5.) as month,
		AVG (population) as population,
	 	SUM (new_case) as new_cases,
	 	SUM (new_death) as new_deaths
	from MID.case_Data
	group by state, month;
quit;

*Merge tables for final table with case and death data;
data mid.first_table;
     merge test final;
     by state month;
run;   

*Ensure county vaccination data totals are from end of each monthm except for October since data used was as of October 28th;
data mid.vacc_data_edit;
  set mid.vacc_data;
  if date < =22553 then
  last_day = intnx('month', date,0,'E');
  else last_day = 22581;
  format last_day MMDDYY10.;
RUN;   

*Aggregate county vaccination totals for each state at end of each month;
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

 

data mid.second_table;
	set test2;
run;

*Merge case and death data with vaccination data;
data MID.merge_table;
	merge mid.first_table
	 	  mid.second_table; /*(rename = (recip_state=state));*/
 	/*format case_to_vacc 2.;*/
	by state month;
run;

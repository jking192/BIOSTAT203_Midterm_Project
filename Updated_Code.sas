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
PROC print data = mid.data2;
proc sort DATA= mid.data2;
   by date;
RUN;

data mid.data_edit;
  set mid.data;
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
   from mid.data_edit
   where submission_date = last_day
   order by state, month;
quit;   
  
 
proc sql;
	create table test as
	select state, put(submission_date,yymmd5.) as month,
	 SUM (new_case) as new_cases,
	 SUM (new_death) as new_deaths 
	from MID.Data
	group by state, month;
quit;

data mid.first_table;
     merge test final;
     by state month;
run;   

data mid.data2_edit;
  set mid.data2;
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
	SUM(Series_Complete_65plus) as fullY_vaccinated_65plus, SUM(Administered_Dose1_Recip) as one_dose, SUM (Administered_Dose1_Recip_12Plus) as one_dose_12plus,
	SUM (Administered_Dose1_Recip_18Plus) as one_dose_18plus, SUM (Administered_Dose1_Recip_65Plus) as one_dose_65plus
   from mid.data2_edit
   where date = last_day
   group by state, month;
quit;  
 

    
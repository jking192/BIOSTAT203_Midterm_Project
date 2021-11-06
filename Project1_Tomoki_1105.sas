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


* Converting population to rates;
data mid.table_analysis;
	set mid.merge_table;
	new_case_rate_percent = new_cases/population*100;
	new_death_rate_percent = new_deaths/population*100;
	fully_vaccinated_rate_percent = fully_vaccinated/population*100;
run;

/*data mid.total_rate;
	set mid.merge_table;
	us_case = 0; us_death = 0; us_pop = 0;
	if month="21-10" then us_case+=total_cases; us_death+=total_deaths; us_pop+=population;
	total_new_case_rate_percent = us_cases/us_pop;
	total_new_death_rate_percent = us_cases/us_pop;
run; */

proc means data=mid.merge_table sum nonobs;
	class month state;
	var total_cases total_deaths fully_vaccinated population;
	where month="20-11" or month="21-10";
run;

*Regression Analysis for new case rate and new death rate before and after vaccines were made available;
proc sql;
 	delete from mid.table_analysis
 	where population =. or state = "HI";
quit; 	

proc reg data = mid.table_analysis;
   model new_case_rate_percent = fully_vaccinated_rate_percent;
   where month between "20-12" and "21-10";
run;

proc means data = mid.table_analysis  stddev mean;
	class month;
	Var new_case_rate_percent new_death_rate_percent;
run;

* Histograms comparing new cases before and after vaccines were available;
proc sgplot data = mid.table_analysis;
histogram new_case_rate_percent;
title "Before Vaccine Available";
where month between "20-01" and "20-11" ;
run;

proc sgplot data = mid.table_analysis;
histogram new_case_rate_percent;
title "After Vaccine Available";
where month between "20-12" and "21-10";
run;

* This code creates an dichotomous indicator that helps identify which states have more than 50% overall vaccination rate
and which states have less than 50% vaccination rate; 
proc sql;
     create table actual_analysis as
     SELECT * from mid.table_analysis
    where month = "21-10";
    title;
quit;

proc sql;
     create table actual_analysis_final as
     SELECT state from actual_analysis
    where month = "21-10" AND fully_vaccinated_rate_percent < 50;
quit;

proc sql;
     create table actual_analysis_final_2 as
     SELECT state from actual_analysis
    where month = "21-10" AND fully_vaccinated_rate_percent > 50;
quit;

proc sql;
	create table more_one_dose as
	SELECT * from actual_analysis as aa, actual_analysis_final as af
	where aa.state = af.state;
quit;	

proc sql;
	create table more_equal as
	SELECT * from actual_analysis as aa, actual_analysis_final_2 as af2
	where aa.state = af2.state;
quit;

data mid.one_dose;
     set more_one_dose;
     indicator = "N";
     
run;

data mid.more_equal;
      set more_equal;
      indicator = "Y";
run;

PROC sort data = mid.one_dose;
	by month;
run;

PROC sort data = mid.more_equal;
	by month;
run;

data mid.final_merge;
	merge mid.one_dose mid.more_equal;
	by month indicator;
run;
proc Format;
	VALUE $status
	'Y' = '< 50% vaccination rate'
	'N' = '≥ 50% vaccination rate';
run;	

* Summary Statistics of new case rates by vaccination rates;
proc means data = mid.final_merge N Mean Median Std MIN MAX;
     class indicator;
     var new_case_rate_percent new_death_rate_percent;
     format indicator $status.;
run;     
     
* Check for differences in new case rates between states with vaccination rates > 50% and states with vaccination rates < 50%;
* Check for Normality;    
proc univariate data=mid.final_merge normal; 
 var new_case_rate_percent;
  qqplot new_case_rate_percent /Normal(mu=est sigma=est color=red l=1);
	by indicator;
	format indicator $status.;
    run;
 * Ranked Sum Test;
  proc NPAR1WAY data=mid.final_merge wilcoxon;
	class indicator;
	format indicator $status.;
	var new_case_rate_percent;
	exact wilcoxon;
   run;
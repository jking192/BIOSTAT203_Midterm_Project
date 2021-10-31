libname mid1 "/home/u59566911/sasuser.v94/Biostats_203A/Midterm";

data mid1.table_analysis;
	set mid1.merge_table;
run;
* Histograms comparing new cases before and after vaccines were available for all adults;
proc sgplot data = mid1.table_analysis;
histogram new_cases;
where month between "20-01" and "21-03" ;

proc sgplot data = mid1.table_analysis;
histogram new_cases;
where month between "21-04" and "21-10";

* This code creates an dichotomous indicator that helps identify which states have more than 85% full
vaccination rate among those who got at least one dose and which states have less than 85% full vaccination 
rate; 
proc sql;
     create table actual_analysis as
     SELECT * from mid1.table_analysis
    where month between "20-12" and "21-10" AND (total_deaths and fully_vaccinated ~=.) ;
quit;

proc sql;
     create table actual_analysis_final as
     SELECT state from actual_analysis
    where month = "21-10" AND fully_vaccinated/one_dose <0.85;
quit;

proc sql;
     create table actual_analysis_final_2 as
     SELECT state from actual_analysis
    where month = "21-10" AND fully_vaccinated/one_dose >=0.85;
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

data mid1.one_dose;
     set more_one_dose;
     indicator = "Yes";
run;

data mid1.more_equal;
      set more_equal;
      indicator = "No";
run;

PROC sort data = mid1.one_dose;
	by month;
run;

PROC sort data = mid1.more_equal;
	by month;
run;
proc print data = mid1.one_dose;
data mid1.final_merge;
	merge mid1.one_dose mid1.more_equal;
	by month indicator;
run;


libname mid1 "/home/u59566911/sasuser.v94/Biostats_203A/Midterm";
* Converting population to rates;
data mid1.table_analysis;
	set mid1.merge_table_1031;
	new_case_rate_percent = new_cases/population*100;
	new_death_rate_percent = new_deaths/population*100;
	fully_vaccinated_rate_percent = fully_vaccinated/population*100;
run;
*Regression Analysis for new case rate and new death rate before and after vaccines were made available;
proc sql;
 	delete from mid1.table_analysis
 	where population =. or state = "HI";
quit; 	
proc reg data = mid1.table_analysis;
   model new_case_rate_percent = fully_vaccinated_rate_percent;
   where month between "20-12" and "21-10";

proc means data = mid1.table_analysis  stddev mean;
	class month;
	Var new_case_rate_percent new_death_rate_percent;
run;

* Histograms comparing new cases before and after vaccines were available;
proc sgplot data = mid1.table_analysis;
histogram new_case_rate_percent;
title "Before Vaccine Available";
where month between "20-01" and "20-11" ;
run;

proc sgplot data = mid1.table_analysis;
histogram new_case_rate_percent;
title "After Vaccine Available";
where month between "20-12" and "21-10";
run;

* This code creates an dichotomous indicator that helps identify which states have more than 50% overall vaccination rate
and which states have less than 50% vaccination rate; 
proc sql;
     create table actual_analysis as
     SELECT * from mid1.table_analysis
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

data mid1.one_dose;
     set more_one_dose;
     indicator = "N";
     
run;

data mid1.more_equal;
      set more_equal;
      indicator = "Y";
run;

PROC sort data = mid1.one_dose;
	by month;
run;

PROC sort data = mid1.more_equal;
	by month;
run;

data mid1.final_merge;
	merge mid1.one_dose mid1.more_equal;
	by month indicator;
run;
proc print data = mid1.final_merge;
proc Format;
	VALUE $status
	'Y' = '< 50% vaccination rate'
	'N' = '≥ 50% vaccination rate';
run;	

* Summary Statistics of new case rates by vaccination rates;
proc means data = mid1.final_merge N Mean Median Std MIN MAX;
     class indicator;
     var new_case_rate_percent new_death_rate_percent;
     format indicator $status.;
run;     
     
* Check for differences in new case rates between states with vaccination rates > 50% and states with vaccination rates < 50%;
proc sgplot data = mid1.final_merge;
    histogram fully_vaccinated_rate_percent;
proc univariate data=mid1.final_merge normal; 
qqplot new_case_rate_percent /Normal(mu=est sigma=est color=red l=1);
	by indicator;
	format indicator $status.;
    run;
  proc NPAR1WAY data=mid1.final_merge wilcoxon;
	class indicator;
	var new_case_rate_percent;
	exact wilcoxon;
   run;
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
   model new_case_rate_percent new_death_rate_percent = fully_vaccinated_rate_percent;
   where month between "20-12" and "21-10";
   label fully_vaccinated_rate_percent = "Fully Vaccinated Rate (%)";
   label new_case_rate_percent = "New Case Rate (%)";
	label new_death_rate_percent = "New Death Rate (%)";
run;
proc means data = mid1.table_analysis N mean std;
	class month;
	Var new_case_rate_percent new_death_rate_percent;
	label new_case_rate_percent = "New Case Rate (%)";
	label new_death_rate_percent = "New Death Rate (%)";
run;

* Histograms comparing new cases before and after vaccines were available;
proc sgplot data = mid1.table_analysis;
histogram new_case_rate_percent;
label new_case_rate_percent = "New Case Rate (%)";
title "Before Vaccine Available";
where month between "20-01" and "20-11" ;
run;

proc sgplot data = mid1.table_analysis;
histogram new_case_rate_percent;
title "After Vaccine Available";
label new_case_rate_percent = "New Case Rate (%)";
where month between "20-12" and "21-10";
run;


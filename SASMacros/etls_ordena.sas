

/*
MACRO etls_ordena

        fich = Input file
         var = by variables
       fich2 = output file
       subset= where clause for input file
	   keeplist= columns to keep in the input file

Example
%ordena2(fich = work.dataset1,var= var1 var2 var3,fich2= work.dataset2);
*/

%MACRO etls_ordena(fich=,var=,fich2=,subset=,keeplist=);

%let lib_in  =%UPCASE(%scan(&fich,1,%str(.)));/*1ºparameter string (Libname.Datasetnama)*/
%let dataset_in =%UPCASE(%scan(&fich,2,%str(.)));/*2ºparameter string (Libname.Datasetnama)*/

%put  lib_in =&lib_in;
%put  dataset_in =&dataset_in ;

%if &dataset_in  = %then %do;/*for work datasets that don't specify libname*/
	%let lib_in  =WORK;  
	%let dataset_in =%UPCASE(%scan(&fich,1,%str(.)));  
%end;

%put  lib_in =&lib_in;
%put  dataset_in =&dataset_in ;

/* Number of observations input dataset */
proc sql noprint;
     select nobs format=14. into :numobs 
     from dictionary.tables
     where libname="&lib_in"
     and memname="&dataset_in" ;
quit;

%put numobs=&numobs;

/*After some tests the best partition is 4%*/

%IF &numobs < 25 %then %do; /* maxobs must be >=1 */
data _null_;
   maxobs="(&numobs)";
   call symput('maxobs',maxobs);
run;
%END;

%ELSE %DO;
data _null_;
   maxobs="(&numobs*4/100)";
   call symput('maxobs',maxobs);
run;
%put &maxobs;
%END;
%let n_div = (&numobs/&maxobs) + 1;
%put &n_div;

%let datasets=;
%let count=%eval(0);

%DO %WHILE (&count<%eval(&n_div));
	%let prim=%eval((&count*&maxobs)+1);
	%let max=%eval((&count+1)*&maxobs);
	%IF &numobs >= &prim %THEN %DO;
	data aa&count;
		set &fich(firstobs=&prim 
				  obs=&max
				  keep= &keeplist);
		%IF subset ne '' %THEN %DO;
			where &subset.;
		%END;
	run;

	proc sort data= aa&count ;
	by &var;
	run;

	%let datasets=&datasets aa&count;
	%END;

	%let count=%eval(&count+1);
%END;

data &fich2;
  set &datasets;
  by &var;
run;

/* clean WORK */
proc datasets lib=work nolist;
   delete &datasets;
quit;

%MEND etls_ordena;

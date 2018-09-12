/**** IX2CLEAR.SOURCE
 * Purpose:  Macro to remove all indexes from a SAS dataset,
 *           but save the information to allow re-creation
 *           by the macro ixremake.
 *
 * Usage:    DATASET= is a required parameter
 *           SAVELOC= is optional, with a default if not supplied.
 *
 * Author: Steve Morton, Applied System Knowledge Ltd.
 *
 * History:  Date       | Remarks
 *         2 Dec.  1999 | Initial development.
 *                      |
 *                      |
 *************************************************************/

%macro ix2clear(dataset=,saveloc=work.save_idx);
%* Purpose: Identify what indexes exist on a dataset, storing;
%*          for a later re-creation, then drop all indexes.  ;
%* Organise parameters - need to be upper-case for SQL below.;
%let DATALIB=%upcase(%scan(&DATASET,1,%str(.)));
%let DATATAB=%upcase(%scan(&DATASET,2,%str(.)));
%if %str(&DATATAB) = %str() %then %do;
   %* a one-level name was specified - means work lib;
   %let DATALIB = WORK;
   %let DATATAB = %upcase(%scan(&DATASET,1,%str(.)));
%end;

* read current index info and store to temporary dataset;
proc sql;
 create table &SAVELOC as
   select *
     from dictionary.indexes
      where libname = "&DATALIB" and memname = "&DATATAB"
     order by indxname, indxpos
  ;
quit;

* process to execute 'drop' for all indexes;
data _null_;
  set &SAVELOC end=eod;
  by indxname;

  length sep $ 2; * separator within sql statement - value will
                     be set according to where we are in processing;

  if _n_ = 1 then do;
    call execute("proc sql; drop index ");
  end;

  if last.indxname then do;
     if not eod then sep = ', ';
     call execute( trim(indxname) || sep );
  end;

  if eod then do;
     call execute( ' from ' || "&DATALIB..&DATATAB; quit;");
  end;

run;

%mend ix2clear;
 
%let DIMLIB = WORK;
%let DIMNAME = AAA;

data aaa;
set sashelp.class;
run;

proc sql;
create index composto on aaa(name,age) ;
create index name on aaa;
create index sex on aaa;
quit;

proc sql;
 create table work.save_idx as
   select *
     from dictionary.indexes
      where libname = "&DIMLIB" and memname = "&DIMNAME"
     order by indxname, indxpos
  ;
quit;

data bbb;
set sashelp.class;
run;

%let outlib = WORK;
%let outname = BBB;

data _null_;
  set work.save_idx end=eod;
  by indxname;

  length ivarlist $ 200 ;
  retain ivarlist ;  * index variables list built over several cycles;
  length dataset $ 50;  * ready for version 8 ! ;
  retain dataset;    * defined once for whole set;

  if _n_ = 1 then do;
    call execute("proc sql;");
    dataset = trim("&OUTLIB") || '.' || trim("&OUTNAME");
  end;
  * build the list of index variables;
  if first.indxname then do;
     ivarlist = name;
  end;
  else do;
     ivarlist = trim(ivarlist) || ',' || name;
  end;

  if last.indxname then do;
    * now execute the appropriate create statement;
     if upcase(unique)='YES' then create = 'CREATE UNIQUE INDEX ';
     else create = 'CREATE INDEX ';
     call execute( create || indxname || ' on '|| dataset);
     call execute( '     (' || trim(ivarlist) || ');' );
  end;

  if eod then do;
     call execute('quit;');
  end;

run;





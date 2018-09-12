/*

Macro name:   bulkLoad:

              this is a macro that can be used to insert, update, delete, merge data from a Sas data set
              into an Oracle table in a Unix system.

              It creates (so your Oracle user has to be granted) a temporary Oracle table from your Sas data set
              (using bulk loading), then it generates Sql code to update the target table and
              finally drops the temporary one.

              If the input table is empty the macro stops executing.

              Bulk loader's utilities (log, control file, data) are written to a folder specified in a global
              macro variable and deleted after loading.
              The folder is created if it does not exist, with writing permissions for the unix group of the
              sas user and, optionally, with a specified unix group.

              After executing, the program sets two macro variables (see "Macro variables set") with
              the Oracle return code and, eventually, error message.
              In case of error a rollback is issued.
              The only Oracle error that does NOT generate a rollback is -1403 (NO data found).

              SAS Version: v8 and above.


Parameters:

              dbTab        = name of the Oracle table to update

              sasTab       = name of the Sas input data set

              mode         = REFRESH     deletes all rows from the Oracle table and inserts the new ones
                                         (it does not return an error in case of "No data found")

                             INSERT      inserts into the Oracle table all the Sas table's rows

                             INSERT_NEW  inserts into the Oracle table only the Sas table's rows that don't
                                         already exist in it (according to a user defined key)

                             UPDATE      deletes from the Oracle table the rows that match the input keys
                                         and inserts the new ones
                                         (it does not return an error in case of "No data found")

                             DELETE      just deletes from the Oracle table the rows that match the input keys

                             MERGE       merge (updates existing rows, insert new ones)
                                         updates the Oracle table with all the columns in the Sas data set
                                         that are not in the keys list
                                         [from Oracle 9 ]

                             UPDATE_JOIN updates the Oracle table with all the columns in the Sas
                                         data set that are not in the keys list


              keys         = (needed if mode is DELETE, UPDATE, INSERT_NEW, MERGE or UPDATE_JOIN)
                             this is the list of the Oracle column names that make the key
                             (separated by comma (,) so it needs a %str() if you have more than one column)

              dbTmpTab     = name of the temporary Oracle table used for loading

              dbNames      = if SASNAMES(default), the macro works with the Sas column NAMES
                             if LABELS,            the macro works with the Sas column LABELS
                                                   (in this case, ALL columns must have a label)

              preExecute   = optional string with a command to be executed by the database prior to load
                             the table.

              oraUser      = Oracle userid

              oraPath      = Oracle path

              oraPw        = Oracle password

              oraTableSpace= optional tablespace name used for creating the temporay working table
                             the output table if it does not exist

              usersGroup   = (OPTIONAL) unix group assigned to a newly created bulk loading folder



Notes:

              - to insert DATE columns = create the sas column either with a Sas Date value and a sas Date format
                                         or a Sas Datetime value and a datetime format

              - to insert NULL values  = use '' for character values and . for numeric ones


Global macro variables needed:

              bulkloadPath = working path for bulk loading operation (data, log, control files).
                             At the end of macro execution all files here are deleted


Macro variables set:

              bulkloadRc   = 0 if no errors, otherwise return code
              bulkloadMsg  = blank if no errors, otherwise error message


              Return codes and messages issued

              * Oracle errors:

              bulkloadRc   = Oracle return code
              bulkloadMsg  = Oracle error message


              * Sas errors:

              bulkloadRc   = Sas syscc value
              bulkloadMsg  = Sas error - check Sas log


              * Other errors:

              - Input data set does not exist

                bulkloadRc   = 9005
                bulkloadMsg  = <sas table> does not exist

*/

/* DEVELOPMENT/MAINTENANCE HISTORY                                      */
/* DATE        BY          NOTE                                         */
/* 08082005    ITAMRZ      Initial creation                             */
/* 03162006    SASEXA      Added Oracle Path parameter for connections  */
/*             SASJBQ      to remote database                           */
/* 03162006    SASEXA      Modified to handle special characters such   */
/*             SASJBQ      as & in the labels; used %nrquote(&__label)  */
/* 03212006    SASEXA      Modified to handle removing the leading      */
/*             SASJBQ      underscore which occurs on some SAP BW ODS   */
/*                         fields                                       */
/* 03222006    SASEXA      Modified to handle the occurrence of Oracle  */
/*             SASJBQ      reserved name TIME being used as a variable  */
/*                         name                                         */
/* 03222006    SASEXA      Modified documentation of Keys to include    */
/*             SASJBQ      mode of DELETE                               */
/*                                                                      */


%macro bulkload (
       dbTab        =,
       sasTab       =,
       mode         =,
       keys         =,
       dbtmptab     =,
       dbNames      =SASNAMES,
       preExecute   =,
       orapath      =,
       orauser      =,
       orapw        =,
       oraTableSpace=,
       usersGroup   =
       );


%let prevSyscc=&syscc;

%if &orapath= %then
   %do;
      %let path=;
   %end;
%else
   %do;
      %let path=path=&orapath;
   %end;

       /* utility */
       %macro droptab(table=,orauser=,orapw=);

       %global droprc;
       %global dropmsg;

       %let droprc=0;
       %let dropmsg=0;

       %let cnt=0;
       %let table=%upcase(&table);

       proc sql noprint;
       connect to oracle(&path user=&orauser pw=&orapw);

       select cnt into : cnt from connection to oracle
       (
       select
       count(*) as cnt
       from
       user_tables
       where
       table_name=%nrbquote(')&table%nrbquote(')
       )
       ;
       disconnect from oracle;
       quit;

       %if &cnt=1 %then %do;
           %put NOTE: *** dropping table &table.... ***;  
           proc sql;
           connect to oracle(&path user=&orauser pw=&orapw);
             execute ( drop table &table ) by oracle ;
             %if &sqlxrc ne 0 %then %do;
                 %let droprc=&sqlxrc;
                 %let dropmsg=&sqlxmsg;
             %end;
           disconnect from oracle;
           quit;
       %end;
       %else %do;
           %put NOTE: *** table &table does not exist ***;  
       %end;

       %mend;



       %macro getCurrPath;

       %global currPath;

       libname ___dummy '.';
       %let currPath =%sysfunc(pathname(___dummy));
       libname ___dummy clear;

       %mend;




       %macro setCurrPath(newCurrPath=);

       %if %sysfunc(fileExist(&newCurrPath)) = 0 %then %do;
           x "mkdir -p &newCurrPath";
           x "chmod g+w &newCurrPath";

           %if "&usersGroup" ne "" %then %do;
               x "chgrp &usersGroup &newCurrPath";
           %end;

       %end;

       x "cd &newCurrPath";

       %mend;




%put NOTE: *** Macro Bulkload Release 1.0 beginning execution ***;


%global
 bulkloadRc
 bulkloadMsg
;

%if %sysfunc(exist(&sasTab))=0 %then %do;
    %let bulkloadRc  =9005;
    %let bulkloadMsg =&sasTab does not exist ;
    %goto errMacro;
%end;

%let ds=%sysfunc(open(&sasTab));
%let nobs=%sysfunc(attrn(&ds,NLOBS));
%let nvars=%sysfunc(attrn(&ds,NVARS));

%let _names   =;
%let _types   =;
%let _lengths =;
%let _labels  =;
%let _formats =;
%let _renames =;

%do i=1 %to &nvars;
    %if (%substr(%upcase(%sysfunc(varname  (&ds,&i)) ),1,1) = _) %then
	   %do;
          %let __name   = %substr(%upcase(%sysfunc(varname  (&ds,&i)) ),2);
		  %let __rename = %upcase(%sysfunc(varname  (&ds,&i)) )=%substr(%upcase(%sysfunc(varname  (&ds,&i)) ),2);
       %end;
	%else
	   %do;
	      %let __name   = %upcase(%sysfunc(varname  (&ds,&i)) );
		  %let __rename = blank;
	   %end;
	%if %upcase(%sysfunc(varname  (&ds,&i)) ) = TIME %then  
	   %do;
          %let __name   =TIME1;
		  %let __rename =TIME=TIME1;
       %end;
    %let __type   = %upcase( %sysfunc(vartype  (&ds,&i)) );
    %let __length = %upcase( %sysfunc(varlen   (&ds,&i)) );
    %let __label  = %upcase( %sysfunc(varlabel (&ds,&i)) );
    %let __format = %upcase( %sysfunc(varfmt   (&ds,&i)) );

    %if &__type=C %then %do;
            %let __type=CHAR;
        %end;
        %else %do;
            %let __type=NUM;
        %end;

    %if &__name   = %then %do; %let __name  =NNN; %end;
    %if &__type   = %then %do; %let __type  =NNN; %end;
    %if &__length = %then %do; %let __length=NNN; %end;
    %if %nrquote(&__label) eq %then %do; %let __label =NNN; %end;
    %if &__format = %then %do; %let __format=NNN; %end;

    %if &i ne 1 %then %do;
        %let __comma=,;
		%let __blank=%str( ) ;
    %end;
    %else %do;
        %let __comma=;
		%let __blank=;
    %end;
    
	%if &__rename ne blank %then
	   %do;   
          %let _renames  =&_renames.&__blank.&__rename;
	   %end;
    %let _names  =&_names.&__comma.&__name;
    %let _types  =&_types.&__comma.&__type;
    %let _lengths=&_lengths.&__comma.&__length;
    %let _labels =&_labels.&__comma.&__label;
    %let _formats=&_formats.&__comma.&__format;

%end;

%let ds=%sysfunc(close(&ds));

%if &nobs=0 %then %do;
    %let bulkloadRc  =0;
    %let bulkloadMsg =Empty input data set;
    %put NOTE: *** &sasTab is empty ***; 
    %goto endEx;
%end;

/* we use labels, to use names put them in the labels */
%if &dbNames=SASNAMES %then %do;
    %let _labels=&_names;
%end;


%if (%scan(&sasTab,2,.)=) %then %do;
    %let sasTab=work.&sasTab;
%end;
%let _addlib=%upcase(%scan(&sasTab,1,.));
%let _addtab=%upcase(%scan(&sasTab,2,.));

%let keys     = %upcase(&keys);

%let bulkloadRc=0;
%let bulkloadMsg=;


%droptab(table=&dbtmptab,orauser=&orauser,orapw=&orapw)
%if &droprc ne 0 %then %do;
    %let bulkloadRc=&droprc;
    %let bulkloadMsg=&dropmsg;
    %goto errORA;
%end;


%let librefEngine = _tmpdb;

libname &librefEngine oracle &path user=&orauser pw=&orapw;

%if %sysfunc(exist(&librefEngine..&dbTab))=0 %then %do;
    data &librefEngine..&dbTab
         %if "&oraTableSpace" ne "" %then %do;
             (dbcreate_table_opts="tablespace &oraTableSpace")
         %end;
         ;
     set &sasTab(obs=0);
	 rename &_renames; 
    run;
%end;

/* set bulkload working path */
%getCurrPath
%put NOTE: *** current path is &currpath ***; 
%setCurrPath(newCurrPath=&bulkloadPath)

data &librefEngine..&dbtmptab (
     bulkload=yes
     %if "&oraTableSpace" ne "" %then %do;
         dbcreate_table_opts="tablespace &oraTableSpace"
     %end;
     );
 set &sasTab;
 rename &_renames; 
run;

x "\rm BL_%upcase(&dbtmptab)*";
%setCurrPath(newCurrPath=&currPath)

%if &syserr>4 %then %do;
    %let bulkloadRc=&syserr;
    %let bulkloadMsg=&sysmsg;
    %goto errMacro;
%end;


proc sql exec noerrorstop;
connect to oracle(&path user=&orauser pw=&orapw);

%if "&preExecute" ne "" %then %do;
    execute (
    &preExecute
    ) by oracle;
%end;

%let pipe_expr=;
%let prefix1_pipe_expr=;
%let comma_expr=;
%let comma_expr_noKeys=;
%let join_expr=;
%let merge_set_expr=;
%let merge_insert_expr=;
%let merge_values_expr=;

%let i=1;
%let first_key=1;
%let first_not_key=1;

%do %while( %scan( %quote(&_labels) ,&i,%str(,)) ne);
    %let _label=%upcase( %scan( %quote(&_labels) ,&i,%str(,)) );

    %if (&i > 1) %then %do;
        %let comma_expr = &comma_expr.,;
        %let merge_insert_expr = &merge_insert_expr.,;
        %let merge_values_expr = &merge_values_expr.,;
    %end;

    %if %index( %quote(&keys) , &_label ) ne 0 %then %do;
        %if &first_key ne 1 %then %do;
            %let pipe_expr         = &pipe_expr.||;
            %let prefix1_pipe_expr = &prefix1_pipe_expr.||;
            %let join_expr         = &join_expr AND ;
        %end;

        %let pipe_expr         = &pipe_expr &_label ;
        %let prefix1_pipe_expr = &prefix1_pipe_expr a.&_label ;
        %let join_expr         = &join_expr a.&_label = b.&_label ;

        %let first_key=0;
    %end;
    %else %do;
        %if &first_not_key=0 %then %do;
            %let comma=,;
        %end;
        %else %do;
            %let comma=;
        %end;

        %let merge_set_expr    = &merge_set_expr &comma a.&_label = b.&_label;
        %let comma_expr_noKeys = &comma_expr_noKeys &comma &_label;

        %let first_not_key=0;
    %end;

    %let comma_expr = &comma_expr &_label ;
    %let merge_insert_expr = &merge_insert_expr a.&_label;
    %let merge_values_expr = &merge_values_expr b.&_label;

    %let i=%eval(&i+1);

%end;



%if (&mode=INSERT_NEW) %then %do;


    execute (
     delete from &dbtmptab
     where &pipe_expr
     IN (
         select &prefix1_pipe_expr
         from &dbTab a, &dbtmptab b
         where &join_expr
         )
        ) by oracle;

    %if &sqlxrc ne 0 and &sqlxrc ne -1403 %then %do;
        %let bulkloadRc=&sqlxrc;
        %let bulkloadMsg=&sqlxmsg ;
        %goto errOra;
    %end;
%end;


%if (&mode=REFRESH) %then %do;
    execute (
     delete from &dbTab
        ) by oracle;

    %if &sqlxrc ne 0 and &sqlxrc ne -1403 %then %do;
        %let bulkloadRc=&sqlxrc;
        %let bulkloadMsg=&sqlxmsg ;
        %goto errOra;
    %end;
%end;


%if (&mode=UPDATE or &mode=DELETE) %then %do;
    execute (
     delete from &dbTab where &pipe_expr
     IN (select &pipe_expr from &dbtmptab)
        ) by oracle;

    %if &sqlxrc ne 0 and &sqlxrc ne -1403 %then %do;
        %let bulkloadRc=&sqlxrc;
        %let bulkloadMsg=&sqlxmsg ;
        %goto errOra;
    %end;
%end;

%if (&mode ne DELETE and &mode ne MERGE and &mode ne UPDATE_JOIN) %then %do;
    execute (
     insert into &dbTab (&comma_expr)
     select &comma_expr from &dbtmptab
    ) by oracle;
    %if &sqlxrc ne 0 %then %do;
        %let bulkloadRc=&sqlxrc;
        %let bulkloadMsg=&sqlxmsg ;
        %goto errOra;
    %end;
%end;


%if (&mode eq MERGE) %then %do;
    execute (
     merge into &dbTab a
     using ( select &comma_expr from &dbtmptab ) b
     on    ( &join_expr )
     when  matched then
           update set &merge_set_expr

     when  not matched then
           insert (&merge_insert_expr)
           values (&merge_values_expr)

    ) by oracle;
    %if &sqlxrc ne 0 %then %do;
        %let bulkloadRc=&sqlxrc;
        %let bulkloadMsg=&sqlxmsg ;
        %goto errOra;
    %end;
%end;


%if (&mode eq UPDATE_JOIN) %then %do;
    execute (
     update &dbTab a
     set (&comma_expr_noKeys) =
     (
       select &comma_expr_noKeys from &dbtmptab b
       where  &join_expr
     )
     where exists
     (
       select * from &dbtmptab b
       where  &join_expr
     )

    ) by oracle;
    %if &sqlxrc ne 0 %then %do;
        %let bulkloadRc=&sqlxrc;
        %let bulkloadMsg=&sqlxmsg ;
        %goto errOra;
    %end;
%end;


disconnect from oracle;
quit;

%droptab(table=&dbtmptab,orauser=&orauser,orapw=&orapw)
%if &droprc ne 0 %then %do;
    %let bulkloadRc=&droprc;
    %let bulkloadMsg=&dropmsg;
    %goto errORA;
%end;


%goto endEx;



%errMacro:
 %put ERROR: *** ending execution ***; 
 %put --> Return code: &bulkloadRc;
 %put --> Error message: &bulkloadMsg;
 %goto endEx;

%errOra:
 execute ( rollback ) by oracle;
 %put ERROR: *** Oracle error - rollback issued ***; 
 %put --> Oracle return code:  &bulkloadRc;
 %put --> Oracle error message: &bulkloadMsg;
 %goto endEx;


 /* check for sas errors */
 %if &syscc > 4 %then %do;
     %put ERROR: *** SAS error ***; 
     %let bulkloadRc=&syscc;
     %let bulkloadMsg=Sas error - check Sas log;
 %end;
 %else %do;
     %let syscc=&prevSyscc;
 %end;

%endEx:


%put NOTE: *** Macro Bulkload Release 1.0 ending execution ***;


%mend bulkload ;

/****************************************************************************/
/* MACRO NAME: columnsExist                                                 */
/* CREATED BY: John Beecher                                                 */
/* VERSION: 1.0                                                             */
/* RELEASED: 2009.10.14                                                     */
/*                                                                          */
/* DESCRIPTION:                                                             */
/* The macro, columnsExist, was written with the intent of being used in    */
/* macros that use libraries, tables, and columns as part of their input.   */
/* This macro checks the existence of columns in a particular library and   */
/* table combination. There are no "return" macro variables. If everything  */
/* is fine then the macro will not generate any errors. However, if the     */
/* library, table, or columns defined for input do not exist an error will  */
/* be thrown and the macro will stop processing.                            */
/*                                                                          */
/* INPUTS:                                                                  */
/* library  -   The library where the table is located. If blank it will    */
/*              default to work.                                            */
/* table    -   The table where columns are located.                        */
/* columns  -   The columns to have checked.                                */
/*                                                                          */
/* OUTPUTS:                                                                 */
/* N/A                                                                      */
/****************************************************************************/
%macro columnsExist(library=work,table=,columns=);

    %let library = %upcase(&library);
    %let table = %upcase(&table);

    proc sql noprint;
        select  count(libname) into : libExist
        from    dictionary.libnames
        where   libname eq "&library";
    quit;

    /* check to make sure the library has been assigned */
    %if %eval(&libExist eq 0) %then %do;
        %put ERROR: Libname &library is not assigned.;
        %return;
    %end;

    /* check to make sure the user has input some value for &table */
    %if &table eq %str() %then %do;
        %put ERROR: No table defined for the macro columnsExist.;
        %return;
    %end;

    /* check to make sure the user has input some value for &columns */
    %if &columns eq %str() %then %do;
        %put ERROR: No columns defined for the macro columnsExist.;
        %return;
    %end;

    /* count the number of columns to check their existence */
    data _null_;
        colCount = count("&columns", ' ') + 1;
        call symput('colCount', colCount);
    run;

    /* set default error codes */
    %let errorCount=0;
    %let errorColumns=;

    proc sql noprint;
        select  count(memname) into : tableExist
        from    dictionary.tables
        where   libname eq "&library" and
                memname eq "&table";
    run;

    /* check to make sure the table exists */
    %if %eval(&tableExist eq 0) %then %do;
        %put ERROR: File &library..&table..DATA does not exist.;
        %return;
    %end;

    /* create a table with a list of column names */
    proc sql;
        create table work.columns as
            select  upcase(name) as name
            from    dictionary.columns
            where   libname eq "&library" and
                    memname eq "&table";
    run;

    /* loop through each column and check its existence */
    %do i = 1 %to &colCount;
        %let colCurr = %scan(&columns, &i, ' ');
        %let errorFlag = 0;

        /* set errorFlag to 1 if the column exists */
        data _null_;
            set work.columns(where=(name eq upcase("&colCurr"))) nobs=nobs;

            if nobs gt 0 then
                call symput('errorFlag', compress(1));
        run;

        /* increment &errorCount by one and add error column to &errorColumns */
        %if %eval(&errorFlag eq 0) %then %do;
            %let errorCount = %eval(&errorCount + 1);

            %if %eval(&errorCount eq 1) %then
                %let errorColumns = &colCurr;
            %else
                %let errorColumns = &errorColumns, &colCurr;
        %end;
    %end;

    /* delete temp table */
    proc datasets library=work nolist;
        delete columns;
    run

    /* if one or more of the columns does not exist display error message */
    %if %eval(&errorCount gt 0) %then %do;
        %put ERROR: The following columns were not found in the table &library..&table.: &errorColumns..;
        %return;
    %end;
%mend columnsExist;
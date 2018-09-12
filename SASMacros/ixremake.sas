 /**** IXREMAKE.SOURCE
 * Purpose:  Macro to recreate all indexes on a SAS dataset,
 *           based on saved information from a dataset stored
 *           by the macro ix_clear.
 *
 * Usage:    SAVELOC= is required, with a default if not supplied.
 *           (Other information is all read from this dataset)
 *
 * Notes:    UNIQUE index property will be restored, but not
 *           the NOMISS property, because I used SQL to create
 *           the indexes. If this becomes required then change
 *           to use proc datasets, but this is often slower to
 *           create an index, hence my choice of SQL.
 *
 * Author: Steve Morton, Applied System Knowledge Ltd.
 *
 * History:  Date       | Remarks
 *         2 Dec.  1999 | Initial development.
 * SBM    14 Dec.  1999 | Fix bug for 'unique' index not made.
 *                      |
 *************************************************************/

%macro ixremake(saveloc=work.save_idx);
%* Purpose: Recreate indexes based on what is in the storing;
%*          location. Designed to work with ix_clear macro. ;

data _null_;
  set &SAVELOC end=eod;
  by indxname;

  length ivarlist $ 200 ;
  retain ivarlist ;  * index variables list built over several cycles;
  length dataset $ 50;  * ready for version 8 ! ;
  retain dataset;    * defined once for whole set;

  if _n_ = 1 then do;
    call execute("proc sql;");
    dataset = trim(libname) || '.' || memname;
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

%mend ixremake;




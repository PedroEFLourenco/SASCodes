/* update path to where columnsExist.sas exists */
%include('C:\columnsExist\columnsExist.sas');

data work.test1;
    format col1 8. col2 $7. col3 $6.;
    input col1 col2 col3;

datalines;
1 apple banana
2 lamp wall
3 chair desk
;
run;

/* examples some with errors */
%columnsExist(library=work, table=test1, columns=col1 col2 col3);
%columnsExist(table=test1, columns=col4);
%columnsExist(library=work, table=test2, columns=col1 col2 col3);
%columnsExist(library=nogood, table=test1, columns=col3);
%columnsExist(library=work, table=test1);
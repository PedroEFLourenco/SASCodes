
* Debug: options mprint mlogic symbolgen;

/* LASR SERVER MACROS */
%let datapath = D:\dev\Data\sas\lasr;
%let host = localhost;


%macro startLasrServer(host=localhost,port=10010,datapath=D:\dev\Data\sas\lasr);

/* Starting the server */
libname lasr sasiola 
    startserver=(path="&datapath." keeplog=yes maxlogsize=20) 
    host=&host. 
    port=10010 
    tag='hps';

%mend startLasrServer;


%macro connectToLasr(host=localhost,port=10010,tag=hps);

libname lasr sasiola host=&host. port=&port. tag="&tag.";  

%mend connectToLasr;


%macro clearLasrLibname();

libname lasr clear;

%mend clearLasrLibname;


%macro va_load_table(lib,table);

*LIBNAME VALIBLA SASIOLA  TAG=HPS  PORT=10010 HOST="sasva.demo.sas.com";

data lasr.&table.;
	set &lib..&table.;
run;
%mend;

%macro va_unload_table(table);

*LIBNAME VALIBLA SASIOLA  TAG=HPS  PORT=10010 HOST="sasva.demo.sas.com";

proc datasets lib=lasr noprint;
	delete &table.;
run;
%mend;


%macro register_table(lib,table);

	/* Connection Settings */
	options metauser="XXXX"
        metapass="XXXX"
        metaserver="10.38.15.68"
        metaport=8561;


	/* Register Table */
	proc metalib;
       omr (library="&lib.");
       update_rule=(delete);
       select (%scan(&table.,2,%str(.)));
       report;
	run;
%mend;


%macro delete_table(table);

	* Delete table;
   proc datasets library = %scan(&table.,1,%str(.));
       delete %scan(&table.,2,%str(.));
   run;
   
   	* Update metadata;
   proc metalib;
       omr (library="%scan(&table.,1,%str(.))");
       update_rule=(delete);
       select (%scan(&table.,2,%str(.)));
       report;
   run;   
   
%mend;



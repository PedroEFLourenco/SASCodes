/**********************************************************************/
/* Macro para gerir os carregamentos para tabelas ORACLE:			  */
/*	-Faz a criação das tabelas particionadas e cria primary key 	  */
/*	 se necessário.													  */
/*	-Faz gestão de histórico.										  */
/*	-Carrega dados para a partição correcta.						  */
/*	-Só carrega dados se não houverem erros na sessão até agora		  */
/* Autor: Pedro Lourenço - SAS                            			  */
/* Data: 14/11/2016                                                   */
/**********************************************************************/

%MACRO WRITE_TO_ORACLE(SOURCE_LIB,SOURCE_TABLE,TARGET_LIB,TARGET_TABLE,PRIM_KEY_VARS,PRIM_KEY_NAME,EXEC_DATE,USER_ORACLE_CI,PASS_ORACLE_CI);
/*Se tabela a ser escrita não existe, então carrega directamente a tabela para o oracle*/


%IF %sysfunc(exist(&TARGET_LIB..&TARGET_TABLE.))=0 %THEN %DO;


data _null_;
	call symput('partition_date',compress(catx("","'",put(intnx('month',&exec_date.,1),ddmmyy10.),"'")));
run;
%put &partition_date.;
	%if &syscc. = 0 %then %do;	
		proc sql noprint;
			create table &TARGET_LIB..&TARGET_TABLE.
			(
				DBCREATE_TABLE_OPTS="partition by range(exec_date) interval(NUMTOYMINTERVAL(1,'MONTH')) 
				(partition m1 VALUES LESS THAN (TO_DATE(&partition_date.,'DD-MM-YYYY')))"
			) AS 
				select * from  &SOURCE_LIB..&SOURCE_TABLE.;
		quit;

		data _null_;
		a = UPCASE(DEQUOTE(symget('PRIM_KEY_VARS')));
			call symput('PRIMARYKEY',a);
		run;
		%PUT &PRIMARYKEY.;

		proc sql noprint;
			connect to oracle(USER=&USER_ORACLE_CI.  PASSWORD="&PASS_ORACLE_CI." 
			path=&ORACLE_PATH_CI. ); 

			EXECUTE 
			( 
				ALTER TABLE &TARGET_TABLE. 
				ADD CONSTRAINT &PRIM_KEY_NAME. PRIMARY KEY (&PRIMARYKEY.)
			)
			by oracle;
		disconnect from oracle;
		quit;

	%end;
	
%END;
%ELSE %DO;
	%if &syscc. = 0 %then %do;
	data _null_;
		a = UPCASE(symget('TARGET_TABLE'));
		call symput ('TARGET_TABLE_QUOTED',cats("","'",a,"'"));
	run;

	proc sql noprint;
		connect to oracle as OraCon(USER=&USER_ORACLE_CI.  PASSWORD="&PASS_ORACLE_CI." 
		path=&ORACLE_PATH_CI. ); 

			create table partitions as 
			select * from connection to OraCon 
			(
				select *
				from									
				user_tab_partitions 
				where table_name=&target_table_quoted.
			);
		disconnect from OraCon;
	quit;

	data _null_;
		if 0 then set partitions nobs=obs;
		call symput('num_partitions',obs);
	run;
	%put &num_partitions.;

	data _null_;
	mes_a_carregar = put(month(&exec_date.),8.);
	call symput('mes_a_carregar',mes_a_carregar);

	run;

	%put &mes_a_carregar.;

	data _null_;
		/*Só para garantir que tem valor numa primeira execução*/
		call symput('ultimo_mes_carregado',1);
		set SCFMAEXP.PROCESS_METADATA(obs=1);
		call symput('ultimo_mes_carregado',month(auto_last_load));
	run;
	
		%if &num_partitions. <= 23 or (&num_partitions. = 24 and &mes_a_carregar. = &ultimo_mes_carregado.) %then %do;
			
			proc append base=&TARGET_LIB..&TARGET_TABLE. data=&SOURCE_LIB..&SOURCE_TABLE.;
			run;

		%end; 
		%else %do;

			data _null_;
				set partitions(obs=1);
				call symput('particao_a_apagar',partition_name);
			run;

			proc sql noprint;
				connect to oracle(USER=&USER_ORACLE_CI.  PASSWORD="&PASS_ORACLE_CI." 
				path=&ORACLE_PATH_CI. ); 

				EXECUTE 
				( 
					ALTER TABLE .&TARGET_TABLE. 
					DROP PARTITION &particao_a_apagar.
				)
				by oracle;
				disconnect from oracle;
			quit;

			
			proc append base=&TARGET_LIB..&TARGET_TABLE. data=&SOURCE_LIB..&SOURCE_TABLE.;
			run;

		%end;
	%end;
%END;
%MEND WRITE_TO_ORACLE;

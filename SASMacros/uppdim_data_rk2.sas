/******************************************************************/
/* Name:UPDDIM_DATA_RK                                            */
/* Title: Update Dimensions Tables                                */
/* Purpose:                                                       */
/*   Macro that update dimensons table by receiving and comparing */
/*   the business dimensons and the warehouse dimensons           */
/* Obs:                                                           */
/*                                                                */
/*                                                                */
/* Parameters:                                                    */
/*  phdim    		=  Dimension physical (lib.ds)                */
/*  bus_date_column = name of the column with the                 */
/*					date from input data                          */
/*  rename_bus_date_column= rename statement for date column      */
/*  keep_date_column= keep date column on PHDIM (Y(es)/N(o))      */
/*  valid_high_dttm = High Date value ('31DEC5999:00.00.00.0'dt)  */
/*  PROCESSED_DTTM	= Column with Processing date 			      */
/*  bus      		= Business update table name (lib.ds)         */
/*  keyneg   		=  Index business name in dimension           */
/*  kncols   		=  Business key                               */
/*  atnames  		=  names of the columns subject to generate   */
/*              		history if they change values             */
/*  stnames  		=  names of the columns not subject to        */
/*						generate history if they change values    */
/*  mtnames  		=  names of the columns that will update      */
/*                     the values without generating history      */
/*  flag_drop_index_append = Flag with drop index strategy for    */
/*						     new records (Y(es)/N(o)/P(ercent))   */
/*  percent_drop_index = Percentage threshold between new records */
/*						 and phdim table records for drop index   */
/*						 strategy                 				  */
/*                                                                */
/*                                                                */
/******************************************************************/


%macro upddim_data_rk2(
phdim=,
bus_date_column=,
rename_bus_date_column=, 
keep_date_column=,
VALID_HIGH_DTTM=,
PROCESSED_DTTM=PROCESSED_DTTM,
bus=,
keyneg=,
kncols=,
atnames=,
stnames=,
mtnames=,
flag_drop_index_append=Y,
percent_drop_index=
);

proc datasets lib=work nolist;
delete diferent diff_app diff_upd match nonmatch save_idx tempcols;
quit;

 %* ensure all parameters are upper case;
 %let phdim  =  %upcase(&PHDIM);     * dimension physical;
 %let bus_date_column = %upcase(&bus_date_column); *Campo com data proveniente da tabela BUS;
 %let rename_bus_date_column = %upcase(&rename_bus_date_column);
 %let keep_date_column = %upcase(&keep_date_column); *Flag a indicar se campo com data fica guardado na tabela phdim;
 %let VALID_HIGH_DTTM = %upcase(&VALID_HIGH_DTTM); *Valor com HIDATE;

 %let bus    =  %upcase(&BUS);       * business update table name (lib.ds);


 %let keyneg =  %upcase(&KEYNEG);    * index business name in dimension ;
 %let kncols =  %upcase(&KNCOLS);    * business key;

 %let atnames = %upcase(&ATNAMES);   * names of the columns subject to generate;
                                                                         * history if they change values;
 %let stnames = %upcase(&STNAMES);   * names of the columns not subject to generate;
                                                                         * history if they change values;
 %let mtnames = %upcase(&MTNAMES);   *names of the columns that will update the values;
                                     *without generating history;
 %let buslib  = %scan(&BUS, 1, %str(.));   * libname of the bus dataset;
 %let busname = %scan(&BUS, 2, %str(.));   * memname of the bus dataset;
 %let dimlib  = %scan(&PHDIM, 1, %str(.));   * libname of the dim dataset;
 %let dimname = %scan(&PHDIM, 2, %str(.));   * memname of the dim dataset;
 %let colsmiss =;

 %let flag_drop_index_append = %upcase(&flag_drop_index_append.);
 
 %if "&flag_drop_index_append" eq "Y" or "&flag_drop_index_append" eq "N" or "&flag_drop_index_append" eq "P" %then %do;
 %end;
 %else %do;
	%let flag_drop_index_append = Y;
 %end;

%if "&flag_drop_index_append" eq "P" %then %do;
	%if "&percent_drop_index" eq "" or "&percent_drop_index" eq "." %then %do;
		%let flag_drop_index_append = Y;
	%end;
	%else %if &percent_drop_index gt 100 or &percent_drop_index lt 0 %then %do;
		%let flag_drop_index_append = Y;
	%end; 
%end;


proc sql noprint;
        create table tempcols as
                select name
                from dictionary.columns
                where libname="&dimlib" and memname="&dimname" and
                upcase(name) not in ('VALID_FROM_DTTM', 'VALID_TO_DTTM',"&PROCESSED_DTTM")
                except
                select name
                from dictionary.columns
                where libname="&buslib" and memname="&busname";
        select name into :colsmiss separated by ' '
                from tempcols;
quit;


* ensure business updates are in sequence;

%if "&rename_bus_date_column" eq "" %then %do;

	proc sort data=&BUS out=_bus_sorted;
	 by &KNCOLS;
	run;

%end;

%else %do;

	proc sort data=&BUS(rename=(&rename_bus_date_column)) out=_bus_sorted;
	 by &KNCOLS;
	run;

%end;


proc sql noprint;
        select name into :varbus separated by ' '
                from dictionary.columns
                where libname="WORK" and memname="_BUS_SORTED" 
				%if "&keep_date_column" ne "Y" %then %do;
				and upcase(name) not in ("&bus_date_column.")
				%end; 
				;

quit;

%local word wordnum n_atnames n_stname n_mtnames aux_renames1 aux_renames2;
%let wordnum=1;
%let word=*;
%let n_atnames=;
%let n_stnames=;
%let n_mtnames=;

%let aux_renames1=;
%let aux_renames2=;

%do %until("&WORD" eq "");
  %let word = %upcase(%scan(&varbus,&WORDNUM,%STR( )));
  %if "&WORD" ne "" %then %do;
  				
                %if %index(&atnames, &word) ne 0 %then %do;
                        %let n_atnames = &n_atnames &WORD;
                %end;
                %if %index(&stnames, &word) ne 0 %then %do;
                        %let n_stnames = &n_stnames &WORD;
                %end;
                %if %index(&mtnames, &word) ne 0 %then %do;
                        %let n_mtnames = &n_mtnames &WORD;
                %end;

				%let aux_renames1 = %str(&aux_renames1. &word = aux_etls_v&wordnum. ;);
				%let aux_renames2 = %str(&aux_renames2. aux_etls_v&wordnum. = &word. ;);
  %end;
  %let wordnum = %eval(&WORDNUM + 1);
%end;


proc sql noprint;
        select name into :vardim separated by ' '
                from dictionary.columns
                where libname="&dimlib" and memname="&dimname";
quit;

%local word wordnum vars_ig vars_igv;
%let wordnum=1;
%let word=*;
%let vars_ig=;
%let vars_igv=;

%do %until("&WORD" eq "");
  %let word = %upcase(%scan(&n_mtnames,&WORDNUM,%STR( )));
  %if "&WORD" ne "" %then %do;
     %let vars_ig = &vars_ig &WORD=X_&WORD;
         %let vars_igv = &vars_igv &WORD=X_&WORD %STR(;);
  %end;
  %let wordnum = %eval(&WORDNUM + 1);
%end;



%if "&n_mtnames" ne "" %then %do;
* update the mtnames vars;
    data &phdim(keep=&vardim);
      set _bus_sorted(keep = &KNCOLS &n_mtnames rename=(&vars_ig));
      key_mch=0;
      _iorc_=0;
      do while(_iorc_ ne %sysrc(_DSENOM));
         modify &phdim key=&KEYNEG;
         if _iorc_ eq %sysrc(_DSENOM) and key_mch ne 1 then
          do;
            _iorc_ = 0;
            _error_ = 0;
            delete;
          end;
         else
         if _iorc_ eq %sysrc(_SOK) then do;
           key_mch=1;
		   &PROCESSED_DTTM. = datetime();
            &vars_igv
            replace;
         end;
         else do;
          _error_=0;
         end;
      end;
    drop key_mch;
    run;
%end;




* Select the rows that match and dont by the key, from dim and bus;
* In the dim pick up only the actual(related to the date of run) rows;

data match nonmatch(keep=&varbus VALID_FROM_DTTM VALID_TO_DTTM);

	set _bus_sorted;

	&aux_renames2;
	

	%if "&keep_date_column" eq "Y" %then %do;
		aux_campo_data_bus = &bus_date_column.;
	%end;

	MIN_VALID_FROM_DTTM = .;
	key_mch=0;
	key_mch_lt_min = 0;
	key_mch_datas = 0;
	_iorc_=0;

	do while(_iorc_ ne %sysrc(_DSENOM));
		set &PHDIM key=&KEYNEG;
		if _iorc_ = %sysrc(_DSENOM) and key_mch ne 1 then do;
			_error_=0;
			VALID_FROM_DTTM = &bus_date_column.;
			VALID_TO_DTTM = &VALID_HIGH_DTTM.;
			&PROCESSED_DTTM. = datetime();
			%if "&keep_date_column" eq "Y" %then %do;
				&bus_date_column. = aux_campo_data_bus;
			%end;
			output nonmatch;
		end;
		else if _iorc_ = %sysrc(_SOK) then do;

			key_mch=1;

			%if "&keep_date_column" eq "Y" %then %do;
				if aux_campo_data_bus>=VALID_FROM_DTTM and aux_campo_data_bus<=VALID_TO_DTTM then do;
					key_mch_datas = 1;
					&bus_date_column. = aux_campo_data_bus;
					output match;
				end;
			%end;

			%else %do;
				if &bus_date_column>=VALID_FROM_DTTM and &bus_date_column<=VALID_TO_DTTM then do;
					key_mch_datas = 1;
					output match;
				end;
			%end;

			

			/*Controla casos em que registo é anterior a qualquer data já existente nos dados.
			A ideia é obter a menor data de VALID_FROM_DTTM existente na tabela PHDIM e aproveitá-la para o caso de 
			o registo que vem do BUS não casar com nenhum registo entre as datas de from e to*/
			else do;

				if MIN_VALID_FROM_DTTM eq . then do;
					MIN_VALID_FROM_DTTM = VALID_FROM_DTTM;
				end;
				else do;
					MIN_VALID_FROM_DTTM = min(MIN_VALID_FROM_DTTM,VALID_FROM_DTTM);
				end;
				
				%if "&keep_date_column" eq "Y" %then %do;
					if  aux_campo_data_bus lt MIN_VALID_FROM_DTTM then do;
						key_mch_lt_min = 1;
					end;
					&bus_date_column = aux_campo_data_bus;
				%end;
				%else %do;
					if  &bus_date_column lt MIN_VALID_FROM_DTTM then do;
						key_mch_lt_min = 1;
					end;
				%end;

			end;

		end;

		else do;
		
			_error_ = 0;

			/*Verifica se houve algum lookup que fez match com chave mas que não tenha emparelhado entre nenhum para de datas.
			Nesta situação, adiciona-se um registo com datas anteriores ao primeiro registo existente na tabela PHDIM*/

			if key_mch_lt_min eq 1 and key_mch_datas ne 1 then do;

				%if "&keep_date_column" eq "Y" %then %do;
					VALID_FROM_DTTM=aux_campo_data_bus;
				%end;
				%else %do;
					VALID_FROM_DTTM=&bus_date_column;
				%end;


				VALID_TO_DTTM=MIN_VALID_FROM_DTTM - 1;
				&PROCESSED_DTTM. = datetime();

				&aux_renames1;

				output nonmatch;

			end;

		end;

			
   
 	end; /*Fim do ciclo do*/

	drop key_mch key_mch_lt_min key_mch_datas;

run;

%if "&N_ATNAMES" ne "" %then %do;
proc compare base=match
          compare=_bus_sorted
          out=diferent(drop= _obs_)
          outbase outcomp outnoequal noprint;
 by &KNCOLS;
 id VALID_FROM_DTTM VALID_TO_DTTM 
				%if "&keep_date_column" ne "Y" %then %do;
				&bus_date_column.
				%end; 
				;
 var &N_ATNAMES;
run;

data diferent;
merge _bus_sorted(in=a  keep=&KNCOLS &n_stnames &n_mtnames) diferent(in=b);
by &KNCOLS;
if b;
run;

data diferent;
merge match(in=a  keep=&KNCOLS &colsmiss) diferent(in=b);
by &KNCOLS;
if b;
run;

* Process the new ones;

data diff_upd(keep=&kncols uVALID_TO_DTTM uVALID_FROM_DTTM) 
diff_app(
		drop=uVALID_TO_DTTM uVALID_FROM_DTTM
		%if "&keep_date_column" ne "Y" %then %do;
			&bus_date_column. 
		%end;
		);
        set diferent;

        drop _type_ xVALID_TO_DTTM;

		retain xVALID_TO_DTTM;
		

        if _type_="BASE" then do;
                xVALID_TO_DTTM=VALID_TO_DTTM;
                delete;
        end;
        else do;
				
                uVALID_TO_DTTM = xVALID_TO_DTTM;
				uVALID_FROM_DTTM = &bus_date_column. - 1;
                output diff_upd;
                VALID_FROM_DTTM = &bus_date_column.;
                VALID_TO_DTTM=xVALID_TO_DTTM;
				&PROCESSED_DTTM. = datetime();
                output diff_app;
        end;
run;

* now update records;

    data &phdim;
      set diff_upd(keep = &KNCOLS uVALID_TO_DTTM uVALID_FROM_DTTM) ;
      key_mch=0;
      _iorc_=0;
      do while(_iorc_ ne %sysrc(_DSENOM));
         modify &phdim key=&KEYNEG;
         if _iorc_ eq %sysrc(_DSENOM) and key_mch ne 1 then
          do;
            _iorc_ = 0;
            _error_ = 0;
            delete;
          end;
         else
         if _iorc_ eq %sysrc(_SOK) then do;
           key_mch=1;
           if VALID_TO_DTTM eq uVALID_TO_DTTM then do;
		        VALID_TO_DTTM = uVALID_FROM_DTTM;
				&PROCESSED_DTTM. = datetime();
                replace;
            end;
         end;
         else do;
          _error_=0;
         end;
      end;
    drop key_mch;drop uVALID_TO_DTTM uVALID_FROM_DTTM;
    run;
%end;

* join diff_app with the news rows (nonmatch);
proc append
  base= diff_app
  data=nonmatch FORCE;
run;

/*Verifica qual a estratégia a usar a nível de Drop de Indíces antes da inserção de registos novos
No caso de estar definido o parâmetro P, terá de se verificar se o rácio entre registos a inserir e o número de registos 
do modelo é superior ou inferior ao número de registos da tabela PHDIM */
%if "&flag_drop_index_append" eq "P" %then %do;

	%local obs_dim;
	%local obs_app;
	%let obs_dim = 0;
	%let obs_app = 0;	

	proc sql noprint;
	select nlobs into: obs_dim
	from dictionary.tables
	where libname eq "&dimlib" and memname eq "&dimname";
	quit;
 
	proc sql noprint;
	select nlobs into: obs_app
	from dictionary.tables
	where libname eq "WORK" and memname eq "DIFF_APP";
	quit;

	data _null_;
		pct_racio = (&obs_app. / &obs_dim.) * 100; 
		if pct_racio ge &percent_drop_index then do;
			call symputx('flag_drop_index_append','Y');
		end;
		else do;
			call symputx('flag_drop_index_append','N');
		end;
	run;


%end;

/* drop the indexes */
%if "&flag_drop_index_append" eq "Y" %then %do;
	%ix2clear(dataset=&phdim);
%end;


* now append new records;
proc append
  base= &phdim
  data=diff_app FORCE;
run;

/* recreate the indexes */
%if "&flag_drop_index_append" eq "Y" %then %do;
	%ixremake;
%end;

%mend upddim_data_rk2;

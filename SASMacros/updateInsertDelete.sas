%macro updateInsertDelete(tabela_fonte=,tabela_destino=,chave=,dados=);
/*
Macro para actualizar e/ou apagar registos de uma tabela com base 
num conjunto de variáveis de chave e variáveis de dados (em caso de update).
*/

/*Prepara Where clause com base nas variáveis de chave de forma a poder fazer o select
em que fazemos o match entre a chave da tabela de destino e a da tabela de fonte*/
	data _null_;
		number_of_variables = countw(&chave,",");
		i=1;
		length where_clause $512.;

		do while (i <= number_of_variables);
			if i > 1 then
				call catx(" ",where_clause,"and");
			next_var_source = catx(".","a",scan(&chave.,i));
			next_var_dest = catx(".","b",scan(&chave.,i));
			next_clause = catx("=",next_var_source,next_var_dest);
			call catx("",where_clause,next_clause);
			i+1;
		end;

		call symput('where_clause',where_clause);
	run;

	proc sql noprint;
		create table updateDeleteRecords as
			select a.* from &tabela_fonte. as a, &tabela_destino. as b where &where_clause.;
	quit;

	data _null_;
		if 0 then
			set updateDeleteRecords nobs=nobs;
		call symput('nrecords',nobs);
	run;
	/*Caso nrecords=0 significa que não há chaves em comum entre a fonte e o destino,
	portanto é tudo registos novos. Basta-nos fazer o append para os inserir na tabela*/
	%if &nrecords. = 0 %then
		%do;

			proc append data=&tabela_fonte. base=&tabela_destino.;
			run;

		%end;
	/*
	Caso nrecords^=0 significa que temos chaves em comum entre a fonte e o destino, 
	portanto haverá registo a apagar ou a actualizar
	*/
	%else
		%do;
	/*
	Preparação da claúsula where para verificar se há registos para apagar,
	criando uma tabela com esses mesmos registos.
	A ideia é nessa tabela ter todos os registos em que as variáveis de dados
	tiverem valor missing
	*/
			data _null_;
				number_of_variables = countw(&dados.,",");
				put number_of_variables;
				i=1;
				length where_clause $512.;

				do while (i <= number_of_variables);
					if i > 1 then
						call catx(" ",where_clause,"and");
					next_var = scan(&dados.,i);
					put next_Var;
					next_clause = catx("=",next_var,.);
					call catx("",where_clause,next_clause);
					i+1;
				end;

				call symput('where_clause_delete',where_clause);
			run;

			/*
	Preparação da claúsula where para verificar se há registos para actualizar,
	criando uma tabela com esses mesmos registos.
	A ideia é nessa tabela ter todos os registos em pelo menos uma das variáveis de dados 
	não tiver valor missing
	*/

			data _null_;
				number_of_variables = countw(&dados.,",");
				put number_of_variables;
				i=1;
				length where_clause $512.;

				do while (i <= number_of_variables);
					if i > 1 then
						call catx(" ",where_clause,"or");
					next_var = scan(&dados.,i);
					put next_Var;
					next_clause = catx("^=",next_var,.);
					call catx("",where_clause,next_clause);
					i+1;
				end;

				call symput('where_clause_update',where_clause);
			run;

			proc sql noprint;
				create table toDelete as
					select * from updateDeleteRecords where &where_clause_delete.;
			quit;

			proc sql noprint;
				create table toUpdate as
					select * from updateDeleteRecords where &where_clause_update.;
			quit;
	/*
	Preparação da claúsula by com a chave das tabelas para utilizar depois nos 
	proc sorts e merges de update e delete
	*/
			data _null_;
				number_of_variables = countw(&chave.,",");
				put number_of_variables;
				i=1;
				length by_clause $256.;

				do while (i <= number_of_variables);
					by_clause = catx(" ",by_clause,scan(&chave.,i));
					i+1;
				end;

				call symput('by_clause',by_clause);
			run;

			proc sort data=&tabela_destino.;
				by &by_clause.;
			run;

			proc sort data=toUpdate;
				by &by_clause.;
			run;

			proc sort data=toDelete;
				by &by_clause.;
			run;

			/*update*/
			data &tabela_destino.;
				merge &tabela_destino. toUpdate;
				by &by_clause.;
			run;

			/*delete*/
			data &tabela_destino. apagados;
				merge &tabela_destino.(in=a) toDelete(in=b);
				by &by_clause.;

				if b then
					output apagados;
				else output &tabela_destino.;
			run;
		%end;
%mend;

%updateInsertDelete(tabela_fonte=work.fonte_entradas,tabela_destino=vaauxtab.entradaslojas,chave="data,StoreName",dados="visitors");
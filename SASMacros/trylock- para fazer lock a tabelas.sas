%macro trylock(member=,timeout=5,retry=1,return_table=);
	%local starttime;

	%let starttime = %sysfunc(datetime());
	%do %until(&syslckrc. <= 0 or %sysevalf(%sysfunc(datetime()) > (&starttime. + &timeout.)));
		%put trying open ...;
	
		data _null_;
			length dsid 8.;

			/* Try opening the dataset till success or timeout */
			do until (dsid = 0 or datetime() > (&starttime + &timeout));

				file=filename('&member.',tabela);
				dsid = fopen('table','U');
				/* The dataset could not be opened, so retry */
				if (dsid > 0) then rc = sleep(&retry);
			end;

			call symput('fileState', dsid);
			
		run;

		%if ( &fileState. <= 0) %then 
			%do;
				%let rc = %sysfunc(fclose(&fileState.));
				%put trying lock ...;
				lock &member;
				%put syslckrc=&syslckrc;
		%end;
			/* Successful in opening the dataset */

	data lock_state;
		format lock 8.;
		lock = symget('syslckrc');
	run;
	
	%end;

	proc append data=lock_state base=&return_table. force;
	run;
	
%mend trylock;

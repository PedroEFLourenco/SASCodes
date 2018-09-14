

%macro logfile(file);
proc printto log="&file.";
run;

%put _all_;
%mend;



/* HTML Macros */



%macro css;
/* put '<link rel="stylesheet" type="text/css" href="<CSS_PATH>">';   OFICIAL */

/* Testes */



'<style type="text/css">' /

'body {' /
    'background-color: #F7F7F7; ' /
	'text-align: center;' /
'}' /

'.button_example{' /
'border:1px solid #13ABAB;-webkit-box-shadow: #13ABAB 0px 0px 5px ;-moz-box-shadow: #13ABAB 0px 0px 5px ; box-shadow: #13ABAB 0px 0px 5px ; -webkit-border-radius: 5px; -moz-border-radius: 5px;border-radius: 5px;font-size:12px;font-family:arial, helvetica, sans-serif; padding: 7px 10px 7px 10px; text-decoration:none; display:inline-block;text-shadow: 0px 1px 0 rgba(255,255,255,0.4);font-weight:bold; color: #0C7D7D;' /
' background-color: #13ABAB; background-image: -webkit-gradient(linear, left top, left bottom, from(#13ABAB), to(#99E0CE));' /
' background-image: -webkit-linear-gradient(top, #13ABAB, #99E0CE);' /
' background-image: -moz-linear-gradient(top, #13ABAB, #99E0CE);' /
' background-image: -ms-linear-gradient(top, #13ABAB, #99E0CE);' /
' background-image: -o-linear-gradient(top, #13ABAB, #99E0CE);' /
' background-image: linear-gradient(to bottom, #13ABAB, #99E0CE);filter:progid:DXImageTransform.Microsoft.gradient(GradientType=0,startColorstr=#13ABAB, endColorstr=#99E0CE);' /
' float:left;' /
'}' /

'.button_example:hover{' /
' border:1px solid #8ed058;' /
' background-color: #8ED058; background-image: -webkit-gradient(linear, left top, left bottom, from(#8ED058), to(#7BB64B));' /
' background-image: -webkit-linear-gradient(top, #8ED058, #7BB64B);' /
' background-image: -moz-linear-gradient(top, #8ED058, #7BB64B);' /
' background-image: -ms-linear-gradient(top, #8ED058, #7BB64B);' /
' background-image: -o-linear-gradient(top, #8ED058, #7BB64B);' /
' background-image: linear-gradient(to bottom, #8ED058, #7BB64B);filter:progid:DXImageTransform.Microsoft.gradient(GradientType=0,startColorstr=#8ED058, endColorstr=#7BB64B);' /
'}' /


/*FORM CSS*/

'.form-grey {' /
'    margin-left:auto;' /
'    margin-right:auto;' /
'	text-align: left	;' /
'    width: 500px;' /
'    background: #F7F7F7;' /
'    padding: 25px 15px 25px 10px;' /
'    font: 14px Calibri, Calibri, Times, serif;' /
'    color: #888;' /
'    text-shadow: 1px 1px 1px #FFF;' /
'    border:1px solid #E4E4E4;' /
'}' /

'.inputtext {' /
'    background: #FDFDFD;' /
'    -webkit-appearance:none; ' /
'    -moz-appearance: none;' /
'    text-indent: 0.01px;' /
'    text-overflow: '';' /
'    width: 100%;' /
'    height: 25px;' /
'    line-height: 25px;' /
'	border-bottom-color: #000000;' /
'	border-bottom-left-radius: 3px;' /
'	border-bottom-right-radius: 3px;' /
'	border-bottom-style: solid;' /
'	border-bottom-width: 1px;' /
'	border-left-color: #000000;' /
'	border-left-style: solid;' /
'	border-left-width: 1px;' /
'	border-right-color: #000000;' /
'	border-right-style: solid;' /
'	border-right-width: 1px;' /
'	border-top-color: #000000;' /
'	border-top-left-radius: 3px;' /
'	border-top-right-radius: 3px;' /
'	border-top-style: solid;' /
'	border-top-width: 1px;' /
'}' /

'.inputtextarea {' /
'    background: #FDFDFD;' /
'    -webkit-appearance:none; ' /
'    -moz-appearance: none;' /
'    text-indent: 0.01px;' /
'    text-overflow: '';' /
'     width: 100%;' /
'    height: 25px;' /
'    line-height: 25px;' /
'	border-bottom-color: #636363;' /
'	border-bottom-left-radius: 3px;' /
'	border-bottom-right-radius: 3px;' /
'	border-bottom-style: solid;' /
'	border-bottom-width: 1px;' /
'	border-left-color: #636363;' /
'	border-left-style: solid;' /
'	border-left-width: 1px;' /
'	border-right-color: #636363;' /
'	border-right-style: solid;' /
'	border-right-width: 1px;' /
'	border-top-color: #636363;' /
'	border-top-left-radius: 3px;' /
'	border-top-right-radius: 3px;' /
'	border-top-style: solid;' /
'	border-top-width: 1px;' /
'	resize:vertical;' /
'}' /

'.inputlabel {' /
'    float: left;' /
'    width: 25%;' /
'    color: #888;' /
'	text-align: right;' /
'}' /

'.loader {' /
'	position: fixed;' /
'	left: 0px;' /
'	top: 0px;' /
'	width: 100%;' /
'	height: 100%;' /
'	z-index: 9999;' /
"	background: url('http://sasva.demo.sas.com/gray75_polling.gif') 50% 50% no-repeat rgb(249,249,249);" /
'}' /



/**/


/*Fecha style tag*/
 '</style>' /

%mend;



/*===============================================================================================================
Página de selecção de cliente para Administradores 
===============================================================================================================*/

%macro admin_selec;

	data _null_;
		set ginfo.sysinfo end=fim;
		file _webout;

		if _N_ = 1 then do;
			put '<form action="'"&_url"'" id="cform">';
			put '<INPUT TYPE="HIDDEN" NAME="_PROGRAM" VALUE="'"&_program."'">';
  			put 'Cliente:<input type="text" name="cliente">';
  			put '<input type="submit">';
			put '</form>';


		/*
			put "<body>" /
				"	<select name=""cliente""> ";
		end;

		put "<option value='" cliente "'>" cliente "</option>";

		if fim = 1 then do;

			put "	</select> ";

	

			put '<input id="mybutton" class="button" value="ok" type="Submit" href='''"&_url?_program=&_program."'&amp;status=0&amp;cliente=cliente'' />';


			put "<script type=""text/javascript"">";
      		put 'var e = document.getElementById("cliente");';
			put 'var strUser = e.options[e.selectedIndex].text;';
			put 'document.getElementById(''mybutton'').href += strUser;';
			put '</script>';
*/
			put "</body> ";
		end;
	run;
	
%mend;


/* GOOGLE MAPS macros */

%macro prepara_regions;
/*prepara regions */

proc sql noprint;
	create table custom_zmc1 as 
	select a.*, b.AREA_NOME as AREA_NOME, b.AREA_ID
	from maps.regions as a, mddados.GONDOMAR_AREA_DIM as b
	where put(a.ID,comma9.) =b.AREA_ID;
quit;


data regions;
	set custom_zmc1(keep= GEO_ID LAT LONG AREA_NOME AREA_ID nivel);
	rename GEO_ID=REGION
			LONG=lng;
	acolor="#00ff00";
	AREA_NOME =translate(AREA_NOME,'','<>/\"ã');
run;

proc sql noprint;
	create table regions as
	select a.*, b.AREA_TIPO, b.NUM_CLIENTES, b.STATUS, b.NUM_EVENTOS
	from regions as a, staging.area_stats as b
	where a.area_id = b.area_id;
quit;
%mend;


%macro acrescenta_regions;

/* 5. Add regions */
data _null_;
	file _webout mod;
	set regions end=fim;
	by region;
	length i $3;
	retain n 0;


	if first.region then put 'var border = [';
	if not last.region then put 'new google.maps.LatLng(' lat ', ' lng '),';
	if last.region then
	do;
		n + 1;
		i = strip(n);
		put
			'new google.maps.LatLng(' lat ', ' lng ') ];' /
  			'var mypoly' i '= new google.maps.Polygon({' /
    		'paths: border,' /
    		'strokeColor: "#FF0000",' /
    		'strokeOpacity: 0.8,' /
    		'strokeWeight: 1,' /
    		'fillColor: "' acolor '",' /
    		'fillOpacity: 0.2' /
  			'});' /
			'mypoly' i +(-1) '.setMap(map);' /
			'var info' i '= "<div style=''width:260px''><b>ZMC ID:</b> ' region  '<br><b>ZMC Name: </b>' AREA_NOME '<br><b>AREA ID: </b> ' AREA_ID '<br><b>N. Clientes:</b> ' NUM_CLIENTES '<br><b>Ev. Abertos: </b> ' NUM_EVENTOS '<br></div>";' / 
			'google.maps.event.addListener(mypoly' i ', "click", function(event) {' /
			'infowindow.setContent(info' i ');' /
			'infowindow.setPosition(event.latLng);' /
			'infowindow.open(map);' /
			'});'
		;
	end;
run;

%mend;

%macro niveis;
	%if %symexist(nivel) %then %do;
		%if &nivel = 0 %then %do;
			data regions;
				set custom_zmc1(keep= GEO_ID LAT LONG AREA_NOME AREA_ID nivel);
				rename GEO_ID=REGION
				LONG=lng;
				acolor="#00ff00";
				AREA_NOME =translate(AREA_NOME,'','<>/\"ã');
			run;
		%end;
		%else %do;
			data regions;
				set regions;
				if nivel=&nivel.;
			run;
		%end;
	%end;
%mend;

%niveis;


/* Add colors */
%macro add_colors;
	proc sql noprint;
		create table temp_events as
		select distinct a.area_id, count(num_eventos) as num_eventos
		from mddados.gondomar_eventos_stats a
		group by area_id;
		create table temp_others as
		select distinct a.area_id as area_id,
			0 as num_eventos
		from mddados.gondomar_area_dim a
		where a.area_id not in (select area_id from temp_events);
	quit;

	proc append base=temp_events data=temp_others force;
	run;


	proc format;
		value colors
		0 = "#33CC33"
		1 - 15 = "#FFFF00"
		16 - high = "#FF0000";
	run;

	data colors;
		set temp_events;
		length acolor $ 7;
		acolor = put(num_eventos,colors.);
	run;


	proc sql noprint;
	create table regions_2 as
	select a.*, b.acolor as acolor2
	from regions as a, colors as b
	where a.area_id = b.area_id;
	quit;

	data regions;
		set regions_2(drop=acolor);
		rename acolor2 = acolor;
	run;
%mend;


%macro filtra_area;
/* validar o nome da variavel que esta a ser passada para filtro de Area*/
	%if %symexist(myselect) %then %do;
		%if &myselect ne Todas %then %do;
			data regions;
				set regions;
						if area_id = "&myselect.";
			run;
		%end;
	%end;
%mend;





%macro determina_centro;

proc means data=regions noprint;
	var lat lng;
	output out=dataspan (keep=minlat maxlat minlng maxlng) min(lat)=minlat max(lat)=maxlat min(lng)=minlng max(lng)= maxlng;
run;

data centerdata;
	set dataspan;
	clat = minlat + (maxlat - minlat)/2;
	clng = minlng + (maxlng - minlng)/2;
run;


%mend;

%macro inicia_google_maps(zoom);
/* 4. Initialize map */
data _null_;
	file _webout mod;
	set centerdata;
	put
	'<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false"></script>' /
	'<script type="text/javascript">' /
	'function initialize() {' /
		'var cpoint = new google.maps.LatLng(' clat ',' clng ');' / 
		'var mapOptions = {' /
			"zoom: &zoom.," /
			'center: cpoint,' /
			'mapTypeId: google.maps.MapTypeId.ROADMAP' /
		'}' /
		'var map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions);' /
		'var infowindow = new google.maps.InfoWindow();' /
	;
run;
%mend;




%macro acrescenta_pontos;


/* Add Points */


/*create points table */
/* Alternativa */
proc sql noprint;
	create table points as
	select a.area_id, b.PM_ID, b.X, b.Y
	from regions as a, staging.pm_geo_2 as b
	where a.area_id = b.area_id;
quit;

PROC SQL;
   CREATE TABLE WORK.POINTS AS 
   SELECT DISTINCT t1.AREA_ID, 
          t1.PM_ID, 
          t1.X, 
          t1.Y, 
          t2.NOME, 
          t2.LOCAL, 
          t2.ESTADO, 
          t2.DATA_ULTIMA_ALTERACAO
      FROM WORK.POINTS t1
           INNER JOIN STAGING.PM_STATS t2 ON (t1.PM_ID = t2.PM_ID);
QUIT;

data _null_;
	file _webout;
	set points;
	n + 1;
	i = strip(n);
	put 'var pll' i '= new google.maps.LatLng(' Y ', ' X ');' /
		'var marker' i ' = new google.maps.Marker({' /
		'position: pll' i+(-1) ',' /
    	'title:"' PM_ID+(-1) '"' /
		'});' /
		'marker' i+(-1) '.setMap(map);';

	put 'var pinfo' i '= "<div style=''width:250px''><b>PM ID:</b> ' PM_ID  '<br><b>Nome: </b>' NOME '<br><b>Estado: </b>' ESTADO '<br><b>Local: </b> ' LOCAL ' <br><b>D. Alteração: </b>' DATA_ULTIMA_ALTERACAO '<br></div>";' / 
		'google.maps.event.addListener(marker' i ', "click", function(event) {' /
		'infowindow.setContent(pinfo' i ');' /
		'infowindow.setPosition(event.latLng);' /
		'infowindow.open(map);' /
		'});';

run;


%mend;	


%macro acrescenta_condutas;
data _null_;
	file _webout mod;
		put 
		 'var ctaLayer = new google.maps.KmlLayer({' /
	    'url: "https://cld.pt/dl/download/e072ff2c-1317-4737-837e-465899ce50a2/condutas_2.kml?download=true"' /
		  '});' /
		 ' ctaLayer.setMap(map);';
run;
%mend;


%macro google_div;
	"<div id='map-canvas' style='max-width:230px;max-height:95px;width: auto;height: auto; border: 2px solid #3872ac;'></div>" /
%mend;

%macro google_div_loading(width,height);
	"<div style='background: transparent url(http://sasva.demo.sas.com/gray75_polling.gif) no-repeat center center;'><div id='map-canvas' style='border:none;position: static; max-width:&width.;height:&height.; border: 1px solid #3872ac;'></div></div>" /
%mend;

%macro google_div_dynamic(width,height);
	"<div id='map-canvas' style='border:none;position: static; max-width:&width.;height:&height.; border: 1px solid #3872ac;'></div>" /
%mend;

%macro controlo_filtro_area;

	'<form action="'"&_url"'" id="cform">' /
	'<INPUT TYPE="HIDDEN" NAME="_PROGRAM" VALUE="'"&_program."'">' /
  	'Area ID:<input type="text" name="area_id">' /
  	'<input type="submit">' /
	'</form>' /

%mend;


%macro table_select_box(selected,table,showvar,outputvar,form, text,macrovar);

	/*if empty, select the first one*/
 	%if &selected. eq %then %do;
 		%let selected=1;
 	%end;
	

	/*get the actual selected value from the numeric reference*/
	/*Except if the argument is a priority because it already comes as selected value*/
	%if "&macrovar" ~= "s_prioridade" %then %do; 
		data _null_;
			set &table.;
			if id = &selected then do;
				call symput("selected",type);
			end;
		run;
	%end;
	%else %do;
		data _null_;
			set &table.;
			if type_orig = "&selected." then do;
				call symput("selected",type);
			end;
		run;
	%end;

	proc sql noprint;
		create table selected_aux as 
		select distinct &showvar._orig, &outputvar.
		from &table.;
	quit;

	data _null_;
		set selected_aux;
			file _webout;

		if _N_=1 then do;
			put	"<tr><td class='inputlabel'>&text. :</td><td> <select name='&macrovar.' form='cform' class='inputtext'>";
		end;
		/* foreach */
		if type="&selected." then 
			do;
				put "<option value=""" &outputvar. """ selected>" &showvar. "</option>" ;
			end;
		else 
			do;
				put "<option value=""" &outputvar. """>" &showvar. "</option>" ;
		end;
	run;

	/* fecha select tag */
	data _null_;
		file _webout;
		

		put '</select>'/
			'</td></tr>';
	run;

%mend;



%macro checkbox(name,value,form);
 "<input type=""CHECKBOX"" name=""&name."" value=""&value."" form=""&form."">" /
%mend;


%macro form(id);

	'<form action="'"&_url"'" id="cform">' /
	'<INPUT TYPE="HIDDEN" NAME="_PROGRAM" VALUE="'"&_program."'">' /

%mend;

%macro form_end;
	'</form>' /
%mend;


%macro input_submit(form);
  	"<input form ='&form.' type='submit' value='Submeter' class='Submeter'/>" /
%mend;


%macro input_text(form,name,text);
	"<p>&text.: <input type='textarea' form='&form.' name='&name.'></p>" /
%mend;

%macro input_file(form,name,text);
	"<p>&text.:<input type='file' form='&form.' name='&name.' class='inputtext'></p>" /
%mend;


%macro table_start;
	'<table>' /
%mend;

%macro table_end;
	'</table>' /
%mend;


%macro table_input_text(form,name,text,value);
	"<tr><td class='inputlabel'>&text.:</td><td> <input type='textarea' style='border-top-color: #636363; border-bottom-color: #636363; border-right-color: #636363; border-left-color: #636363;'  form='&form.' name='&name.' value='&value.' class='inputtext'></td></tr>" /
%mend;

%macro table_textarea_text(form,name,text,value);
	"<tr><td class='inputlabel'>&text.:</td><td> <textarea type='textarea' form='&form.' name='&name.' cols='35' rows='5' maxlength='256' placeholder='&value.' class='inputtextarea'></textarea></td></tr>" /
%mend;


%macro table_input_number(form,name,text,value);
	
	"<tr><td class='inputlabel'>&text.:</td><td> <input type='textarea' style='background-color: #C6C6C6' class='inputtext' form='&form.' name='&name.' value='&value.' readonly></td></tr>" /
	
%mend;

%macro table_input_file(form,name,text);
	"<tr><td class='inputlabel'>&text.:</td><td width='550'> <input type='file' form='&form.' name='&name.' ></td></tr>" /
%mend;

%macro table_input_date(form,name,text,value);

	%let emFormato= %sysfunc(putn(&value,datetime.));
		
	"<tr><td class='inputlabel'>&text.:</td><td> <input type='textarea' style='background-color: #C6C6C6' class='inputtext' form='&form.' name='&name.' value='&emFormato.' readonly></td></tr>" /
%mend;

%macro select_box(table,showvar,outputvar,form, text);

	proc sort data=&table.;
		by &showvar.;
	run;
	
	data _null_;
		set &table.;
		file _webout;
		if _N_ = 1 then do;
			put	"&text. : <select name='myselect' form='cform' class='inputtext'>";
			put "<option value=""Todas"">Todas</option>" ;

		end;
		/* foreach */
		put "<option value=""" &outputvar. """>" &showvar. "</option>" ;

	run;

	/* fecha select tag */
	data _null_;
		file _webout;
		 put '</select>';
	run;

%mend;

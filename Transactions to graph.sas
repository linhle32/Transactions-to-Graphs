%MACRO BUILD_GRAPH(data,link_object,item,filter,prob_graph=no);
/*parsing data*/
Data temp (keep = &link_object &item);
	set &data;
	where &filter;
	
/*making sure all &link_object - &item pairs are unique*/
proc sql;
	create table unique_temp as
	select distinct &link_object, &item
	from temp;

/*get individual item count*/
proc sql;
	create table itemcount as
	select &item, count(*) as count
	from &data
	group by &item;
Proc sort data=unique_temp ;
	by &link_object &item;

/*Get wide data*/
Proc Transpose DATA=unique_temp OUT=temp2 prefix=itm;
	var &item;
	by &link_object;
proc sql;
	select nvar - 2
	into :nvar1
	from dictionary.tables
	where libname='WORK' and memname='TEMP2';
quit;

%let nvar = %trim(&nvar1);
%let dsid=%sysfunc(open(TEMP,i));
%if %trim(%sysfunc(vartype(&dsid,2))) = C %then %let sign = 1;
%else %let sign = 0;
%let rc=%sysfunc(close(&dsid));

/*subsetting pairs*/
Data TEMP3 (drop=itm1-itm&&nvar i j);
	set TEMP2;
	%if &sign = 1 %then %do;
		array vars{*} $ itm1-itm&&nvar;
		do i = 1 to &nvar-1;
			if TRIM(vars[i]) = " " then leave;
			else do j = i+1 to &nvar;
				if TRIM(vars[j]) = " " then leave;
				else do;
					pair = CATX("|",PUT(vars[i],8.),PUT(vars[j],8.));
					item1 = vars[i];
					item2 = vars[j];
					output;
				end;
			end;
		end;
	%end;
	%else %do;
	array vars{*} itm1-itm&&nvar;
		do i = 1 to &nvar-1;
			if vars[i] = . then leave;
			else do j = i+1 to &nvar;
				if vars[j] = . then leave;
				else do;
					pair = CATX("|",PUT(vars[i],8.),PUT(vars[j],8.));
					item1 = vars[i];
					item2 = vars[j];
					output;
				end;
			end;
		end;
	%end;
	drop _name_;
	
/*Create Co-occurrence Graph Set*/
proc sql;
	create table co_occ_graph as
	select item1 as v1, item2 as v2, count(pair) as weight
	from temp3
	group by pair, item1, item2;
quit;
	
%if %lowcase(&prob_graph) = yes %then %do;
/*Create Probability Graph Set*/
proc sort data=co_occ_graph; by v1 v2;

/*transform to directed graph*/
data _temp_ (drop=temp);
	set co_occ_graph;
	temp = v1;
	v1 = v2;
	v2 = temp;
data di_graph;
	set co_occ_graph _temp_;	

proc sort data=di_graph; by v1;
proc sort data=itemcount; by &item;
data prob_graph;
	merge di_graph (in=a rename=(weight=co_occ)) 
		  itemcount (rename =(&item=v1 count=v1_occ));
	by v1;
	weight = co_occ / v1_occ;
	if a;

proc datasets library=work;
	delete di_graph _temp_;
%end;

proc datasets library=work;
	delete temp unique_temp temp2 temp3 itemcount;
%MEND;

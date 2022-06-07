
LIBNAME SNAP '\\rmc.local\dfsroot\Dept\Marketing\Analytics\SNAPSHOTS';
****** When Importing the file change SSN from Number to String *****;

data closed;
	SET WORK.FBXSPB_ITA_20220120FINAL_HH_0000;
	*BIGAUTO_FLAG=' ';   /* This field is created to keep the layout format same.   Comment this field when PB data is used  */
run;

/*proc freq; tables BIGAUTO_FLAG/norow nocol nopercent; run;*/

proc sort;
	by bracctno;
run;

proc sort 
	data = snap.email_master out = email_master1;
	by bracctno;
run;

data temp;
	set email_master1;
	if email_status eq 'valid';
run;

proc sql;
	create table email_master2 as
	select t1.*, t2.bracctno, t2.email, t2.email_status 
	from closed as t1
		left join temp as t2 on t1.bracctno = t2.bracctno;
quit;  

data email_master2;
retain 
custid	branch	cfname1	cmname1	clname1	caddr1	caddr2	ccity	cst	czip	ssn	amt_given1	From_Offer_Amount	Up_to_Offer	percent	numpymnts	
camp_type	orig_amtid	fico	DOB	MLA_STATUS	n_60_dpd	ConProfile	Risk_Segment	BrAcctNo	cifno	campaign_id	mgc	month_split	Made_Unmade	
fico_range_25pt	state1	test_code	POffDate	Phone	CellPhone	EMAIL	email_status BIGAUTO_FLAG;

set email_master2;
run;

/*
data email_master3;
	set email_master2;
	if camp_type = 'PB' and amt_given1 >= 500 then PB_AMTGTEQ_FLAG = 'X';
	if camp_type = 'PB' and amt_given1 < 500 then PB_AMTLT_FLAG = 'X';
run;   */

PROC EXPORT 
	DATA = email_master2  
	OUTFILE = 
	"\\mktg-APP01\E\Production\2022\03_March_2022\ITA\FBXS_ITA_20220309final_HH_Updated.xlsx" 
	DBMS = EXCEL replace;  ** THIS WILL BE FINAL MAIL FILE WITH EMAIL;
run;

PROC EXPORT 
	DATA = email_master2 
	OUTFILE = 
	"\\mktg-APP01\E\Production\2022\03_March_2022\ITA\FBXS_ITA_20220309final_HH_Updated.txt" 
	DBMS = TAB replace; 
run;

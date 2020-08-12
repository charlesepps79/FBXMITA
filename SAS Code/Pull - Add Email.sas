LIBNAME SNAP '\\rmc.local\dfsroot\Dept\Marketing\Analytics\SNAPSHOTS'; 

data closed ;
SET WORK.FBXSPB_ITA_20200615final_HH;
run;

proc sort ;    by bracctno;

proc sort data=snap.email_master out=email_master1;
by bracctno;

data temp;
set email_master1;
if email_status eq 'valid' ;
run;


proc sql;
create table email_master2 as
select t1.*, t2.bracctno, t2.email,t2.email_status from closed as t1
left join temp as t2 on t1.bracctno=t2.bracctno;
quit;

PROC EXPORT DATA = email_master2  OUTFILE = 
"\\mktg-APP01\E\Production\2020\06_June_2020\ITA\FBXSPB_ITA_20200615final_HH_Email.xlsx" DBMS=EXCEL replace;  ** THIS WILL BE FINAL MAIL FILE WITH EMAIL;

PROC EXPORT DATA = email_master2  OUTFILE = 
"\\mktg-APP01\E\Production\2020\06_June_2020\ITA\FBXSPB_ITA_20200615final_HH_Email.txt" DBMS=TAB replace; 

run;

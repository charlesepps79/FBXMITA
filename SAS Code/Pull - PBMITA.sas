
DATA _NULL_;
	CALL SYMPUT('_5YR','2013-05-11');
	CALL SYMPUT ('_13MO','2017-04-09');
	CALL SYMPUT ('_1DAY','2018-05-09');
	CALL SYMPUT ('PB_ID', 'PB06.0_18ITA');
	CALL SYMPUT ('FINALEXPORTFLAGGED', 
		'\\mktg-app01\E\Production\2018\06-JuNE_2018\ITA\PB_ITA_20180510flagged.txt');
	CALL SYMPUT ('FINALEXPORTDROPPED', 
		'\\mktg-app01\E\Production\2018\06-JuNE_2018\ITA\PB_ITA_20180510FINal.txt');
	CALL SYMPUT ('EXPORTMLA', 
		'\\mktg-app01\E\Production\MLA\MLA-INput files TO WEBSITE\PBITA_20180510.txt');
RUN;

DATA LOAN1;
	SET DW.vw_Loan_NLS(
		KEEP = CIFNO BRACCTNO XNO_AVAILCREDIT XNO_TDUEPOFF ID OWNBR
			   OWNST SSNO1 SSNO2 SSNO1_RT7 LNAMT FINCHG LOANTYPE
			   ENTDATE LOANDATE CLASSID CLASSTRANSLATION
			   XNO_TRUEDUEDATE FIRSTPYDATE SRCD POCD POFFDATE PLCD
			   PLDATE PLAMT BNKRPTDATE BNKRPTCHAPTER DATEPAIDLAST
			   APRATE CRSCORE NETLOANAMOUNT XNO_AVAILCREDIT
			   XNO_TDUEPOFF CURBAL CONPROFILE1);
	WHERE CIFNO NE "" & POCD = "" & PLCD = "" & BNKRPTDATE = "" &
		  PLDATE = "" & POFFDATE = "" &
		  OWNST IN("NC", "VA", "NM", "OK", "SC", "TX");
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	IF CIFNO NOT =: "B";
RUN;

DATA BorrNLS;
length firstname $20 mIDdlename $20 lastname $30;
SET DW.vw_borrower (KEEP= rmc_updated phoNE CIFNO ssno ssno_rt7  FName LName Adr1 Adr2 City State zip BrNo age ConfIDential Solicit CeaseandDesist CreditScore);
WHERE CIFNO NOT =: "B";
FName=strip(fname);
LName=strip(lname);
Adr1=strip(Adr1);
Adr2=strip(adr2);
City=strip(city);
State=strip(state);
Zip=strip(zip);
IF fINd(fname,"JR") ge 1 then do;
firstname=compress(fname,"JR");
suffix="JR";
end;
IF fINd(fname,"SR") ge 1 then do;
firstname=compress(fname,"SR");
suffix="SR";
end;
IF suffix = "" then do;
firstname=scan(fname,1,1);
mIDdlename=catx(" ",scan(fname,2," "),scan(fname,3," "),scan(fname,4," "));
end;
nwords=countw(fname," ");
IF nwords>2 & suffix NE "" then do;
firstname=scan(fname,1," ");
mIDdlename=scan(fname,2," ");
end;
lastname=lname;
DOB=compress(age,"-");
drop fname lname nwords age;
IF CIFNO NE "";
RUN;

proc sql;
create table LOAN1nls as
select *
from LOAN1
group by CIFNO
havINg ENTDATE = max(ENTDATE);
quit;
proc sort DATA=LOAN1nls nodupkey; by CIFNO; RUN;
proc sort DATA=borrnls; by CIFNO descendINg rmc_updated; RUN;
proc sort DATA=borrnls out=borrnls2 nodupkey; by CIFNO; RUN;

DATA loannls;
merge LOAN1nls(IN=x) borrnls2(IN=y);
by CIFNO;
IF x and y;
RUN;



DATA loaNExtra;
SET DW.vw_loan(KEEP= BRACCTNO XNO_AVAILCREDIT XNO_TDUEPOFF ID OWNBR OWNST SSNO1 SSNO2 SSNO1_RT7 LNAMT FINCHG LOANTYPE ENTDATE LOANDATE CLASSID CLASSTRANSLATION XNO_TRUEDUEDATE FIRSTPYDATE SRCD POCD POFFDATE PLCD PLDATE PLAMT BNKRPTDATE BNKRPTCHAPTER DATEPAIDLAST APRATE CRSCORE NETLOANAMOUNT XNO_AVAILCREDIT XNO_TDUEPOFF CURBAL CONPROFILE1);
WHERE PLCD="" & POCD="" & POFFDATE="" & PLDATE="" & BNKRPTDATE="" & OWNST IN("NC","VA","NM","OK","SC","TX");
SS7BRSTATE=CATS(SSNO1_RT7,SUBSTR(OWNBR,1,2));
IF SSNO1=: "99" then BadSSN="X";  *Flag bad ssns;
IF SSNO1=: "98" then BadSSN="X";
RUN;
DATA LOAN1_2;
SET LOAN1;
KEEP BRACCTNO;
RUN;
proc sort DATA=LOAN1_2;
by BRACCTNO;
RUN;
proc sort DATA=loaNExtra;
by BRACCTNO;
RUN;
DATA loaNExtra2;
merge loaNExtra(IN=x) LOAN1_2(IN=y);
by BRACCTNO;
IF x and NOT y;
RUN;


DATA loanparaDATA;
SET DW.vw_loan(KEEP= BRACCTNO XNO_AVAILCREDIT XNO_TDUEPOFF ID OWNBR OWNST SSNO1 SSNO2 SSNO1_RT7 LNAMT FINCHG LOANTYPE ENTDATE LOANDATE CLASSID CLASSTRANSLATION XNO_TRUEDUEDATE FIRSTPYDATE SRCD POCD POFFDATE PLCD PLDATE PLAMT BNKRPTDATE BNKRPTCHAPTER DATEPAIDLAST APRATE CRSCORE NETLOANAMOUNT XNO_AVAILCREDIT XNO_TDUEPOFF CURBAL CONPROFILE1);
WHERE PLCD="" & POCD="" & POFFDATE="" & PLDATE="" & BNKRPTDATE="" & OWNST NOT IN ("NC","VA","NM","OK","SC","TX");
SS7BRSTATE=CATS(SSNO1_RT7,SUBSTR(OWNBR,1,2));
IF SSNO1=: "99" then BadSSN="X";  *Flag bad ssns;
IF SSNO1=: "98" then BadSSN="X"; 
RUN;

DATA SET1;
SET loanparaDATA loaNExtra2;
RUN;


DATA BorrParaDATA;
length firstname $20 mIDdlename $20 lastname $30;
SET DW.vw_borrower (KEEP=rmc_updated phoNE CIFNO ssno ssno_rt7  FName LName Adr1 Adr2 City State zip BrNo age ConfIDential Solicit CeaseandDesist CreditScore);
FName=strip(fname);
LName=strip(lname);
Adr1=strip(Adr1);
Adr2=strip(adr2);
City=strip(city);
State=strip(state);
Zip=strip(zip);
IF fINd(fname,"JR") ge 1 then do;
firstname=compress(fname,"JR");
suffix="JR";
end;
IF fINd(fname,"SR") ge 1 then do;
firstname=compress(fname,"SR");
suffix="SR";
end;
IF suffix = "" then do;
firstname=scan(fname,1,1);
mIDdlename=catx(" ",scan(fname,2," "),scan(fname,3," "),scan(fname,4," "));
end;
nwords=countw(fname," ");
IF nwords>2 & suffix NE "" then do;
firstname=scan(fname,1," ");
mIDdlename=scan(fname,2," ");
end;
SS7BRSTATE=CATS(ssno_rt7,SUBSTR(brno,1,2));
lastname=lname;
rename ssno_rt7=SSNO1_RT7 ssno=SSNO1;
IF ssno=: "99" then BadSSN="X";  *Flag bad ssns;
IF ssno=: "98" then BadSSN="X"; 
DOB=compress(age,"-");
drop nwords age fname lname;
RUN;

DATA goodssn_l badssn_l;
SET SET1;
IF badssn="X" then output badssn_l;
else output goodssn_l;
RUN;
DATA goodssn_b badssn_b;
SET borrparaDATA;
IF badssn="X" then output badssn_b;
else output goodssn_b;
RUN;


proc sort DATA=goodssn_l; by SSNO1; RUN;
proc sql;
create table goodssn_l as
select *
from goodssn_l
group by SSNO1
havINg ENTDATE = max(ENTDATE);
quit;
proc sort DATA=goodssn_l nodupkey; by SSNO1; RUN;

proc sort DATA=goodssn_b; by SSNO1 descendINg rmc_updated; RUN;
proc sort DATA=goodssn_b nodupkey; by SSNO1; RUN;
DATA mergedgoodssn;
merge goodssn_l(IN=x) goodssn_b(IN=y);
by SSNO1;
IF x and y;
RUN;


proc sort DATA=badssn_l; by SS7BRSTATE; RUN;
proc sql;
create table badssn_l as
select *
from badssn_l
group by SS7BRSTATE
havINg ENTDATE = max(ENTDATE);
quit;
proc sort DATA=badssn_l nodupkey; by SS7BRSTATE; RUN;

proc sort DATA=badssn_b; by SS7BRSTATE descendINg RMC_Updated; RUN;
proc sort DATA=badssn_b nodupkey; by SS7BRSTATE; RUN;
DATA mergedbadssn;
merge badssn_l(IN=x) badssn_b(IN=y);
by SS7BRSTATE;
IF x and y;
RUN;

DATA ssns;
SET mergedgoodssn mergedbadssn;
RUN;

proc sort DATA=ssns nodupkey; by BRACCTNO; RUN;
proc sort DATA=loannls nodupkey; by BRACCTNO; RUN;

DATA paraDATA;
merge loannls(IN=x) ssns(IN=y);
by BRACCTNO;
IF NOT x and y;
RUN;

DATA merged_l_b2;
SET loannls paraDATA;
RUN; 

proc sort DATA=merged_l_b2 out=merged_l_b2_2 nodupkey; by BRACCTNO; RUN;

*Pull IN INformation for statflags;
DATA Statflags;
SET DW.vw_loan (KEEP= OWNBR SSNO1_RT7 ENTDATE StatFlags);
WHERE ENTDATE > "&_5YR" & statflags NE "";
RUN;
 proc sql;
 create table statflags2 as
 select * from statflags WHERE statflags contaINs "1"
 union
 select * from statflags WHERE statflags contaINs "2"
 union
 select * from statflags WHERE statflags contaINs "3"
 union
 select * from statflags WHERE statflags contaINs "4"
 union
 select * from statflags WHERE statflags contaINs "5"
 union
 select * from statflags WHERE statflags contaINs "6"
 union 
 select * from statflags WHERE statflags contaINs "7"
 union
 select * from statflags WHERE statflags contaINs "A"
 union 
 select * from statflags WHERE statflags contaINs "B"
 union
 select * from statflags WHERE statflags contaINs "C"
 union
 select * from statflags WHERE statflags contaINs "D"
 union
 select * from statflags WHERE statflags contaINs "I"
 union
 select * from statflags WHERE statflags contaINs "J"
 union 
 select * from statflags WHERE statflags contaINs "L"
 union 
 select * from statflags WHERE statflags contaINs "P"
 union 
 select * from statflags WHERE statflags contaINs "R"
union 
select * from statflags WHERE statflags contaINs "V"
union 
select * from statflags WHERE statflags contaINs "W"
union 
select * from statflags WHERE statflags contaINs "X"
union 
select * from statflags WHERE statflags contaINs "S";
quit;
DATA statflags2; *taggINg bad statflags;
 SET statflags2;
 statfl_flag="X";
SS7BRSTATE=CATS(SSNO1_RT7,SUBSTR(OWNBR,1,2));
drop ENTDATE OWNBR SSNO1_RT7;
 RUN;
proc sort DATA=statflags2 nodupkey;
by SS7BRSTATE;
RUN;
proc sort DATA=Merged_L_B2_2;
by SS7BRSTATE;
RUN;
DATA Merged_L_B2; *Merge file with statflag flags;
merge Merged_L_B2_2(IN=x) statflags2;
by SS7BRSTATE;
IF x=1;
RUN;

DATA con5yr_fl;
SET DW.vw_loan (KEEP= OWNBR SSNO1_RT7 ENTDATE CONPROFILE1);
WHERE ENTDATE > "&_5YR" & CONPROFILE1 NE "";
RUN;
DATA con5yr_fl; *flag for con5;
SET con5yr_fl;
_30=countc(CONPROFILE1,"1");
_60=countc(CONPROFILE1,"2");
_90=countc(CONPROFILE1,"3");
_120a=countc(CONPROFILE1,"4");
_120b=countc(CONPROFILE1,"5");
_120c=countc(CONPROFILE1,"6");
_120d=countc(CONPROFILE1,"7");
_120e=countc(CONPROFILE1,"8");
_90plus=sum(_90,_120a,_120b,_120c,_120d,_120e);
IF _30>1 | _60>0 | _90plus>0 then con5yr_flag="X";
SS7BRSTATE=CATS(SSNO1_RT7,SUBSTR(OWNBR,1,2));
drop ENTDATE SSNO1_RT7 OWNBR CONPROFILE1 _30 _60 _90 _120a _120b _120c _120d _120e _90plus;
RUN;
DATA con5yr_fl_2;
SET con5yr_fl;
IF con5yr_flag="X";
RUN;
proc sort DATA=con5yr_fl_2 nodupkey;
by SS7BRSTATE;
RUN;
proc sort DATA=merged_l_b2;
by SS7BRSTATE;
RUN;
DATA Merged_L_B2; *merge pull with con5 flags;
merge Merged_L_B2(IN=x) con5yr_fl_2;
by SS7BRSTATE;
IF x;
RUN;

*IDentIFy bad PO Codes;
DATA PO_codes_5yr;
SET DW.vw_loan (KEEP=ENTDATE POCD SSNO1_RT7 OWNBR);
WHERE ENTDATE > "&_5YR" & POCD IN ("49", "50", "61", "62", "63", "64", "66", "68", "93", "97", "PB", "PO");
RUN;
DATA po_codes_5yr;
SET po_codes_5yr;
BadPOcode_flag = "X";
SS7BRSTATE=CATS(SSNO1_RT7,SUBSTR(OWNBR,1,2));
drop ENTDATE POCD SSNO1_RT7 OWNBR;
RUN;
proc sort DATA=po_codes_5yr nodupkey;
by SS7BRSTATE;
RUN;
proc sort DATA=merged_l_b2;
by SS7BRSTATE;
RUN;
DATA merged_l_b2;
merge merged_l_b2(IN=x) po_codes_5yr;
by SS7BRSTATE;
IF x;
RUN;



DATA PO_codes_forever;
SET DW.vw_loan (KEEP=ENTDATE POCD SSNO1_RT7 OWNBR);
WHERE POCD IN ("21", "94", "95", "96");
RUN;
DATA po_codes_forever;
SET po_codes_forever;
Deceased_flag = "X";
SS7BRSTATE=CATS(SSNO1_RT7,SUBSTR(OWNBR,1,2));
drop ENTDATE POCD SSNO1_RT7 OWNBR;
RUN;
proc sort DATA=po_codes_forever nodupkey;
by SS7BRSTATE;
RUN;
DATA merged_l_b2;
merge merged_l_b2(IN=x) po_codes_forever;
by SS7BRSTATE;
IF x;
RUN;



DATA openloans2;
SET DW.vw_loan (KEEP= OWNBR SSNO2 SSNO1_RT7 POCD PLCD POFFDATE PLDATE BNKRPTDATE);
WHERE POCD = "" & PLCD="" & POFFDATE="" & PLDATE="" & BNKRPTDATE="";
SS7BRSTATE=CATS(SSNO1_RT7,SUBSTR(OWNBR,1,2));
RUN;
DATA SSNO2s;
SET openloans2;
SS7BRSTATE=CATS((SUBSTR(SSNO2,max(1,length(SSNO2)-6))),SUBSTR(OWNBR,1,2));
IF SSNO2 NE "" then output SSNO2s;
RUN;
DATA openloans3;
SET openloans2 SSNO2s;
RUN;
DATA openloans4;
SET openloans3;
Open_flag2 = "X";
IF SS7BRSTATE = "" then SS7BRSTATE=CATS(SSNO1_RT7,SUBSTR(OWNBR,1,2));
drop POCD SSNO2 SSNO1_RT7 OWNBR PLCD POFFDATE PLDATE BNKRPTDATE;
RUN;
proc sort DATA=openloans4;
by SS7BRSTATE;
RUN;
DATA oNE_open mult_open;
SET openloans4;
by SS7BRSTATE;
IF first.SS7BRSTATE and last.SS7BRSTATE then output oNE_open;
else output mult_open;
RUN;
proc sort DATA=mult_open nodupkey;
by SS7BRSTATE;
RUN;
proc sort DATA=merged_l_b2;
by SS7BRSTATE;
RUN;
DATA merged_l_b2;
merge merged_l_b2(IN=x) mult_open;
by SS7BRSTATE;
IF x;
RUN;



*Flag bankruptcies IN past 5 years;
DATA bk5yrdrops;
SET DW.vw_loan (KEEP= ENTDATE SSNO1_RT7 OWNBR BNKRPTDATE BNKRPTCHAPTER);
WHERE ENTDATE > "&_5YR";
RUN;
DATA bk5yrdrops;
SET bk5yrdrops;
WHERE BNKRPTCHAPTER>0 | BNKRPTDATE NE "";
RUN;
DATA bk5yrdrops;
SET bk5yrdrops;
bk5_flag = "X";
SS7BRSTATE=CATS(SSNO1_RT7,SUBSTR(OWNBR,1,2));
drop BNKRPTDATE ENTDATE SSNO1_RT7 OWNBR BNKRPTCHAPTER;
RUN;
proc sort DATA=bk5yrdrops nodupkey;
by SS7BRSTATE;
RUN;
proc sort DATA=merged_l_b2;
by SS7BRSTATE;
RUN;
DATA Merged_L_B2;
merge Merged_L_B2(IN=x) bk5yrdrops;
by SS7BRSTATE;
IF x;
RUN;
DATA merged_l_b2;
SET merged_l_b2;
IF BNKRPTDATE NE "" then bk5_flag="X";
IF BNKRPTCHAPTER NE 0 then bk5_flag="X";
RUN;

*Flag bad TRW status;
DATA trwstatus_fl;
SET DW.vw_loan (KEEP= OWNBR SSNO1_RT7 ENTDATE trwstatus);
WHERE ENTDATE > "&_5YR" & TrwStatus NE "";
RUN;
DATA trwstatus_fl; *flag for bad trw's;
SET trwstatus_fl;
TRW_flag = "X";
SS7BRSTATE=CATS(SSNO1_RT7,SUBSTR(OWNBR,1,2));
drop ENTDATE OWNBR SSNO1_RT7;
RUN;
proc sort DATA=trwstatus_fl nodupkey;
by SS7BRSTATE;
RUN;
proc sort DATA=merged_l_b2;
by SS7BRSTATE;
RUN;
DATA Merged_L_B2; *merge pull with trw flags;
merge Merged_L_B2(IN=x) trwstatus_fl;
by SS7BRSTATE;
IF x;
RUN;





*FINd states outsIDe of footprINt;
*Flag DNS DNH;
*Flag nonmatchINg branch state and borrower state;
*IDentIFy all auto loans;
*count number of months of INactivity;
*calculate for equity threshhold;
*flag INcomplete INfo;


DATA Merged_L_B2; 
SET Merged_L_B2;
Adr1=strip(Adr1);
Adr2=strip(adr2);
City=strip(city);
State=strip(state);
Zip=strip(zip);
confIDential=strip(confIDential);
solicit=strip(solicit);
firstname=compress(firstname,'1234567890!@#$^&*()''"%');
lastname=compress(lastname,'1234567890!@#$^&*()''"%');
IF adr1="" then MissINgINfo_flag = "X";
IF state="" then MissINgINfo_flag = "X";
IF Firstname="" then MissINgINfo_flag = "X";
IF Lastname="" then MissINgINfo_flag = "X";
IF OWNBR IN ("600" , "9000" , "198" , "1", "0001" , "0198" , "0600") then BadBranch_flag="X";
IF SUBSTR(OWNBR,3,2)="99" then BadBranch_flag="X";
IF CLASSTRANSLATION IN ("Auto-I", "Auto-D") then autodelete_flag="X"; *IDentIFy all auto loans;
IF CLASSTRANSLATION = "Retail" then retaildelete_flag="X";
IF state NOT IN ("AL", "GA", "NC", "NM", "OK", "SC", "TN", "TX", "VA") then OOS_flag = "X"; *FINd states outsIDe of footprINt;
IF confIDential = "Y" then DNS_DNH_flag = "X";  *Flag ConfIDential;
IF solicit = "N" then DNS_DNH_flag = "X";  *Flag DNS;
IF ceaseanddesist = "Y" then DNS_DNH_flag = "X";  *Flag CandD;
IF SSNO1="" then SSNO1=ssno;
IF OWNST NE state then State_Mismatch_flag = "X"; *Flag nonmatchINg branch state and borrower state;
_9s=countc(CONPROFILE1,"9"); *count number of months of INactivity;
IF _9s>10 then lessthan2_flag = "X";
XNO_TRUEDUEDATE2=INput(SUBSTR(XNO_TRUEDUEDATE,6,2)||'/'||SUBSTR(XNO_TRUEDUEDATE,9,2)||'/'||SUBSTR(XNO_TRUEDUEDATE,1,4),mmddyy10.);
FIRSTPYDATE2=INput(SUBSTR(FIRSTPYDATE,6,2)||'/'||SUBSTR(FIRSTPYDATE,9,2)||'/'||SUBSTR(FIRSTPYDATE,1,4),mmddyy10.);
Pmt_days=XNO_TRUEDUEDATE2-FIRSTPYDATE2;
IF pmt_days<60 then lessthan2_flag="X";
IF pmt_days = . & _9s <10 then lessthan2_flag="";
IF pmt_days>59 & _9s>10 then lessthan2_flag=""; *pmt_days calculation wINs over conprofile;
IF OWNBR = "1016" then OWNBR="1008";
IF OWNBR="1003" and zip=:"87112" then OWNBR="1013";
IF brno = "1016" then brno="1008";
IF brno="1003" and zip=:"87112" then brno="1013";
IF OWNBR = "0251" then OWNBR="0580";
IF OWNBR = "0252" then OWNBR="0683";
IF OWNBR = "0253" then OWNBR="0581";
IF OWNBR = "0254" then OWNBR="0582";
IF OWNBR = "0255" then OWNBR="0583";
IF OWNBR = "0256" then OWNBR="1103";
IF zip=:"36264" & OWNBR="0877" then OWNBR="0870";
IF OWNBR="0877" then OWNBR="0806";
IF OWNBR="0159" then OWNBR="0132";
IF zip=:"29659" & OWNBR="0152" then OWNBR="0121";
IF OWNBR="0152" then OWNBR="0115";
IF OWNBR="0885" then OWNBR="0802";
RUN;




*pull and merge dlq INfo;
DATA atb; 
   SET DW.atb_DATA(KEEP=BRACCTNO age2 yearmonth WHERE=(yearmonth between "&_13MO" and "&_1DAY")); 
   atbdt = INput(SUBSTR(yearmonth,6,2)||'/'||SUBSTR(yearmonth,9,2)||'/'||SUBSTR(yearmonth,1,4),mmddyy10.);     
   age = INtck('month',atbdt,"&sysdate"d); *age is month number of loan WHERE 1 is most recent month;
cd = SUBSTR(age2,1,1)*1;   
 *i.e. for age=1: this is most recent month.;
   *Fill delq1, which is delq for month 1, with delq status (cd).;
   IF      age = 1 then delq1 = cd;
   else IF age = 2 then delq2 = cd;
   else IF age = 3 then delq3 = cd;
   else IF age = 4 then delq4 = cd;
   else IF age = 5 then delq5 = cd;
   else IF age = 6 then delq6 = cd;
   else IF age = 7 then delq7 = cd;
   else IF age = 8 then delq8 = cd;
   else IF age = 9 then delq9 = cd;
   else IF age =10 then delq10= cd;
   else IF age =11 then delq11= cd;
   else IF age =12 then delq12= cd;
   IF cd>4 then cd90 = 1;
   IF cd>3 then cd60 = 1; *IF cd is greater than 30-59 days late, SET cd60 to 1;
   IF cd>2 then cd30 = 1; *IF cd is greater than 1-29 days late, SET cd30 to 1;
   IF age<7 then do;
		IF cd=3 then recent6=1; *NOTe 30-59s IN last six months;
		end;
		else IF 6<age<13 then do;
		IF cd=3 then first6=1; *NOTe 30-59s from 7 to 12 months ago;
		end;
   KEEP BRACCTNO delq1-delq12 cd cd30 cd60 cd90 age2 atbdt age first6 recent6;
RUN;
DATA atb2;
SET atb;
last12=sum(recent6,first6); *count the number of 30-59s IN the last year;
RUN;
*count cd30, cd60,recent6,first6 by BRACCTNO (*reCALL loan potentially counted for each month);
proc summary DATA=atb2 nway missINg;
   class BRACCTNO;
   var delq1-delq12 recent6 last12 first6 cd90 cd60 cd30;
   output out=atb3(drop=_type_ _freq_) sum=;
RUN; 
proc format; *defINE format for delq;
   value cdfmt
   1 = 'Current'
   2 = '1-29cd'
   3 = '30-59cd'
   4 = '60-89cd'
   5 = '90-119cd'
   6 = '120-149cd'
   7 = '150-179cd'
   8 = '180+cd'
   other=' ';
RUN;
DATA atb4; *create NEw counter variables;
   SET atb3;
   IF cd60 > 0 then ever60 = 'Y'; else ever60 = 'N';
   times30 = cd30;
   IF times30 = . then times30 = 0;
   IF recent6 = null then recent6=0;
   IF first6 = null then first6=0;
   IF last12 = null then last12=0;
   drop cd30;
   format delq1-delq12 cdfmt.;
RUN;
proc sort DATA=atb4 nodupkey; by BRACCTNO; RUN; *sort to merge;
DATA dlq;
SET atb4;
drop null; *droppINg the null column (NOT nulls IN DATASET);
RUN;
proc sort DATA=merged_l_b2; *sort to merge;
by BRACCTNO;
RUN;
DATA Merged_l_b2; *merge pull and dql INformation;
merge merged_l_b2(IN=x) dlq(IN=y);
by BRACCTNO;
IF x=1;
RUN;
DATA merged_l_b2; *flag for bad dlq;
SET merged_l_b2;
IF last12>3 or cd60>1 or cd90>0 then DLQ_Flag="X";
RUN;



*Conprofile flags;
DATA merged_l_b2;
SET merged_l_b2;
_30=countc(CONPROFILE1,"1");
_60=countc(CONPROFILE1,"2");
_90=countc(CONPROFILE1,"3");
_120a=countc(CONPROFILE1,"4");
_120b=countc(CONPROFILE1,"5");
_120c=countc(CONPROFILE1,"6");
_120d=countc(CONPROFILE1,"7");
_120e=countc(CONPROFILE1,"8");
_90plus=sum(_90,_120a,_120b,_120c,_120d,_120e);
IF _30>3 | _60>1 | _90plus>0 then conprofile_flag="X";
camp_type="PB";
RUN;

DATA merged_l_b2;
SET merged_l_b2;
equityt=(XNO_AVAILCREDIT/XNO_TDUEPOFF)*100;
IF equityt <10 then et_flag="X";
IF XNO_AVAILCREDIT<100 then et_flag="X";
RUN;



*Export Flagged File;
proc export DATA=merged_l_b2 outfile="&FINALEXPORTFLAGGED" dbms=tab;
 RUN;




 DATA Waterfall;
 length Criteria $30 Count 8.;
 INfile DATAlINEs dlm="," tRUNcover;
 INput Criteria $ Count;
 DATAlINEs;
PB Pull Total,
Delete cust IN Bad Branches,		
Delete cust with MissINg INfo,	
Delete cust OutsIDe of FootprINt,	
Delete WHERE State/OWNST Mismatch,
Delete IF customer has >1 open loan,
Delete cust with Bad POCODE,
Delete Deceased,
Delete IF Less than Two Payments Made,	
Delete for ATB DelINquency,		
Delete for Conprofile DelINquency,
Delete for Bankruptcy (5yr),
Delete for Statflag (5yr),
Delete for TRW Status (5yr),
Delete IF DNS or DNH,
Equity Threshhold,
Delete Auto Loans,
Delete Retail Loans,		
;
RUN;
	


DATA fINal; SET merged_l_b2; RUN;
proc sql; create table Count as select count(*) as Count from merged_l_b2; RUN;
DATA fINal; SET fINal; IF BadBranch_flag=""; RUN; 
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF MissINgINfo_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF OOS_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF State_Mismatch_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF open_flag2=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF BadPOcode_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF deceased_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF lessthan2_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF dlq_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF conprofile_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF bk5_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit; 
DATA fINal; SET fINal; IF statfl_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit; 
DATA fINal; SET fINal; IF TRW_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF DNS_DNH_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF et_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit; 
DATA fINal; SET fINal; IF autodelete_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;
DATA fINal; SET fINal; IF retaildelete_flag=""; RUN;
proc sql; INsert INto count select count(*) as Count from fINal; quit;

proc prINt DATA=count noobs; RUN;

proc prINt DATA=waterfall; RUN;


 proc export DATA=fINal outfile="&FINALEXPORTDROPPED" dbms=tab;
 RUN;



*Send to DOD;
DATA mla;
SET fINal;
KEEP SSNO1 dob lastname firstname mIDdlename BRACCTNO;
RUN;
proc DATASETs;
modIFy mla;
rename dob ="Date of Birth"n SSNO1="Social Security Number (SSN)"n lastname="Last Name"n firstname="First Name"n mIDdlename="MIDdle Name"n BRACCTNO="Customer Record ID"n;
RUN;
DATA fINalmla;
length "Social Security Number (SSN)"n $ 9 "Date of Birth"n $ 8 "Last Name"n $ 26 "First Name"n $20 "MIDdle Name"n $ 20  "Customer Record ID"n $ 28;
SET mla;
RUN;
proc prINt DATA=fINalmla (obs=10);
RUN;
proc contents DATA=fINalmla;
RUN;



DATA _NULL_;
 SET fINalmla;
 file "&EXPORTMLA";
 put @1 "Social Security Number (SSN)"n @10 "Date of Birth"n @ 18 "Last Name"n @ 44 "First Name"n @ 64 "MIDdle Name"n @ 84 "Customer Record ID"n ;
 RUN; 

DATA fINalpb;
SET fINal;
RUN;


*Step 2: Import file from DOD, append offer INformation.;
filename mla1 "\\mktg-app01\E\Production\MLA\MLA-Output files FROM WEBSITE\PBITA.txt";
DATA mla1;
INfile mla1;
INput SSNO1 $ 1-9 dob $ 10-17 lastname $ 18-43 firstname $ 44-63 mIDdlename $ 64-83  BRACCTNO $ 84-120 mla_dod $121-145;
mla_status=SUBSTR(mla_dod,1,1);
RUN;
proc prINt DATA=mla1 (obs=10);
RUN;




proc sort DATA=fINalpb;
by BRACCTNO;
RUN;
proc sort DATA=mla1;
by BRACCTNO;
RUN;
DATA fINalhh;
merge fINalpb(IN=x) mla1;
by BRACCTNO;
IF x;
RUN;


*Count for Waterfall;
proc freq DATA=fINalhh;
table mla_status;
RUN;


DATA ficos;
SET fINalhh;
rename CRSCORE=fico;;
RUN;

DATA fINalhh2;
length fico_range_25pt $10 campaign_ID $25 Made_Unmade $15 CIFNO $20 custID $20 mgc $20 state1 $5 test_code $20;
SET ficos;
IF mla_status NE "Y";
IF fico=0 then fico_range_25pt= "0";
IF 0<fico<500 then fico_range_25pt="<500";
IF 500<=fico<=524 then fico_range_25pt= "500-524";
IF 525<=fico<=549 then fico_range_25pt= "525-549";
IF 550<=fico<=574 then fico_range_25pt= "550-574";
IF 575<=fico<=599 then fico_range_25pt= "575-599";
IF 600<=fico<=624 then fico_range_25pt= "600-624";
IF 625<=fico<=649 then fico_range_25pt= "625-649";
IF 650<=fico<=674 then fico_range_25pt= "650-674";
IF 675<=fico<=699 then fico_range_25pt= "675-699";
IF 700<=fico<=724 then fico_range_25pt= "700-724";
IF 725<=fico<=749 then fico_range_25pt= "725-749";
IF 750<=fico<=774 then fico_range_25pt= "750-774";
IF 775<=fico<=799 then fico_range_25pt= "775-799";
IF 800<=fico<=824 then fico_range_25pt= "800-824";
IF 825<=fico<=849 then fico_range_25pt= "825-849";
IF 850<=fico<=874 then fico_range_25pt= "850-874";
IF 875<=fico<=899 then fico_range_25pt= "875-899";
IF 975<=fico<=999 then fico_range_25pt= "975-999";
IF fico="" then fico_range_25pt= "";
CAMPAIGN_ID = "&PB_ID";
custID=strip(_n_);
Made_Unmade=madeunmade_flag;
offer_segment="ITA";
IF state1="" then state1=state;
IF state1="TX" then state1="";
amt_given1=XNO_AVAILCREDIT;
IF state = "AL" & amt_given1>6000 then amt_given1=6000;
IF state NE "AL" & amt_given1>7000 then amt_given1=7000;
RUN;
DATA fINalhh2;
SET fINalhh2;
rename OWNBR=branch firstname=cfname1 mIDdlename=cmname1 lastname=clname1 adr1=caddr1 adr2=caddr2
city=ccity state=cst zip=czip SSNO1_RT7=ssn cd60=n_60_dpd CONPROFILE1=ConProfile;
RUN;


DATA pbita_hh;
SET fINalhh2;
RUN;



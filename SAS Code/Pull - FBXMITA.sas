*** IMPORT NEW CROSS SELL FILES. INSTRUCTIONS HERE:                ***;
*** `R:\Production\MLA\Files for MLA PROCessing\XSELL\             ***;
*** XSELL TCI DECSION LENDER.txt`. CHANGE DATES IN THE LINES       ***;
*** IMMEDIATELY BELOW ALONG WITH FILE PATHS. FOR THE FILES PATHS,  ***;
*** YOU WILL LIKELY NEED TO CREATE A NEW FOLDER "ITA" IN THE       ***;
*** APPROPRIATE MONTH FILE. DO NOT CHANGE THE ARGUMENT TO THE LEFT ***;
*** OF THE COMMA - ONLY CHANGE WHAT IS TO THE RIGHT OF THE COMMA.  ***;

*** STEP 1: PULL ALL DATA AND SEND TO DOD ------------------------ ***;
DATA _NULL_;
CALL SYMPUT('_7YR','2011-05-12');
CALL SYMPUT('_6YR','2012-05-11');
CALL SYMPUT ('_1YR','2017-05-10');
CALL SYMPUT ('_1DAY','2018-05-09');
CALL SYMPUT ('RETAIL_ID', 'RETAILXSITA6.0_2018');
CALL SYMPUT ('AUTO_ID', 'AUTOXSITA6.0_2018');
CALL SYMPUT ('FB_ID', 'FBITA6.0_2018');
CALL SYMPUT ('FINALEXPORTFLAGGED', 
	'\\mktg-APP01\E\Production\2018\06-JuNE_2018\ITA\FBXS_ITA_20180510flagGEd.txt');
CALL SYMPUT ('FINALEXPORTDROPPED', 
	'\\mktg-APP01\E\Production\2018\06-JuNE_2018\ITA\FBXS_ITA_20180510Final.txt');
CALL SYMPUT ('EXPORTMLA1', 
	'\\mktg-APP01\E\Production\MLA\MLA-INPUT files TO WEBSITE\FB_MITA_20180510p1.txt');
CALL SYMPUT ('EXPORTMLA2', 
	'\\mktg-APP01\E\Production\MLA\MLA-INPUT files TO WEBSITE\FB_MITA_20180510p2.txt');
CALL SYMPUT ('FINALEXPORTED', 
	'\\mktg-APP01\E\Production\2018\06-JuNE_2018\ITA\FBXSPB_ITA_20180510final_HH.csv');
CALL SYMPUT ('FINALEXPORTHH', 
	'\\mktg-APP01\E\Production\2018\06-JuNE_2018\ITA\FBXSPB_ITA_20180510final_HH.txt');
CALL SYMPUT ('FINALEXPORTED2', 
	'\\mktg-APP01\E\Production\2018\06-JuNE_2018\ITA\FBXS_ITA_20180510final_HH.csv');
CALL SYMPUT ('FINALEXPORTHH2', 
	'\\mktg-APP01\E\Production\2018\06-JuNE_2018\ITA\FBXS_ITA_20180510final_HH.txt');
RUN;

%PUT "&_1YR" "&_1DAY";

*** OLD TCI 3.5 DATA - RETAIL AND AUTO --------------------------- ***;
PROC IMPORT 
	DATAFILE = "\\mktg-APP01\E\Production\MLA\Files for MLA PROCessing\XSELL\TCI3_5.txt" 
		OUT =  TCI2 REPLACE DBMS = DLM;
	DELIMITER = '09'x;
	GUESSINGROWS = MAX;
RUN;

DATA TCI3;
	SET TCI2;
	SSN = PUT(INPUT(SSNO1 ,best32.), z9.);
	SS7 = PUT(INPUT(SSNO1_RT7, best32.), z7.);
	APPNUM = STRIP(PUT('APPLICATION NUMBER'n, 10.));
	DROP SSNO1 SSNO1_RT7 'APPLICATION NUMBER'n;
	RENAME SSN = SSNO1 SS7 = SSNO1_RT7 APPNUM = 'APPLICATION NUMBER'n;
RUN;

*** NEW TCI DATA - RETAIL AND AUTO ------------------------------- ***;
PROC IMPORT 
	DATAFILE = "\\mktg-APP01\E\cepps\FBXMITA\XS_Mail_PULL.xlsx" 
		DBMS = XLSX OUT = NEWXS REPLACE;
	RANGE = "XS Mail PULL$A3:0";
	GETNAMES = YES;
RUN;

DATA NEWXS2;
	SET NEWXS;
	IF 'LOAN TYPE'n = "Auto Indirect" THEN SOURCE = "TCICENTRAL";
	IF 'LOAN TYPE'n = "Retail" THEN SOURCE = "TCIRETAIL";
	IF SOURCE NE "";

	IF FIND('APPLICANT ADDRESS'n, "APT") = 0  THEN DO;
		ADR1 = SCAN('APPLICANT ADDRESS'n, 1, ",");
		CITY = SCAN('APPLICANT ADDRESS'n, 2, ",");
		STATE = SCAN('APPLICANT ADDRESS'n, 3, ",");
		ZIP = SCAN('APPLICANT ADDRESS'n, 4, ",");
	END;

	IF FIND('APPLICANT ADDRESS'n,"APT") GE 1 THEN DO;
		ADR1 = SCAN('APPLICANT ADDRESS'n, 1, ",");
		ADR2 = SCAN('APPLICANT ADDRESS'n, 2, ",");
		CITY = SCAN('APPLICANT ADDRESS'n, 3, ",");
		STATE = SCAN('APPLICANT ADDRESS'n, 4, ",");
		ZIP = SCAN('APPLICANT ADDRESS'n, 5, ",");
	END;

	DOB = PUT('APPLICANT DOB'n, yymmdd10.);
	'APPLICATION DATE1'n = PUT('APPLICATION DATE'n, mmddyy10.);
	BRACCTNO = CATS("TCI", 'APPLICATION NUMBER'n);
	SSNO1_RT7 = substrn('APPLICANT SSN'n, MAX(1, length('APPLICANT SSN'n) - 6), 7);
	DROP 'APPLICATION DATE'n 
		 'APPLICANT ADDRESS'n
		 'APPLICANT ADDRESS ZIP'n 
		 'APPLICANT DOB'n 
		 'APP. WORK PHONE'n;
	RENAME 'APPLICATION DATE1'n = 'APPLICATION DATE'n 
		   'APPLICANT EMAIL'n = EMAIL 
		   'APPLICANT CREDIT SCORE'n = CRSCORE 
		   'APPLICANT FIRST NAME'n = FIRSTNAME 
		   'APPLICANT LAST NAME'n = LASTNAME 
		   'APPLICANT SSN'n = SSNO1 
		   'APPLICANT MIDDLE NAME'n = MIDDLENAME 
		   'APP. CELL PHONE'n = CELLPHONE 
		   'APP. HOME PHONE'n = PHONE;
RUN;

DATA TCI;
	length ADR1 $40 
		   CITY $25 
		   STATE $4 
		   ZIP $10 
		   MIDDLENAME $25 
		   SOURCE $11 
		   BRACCTNO $15;;
	SET TCI3 NEWXS2;
	SSNO1=STRIP(SSNO1);
	DOB=compress(DOB,"-");
	format _character_;
RUN;

*PULL in XS from loan table, borrower table AND merGE;
DATA XS_L;
SET dw.vw_loan_NLS (keep=ownst xno_availCREDIT xno_tduepoff cIFno BRACCTNO id SSNO1 ownbr SSNO1_RT7 SSNo2 LnAmt FinChg LoanType EntDATE LoANDATE ClassID ClassTranslation XNO_TrueDueDATE FIRSTPyDATE SrCD pocd POffDATE plcd PlDATE PlAmt BnkrptDATE BnkrptChAPTer ConProfile1 DATEPaidLAST APRate CRSCORE CurBal);
where cIFno NE "" & entDATE >= "&_1YR" & pocd="" & plcd="" & plDATE="" & poffDATE=""  & bnkrptDATE="" & classid in (10,19,20,31,34) & ownst in ("NC","VA","NM","SC","OK","TX");
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
IF cIFno not =: "B";
RUN;
PROC sql;
create table XS_Ldeduped as
select *
from XS_L
group by cIFno
having entDATE = MAX(entDATE);
quit;

DATA BorrNLS;
length FIRSTNAME $20 MIDDLENAME $20 LASTNAME $30;
SET dw.vw_borrower (keep=rmc_upDATEd PHONE CELLPHONE cIFno SSNo SSNo_rt7  FNAME LNAME ADR1 ADR2 CITY STATE ZIP BrNo aGE Confidential Solicit CeaseANDDesist CREDITSCORE);
where cIFno not =: "B";
FNAME=STRIP(fNAME);
LNAME=STRIP(lNAME);
ADR1=STRIP(ADR1);
ADR2=STRIP(ADR2);
CITY=STRIP(CITY);
STATE=STRIP(STATE);
ZIP=STRIP(ZIP);
IF FIND(fNAME,"JR") GE 1 THEN DO;
FIRSTNAME=compress(fNAME,"JR");
suffix="JR";
END;
IF FIND(fNAME,"SR") GE 1 THEN DO;
FIRSTNAME=compress(fNAME,"SR");
suffix="SR";
END;
IF suffix = "" THEN DO;
FIRSTNAME=SCAN(fNAME,1,1);
MIDDLENAME=catx(" ",SCAN(fNAME,2," "),SCAN(fNAME,3," "),SCAN(fNAME,4," "));
END;
nwords=countw(fNAME," ");
IF nwords>2 & suffix NE "" THEN DO;
FIRSTNAME=SCAN(fNAME,1," ");
MIDDLENAME=SCAN(fNAME,2," ");
END;
DOB=compress(aGE,"-");
LASTNAME=lNAME;
DROP fNAME lNAME nwords aGE;
IF cIFno NE "";
RUN;


PROC sort DATA=XS_Ldeduped nodupkey; by cIFno; RUN;
PROC sort DATA=borrnls; by cIFno descENDing rmc_upDATEd; RUN;
PROC sort DATA=borrnls OUT=borrnls2 nodupkey; by cIFno; RUN;

DATA loannlsxs;
merGE xs_ldeduped(in=x) borrnls2(in=y);
by cIFno;
IF x AND y;
RUN;

*modIFy as NEeded when more STATEs convert TO NLS;
DATA loaNExtraXS;
SET dw.vw_loan (keep= xno_availCREDIT xno_tduepoff BRACCTNO id SSNO1 ownbr ownst SSNO1_RT7 SSNo2 LnAmt FinChg LoanType EntDATE LoANDATE ClassID ClassTranslation XNO_TrueDueDATE FIRSTPyDATE SrCD pocd POffDATE plcd PlDATE PlAmt BnkrptDATE BnkrptChAPTer ConProfile1 DATEPaidLAST APRate CRSCORE CurBal);
where entDATE >= "&_1YR" & pocd="" & plcd="" & plDATE="" & poffDATE=""  & bnkrptDATE="" & classid in (10,19,20,31,34) & ownst in ("NC","VA","NM","SC","OK","TX") ; 
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
IF SSNO1=: "99" THEN BadSSN="X";  *Flag bad SSNs;
IF SSNO1=: "98" THEN BadSSN="X";
RUN;
*identIFy loans in NLS STATEs that are not in vw_loan_nls;
DATA loan1_2xs;
SET xs_l;
keep BRACCTNO;
RUN;
PROC sort DATA=loan1_2xs; by BRACCTNO; RUN;
PROC sort DATA=loaNExtraxs; by BRACCTNO; RUN;
DATA loaNExtra2xs;
merGE loaNExtraxs(in=x) loan1_2xs(in=y);
by BRACCTNO;
IF x AND not y;
RUN;

*modIFy as STATEs convert. When ALL STATEs are converted, this section can be removed;
DATA loanparaDATAXS;
SET dw.vw_loan(keep= BRACCTNO xno_availCREDIT xno_tduepoff id ownbr ownst SSNO1 SSNo2 SSNO1_RT7 LnAmt FinChg LoanType EntDATE LoANDATE ClassID ClassTranslation XNO_TrueDueDATE FIRSTPyDATE SrCD pocd POffDATE plcd PlDATE PlAmt BnkrptDATE BnkrptChAPTer DATEPaidLAST APRate CRSCORE NEtLoanAmount XNO_AvailCREDIT XNO_TDuePOff CurBal conprofile1);
where entDATE >= "&_1YR" & plcd="" & pocd="" & poffDATE="" & plDATE="" & bnkrptDATE="" & ownst not in ("NC","VA","NM","SC","OK","TX") & classid in (10,19,20,31,34);
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
IF SSNO1=: "99" THEN BadSSN="X";  *Flag bad SSNs;
IF SSNO1=: "98" THEN BadSSN="X"; 
RUN;

DATA SET1xs;
SET loanparaDATAxs loaNExtra2xs;
RUN;


DATA BorrParaDATA;
length FIRSTNAME $20 MIDDLENAME $20 LASTNAME $30;
SET dw.vw_borrower (keep=rmc_upDATEd PHONE CELLPHONE cIFno SSNo SSNo_rt7  FNAME LNAME ADR1 ADR2 CITY STATE ZIP BrNo aGE Confidential Solicit CeaseANDDesist CREDITSCORE);
FNAME=STRIP(fNAME);
LNAME=STRIP(lNAME);
ADR1=STRIP(ADR1);
ADR2=STRIP(ADR2);
CITY=STRIP(CITY);
STATE=STRIP(STATE);
ZIP=STRIP(ZIP);
IF FIND(fNAME,"JR") GE 1 THEN DO;
FIRSTNAME=compress(fNAME,"JR");
suffix="JR";
END;
IF FIND(fNAME,"SR") GE 1 THEN DO;
FIRSTNAME=compress(fNAME,"SR");
suffix="SR";
END;
IF suffix = "" THEN DO;
FIRSTNAME=SCAN(fNAME,1,1);
MIDDLENAME=catx(" ",SCAN(fNAME,2," "),SCAN(fNAME,3," "),SCAN(fNAME,4," "));
END;
nwords=countw(fNAME," ");
IF nwords>2 & suffix NE "" THEN DO;
FIRSTNAME=SCAN(fNAME,1," ");
MIDDLENAME=SCAN(fNAME,2," ");
END;
DOB=compress(aGE,"-");
SS7brSTATE=CATS(SSNo_rt7,substr(brno,1,2));
LASTNAME=lNAME;
RENAME SSNo_rt7=SSNO1_RT7 SSNo=SSNO1;
IF SSNo=: "99" THEN BadSSN="X";  *Flag bad SSNs;
IF SSNo=: "98" THEN BadSSN="X"; 
DROP nwords fNAME lNAME aGE;
RUN;

DATA goodSSN_lxs badSSN_lxs;
SET SET1xs;
IF badSSN="X" THEN OUTPUT badSSN_lxs;
else OUTPUT goodSSN_lxs;
RUN;
DATA goodSSN_b badSSN_b;
SET borrparaDATA;
IF badSSN="X" THEN OUTPUT badSSN_b;
else OUTPUT goodSSN_b;
RUN;


PROC sort DATA=goodSSN_lxs; by SSNO1; RUN;
PROC sql;
create table goodSSN_lxs as
select *
from goodSSN_lxs
group by SSNO1
having entDATE = MAX(entDATE);
quit;
PROC sort DATA=goodSSN_lxs nodupkey; by SSNO1; RUN;
PROC sort DATA=goodSSN_b; by SSNO1 descENDing rmc_upDATEd; RUN;
PROC sort DATA=goodSSN_b nodupkey; by SSNO1; RUN;
DATA merGEdgoodSSNxs;
merGE goodSSN_lxs(in=x) goodSSN_b(in=y);
by SSNO1;
IF x AND y;
RUN;

PROC sort DATA=badSSN_lxs; by SS7brSTATE; RUN;
PROC sql;
create table badSSN_lxs as
select *
from badSSN_lxs
group by SS7brSTATE
having entDATE = MAX(entDATE);
quit;
PROC sort DATA=badSSN_lxs nodupkey; by SS7brSTATE; RUN;
PROC sort DATA=badSSN_b; by SS7brSTATE descENDing rmc_upDATEd; RUN;
PROC sort DATA=badSSN_b nodupkey; by SS7brSTATE; RUN;
DATA merGEdbadxs;
merGE badSSN_lxs(in=x) badSSN_b(in=y);
by SS7brSTATE;
IF x AND y;
RUN;

PROC sort DATA=merGEdbadxs OUT=merGEdbadSSNxs nodupkey; by SS7brSTATE; RUN;

DATA SSNs;
SET merGEdgoodSSNxs merGEdbadSSNxs;
RUN;

PROC sort DATA=SSNs nodupkey; by BRACCTNO; RUN;
PROC sort DATA=loannlsXS nodupkey; by BRACCTNO; RUN;

DATA paraDATA;
merGE loannlsXS(in=x) SSNs(in=y);
by BRACCTNO;
IF not x AND y;
RUN;

DATA xs;
SET loannlsXS paraDATA;
RUN; 



*MerGE XS from our dw with info from TCI sites TO identIFy mades AND PULL in unmades;
PROC sort DATA=XS; by SSNO1; RUN;
PROC sort DATA=tci; by SSNO1; RUN;
DATA tcimades;
SET tci;
DROP BRACCTNO;
RUN;
DATA mades;
merGE XS(in=x) tcimades(in=y);
by SSNO1;
IF x=1;
RUN;
DATA unmades;
merGE XS(in=x) tci(in=y);
by SSNO1;
IF x=0 AND y=1;
made_unmade="UNMADE";
RUN;

DATA mades2;  *for matched, keep only info from loan AND borrower tables;
SET mades (keep=BRACCTNO SSNO1 id ownbr SSNO1_RT7 SSNo2 LnAmt FinChg LoanType EntDATE LoANDATE ClassID ClassTranslation SrCD pocd POffDATE plcd PlDATE PlAmt BnkrptDATE BnkrptChAPTer ConProfile1 DATEPaidLAST APRate CRSCORE CurBal ADR1 ADR2 CITY STATE ZIP DOB Confidential Solicit CeaseANDDesist CREDITSCORE FIRSTNAME MIDDLENAME LASTNAME SS7brSTATE PHONE CELLPHONE);
made_unmade="MADE";
RUN;
DATA XSTOt; *APPEND mades AND unmades for full XS universe;
SET unmades mades2;
DROP nwords;
RUN;

DATA xsTOt;
SET xsTOt;
IF SS7brSTATE="" THEN SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
IF CRSCORE <625 THEN Risk_Segment="624 AND below";
IF 625<=CRSCORE<650 THEN Risk_Segment="625-649";
IF 650<=CRSCORE<851 THEN Risk_Segment="650-850";
IF classid in (10,21,31) THEN SOURCE_2="RETAIL";
IF SOURCE="TCIRETAIL" THEN SOURCE_2="RETAIL";
IF classid in (13,14,19,20,32,34,40,41,45,68,69,72,75,78,79,80,88,89,90) THEN SOURCE_2="AUTO";
IF SOURCE = "TCICENTRAL" THEN SOURCE_2="AUTO";
RUN;
DATA xs_TOtal;
length offer_segment $20;
SET xsTOt;
	IF CRSCORE = 0 THEN BadFico_Flag="X";
	IF CRSCORE = . THEN BadFico_Flag="X";
	IF CRSCORE > 850 THEN BadFico_Flag="X";
	IF STATE="NC" & SOURCE_2="AUTO" & made_unmade="UNMADE" THEN NCAUTOUn_Flag="X";
	IF STATE="NC" & SOURCE_2="AUTO" & made_unmade="MADE" THEN offer_segment="ITA";
	IF STATE in ("GA", "VA") THEN offer_segment="ITA";
	IF STATE in ("SC","TX","TN","AL","OK","NM") & SOURCE_2="AUTO" THEN offer_segment="ITA";
	IF STATE in ("SC","NC","TX","TN","AL","OK","NM") & SOURCE_2="RETAIL" & Risk_Segment="624 AND below" THEN offer_segment="ITA";
RUN;


*Dedupe XS;
DATA xs_TOtal;
SET xs_TOtal;
IF offer_segment = "ITA";  *keep only ITAs;
camp_type="XS";
RUN;


*PULL in DATA for FBs;
DATA loan_PULL;
SET dw.vw_loan_nls (keep= cIFno BRACCTNO id ownbr ownst SSNO1_RT7 SSNO1 SSNo2 LnAmt FinChg SSNO1_RT7 LoanType EntDATE LoANDATE ClassID ClassTranslation XNO_TrueDueDATE FIRSTPyDATE SrCD pocd POffDATE plcd PlDATE PlAmt BnkrptDATE BnkrptChAPTer DATEPaidLAST APRate CRSCORE CurBal);
where POffDATE between "&_6YR" AND "&_1DAY" & (pocd="13" or pocd= "10" or pocd= "50") & ownst in ("NC","VA","NM","SC","OK","TX");
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
IF cIFno not =: "B";
RUN;


PROC sql;
create table loan1nlsfb as
select *
from loan_PULL
group by cIFno
having entDATE = MAX(entDATE);
quit;
PROC sort DATA=loan1nlsfb nodupkey; by cIFno; RUN;
DATA loannlsfb;
merGE loan1nlsfb(in=x) borrnls2(in=y);
by cIFno;
IF x AND y;
RUN;


DATA loaNExtrafb; *FIND NLS loans not in vw_nls_loan;
SET dw.vw_loan(keep= BRACCTNO xno_availCREDIT xno_tduepoff id ownbr ownst SSNO1 SSNo2 SSNO1_RT7 LnAmt FinChg LoanType EntDATE LoANDATE ClassID ClassTranslation XNO_TrueDueDATE FIRSTPyDATE SrCD pocd POffDATE plcd PlDATE PlAmt BnkrptDATE BnkrptChAPTer DATEPaidLAST APRate CRSCORE NEtLoanAmount XNO_AvailCREDIT XNO_TDuePOff CurBal conprofile1);
where POffDATE between "&_6YR" AND "&_1DAY" & (pocd="13" or pocd= "10" or pocd= "50") & ownst in("NC","VA","NM","SC","OK","TX");
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
IF SSNO1=: "99" THEN BadSSN="X";  *Flag bad SSNs;
IF SSNO1=: "98" THEN BadSSN="X";
RUN;
DATA loan1_2fb;
SET loan_PULL;
keep BRACCTNO;
RUN;
PROC sort DATA=loan1_2fb; by BRACCTNO; RUN;
PROC sort DATA=loaNExtrafb; by BRACCTNO; RUN;
DATA loaNExtra2fb;
merGE loaNExtrafb(in=x) loan1_2fb(in=y);
by BRACCTNO;
IF x AND not y;
RUN;


DATA loanparaDATAfb;
SET dw.vw_loan(keep= BRACCTNO xno_availCREDIT xno_tduepoff id ownbr ownst SSNO1 SSNo2 SSNO1_RT7 LnAmt FinChg LoanType EntDATE LoANDATE ClassID ClassTranslation XNO_TrueDueDATE FIRSTPyDATE SrCD pocd POffDATE plcd PlDATE PlAmt BnkrptDATE BnkrptChAPTer DATEPaidLAST APRate CRSCORE NEtLoanAmount XNO_AvailCREDIT XNO_TDuePOff CurBal conprofile1);
where POffDATE between "&_6YR" AND "&_1DAY" & (pocd="13" or pocd= "10" or pocd= "50") & ownst not in ("NC","VA","NM","SC","OK","TX");
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
IF SSNO1=: "99" THEN BadSSN="X";  *Flag bad SSNs;
IF SSNO1=: "98" THEN BadSSN="X"; 
RUN;

DATA SET1fb;
SET loanparaDATAfb loaNExtra2fb;
RUN;

DATA goodSSN_lfb badSSN_lfb;
SET SET1fb;
IF badSSN="X" THEN OUTPUT badSSN_lfb;
else OUTPUT goodSSN_lfb;
RUN;

PROC sort DATA=goodSSN_lfb; by SSNO1; RUN;
PROC sql;
create table goodSSN_lfb as
select *
from goodSSN_lfb
group by SSNO1
having entDATE = MAX(entDATE);
quit;
PROC sort DATA=goodSSN_lfb nodupkey; by SSNO1; RUN;
PROC sort DATA=goodSSN_b; by SSNO1; RUN;
DATA merGEdgoodSSNfb;
merGE goodSSN_lfb(in=x) goodSSN_b(in=y);
by SSNO1;
IF x AND y;
RUN;

PROC sql;
create table badSSN_lfb as
select *
from badSSN_lfb
group by SS7brSTATE
having entDATE = MAX(entDATE);
quit;
PROC sort DATA=badSSN_lfb nodupkey; by SS7brSTATE; RUN;
PROC sort DATA=badSSN_b; by SS7brSTATE; RUN;
DATA merGEdbadSSNfb;
merGE badSSN_lfb(in=x) badSSN_b(in=y);
by SS7brSTATE;
IF x AND y;
RUN;

PROC sort DATA=merGEdbadSSNfb nodupkey; by SS7brSTATE; RUN;

DATA SSNsfb;
SET merGEdgoodSSNfb merGEdbadSSNfb;
RUN;


PROC sort DATA=SSNsfb nodupkey; by BRACCTNO; RUN;
PROC sort DATA=loannlsfb nodupkey; by BRACCTNO; RUN;

DATA paraDATA;
merGE loannlsfb(in=x) SSNsfb(in=y);
by BRACCTNO;
IF not x AND y;
RUN;

DATA fb;
SET loannlsfb paraDATA;
camp_type="FB";
RUN; 

*APPEND XS TO FB;
DATA merGEd_l_b_xs_fb;
SET fb xs_TOtal;
RUN;
PROC sort DATA=merGEd_l_b_xs_fb OUT=merGEd_l_b_xs_fb2 nodupkey; by BRACCTNO; RUN;

DATA y;
SET dw.exclude_loan (keep=BRACCTNO conprofile1);
RENAME ConProfile1=OLDCon;
RUN;

PROC sort DATA=merGEd_l_b_xs_fb2;
by BRACCTNO;
RUN;
PROC sort DATA=y;
by BRACCTNO;
RUN;

DATA merGEd_l_b_xs_fb2;
merGE merGEd_l_b_xs_fb2 (in=x) y;
by BRACCTNO;
IF x;
RUN;

DATA merGEd_l_b_xs_fb2;
SET merGEd_l_b_xs_fb2;
IF cOLDcon NE "" THEN conprofile1 = OLDcon;
RUN;


*PULL in information for statflags;
DATA Statflags;
SET dw.vw_loan (keep= ownbr SSNO1_RT7 entDATE StatFlags);
where entDATE > "&_7YR" & statflags NE "";
RUN;
 PROC sql; *identIFying bad statflags;
 create table statflags2 as
 select * from statflags where statflags contains "A"
 union 
 select * from statflags where statflags contains "B"
 union
 select * from statflags where statflags contains "C"
 union
 select * from statflags where statflags contains "D"
 union
 select * from statflags where statflags contains "I"
 union
 select * from statflags where statflags contains "J"
 union 
 select * from statflags where statflags contains "L"
  union 
 select * from statflags where statflags contains "P"
  union 
 select * from statflags where statflags contains "R"
	union 
 select * from statflags where statflags contains "V"
union 
 select * from statflags where statflags contains "W"
union 
 select * from statflags where statflags contains "X"
union 
 select * from statflags where statflags contains "S";
 quit;
DATA statflags2; *tagging bad statflags;
 SET statflags2;
 statfl_flag="X";
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
DROP entDATE ownbr SSNO1_RT7;
RENAME statflags=statflags_OLD;
 RUN;
PROC sort DATA=statflags2 nodupkey; by SS7brSTATE; RUN;
PROC sort DATA=merGEd_l_b_xs_fb2; by SS7brSTATE; RUN;
DATA MerGEd_L_B2; *MerGE file with statflag flags;
merGE merGEd_l_b_xs_fb2(in=x) statflags2;
by SS7brSTATE;
IF x=1;
RUN;


DATA merGEd_l_b2;
SET merGEd_l_b2;
IF bnkrptDATE NE "" THEN bk5_flag="X";
IF bnkrptchAPTer not in (0,.) THEN bk5_flag="X";
RUN;


*Flag bad TRW status;
DATA trwstatus_fl;
SET dw.vw_loan (keep= ownbr SSNO1_RT7 EntDATE trwstatus);
where entDATE > "&_7YR" & TrwStatus NE "";
RUN;
DATA trwstatus_fl; *flag for bad trw's;
SET trwstatus_fl;
TRW_flag = "X";
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
DROP entDATE SSNO1_RT7 ownbr;
RUN;
PROC sort DATA=trwstatus_fl nodupkey; by SS7brSTATE; RUN;
PROC sort DATA=merGEd_l_b2; by SS7brSTATE; RUN;
DATA MerGEd_L_B2; *merGE PULL with trw flags;
merGE MerGEd_L_B2(in=x) trwstatus_fl;
by SS7brSTATE;
IF x;
RUN;


*IdentIFy bad PO Codes;
DATA PO_codes_5yr;
SET dw.vw_loan (keep=EntDATE pocd SSNO1_RT7 ownbr);
where EntDATE > "&_7YR" & pocd in ("49", "50", "61", "62", "63", "64", "66", "68", "93", "97", "PB", "PO");
RUN;
DATA po_codes_5yr;
SET po_codes_5yr;
BadPOcode_flag = "X";
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
DROP entDATE pocd SSNO1_RT7 ownbr;
RUN;
PROC sort DATA=po_codes_5yr nodupkey; by SS7brSTATE; RUN;
PROC sort DATA=merGEd_l_b2; by SS7brSTATE; RUN;
DATA merGEd_l_b2;
merGE merGEd_l_b2(in=x) po_codes_5yr;
by SS7brSTATE;
IF x;
RUN;


DATA PO_codes_forever;
SET dw.vw_loan (keep=EntDATE pocd SSNO1_RT7 ownbr);
where pocd in ("21", "94", "95", "96");
RUN;
DATA po_codes_forever;
SET po_codes_forever;
Deceased_flag = "X";
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
DROP entDATE pocd SSNO1_RT7 ownbr;
RUN;
PROC sort DATA=po_codes_forever nodupkey; by SS7brSTATE; RUN;
DATA merGEd_l_b2;
merGE merGEd_l_b2(in=x) po_codes_forever;
by SS7brSTATE;
IF x;
RUN;

DATA con5yr_fl;
SET dw.vw_loan (keep= ownbr SSNO1_RT7 EntDATE conprofile1);
where entDATE > "&_7YR" & conprofile1 NE "";
RUN;
DATA con5yr_fl; *flag for con5;
SET con5yr_fl;
_60=countc(conprofile1,"2");
IF _60>3 THEN con5yr_flag="X";
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
DROP entDATE SSNO1_RT7 ownbr conprofile1 _60;
RUN;
DATA con5yr_fl_2;
SET con5yr_fl;
IF con5yr_flag="X";
RUN;
PROC sort DATA=con5yr_fl_2 nodupkey; by SS7brSTATE; RUN;
PROC sort DATA=merGEd_l_b2; by SS7brSTATE; RUN;
DATA MerGEd_L_B2; *merGE PULL with con5 flags;
merGE MerGEd_L_B2(in=x) con5yr_fl_2;
by SS7brSTATE;
IF x;
RUN;


*IdentIFy IF cusTOmer currently has an open loan for FB;
DATA openloans;
SET dw.vw_loan (keep= ownbr SSNo2 SSNO1_RT7 pocd plcd poffDATE plDATE bnkrptDATE);
where pocd = "" & plcd="" & poffDATE="" & plDATE="" & bnkrptDATE="";
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
RUN;
DATA SSNo2s;
SET openloans;
SS7brSTATE=CATS((substr(SSNo2,MAX(1,length(SSNo2)-6))),substr(ownbr,1,2));
IF SSNo2 NE "" THEN OUTPUT SSNo2s;
RUN;
DATA openloans1;
SET openloans SSNo2s;
RUN;
DATA openloans1;
SET openloans1;
Open_flag = "X";
DROP pocd SSNO1_RT7 OwnBr plcd poffDATE plDATE bnkrptDATE SSNo2;
RUN;
PROC sort DATA=openloans1 nodupkey; by SS7brSTATE; RUN;
PROC sort DATA=merGEd_l_b2; by SS7brSTATE; RUN;
DATA merGEd_l_b2;
merGE merGEd_l_b2(in=x) openloans1;
by SS7brSTATE;
IF x;
RUN;
DATA merGEd_l_b2;
SET merGEd_l_b2;
IF camp_type="XS" THEN open_flag="";
RUN;



*IdentIFy IF cusTOmer currently has an open loan for XS;
DATA openloansxs;
SET dw.vw_loan (keep= SSNo2 SSNO1 pocd plcd poffDATE plDATE bnkrptDATE);
where pocd = "" & plcd="" & poffDATE="" & plDATE="" & bnkrptDATE="";
RUN;
DATA SSNo2s2;
SET openloansxs;
IF SSNo2 NE "" THEN OUTPUT SSNo2s2;
RUN;
DATA SSNo2s2;
SET SSNo2s2;
SSNO1=SSNo2;
RUN;
DATA openloans1xs;
SET openloansxs SSNo2s2;
RUN;
DATA openloans1xs;
SET openloans1xs;
Open_flag = "X";
DROP pocd plcd poffDATE plDATE bnkrptDATE SSNo2;
RUN;
PROC sort DATA=openloans1xs nodupkey; by SSNO1; RUN;
DATA unmadesDROP merGEd_l_b3;
SET merGEd_l_b2;
IF made_unmade="UNMADE" THEN OUTPUT unmadesDROP;
else OUTPUT merGEd_l_b3;
RUN;
PROC sort DATA=unmadesDROP; by SSNO1; RUN;
DATA unmadesDROP;
merGE unmadesDROP(in=x) openloans1xs;
by SSNO1;
IF x;
RUN;

DATA merGEd_l_b2;
SET merGEd_l_b3 unmadesDROP;
RUN;


DATA openloans2;
SET dw.vw_loan (keep= ownbr SSNo2 SSNO1_RT7 pocd plcd poffDATE plDATE bnkrptDATE);
where pocd = "" & plcd="" & poffDATE="" & plDATE="" & bnkrptDATE="";
SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
RUN;
DATA SSNo2s;
SET openloans2;
SS7brSTATE=CATS((substr(SSNo2,MAX(1,length(SSNo2)-6))),substr(ownbr,1,2));
IF SSNo2 NE "" THEN OUTPUT SSNo2s;
RUN;
DATA openloans3;
SET openloans2 SSNo2s;
RUN;
DATA openloans4;
SET openloans3;
Open_flag2 = "X";
IF SS7brSTATE = "" THEN SS7brSTATE=CATS(SSNO1_RT7,substr(ownbr,1,2));
DROP pocd SSNo2 SSNO1_RT7 OwnBr plcd poffDATE plDATE bnkrptDATE;
RUN;
PROC sort DATA=openloans4; by SS7brSTATE; RUN;
DATA oNE_open mult_open;
SET openloans4;
by SS7brSTATE;
IF FIRST.SS7brSTATE AND LAST.SS7brSTATE THEN OUTPUT oNE_open;
else OUTPUT mult_open;
RUN;
PROC sort DATA=mult_open nodupkey; by SS7brSTATE; RUN;
PROC sort DATA=merGEd_l_b2; by SS7brSTATE; RUN;
DATA merGEd_l_b2;
merGE merGEd_l_b2(in=x) mult_open;
by SS7brSTATE;
IF x;
RUN;





*flag incomplete info;
*flag null DOB;
*FIND STATEs OUTside of footprint;
*Flag DNS DNH;
*Flag nonmatching branch STATE AND borrower STATE;
*Flag bad SSNs;

DATA MerGEd_L_B2; 
SET MerGEd_L_B2;
ADR1=STRIP(ADR1);
ADR2=STRIP(ADR2);
CITY=STRIP(CITY);
STATE=STRIP(STATE);
ZIP=STRIP(ZIP);
confidential=STRIP(confidential);
solicit=STRIP(solicit);
FIRSTNAME=compress(FIRSTNAME,'1234567890!@#$^&*()''"%');
LASTNAME=compress(LASTNAME,'1234567890!@#$^&*()''"%');
IF ADR1="" THEN MissingInfo_flag = "X"; *flag incomplete info;
IF STATE="" THEN MissingInfo_flag = "X"; *flag incomplete info;
IF FIRSTNAME="" THEN MissingInfo_flag = "X"; *flag incomplete info;
IF LASTNAME="" THEN MissingInfo_flag = "X"; *flag incomplete info;
IF STATE not in ("AL", "GA", "NC", "NM", "OK", "SC", "TN", "TX", "VA") THEN OOS_flag = "X"; *FIND STATEs OUTside of footprint;
IF confidential = "Y" THEN DNS_DNH_flag = "X";  *Flag Confidential;
IF solicit = "N" THEN DNS_DNH_flag = "X";  *Flag DNS;
IF ceaseANDdesist = "Y" THEN DNS_DNH_flag = "X";  *Flag CANDD;
IF SSNO1="" THEN SSNO1=SSNo;
IF ownbr in ("600" , "9000" , "198" , "1", "0001" , "0198" , "0600") THEN BadBranch_flag="X";
IF substr(ownbr,3,2)="99" THEN BadBranch_flag="X";
_60=countc(conprofile1,"2");
_90=countc(conprofile1,"3");
_120a=countc(conprofile1,"4");
_120b=countc(conprofile1,"5");
_120c=countc(conprofile1,"6");
_120d=countc(conprofile1,"7");
_120e=countc(conprofile1,"8");
_90plus=sum(_90,_120a,_120b,_120c,_120d,_120e);
IF _60>2 | _90plus>2 THEN conprofile_flag="X";
_9s=countc(conprofile1,"9");
IF _9s>10 THEN lessthan2_flag = "X";
XNO_TrueDueDATE2=INPUT(substr(XNO_TrueDueDATE,6,2)||'/'||substr(XNO_TrueDueDATE,9,2)||'/'||substr(XNO_TrueDueDATE,1,4),mmddyy10.);
FIRSTPyDATE2=INPUT(substr(FIRSTPyDATE,6,2)||'/'||substr(FIRSTPyDATE,9,2)||'/'||substr(FIRSTPyDATE,1,4),mmddyy10.);
Pmt_days=XNO_TrueDueDATE2-FIRSTPyDATE2;
IF pmt_days<60 THEN lessthan2_flag="X";
IF pmt_days = . & _9s <10 THEN lessthan2_flag="";
IF pmt_days>59 & _9s>10 THEN lessthan2_flag=""; *pmt_days calculation wins over conprofile;
equityt=(XNO_AvailCREDIT/xno_tduepoff)*100;
IF equityt <10 THEN et_flag="X";
IF xno_availCREDIT<100 THEN et_flag="X";
IF ownbr = "0251" THEN ownbr="0580";
IF ownbr = "0252" THEN ownbr="0683";
IF ownbr = "0253" THEN ownbr="0581";
IF ownbr = "0254" THEN ownbr="0582";
IF ownbr = "0255" THEN ownbr="0583";
IF ownbr = "0256" THEN ownbr="1103";
IF ZIP=:"36264" & ownbr="0877" THEN ownbr="0870";
IF ownbr="0877" THEN ownbr="0806";
IF ownbr="0159" THEN ownbr="0132";
IF ZIP=:"29659" & ownbr="0152" THEN ownbr="0121";
IF ownbr="0152" THEN ownbr="0115";
IF ownbr="0885" THEN ownbr="0802";
IF ownbr="0302" THEN ownbr="0133";
IF ownbr="0102" THEN ownbr="0303";
IF ownbr="0150" THEN ownbr="0105";
IF ownbr="0890" THEN ownbr="0875";
IF ownbr = "1016" THEN ownbr="1008";
IF ownbr="1003" AND ZIP=:"87112" THEN ownbr="1013";
RUN;


DATA merGEd_l_b2;
SET merGEd_l_b2;
IF camp_type="FB" THEN DO;
IF ownst NE STATE THEN STATE_Mismatch_flag = "X"; *Flag nonmatching branch STATE AND borrower STATE;
lessthan2_flag="";
et_flag = "";
END;
IF camp_type="XS" & made_unmade="UNMADE" THEN et_flag="";
RUN;



*PULL AND merGE dlq info for fbs;
PROC format;
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
DATA temp;   
   SET dw.vw_loan(keep=BRACCTNO entDATE poffDATE pocd classtranslation lnamt conprofile1 
                       brtrffg SSNO1_RT7 where=(pocd in ("10","13","50") AND poffDATE > "&_6YR"));
   entdt = INPUT(substr(entDATE,6,2)||'/'||substr(entDATE,9,2)||'/'||substr(entDATE,1,4),mmddyy10.);
   podt = INPUT(substr(poffDATE,6,2)||'/'||substr(poffDATE,9,2)||'/'||substr(poffDATE,1,4),mmddyy10.);
   IF poffDATE > "&_1DAY" THEN delete; 													   
   IF PUT(entdt,yymmn6.) = PUT(podt,yymmn6.) THEN delete;    
   DROP poffDATE entDATE pocd;
RUN;
PROC sort nodupkey; by BRACCTNO; RUN;
DATA atb;
   SET dw.atb_DATA(keep=BRACCTNO aGE2 yearmonth);    
   poacctno = BRACCTNO*1;   
   atbdt = INPUT(substr(yearmonth,6,2)||'/'||substr(yearmonth,9,2)||'/'||substr(yearmonth,1,4),mmddyy10.);   
   IF aGE2 =: '1' THEN aGE2 = '1.Current';   
   keep atbdt aGE2 BRACCTNO;
RUN;
PROC sort nodupkey; by BRACCTNO atbdt; RUN;
DATA temp;     
   merGE temp(in=a) atb(in=b);
   by BRACCTNO;
   IF a;  
   cd = substr(aGE2,1,1)*1;   
   aGE = intck('month',atbdt,podt); 
   IF      aGE = 1 THEN delq1 = cd;
   else IF aGE = 2 THEN delq2 = cd;
   else IF aGE = 3 THEN delq3 = cd;
   else IF aGE = 4 THEN delq4 = cd;
   else IF aGE = 5 THEN delq5 = cd;
   else IF aGE = 6 THEN delq6 = cd;
   else IF aGE = 7 THEN delq7 = cd;
   else IF aGE = 8 THEN delq8 = cd;
   else IF aGE = 9 THEN delq9 = cd;
   else IF aGE =10 THEN delq10= cd;
   else IF aGE =11 THEN delq11= cd;
   else IF aGE =12 THEN delq12= cd;
   else delete;
       IF cd>4 THEN cd90 = 1; *IF cd is greater than 60-89 days late, SET cd90 TO 1;
    IF cd>3 THEN cd60 = 1; *IF cd is greater than 30-59 days late, SET cd60 TO 1;
   IF cd>2 THEN cd30 = 1; *IF cd is greater than 1-29 days late, SET cd30 TO 1;
   IF aGE<7 THEN DO;
		IF cd=3 THEN recent6=1; *note 30-59s in LAST six months of LAST open loan;
		END;
		else IF 6<aGE<13 THEN DO;
		IF cd=3 THEN FIRST6=1; *note 30-59s from 7 TO 12 months of LAST open loan;
		END;
   format podt entdt atbdt mmddyy10.;
RUN;
DATA temp2;
SET temp;
LAST12=sum(recent6,FIRST6); *count the number of 30-59s in the LAST year when fb had open loan;
RUN;
PROC summary DATA=temp2 nway missing;
   class classtranslation SSNO1_RT7 BRACCTNO entdt podt lnamt conprofile1;
   var delq1-delq12 recent6 LAST12 FIRST6 cd90 cd60 cd30;
   OUTPUT OUT=final(DROP=_type_ _freq_) sum=;
RUN; 
DATA fbdlq;
   SET final;
   IF cd60 > 0 THEN ever60 = 'Y'; else ever60 = 'N';
   times30 = cd30;
   IF times30 = . THEN times30 = 0;
   DROP cd30;
   format delq1-delq12 cdfmt.;
RUN;
PROC sort DATA=fbdlq; by BRACCTNO; RUN;
 DATA fb;
 SET merGEd_l_b2;
 IF camp_type="FB";
 RUN;
PROC sort DATA=fb; *sort TO merGE; by BRACCTNO; RUN;
DATA fbwithdlq; *merGE PULL AND dql information;
merGE fb(in=x) fbdlq(in=y);
by BRACCTNO;
IF x=1;
RUN;


*****************************************;
*PULL AND merGE dlq info for xs;
DATA atb; 
   SET dw.atb_DATA(keep=BRACCTNO aGE2 yearmonth where=(yearmonth between "&_1YR" AND "&_1DAY"));  
   atbdt = INPUT(substr(yearmonth,6,2)||'/'||substr(yearmonth,9,2)||'/'||substr(yearmonth,1,4),mmddyy10.);     
   aGE = intck('month',atbdt,"&sysDATE"d);
cd = substr(aGE2,1,1)*1;   
 *i.e. for aGE=1: this is most recent month. Fill delq1, which is delq for month 1, with delq status (cd);
   IF      aGE = 1 THEN delq1 = cd;
   else IF aGE = 2 THEN delq2 = cd;
   else IF aGE = 3 THEN delq3 = cd;
   else IF aGE = 4 THEN delq4 = cd;
   else IF aGE = 5 THEN delq5 = cd;
   else IF aGE = 6 THEN delq6 = cd;
   else IF aGE = 7 THEN delq7 = cd;
   else IF aGE = 8 THEN delq8 = cd;
   else IF aGE = 9 THEN delq9 = cd;
   else IF aGE =10 THEN delq10= cd;
   else IF aGE =11 THEN delq11= cd;
   else IF aGE =12 THEN delq12= cd;
   IF cd>4 THEN cd90 = 1; *IF cd is greater than 60-89 days late, SET cd90 TO 1;
   IF cd>3 THEN cd60 = 1; *IF cd is greater than 30-59 days late, SET cd60 TO 1;
   IF cd>2 THEN cd30 = 1; *IF cd is greater than 1-29 days late, SET cd30 TO 1;
   IF aGE<7 THEN DO;
		IF cd=3 THEN recent6=1; *note 30-59s in LAST six months;
		END;
		else IF 6<aGE<13 THEN DO;
		IF cd=3 THEN FIRST6=1; *note 30-59s from 7 TO 12 months ago;
		END;
   keep BRACCTNO delq1-delq12 cd cd30 cd60 cd90 aGE2 atbdt aGE FIRST6 recent6;
RUN;
DATA atb2;
SET atb;
LAST12=sum(recent6,FIRST6); *count the number of 30-59s in the LAST year;
RUN;
*count cd30, cd60,recent6,FIRST6 by BRACCTNO (*reCALL loan potentiALLy counted for each month);
PROC summary DATA=atb2 nway missing;
   class BRACCTNO;
   var delq1-delq12 recent6 LAST12 FIRST6 cd90 cd60 cd30;
   OUTPUT OUT=atb3(DROP=_type_ _freq_) sum=;
RUN; 
DATA atb4; *create NEW counter variables;
   SET atb3;
   IF cd60 > 0 THEN ever60 = 'Y'; else ever60 = 'N';
   times30 = cd30;
   IF times30 = . THEN times30 = 0;
   IF recent6 = null THEN recent6=0;
   IF FIRST6 = null THEN FIRST6=0;
   IF LAST12 = null THEN LAST12=0;
   DROP cd30;
   format delq1-delq12 cdfmt.;
RUN;
PROC sort DATA=atb4 nodupkey; by BRACCTNO; RUN; *sort TO merGE;
DATA xsdlq; SET atb4; DROP null; *DROPping the null column (not nulls in DATASET); RUN;



DATA xs;
SET merGEd_l_b2;
IF camp_type="XS";
RUN;
PROC sort DATA=xs; *sort TO merGE; by BRACCTNO; RUN;
DATA xswithdlq; *merGE PULL AND dql information;
merGE xs(in=x) xsdlq(in=y);
by BRACCTNO;
IF x=1;
RUN;

DATA merGEd_l_b2;
SET fbwithdlq xswithdlq;
RUN;


*APPly ALL delinquency related flags;
DATA merGEd_l_b2; *flag for bad dlqatb;
SET merGEd_l_b2;
IF cd60>1 or cd90>1 THEN DLQ_Flag="X";
RUN;

PROC sort DATA=merGEd_l_b2 OUT= deduped nodupkey; by BRACCTNO; RUN;


*Export FlagGEd File;
/*
PROC export DATA=deduped OUTfile="&FINALEXPORTFLAGGED" DBMS=tab;
RUN;
*/

 *Create final file for DROPs;
 DATA final;
 SET deduped;
 IF entDATE="" THEN entDATE=1;
 RUN;


  DATA WaterfALL;
 length Criteria $50 Count 8.;
 infile DATAliNEs DLM="," tRUNcover;
 INPUT Criteria $ Count;
 DATAliNEs;
TCI DATA,
XS TOtal,
FB TOtal,
XS + FB TOtal,	
Delete cust in Bad Branches,	
Delete cust with Missing Info,	
Delete cust OUTside of Footprint,	
Delete where STATE/OwnSt Mismatch,
Delete FB With Open Loan,
Delete Any CusTOmer with >1 Loan,
Delete cust with Bad POCODE,
Delete Deceased,
Delete IF Less than Two Payments Made,	
Delete for ATB Delinquency,	
Delete for Conprofile Delinquency,
Delete for 5 Yr. Conprofile Delinquency,
Delete for Bankruptcy (5yr),
Delete for Statflag (5yr),
Delete for TRW Status (5yr),
Delete IF DNS or DNH,
Delete NC AUTO Unmades,	
Delete XS Bad FICOs,
Delete IF Equity ThreshhOLD not met,		
;
RUN;
	



PROC sql; *Count obs; create table count as select count(*) as Count from tci; quit;
PROC sql; insert inTO count select count(*) as Count from xs_TOtal; quit;
PROC sql; insert inTO count select count(*) as Count from fb; quit;
PROC sql; insert inTO count select count(*) as Count from MerGEd_L_B_xs_fb2; quit;
DATA final; SET final; IF BadBranch_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit;
DATA final; SET final; IF MissingInfo_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit; 
DATA final; SET final; IF OOS_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit; 
DATA final; SET final; IF STATE_Mismatch_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit; 
DATA final; SET final; IF open_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit;
DATA final; SET final; IF open_flag2=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit;
DATA final; SET final; IF BadPOcode_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit; 
DATA final; SET final; IF deceased_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit;
DATA final; SET final; IF lessthan2_flag=""; RUN; 
PROC sql; insert inTO count select count(*) as Count from final; quit; 
DATA final; SET final; IF dlq_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit;
DATA final; SET final; IF conprofile_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit;
DATA final; SET final; IF con5yr_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit;  
DATA final; SET final; IF bk5_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit; 
DATA final; SET final; IF statfl_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit; 
DATA final; SET final; IF TRW_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit; 
DATA final; SET final; IF DNS_DNH_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit; 
DATA final; SET final; IF NCAUTOUn_Flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit; 
DATA final; SET final; IF badfico_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit;
DATA final; SET final; IF et_flag=""; RUN;
PROC sql; insert inTO count select count(*) as Count from final; quit;

PROC print DATA=count noobs;  *Print Final Count Table;
RUN;
PROC print DATA=waterfALL;  *Print Final Count Table;
RUN;


*Export Final File;
DATA fbxsmita;
SET final;
RUN;
/*
PROC export DATA=final OUTfile="&FINALEXPORTDROPPED" DBMS=tab;
RUN;
*/

*SEND TO DOD;
DATA mla;
SET final;
keep SSNO1 DOB LASTNAME FIRSTNAME MIDDLENAME BRACCTNO;
RUN;
PROC DATASETs;
modIFy mla;
RENAME DOB ="DATE of Birth"n SSNO1="Social Security Number (SSN)"n LASTNAME="LAST NAME"n FIRSTNAME="FIRST NAME"n MIDDLENAME="MIDDLE NAME"n BRACCTNO="CusTOmer Record ID"n;
RUN;
DATA finalmla;
length "Social Security Number (SSN)"n $ 9 "DATE of Birth"n $ 8 "LAST NAME"n $ 26 "FIRST NAME"n $20 "MIDDLE NAME"n $ 20  "CusTOmer Record ID"n $ 28;
SET mla;
RUN;
PROC print DATA=finalmla (obs=10);
RUN;
PROC contents DATA=finalmla;
RUN;

DATA split1 split2;
SET finalmla;
IF "Social Security Number (SSN)"n=:"1" | "Social Security Number (SSN)"n=:"2" THEN OUTPUT split1;
else OUTPUT split2;
RUN;
DATA _NULL_;
 SET split1;
 file "&EXPORTMLA1"; 
 PUT @1 "Social Security Number (SSN)"n @10 "DATE of Birth"n @ 18 "LAST NAME"n @ 44 "FIRST NAME"n @ 64 "MIDDLE NAME"n @ 84 "CusTOmer Record ID"n ;
 RUN; 
 DATA _NULL_;
 SET split2;
 file "&EXPORTMLA2";  
 PUT @1 "Social Security Number (SSN)"n @10 "DATE of Birth"n @ 18 "LAST NAME"n @ 44 "FIRST NAME"n @ 64 "MIDDLE NAME"n @ 84 "CusTOmer Record ID"n ;
 RUN; 



*STEP 2: IMPORT file FROM DOD, APPEND offer information, AND APPEND PB IF APPlicable;
fileNAME mla1 "\\mktg-APP01\E\Production\MLA\MLA-OUTPUT files FROM WEBSITE\FBITAp1.txt";
DATA mla1;
infile mla1;
INPUT SSNO1 $ 1-9 DOB $ 10-17 LASTNAME $ 18-43 FIRSTNAME $ 44-63 MIDDLENAME $ 64-83  BRACCTNO $ 84-120 mla_DOd $121-145;
mla_status=substr(mla_DOd,1,1);
RUN;
fileNAME mla2 "\\mktg-APP01\E\Production\MLA\MLA-OUTPUT files FROM WEBSITE\FBITAp2.txt";
DATA mla2;
infile mla2;
INPUT SSNO1 $ 1-9 DOB $ 10-17 LASTNAME $ 18-43 FIRSTNAME $ 44-63 MIDDLENAME $ 64-83  BRACCTNO $ 84-120 mla_DOd $121-145;
mla_status=substr(mla_DOd,1,1);
RUN;

DATA mla1;
SET mla1 mla2;
RUN;
PROC contents DATA=mla1;
RUN;



PROC sort DATA=fbxsmita;
by BRACCTNO;
RUN;
PROC sort DATA=mla1;
by BRACCTNO;
RUN;
DATA finalhh;
merGE fbxsmita(in=x) mla1;
by BRACCTNO;
IF x;
RUN;

*Count for WaterfALL;
PROC freq DATA=finalhh;
table mla_status;
RUN;

DATA ficos;
SET finalhh;
RENAME CRSCORE=fico;
RUN;

DATA finalhh2;
length fico_RANGE_25pt $10 campaign_id $25 Made_Unmade $15 cIFno $20 custid $20 mgc $20 STATE1 $5 test_code $20;
SET ficos;
IF mla_status not in ("Y","");
IF fico=0 THEN fico_RANGE_25pt= "0";
IF 0<fico<500 THEN fico_RANGE_25pt="<500";
IF 500<=fico<=524 THEN fico_RANGE_25pt= "500-524";
IF 525<=fico<=549 THEN fico_RANGE_25pt= "525-549";
IF 550<=fico<=574 THEN fico_RANGE_25pt= "550-574";
IF 575<=fico<=599 THEN fico_RANGE_25pt= "575-599";
IF 600<=fico<=624 THEN fico_RANGE_25pt= "600-624";
IF 625<=fico<=649 THEN fico_RANGE_25pt= "625-649";
IF 650<=fico<=674 THEN fico_RANGE_25pt= "650-674";
IF 675<=fico<=699 THEN fico_RANGE_25pt= "675-699";
IF 700<=fico<=724 THEN fico_RANGE_25pt= "700-724";
IF 725<=fico<=749 THEN fico_RANGE_25pt= "725-749";
IF 750<=fico<=774 THEN fico_RANGE_25pt= "750-774";
IF 775<=fico<=799 THEN fico_RANGE_25pt= "775-799";
IF 800<=fico<=824 THEN fico_RANGE_25pt= "800-824";
IF 825<=fico<=849 THEN fico_RANGE_25pt= "825-849";
IF 850<=fico<=874 THEN fico_RANGE_25pt= "850-874";
IF 875<=fico<=899 THEN fico_RANGE_25pt= "875-899";
IF 975<=fico<=999 THEN fico_RANGE_25pt= "975-999";
IF fico="" THEN fico_RANGE_25pt= "";
IF SOURCE_2 = "RETAIL" THEN CAMPAIGN_id = "&RETAIL_ID";
IF SOURCE_2 = "AUTO" THEN CAMPAIGN_id = "&AUTO_ID";
IF camp_type="FB" THEN CAMPAIGN_id = "&FB_ID";
custid=STRIP(_n_);
Made_Unmade=madeunmade_flag;
offer_segment="ITA";
IF STATE1="" THEN STATE1=STATE;
IF STATE1="TX" THEN STATE1="";
IF entDATE=1 THEN entDATE="";
RUN;
DATA finalhh2;
SET finalhh2;
RENAME ownbr=branch FIRSTNAME=cfNAME1 MIDDLENAME=cmNAME1 LASTNAME=clNAME1 ADR1=caddr1 ADR2=caddr2
CITY=cCITY STATE=cst ZIP=cZIP SSNO1_RT7=SSN cd60=n_60_dpd conprofile1=ConProfile;
RUN;


DATA fbxsita_hh;
length From_Offer_Amount 8. Up_TO_Offer 8.;
SET finalhh2;
IF cst="NC" THEN From_Offer_Amount = 700;
IF cst="AL" THEN up_TO_offer=6000;
IF from_offer_amount = . THEN from_offer_amount = 600;
IF up_TO_offer = . THEN up_TO_offer = 7000;
IF branch="1019" THEN from_offer_amount=2501;
RUN;



*APPEND pbita;
DATA finalhh3;
length amt_given1 8. month_split $15 numpymnts $15 orig_amtid $15 percent $15 From_Offer_Amount 8. Up_TO_Offer 8.;
SET fbxsita_hh pbita_hh;
IF mla_status NE "";
RUN;
PROC sql;
create table finalesthh as
select custid, branch, cfNAME1,	cmNAME1, clNAME1, caddr1, caddr2, cCITY, cst, cZIP,	SSN, amt_given1, from_offer_amount, up_TO_offer, percent,numpymnts, camp_type, orig_amtid, fico, DOB, mla_status, risk_segment, n_60_dpd, conprofile, BRACCTNO, cIFno, campaign_id, mgc, month_split, made_unmade, fico_RANGE_25pt, STATE1, test_code, poffDATE, PHONE, CELLPHONE
from finalhh3;
quit;

PROC export DATA=finalesthh OUTfile="&FINALEXPORTHH" DBMS=tab;
 RUN;

 PROC export DATA=finalesthh OUTfile="&FINALEXPORTED"  DBMS=csv;
 RUN;
PROC freq DATA=finalesthh;
tables mla_status Risk_Segment STATE1 cst;
RUN;



 *For when pbita isn't included;
DATA finalhh3;
length amt_given1 8. month_split $15 numpymnts $15 orig_amtid $15 percent $15 From_Offer_Amount 8. Up_TO_Offer 8.;
SET fbxsita_hh;
IF mla_status NE "";
RUN;
PROC sql;
create table finalesthh as
select custid, branch, cfNAME1,	cmNAME1, clNAME1, caddr1, caddr2, cCITY, cst, cZIP,	SSN, amt_given1, from_offer_amount, up_TO_offer, percent,numpymnts, camp_type, orig_amtid, fico, DOB, mla_status, risk_segment, n_60_dpd, conprofile, BRACCTNO, cIFno, campaign_id, mgc, month_split, made_unmade, fico_RANGE_25pt, STATE1, test_code, poffDATE, PHONE, CELLPHONE
from finalhh3;
quit;

PROC export DATA=finalesthh OUTfile="&FINALEXPORTHH2" DBMS=tab;
 RUN;

 PROC export DATA=finalesthh OUTfile="&FINALEXPORTED2"  DBMS=csv;
 RUN;


PROC freq DATA=finalesthh;
tables mla_status Risk_Segment STATE1 cst;
RUN;
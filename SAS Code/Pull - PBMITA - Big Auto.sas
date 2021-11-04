OPTIONS MPRINT MLOGIC SYMBOLGEN; /* SET DEBUGGING OPTIONS */

%LET PULLDATE = %SYSFUNC(today(), yymmdd10.);
%PUT "&PULLDATE";

%LET _5YR_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-1825);
%LET _5YR = %SYSFUNC(putn(&_5YR_NUM,yymmdd10.));
%PUT "&_5YR";

%LET _13MO_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-395);
%LET _13MO = %SYSFUNC(putn(&_13MO_NUM,yymmdd10.));
%PUT "&_13MO";

%LET _1DAY_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-1);
%LET _1DAY = %SYSFUNC(putn(&_1DAY_NUM,yymmdd10.));
%PUT "&_1DAY";

DATA _NULL_;
	CALL SYMPUT ('PB_ID', 'PB10.1_2021ITA');
	CALL SYMPUT ('FINALEXPORTFLAGGED', 
		'\\mktg-app01\E\Production\2021\10_October_2021\ITA\PB_ITA_20210923flagged.txt');
	CALL SYMPUT ('FINALEXPORTDROPPED', 
		'\\mktg-app01\E\Production\2021\10_October_2021\ITA\PB_ITA_20210923final.txt');
	CALL SYMPUT ('EXPORTMLA', 
		'\\mktg-app01\E\Production\MLA\MLA-INPUT FILEs TO WEBSITE\PBITA_20210923.txt');
RUN;

DATA LOAN1;
	SET DW.VW_LOAN_NLS(
		KEEP = CIFNO BRACCTNO XNO_AVAILCREDIT XNO_TDUEPOFF ID OWNBR
			   OWNST SSNO1 SSNO2 SSNO1_RT7 LNAMT FINCHG LOANTYPE
			   ENTDATE LOANDATE CLASSID CLASSTRANSLATION
			   XNO_TRUEDUEDATE FIRSTPYDATE SRCD purcd POCD POFFDATE 
			   PLCD PLDATE PLAMT BNKRPTDATE BNKRPTCHAPTER DATEPAIDLAST
			   APRATE CRSCORE NETLOANAMOUNT XNO_AVAILCREDIT 
			   XNO_TDUEPOFF CURBAL CONPROFILE1);
	WHERE CIFNO NE "" & POCD = "" & PLCD = "" & BNKRPTDATE = "" &
		  PLDATE = "" & POFFDATE = "" &
		  OWNST IN("SC","NM","NC","OK","VA","TX","AL","GA","TN","MO", 
				   "WI", "IL");
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	IF CIFNO NOT =: "B";
RUN;

DATA BORRNLS;
	LENGTH FIRSTNAME $20 MIDDLENAME $20 LASTNAME $30;
	SET DW.VW_BORROWER(
		KEEP = RMC_UPDATED PHONE CIFNO SSNO SSNO_RT7 FNAME LNAME ADR1
			   ADR2 CITY STATE ZIP BRNO AGE CONFIDENTIAL SOLICIT
			   CEASEANDDESIST CREDITSCORE);
	WHERE CIFNO NOT =: "B";
	FNAME = STRIP(FNAME);
	LNAME = STRIP(LNAME);
	ADR1 = STRIP(ADR1);
	ADR2 = STRIP(ADR2);
	CITY = STRIP(CITY);
	STATE = STRIP(STATE);
	ZIP = STRIP(ZIP);

	IF FIND(FNAME, "JR") GE 1 THEN DO;
		FIRSTNAME = COMPRESS(FNAME, "JR");
		SUFFIX = "JR";
	END;

	IF FIND(FNAME, "SR") GE 1 THEN DO;
		FIRSTNAME = COMPRESS(FNAME, "SR");
		SUFFIX = "SR";
	END;

	IF SUFFIX = "" THEN DO;
		FIRSTNAME = SCAN(FNAME, 1, 1);
		MIDDLENAME = CATX(" ", SCAN(FNAME, 2, " "), 
							   SCAN(FNAME, 3, " "), 
							   SCAN(FNAME, 4, " "));
	END;

	NWORDS = COUNTW(FNAME, " ");

	IF NWORDS > 2 & SUFFIX NE "" THEN DO;
		FIRSTNAME = SCAN(FNAME, 1, " ");
		MIDDLENAME = SCAN(FNAME, 2, " ");
	END;

	LASTNAME = LNAME;
	DOB = COMPRESS(AGE,	"-");
	DROP FNAME LNAME NWORDS AGE;
	IF CIFNO NE "";
	
RUN;

PROC SQL;
	CREATE TABLE LOAN1NLS AS
	SELECT *
	FROM LOAN1
	GROUP BY CIFNO
	HAVING ENTDATE = MAX(ENTDATE);
QUIT;

PROC SORT 
	DATA = LOAN1NLS NODUPKEY; 
	BY CIFNO; 
RUN;

PROC SORT 
	DATA = BORRNLS; 
	BY CIFNO DESCENDING RMC_UPDATED; 
RUN;

PROC SORT 
	DATA = BORRNLS OUT = BORRNLS2 NODUPKEY; 
	BY CIFNO; 
RUN;

DATA LOANNLS;
	MERGE LOAN1NLS(IN = x) BORRNLS2(IN = y);
	BY CIFNO;
	IF x AND y;
RUN;

DATA LOANEXTRA;
	SET DW.VW_LOAN(
		KEEP = BRACCTNO XNO_AVAILCREDIT XNO_TDUEPOFF ID OWNBR OWNST
			   SSNO1 SSNO2 SSNO1_RT7 LNAMT FINCHG LOANTYPE ENTDATE
			   LOANDATE CLASSID CLASSTRANSLATION XNO_TRUEDUEDATE
			   FIRSTPYDATE SRCD purcd POCD POFFDATE PLCD PLDATE PLAMT
			   BNKRPTDATE BNKRPTCHAPTER DATEPAIDLAST APRATE CRSCORE
			   NETLOANAMOUNT XNO_AVAILCREDIT XNO_TDUEPOFF CURBAL
			   CONPROFILE1);
	WHERE PLCD = "" & 
		  POCD = "" & 
		  POFFDATE = "" & 
		  PLDATE = "" & 
		  BNKRPTDATE = "" & 
		  OWNST IN("SC", "NM", "NC", "OK", "VA", "TX", "AL", "GA",
				   "TN","MO", "WI","IL");
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	IF SSNO1 =: "99" THEN BADSSN = "X"; /* FLAG BAD SSNS */
	IF SSNO1 =: "98" THEN BADSSN = "X";
RUN;

DATA LOAN1_2;
	SET LOAN1;
	KEEP BRACCTNO;
RUN;

PROC SORT 
	DATA = LOAN1_2;
	BY BRACCTNO;
RUN;

PROC SORT 
	DATA = LOANEXTRA;
	BY BRACCTNO;
RUN;

DATA LOANEXTRA2;
	MERGE LOANEXTRA(IN = x) LOAN1_2(IN = y);
	BY BRACCTNO;
	IF x AND NOT y;
RUN;

DATA LOANPARADATA;
	SET DW.VW_LOAN(
		KEEP = BRACCTNO XNO_AVAILCREDIT XNO_TDUEPOFF ID OWNBR OWNST
			   SSNO1 SSNO2 SSNO1_RT7 LNAMT FINCHG LOANTYPE ENTDATE
			   LOANDATE CLASSID CLASSTRANSLATION XNO_TRUEDUEDATE
			   FIRSTPYDATE SRCD purcd POCD POFFDATE PLCD PLDATE PLAMT
			   BNKRPTDATE BNKRPTCHAPTER DATEPAIDLAST APRATE CRSCORE
			   NETLOANAMOUNT XNO_AVAILCREDIT XNO_TDUEPOFF CURBAL
			   CONPROFILE1);
	WHERE PLCD = "" & 
		  POCD = "" & 
		  POFFDATE = "" & 
		  PLDATE = "" & 
		  BNKRPTDATE = "" & 
		  OWNST NOT IN ("SC", "NM", "NC", "OK", "VA", "TX", "AL", "GA",
						"TN","MO", "WI", "IL");
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	IF SSNO1 =: "99" THEN BADSSN = "X"; /* FLAG BAD SSNS */
	IF SSNO1 =: "98" THEN BADSSN = "X"; 
RUN;

DATA SET1;
	SET LOANPARADATA LOANEXTRA2;
RUN;

DATA BORRPARADATA;
	LENGTH FIRSTNAME $20 MIDDLENAME $20 LASTNAME $30;
	SET DW.VW_BORROWER(
		KEEP = RMC_UPDATED PHONE CIFNO SSNO SSNO_RT7 FNAME LNAME ADR1
			   ADR2 CITY STATE ZIP BRNO AGE CONFIDENTIAL SOLICIT
			   CEASEANDDESIST CREDITSCORE);
	FNAME = STRIP(FNAME);
	LNAME = STRIP(LNAME);
	ADR1 = STRIP(ADR1);
	ADR2 = STRIP(ADR2);
	CITY = STRIP(CITY);
	STATE = STRIP(STATE);
	ZIP = STRIP(ZIP);

	IF FIND(FNAME, "JR") GE 1 THEN DO;
		FIRSTNAME = COMPRESS(FNAME, "JR");
		SUFFIX = "JR";
	END;

	IF FIND(FNAME, "SR") GE 1 THEN DO;
		FIRSTNAME = COMPRESS(FNAME, "SR");
		SUFFIX = "SR";
	END;

	IF SUFFIX = "" THEN DO;
		FIRSTNAME = SCAN(FNAME, 1, 1);
		MIDDLENAME = CATX(" ", SCAN(FNAME, 2, " "),
							   SCAN(FNAME, 3, " "), 
							   SCAN(FNAME, 4, " "));
	END;

	NWORDS = COUNTW(FNAME, " ");

	IF NWORDS > 2 & SUFFIX NE "" THEN DO;
		FIRSTNAME = SCAN(FNAME, 1, " ");
		MIDDLENAME = SCAN(FNAME, 2, " ");
	END;

	SS7BRSTATE = CATS(SSNO_RT7, SUBSTR(BRNO, 1, 2));
	LASTNAME = LNAME;
	RENAME SSNO_RT7 = SSNO1_RT7 
		   SSNO = SSNO1;
	IF SSNO =: "99" THEN BADSSN = "X"; /* FLAG BAD SSNS */
	IF SSNO =: "98" THEN BADSSN = "X"; 
	DOB = COMPRESS(AGE, "-");
	DROP NWORDS AGE FNAME LNAME;
RUN;

DATA GOODSSN_L BADSSN_L;
	SET SET1;
	IF BADSSN = "X" THEN OUTPUT BADSSN_L;
	ELSE OUTPUT GOODSSN_L;
RUN;

DATA GOODSSN_B BADSSN_B;
	SET BORRPARADATA;
	IF BADSSN = "X" THEN OUTPUT BADSSN_B;
	ELSE OUTPUT GOODSSN_B;
RUN;

PROC SORT 
	DATA = GOODSSN_L; 
	BY SSNO1; 
RUN;

PROC SQL;
	CREATE TABLE GOODSSN_L AS
	SELECT *
	FROM GOODSSN_L
	GROUP BY SSNO1
	HAVING ENTDATE = MAX(ENTDATE);
QUIT;

PROC SORT 
	DATA = GOODSSN_L NODUPKEY; 
	BY SSNO1; 
RUN;

PROC SORT 
	DATA = GOODSSN_B; 
	BY SSNO1 DESCENDING RMC_UPDATED; 
RUN;

PROC SORT 
	DATA = GOODSSN_B NODUPKEY; 
	BY SSNO1; 
RUN;

DATA MERGEDGOODSSN;
	MERGE GOODSSN_L(IN = x) GOODSSN_B(IN = y);
	BY SSNO1;
	IF x AND y;
RUN;

PROC SORT 
	DATA = BADSSN_L; 
	BY SS7BRSTATE; 
RUN;

PROC SQL;
	CREATE TABLE BADSSN_L AS
	SELECT *
	FROM BADSSN_L
	GROUP BY SS7BRSTATE
	HAVING ENTDATE = MAX(ENTDATE);
QUIT;

PROC SORT 
	DATA = BADSSN_L NODUPKEY; 
	BY SS7BRSTATE; 
RUN;

PROC SORT 
	DATA = BADSSN_B; 
	BY SS7BRSTATE DESCENDING RMC_UPDATED; 
RUN;

PROC SORT 
	DATA = BADSSN_B NODUPKEY; 
	BY SS7BRSTATE; 
RUN;

DATA MERGEDBADSSN;
	MERGE BADSSN_L(IN = x) BADSSN_B(IN = y);
	BY SS7BRSTATE;
	IF x AND y;
RUN;

DATA SSNS;
	SET MERGEDGOODSSN MERGEDBADSSN;
RUN;

PROC SORT 
	DATA = SSNS NODUPKEY; 
	BY BRACCTNO; 
RUN;

PROC SORT 
	DATA = LOANNLS NODUPKEY; 
	BY BRACCTNO; 
RUN;

DATA PARADATA;
	MERGE LOANNLS(IN = x) SSNS(IN = y);
	BY BRACCTNO;
	IF NOT x AND y;
RUN;

DATA MERGED_L_B2;
	SET LOANNLS PARADATA;
RUN; 

PROC SORT 
	DATA = MERGED_L_B2 OUT = MERGED_L_B2_2 NODUPKEY; 
	BY BRACCTNO; 
RUN;

*** PULL IN INFORMATION FOR STATFLAGS ---------------------------- ***;
DATA STATFLAGS;
	SET DW.VW_LOAN(
		KEEP = OWNBR SSNO1_RT7 ENTDATE STATFLAGS);
	WHERE ENTDATE > "&_5YR" & 
		  STATFLAGS NE "";
RUN;

PROC SQL; /* IDENTIFYING BAD STATFLAGS */
 	CREATE TABLE STATFLAGS2 AS
	SELECT * 
	FROM STATFLAGS 
	WHERE STATFLAGS CONTAINS "1" OR STATFLAGS CONTAINS "2" OR
		  STATFLAGS CONTAINS "3" OR STATFLAGS CONTAINS "4" OR
		  STATFLAGS CONTAINS "5" OR STATFLAGS CONTAINS "6" OR
		  STATFLAGS CONTAINS "7" OR STATFLAGS CONTAINS "A" OR
		  STATFLAGS CONTAINS "B" OR STATFLAGS CONTAINS "C" OR
		  STATFLAGS CONTAINS "D" OR STATFLAGS CONTAINS "I" OR
		  STATFLAGS CONTAINS "J" OR STATFLAGS CONTAINS "L" OR
		  STATFLAGS CONTAINS "P" OR STATFLAGS CONTAINS "R" OR
		  STATFLAGS CONTAINS "V" OR STATFLAGS CONTAINS "W" OR
		  STATFLAGS CONTAINS "X" OR STATFLAGS CONTAINS "S";
RUN;

DATA STATFLAGS2; /* TAGGING BAD STATFLAGS */
	SET STATFLAGS2;
	STATFL_FLAG = "X";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP ENTDATE OWNBR SSNO1_RT7;
RUN;

PROC SORT 
	DATA = STATFLAGS2 NODUPKEY;
	BY SS7BRSTATE;
RUN;

PROC SORT 
	DATA = MERGED_L_B2_2;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2; /* MERGE FILE WITH STATFLAG FLAGS */
	MERGE MERGED_L_B2_2(IN = x) STATFLAGS2;
	BY SS7BRSTATE;
	IF x = 1;
RUN;

DATA CON5YR_FL;
	SET DW.VW_LOAN(
		KEEP = OWNBR SSNO1_RT7 ENTDATE CONPROFILE1);
	WHERE ENTDATE > "&_5YR" & 
		  CONPROFILE1 NE "";
RUN;

DATA CON5YR_FL; /* FLAG FOR CON5 */
	SET CON5YR_FL;
	_30 = COUNTC(CONPROFILE1, "1");
	_60 = COUNTC(CONPROFILE1, "2");
	_90 = COUNTC(CONPROFILE1, "3");
	_120A = COUNTC(CONPROFILE1, "4");
	_120B = COUNTC(CONPROFILE1, "5");
	_120C = COUNTC(CONPROFILE1, "6");
	_120D = COUNTC(CONPROFILE1, "7");
	_120E = COUNTC(CONPROFILE1, "8");
	_90PLUS = SUM(_90, _120A, _120B, _120C, _120D, _120E);
	IF _30 > 1 | _60 > 0 | _90PLUS > 0 THEN CON5YR_FLAG = "X";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP ENTDATE SSNO1_RT7 OWNBR CONPROFILE1 _30 _60 _90 _120A _120B
		 _120C _120D _120E _90PLUS;
RUN;

DATA CON5YR_FL_2;
	SET CON5YR_FL;
	IF CON5YR_FLAG = "X";
RUN;

PROC SORT 
	DATA = CON5YR_FL_2 NODUPKEY;
	BY SS7BRSTATE;
RUN;

PROC SORT 
	DATA = MERGED_L_B2;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2; /* MERGE PULL WITH CON5 FLAGS */
	MERGE MERGED_L_B2(IN = x) CON5YR_FL_2;
	BY SS7BRSTATE;
	IF x;
RUN;

*** IDENTIFY BAD PO CODES ---------------------------------------- ***;
DATA PO_CODES_5YR;
	SET DW.VW_LOAN(
		KEEP = ENTDATE POCD SSNO1_RT7 OWNBR);
	WHERE ENTDATE > "&_5YR" & 
		  POCD IN ("49", "50", "61", "62", "63", "64", "66", "68",
				   "93", "97", "PB", "PO");
RUN;

DATA PO_CODES_5YR;
	SET PO_CODES_5YR;
	BADPOCODE_FLAG = "X";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP ENTDATE POCD SSNO1_RT7 OWNBR;
RUN;

PROC SORT 
	DATA =PO_CODES_5YR NODUPKEY;
	BY SS7BRSTATE;
RUN;

PROC SORT 
	DATA = MERGED_L_B2;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) PO_CODES_5YR;
	BY SS7BRSTATE;
	IF x;
RUN;

DATA PO_CODES_FOREVER;
	SET DW.VW_LOAN(
		KEEP = ENTDATE POCD SSNO1_RT7 OWNBR);
	WHERE POCD IN ("21", "94", "95", "96");
RUN;

DATA PO_CODES_FOREVER;
	SET PO_CODES_FOREVER;
	DECEASED_FLAG = "X";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP ENTDATE POCD SSNO1_RT7 OWNBR;
RUN;

PROC SORT 
	DATA = PO_CODES_FOREVER NODUPKEY;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) PO_CODES_FOREVER;
	BY SS7BRSTATE;
	IF x;
RUN;

DATA OPENLOANS2;
	SET DW.VW_LOAN(
		KEEP = OWNBR SSNO2 SSNO1_RT7 POCD PLCD POFFDATE PLDATE
			   BNKRPTDATE);
	WHERE POCD = "" & 
		  PLCD = "" & 
		  POFFDATE = "" & 
		  PLDATE = "" & 
		  BNKRPTDATE = "";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
RUN;

DATA SSNO2S;
	SET OPENLOANS2;
	SS7BRSTATE = CATS((SUBSTR(SSNO2, MAX(1, LENGTH(SSNO2) - 6))), 
					   SUBSTR(OWNBR, 1, 2));
	IF SSNO2 NE "" THEN OUTPUT SSNO2S;
RUN;

DATA OPENLOANS3;
	SET OPENLOANS2 SSNO2S;
RUN;

DATA OPENLOANS4;
	SET OPENLOANS3;
	OPEN_FLAG2 = "X";
	IF SS7BRSTATE = "" THEN 
		SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP POCD SSNO2 SSNO1_RT7 OWNBR PLCD POFFDATE PLDATE BNKRPTDATE;
RUN;

PROC SORT 
	DATA = OPENLOANS4;
	BY SS7BRSTATE;
RUN;

DATA ONE_OPEN MULT_OPEN;
	SET OPENLOANS4;
	BY SS7BRSTATE;
	IF FIRST.SS7BRSTATE AND LAST.SS7BRSTATE THEN OUTPUT ONE_OPEN;
	ELSE OUTPUT MULT_OPEN;
RUN;

PROC SORT 
	DATA = MULT_OPEN NODUPKEY;
	BY SS7BRSTATE;
RUN;

PROC SORT 
	DATA = MERGED_L_B2;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) MULT_OPEN;
	BY SS7BRSTATE;
	IF x;
RUN;

*** FLAG BANKRUPTCIES IN PAST 5 YEARS ---------------------------- ***;
DATA BK5YRDROPS;
	SET DW.VW_LOAN(
		KEEP = ENTDATE SSNO1_RT7 OWNBR BNKRPTDATE BNKRPTCHAPTER);
	WHERE ENTDATE > "&_5YR";
RUN;

DATA BK5YRDROPS;
	SET BK5YRDROPS;
	WHERE BNKRPTCHAPTER > 0 | BNKRPTDATE NE "";
RUN;

DATA BK5YRDROPS;
	SET BK5YRDROPS;
	BK5_FLAG = "X";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP BNKRPTDATE ENTDATE SSNO1_RT7 OWNBR BNKRPTCHAPTER;
RUN;

PROC SORT 
	DATA = BK5YRDROPS NODUPKEY;
	BY SS7BRSTATE;
RUN;

PROC SORT 
	DATA = MERGED_L_B2;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) BK5YRDROPS;
	BY SS7BRSTATE;
	IF x;
RUN;

DATA MERGED_L_B2;
	SET MERGED_L_B2;
	IF BNKRPTDATE NE "" THEN BK5_FLAG = "X";
	IF BNKRPTCHAPTER NE 0 THEN BK5_FLAG = "X";
RUN;

*** FLAG BAD TRW STATUS ------------------------------------------ ***;
DATA TRWSTATUS_FL;
	SET DW.VW_LOAN(
		KEEP = OWNBR SSNO1_RT7 ENTDATE TRWSTATUS);
	WHERE ENTDATE > "&_5YR" & 
		  TRWSTATUS NE "";
RUN;

DATA TRWSTATUS_FL; /* FLAG FOR BAD TRW'S */
	SET TRWSTATUS_FL;
	TRW_FLAG = "X";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP ENTDATE OWNBR SSNO1_RT7;
RUN;

PROC SORT 
	DATA = TRWSTATUS_FL NODUPKEY;
	BY SS7BRSTATE;
RUN;

PROC SORT 
	DATA = MERGED_L_B2;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2; /* MERGE PULL WITH TRW FLAGS */
	MERGE MERGED_L_B2(IN = x) TRWSTATUS_FL;
	BY SS7BRSTATE;
	IF x;
RUN;

*** FIND STATES OUTSIDE OF FOOTPRINT                               ***;
*** FLAG DNS DNH                                                   ***;
*** FLAG NONMATCHING BRANCH STATE AND BORROWER STATE               ***;
*** IDENTIFY ALL AUTO LOANS                                        ***;
*** COUNT NUMBER OF MONTHS OF INACTIVITY                           ***;
*** CALCULATE FOR EQUITY THRESHOLD                                 ***;
*** FLAG INCOMPLETE INFO ----------------------------------------- ***;
DATA MERGED_L_B2; 
	SET MERGED_L_B2;
	ADR1 = STRIP(ADR1);
	ADR2 = STRIP(ADR2);
	CITY = STRIP(CITY);
	STATE = STRIP(STATE);
	ZIP = STRIP(ZIP);
	CONFIDENTIAL = STRIP(CONFIDENTIAL);
	SOLICIT = STRIP(SOLICIT);
	FIRSTNAME = COMPRESS(FIRSTNAME, '1234567890!@#$^&*()''"%');
	LASTNAME = COMPRESS(LASTNAME, '1234567890!@#$^&*()''"%');
	IF ADR1 = "" THEN MISSINGINFO_FLAG = "X";
	IF STATE = "" THEN MISSINGINFO_FLAG = "X";
	IF FIRSTNAME = "" THEN MISSINGINFO_FLAG = "X";
	IF LASTNAME = "" THEN MISSINGINFO_FLAG = "X";
	
	IF OWNBR IN ("1", "9000", "198", "498", "580", "600", "698", 
				 "898", "0001", "9000", "0198", "0498", "0580", 
				 "0600", "0698", "0898") THEN BADBRANCH_FLAG = "X";
	IF SUBSTR(OWNBR, 3, 2) = "99" THEN BADBRANCH_FLAG = "X";

	IF CLASSTRANSLATION IN ("Auto-I", "Auto-D") THEN 
		AUTODELETE_FLAG = "X"; /* IDENTIFY ALL AUTO LOANS */
	IF CLASSTRANSLATION = "Retail" THEN RETAILDELETE_FLAG = "X";

	*** FIND STATES OUTSIDE OF FOOTPRINT ------------------------- ***;
	IF STATE NOT IN ("SC", "NM", "NC", "OK", "VA", "TX", "AL", "GA",
					 "TN","MO", "WI", "IL") THEN OOS_FLAG = "X"; 

	*** FLAG CONFIDENTIAL ---------------------------------------- ***;
	IF CONFIDENTIAL = "Y" THEN DNS_DNH_FLAG = "X"; 
	IF SOLICIT = "N" THEN DNS_DNH_FLAG = "X"; /* FLAG DNS */
	IF CEASEANDDESIST = "Y" THEN DNS_DNH_FLAG = "X"; /* FLAG CANDD */
	IF SSNO1 = "" THEN SSNO1 = SSNO;
	*** FLAG NONMATCHING BRANCH STATE AND BORROWER STATE --------- ***;
	IF OWNST NE STATE THEN STATE_MISMATCH_FLAG = "X"; 
	*** COUNT NUMBER OF MONTHS OF INACTIVITY --------------------- ***;
	_9S = COUNTC(CONPROFILE1, "9"); 
	IF _9S > 10 THEN LESSTHAN2_FLAG = "X";
	XNO_TRUEDUEDATE2 = INPUT(SUBSTR(XNO_TRUEDUEDATE, 6, 2) || '/' || 
							 SUBSTR(XNO_TRUEDUEDATE, 9, 2) || '/' || 
							 SUBSTR(XNO_TRUEDUEDATE, 1, 4), mmddyy10.);
	FIRSTPYDATE2 = INPUT(SUBSTR(FIRSTPYDATE, 6, 2) || '/' || 
						 SUBSTR(FIRSTPYDATE, 9, 2) || '/' || 
						 SUBSTR(FIRSTPYDATE, 1, 4), mmddyy10.);
	PMT_DAYS = XNO_TRUEDUEDATE2 - FIRSTPYDATE2;
	IF PMT_DAYS < 60 THEN LESSTHAN2_FLAG = "X";
	IF PMT_DAYS = . & _9S < 10 THEN LESSTHAN2_FLAG = "";
	*** PMT_DAYS CALCULATION WINS OVER CONPROFILE ---------------- ***;
	IF PMT_DAYS > 59 & _9S > 10 THEN LESSTHAN2_FLAG = ""; 
	if purcd in ("020", "015", "016", "021", "022") then dlqren_flag = "X";
	IF OWNBR = "1016" THEN OWNBR = "1008";
	IF OWNBR = "1003" AND ZIP =: "87112" THEN OWNBR = "1013";
	IF BRNO = "1016" THEN BRNO = "1008";
	IF BRNO = "1003" AND ZIP =: "87112" THEN BRNO = "1013";
	IF OWNBR = "0251" THEN OWNBR = "0580";
	IF OWNBR = "0252" THEN OWNBR = "0683";
	IF OWNBR = "0253" THEN OWNBR = "0581";
	IF OWNBR = "0254" THEN OWNBR = "0582";
	IF OWNBR = "0255" THEN OWNBR = "0583";
	IF OWNBR = "0256" THEN OWNBR = "1103";
	IF ZIP =: "36264" & OWNBR = "0877" THEN OWNBR = "0870";
	IF OWNBR = "0877" THEN OWNBR = "0806";
	IF OWNBR = "0159" THEN OWNBR = "0132";
	IF ZIP =: "29659" & OWNBR = "0152" THEN OWNBR = "0121";
	IF OWNBR = "0152" THEN OWNBR = "0115";
	IF OWNBR = "0885" THEN OWNBR = "0802";
	IF OWNBR = "1018" THEN OWNBR = "1008";
	IF BRNO = "1018" THEN BRNO = "1008";

	/*COVID*/
	*IF OWNST = "NM" THEN BADBRANCH_FLAG = "X";
	/*Tiger King Branches*/
	/*
	IF OWNBR = "0415" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0504" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0518" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0521" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0537" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0585" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0586" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0589" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0904" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0910" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0915" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0917" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0918" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0921" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "0923" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "1001" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "1002" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "1007" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "1010" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "1011" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "1012" THEN BADBRANCH_FLAG = "X";
	IF OWNBR = "1014" THEN BADBRANCH_FLAG = "X";   */
RUN;   

*** PULL AND MERGE DLQ INFO -------------------------------------- ***;
DATA ATB; 
	SET dw.vw_AgedTrialBalance(
		KEEP = LoanNumber AGE2 BOM 
			WHERE = (BOM BETWEEN "&_13MO" AND "&_1DAY")); 
	BRACCTNO = LoanNumber;
	YEARMONTH = BOM;
	ATBDT = INPUT(SUBSTR(YEARMONTH, 6, 2) || '/' || 
				  SUBSTR(YEARMONTH, 9, 2) || '/' || 
				  SUBSTR(YEARMONTH, 1, 4), mmddyy10.);
	*** AGE IS MONTH NUMBER OF LOAN WHERE 1 IS MOST RECENT MONTH - ***;
	AGE = INTCK('MONTH', ATBDT, "&sysdate"d);
	CD = SUBSTR(AGE2, 1, 1) * 1;
	*** I.E. FOR AGE = 1: THIS IS MOST RECENT MONTH                ***;
	*** FILL DELQ1, WHICH IS DELQ FOR MONTH 1, WITH DELQ STATUS    ***; 
	*** (CD) ----------------------------------------------------- ***;
	IF AGE = 1 THEN DELQ1 = CD;
	ELSE IF AGE = 2 THEN DELQ2 = CD;
	ELSE IF AGE = 3 THEN DELQ3 = CD;
	ELSE IF AGE = 4 THEN DELQ4 = CD;
	ELSE IF AGE = 5 THEN DELQ5 = CD;
	ELSE IF AGE = 6 THEN DELQ6 = CD;
	ELSE IF AGE = 7 THEN DELQ7 = CD;
	ELSE IF AGE = 8 THEN DELQ8 = CD;
	ELSE IF AGE = 9 THEN DELQ9 = CD;
	ELSE IF AGE = 10 THEN DELQ10 = CD;
	ELSE IF AGE = 11 THEN DELQ11 = CD;
	ELSE IF AGE = 12 THEN DELQ12 = CD;
	IF CD > 4 THEN CD90 = 1;
	*** IF CD IS GREATER THAN 30 - 59 DAYS LATE, SET CD60 TO 1 --- ***;
	IF CD > 3 THEN CD60 = 1; 
	*** IF CD IS GREATER THAN 1 - 29 DAYS LATE, SET CD30 TO 1 ---- ***;
	IF CD > 2 THEN CD30 = 1; 

	IF AGE < 7 THEN DO;
		*** NOTE 30 - 59S IN LAST SIX MONTHS --------------------- ***;
		IF CD = 3 THEN RECENT6 = 1; 
	END;
	ELSE IF 6 < AGE < 13 THEN DO;
		*** NOTE 30 - 59S FROM 7 TO 12 MONTHS AGO ---------------- ***;
		IF CD = 3 THEN FIRST6 = 1; 
	END;

	KEEP BRACCTNO DELQ1-DELQ12 CD CD30 CD60 CD90 AGE2 ATBDT AGE FIRST6
		 RECENT6;
RUN;

DATA ATB2;
	SET ATB;
	*** COUNT THE NUMBER OF 30 - 59S IN THE LAST YEAR ------------ ***;
	LAST12 = SUM(RECENT6, FIRST6); 
RUN;

*** COUNT CD30, CD60, RECENT6, FIRST6 BY BRACCTNO (*RECALL LOAN    ***;
*** POTENTIALLY COUNTED FOR EACH MONTH) -------------------------- ***;
PROC SUMMARY 
	DATA = ATB2 NWAY MISSING;
	CLASS BRACCTNO;
	VAR DELQ1-DELQ12 RECENT6 LAST12 FIRST6 CD90 CD60 CD30;
	OUTPUT OUT = ATB3(DROP = _type_ _freq_) SUM = ;
RUN; 

PROC FORMAT; /* DEFINE FORMAT FOR DELQ */
	VALUE CDFMT 1 = 'Current'
				2 = '1-29CD'
				3 = '30-59CD'
				4 = '60-89CD'
				5 = '90-119CD'
				6 = '120-149CD'
				7 = '150-179CD'
				8 = '180+CD'
				OTHER = ' ';
RUN;

DATA ATB4; /* CREATE NEW COUNTER VARIABLES */
	SET ATB3;
	IF CD60 > 0 THEN EVER60 = 'Y'; 
	ELSE EVER60 = 'N';
	TIMES30 = CD30;
	IF TIMES30 = . THEN TIMES30 = 0;
	IF RECENT6 = NULL THEN RECENT6 = 0;
	IF FIRST6 = NULL THEN FIRST6 = 0;
	IF LAST12 = NULL THEN LAST12 = 0;
	DROP CD30;
	FORMAT DELQ1-DELQ12 CDFMT.;
RUN;

PROC SORT 
	DATA = ATB4 NODUPKEY; 
	BY BRACCTNO; 
RUN; /* SORT TO MERGE */

DATA DLQ;
	SET ATB4;
	DROP NULL; /* DROPPING THE NULL COLUMN (NOT NULLS IN DATASET) */
RUN;

PROC SORT 
	DATA = MERGED_L_B2; /* SORT TO MERGE */
	BY BRACCTNO;
RUN;

DATA MERGED_L_B2; /* MERGE PULL AND DQL INFORMATION */
	MERGE MERGED_L_B2(IN = x) DLQ(IN = y);
	BY BRACCTNO;
	IF x = 1;
RUN;

DATA MERGED_L_B2; /* FLAG FOR BAD DLQ */
	SET MERGED_L_B2;
	IF LAST12 > 3 or CD60 > 1 or CD90 > 0 THEN DLQ_FLAG = "X";
RUN;

*** CONPROFILE FLAGS --------------------------------------------- ***;
DATA MERGED_L_B2;
	SET MERGED_L_B2;
	_30 = COUNTC(CONPROFILE1, "1");
	_60 = COUNTC(CONPROFILE1, "2");
	_90=COUNTC(CONPROFILE1,"3");
	_120A = COUNTC(CONPROFILE1, "4");
	_120B = COUNTC(CONPROFILE1, "5");
	_120C = COUNTC(CONPROFILE1, "6");
	_120D = COUNTC(CONPROFILE1, "7");
	_120E = COUNTC(CONPROFILE1, "8");
	_90PLUS = SUM(_90, _120A, _120B, _120C, _120D, _120E);
	IF _30 > 3 | _60 > 1 | _90PLUS > 0 THEN CONPROFILE_FLAG = "X";
	camp_type = "PB";
RUN;

DATA MERGED_L_B2;
	SET MERGED_L_B2;
	EQUITYt = (XNO_AVAILCREDIT / XNO_TDUEPOFF) * 100;
	IF EQUITYt < 10 THEN et_FLAG = "X";
	IF XNO_AVAILCREDIT < 100 THEN et_FLAG = "X";
RUN;

PROC SORT
	DATA = MERGED_L_B2 OUT = DEDUPED NODUPKEY; 
	BY BRACCTNO; 
RUN;

**********************************************************************;
*************************** Big Auto Criteria ************************;
**********************************************************************;

libname nls odbc 
complete="driver=SQL Server; database=NLS_Prod; server=nls-prod-sqlreports" 
schema=DBO;

libname prod odbc 
complete="driver=SQL Server; database=RMCDW; server=server-dw" 
schema=DBO;

*** pulling the profiles reported in April'21 -------------------- ***;

proc sql;
	create table credit_profile as
	select * 
	from nls.CreditProfile
	/* change dates for desired month */
	where ReportDate >= '23SEP2020'D and 
		  ReportDate < '23SEP2021'D 
	group by cifno
    having CreditProfileID=max(CreditProfileID);
run;

proc sort 
	data = credit_profile nodupkey; 
	by cifno; 
run;

data booked_loan;
	set DEDUPED;
	cifno_new = input(cifno, 8.);
run;

*** joining booked loan data with credit profile data ------------ ***;
proc sql;
	create table loan_match as
	select A.*, B.* 
	from booked_loan A 
	left join credit_profile B 
		on A.cifno_new = B.cifno;
run;

*** loans can have duplicate creditprofileid, dedup on             ***;
*** creditprofileid ---------------------------------------------- ***;
proc sort 
	data = loan_match nodupkey; 
	by creditprofileid; 
run;

*** for the profiles match, pull in the tradeline details -------- ***;
proc sql;
	create table tradeline as
	select *
	from nls.credittradeline
	where CreditProfileID in(
		select CreditProfileID 
		from loan_match) 
	order by CreditProfileID;
run;

*** joined credit profile and tradeline -------------------------- ***;
proc sql;
	create table tradeline_profile as
	select B.*, A.*
	from Credit_Profile A 
	inner join tradeline B 
		on A.CreditProfileId = B.CreditProfileId;
run;

*** selecting profiles with one or more AUTO tradeline ----------- ***;
proc sql;
	create table auto as
	select * 
	from tradeline_profile 
	where AccountType in ('00', '3A'); 
run;

proc sql;
	select count(distinct creditprofileid) 
	from auto; 
run;

*** logic for tradline status - Open/Closed ---------------------- ***;
data auto1;
	set auto;
	if ECOA = 'X' or ECOA = 'T' 
		then Account_Status = 'Closed';

	if Status in ('6','7','8','9') 
		then Account_Status = 'Closed';

	if IsClosed in ('B','C') 
		then Account_Status = 'Closed';;

	if IsRevolving = 'I' and balanceamount = '0' 
		then Account_Status = 'Closed';

	else Account_Status = 'Open';
run;

proc freq 
	data = auto1; 
	tables account_status; 
run;

proc sql; 
	select account_status, count(distinct creditprofileid) 
	from auto1 
	group by account_status; 
run;

data auto2;
	set auto1;
	t = today();
	d = datepart(datereported);
	format d t date10.;
	age = intck('month',d,t)-1;

	if age <= 3 
		then Last_Reported = '1. <=3 months';

	if age > 3 and age <= 6 
		then Last_Reported = '2. 4-6 months';

	if age >= 7 
		then Last_Reported = '3. 7+ months';
run;

proc sql; 
	select Last_Reported, count(distinct creditprofileid) 
	from auto2 
	group by Last_Reported; 
run;

data auto3;
	set auto2;
	t1 = today();
	d1 = datepart(opendate);
	format d t date10.;
	age1 = intck('month',d,t)-1;

	if age1 <= 6 
		then Open = '1. <=6 months    ';

	if age1 > 6 and age <= 11 
		then Open = '2. 6-11 months';

	if age1 > 11 and age <= 23 
		then Open = '3. 12-23 months';

	if age1 >= 24 
		then Open = '4. 24+ months';
run;

proc sql; 
	select Open, count(distinct creditprofileid) 
	from auto3 
	group by Open; 
run;

data auto4;
	set auto3;
	t2 = today();
	d2 = datepart(lastpaymentdate);
	format d t date10.;
	age2 = intck('month',d,t)-1;

	if age2 <= 6 
		then last_payment = '1. <=6 months    ';

	if age2 > 6 and age <= 11 
		then last_payment = '2. 6-11 months';

	if age2 > 11 and age <= 23 
		then last_payment = '3. 12-23 months';

	if age2 >= 24 
		then last_payment = '4. 24+ months';
run;

proc sql; 
	select last_payment, count(distinct creditprofileid) 
	from auto4 
	group by last_payment; 
run;

DATA risk1; 
	SET auto4; 
	BIGAUTO_FLAG = 'X';
	IF AccountType IN ('00', '3A'); 
	KEEP cifno bigauto_flag;
RUN;

PROC SORT
	DATA = risk1 OUT = risk1 NODUPKEY; 
	BY cifno; 
RUN;

proc sql;
	create table MERGED_L_B2 as
	select A.*, B.* 
	from booked_loan A 
	left join risk1 B 
		on A.cifno_new = B.cifno;
run;










*** Export FLAGGEd FILE ------------------------------------------ ***;
PROC export 
	DATA = MERGED_L_B2 OUTFILE = "&FINALEXPORTFLAGGED" dbms = tab;
RUN;

DATA WaterfALL;
	LENGTH Criteria $30 
		   COUNT 8.;
 	INFILE DATAlINEs dlm = "," tRUNcOVER;
 	INPUT Criteria $ COUNT;
 	DATAlINEs;
PB PULL Total,
Delete cust IN BAD BRANCHes,		
Delete cust WITH MISSING INFO,	
Delete cust OUTSIDE OF FOOTPRINT,	
Delete WHERE STATE/OWNST MISmatch,
Delete IF customer hAS >1 open LOAN,
Delete cust WITH BAD POCODE,
Delete DeceASed,
Delete IF Less THAN Two Payments Made,	
Delete FOR ATB DelINquency,		
Delete FOR CONPROFILE DelINquency,
Delete FOR Bankruptcy (5yr),
Delete FOR STATFLAG (5yr),
Delete FOR TRW STATUS (5yr),
Delete IF DNS or DNH,
EQUITY THRESHHOLD,
Delete AUTO LOANS,
Delete Retail LOANS,
Delete DLQ Renewal,	
;
RUN;

DATA fINal; 
	SET MERGED_L_B2; 
RUN;

PROC SQL; 
	CREATE TABLE COUNT AS 
	SELECT COUNT(*) AS COUNT 
	FROM MERGED_L_B2; 
RUN;

DATA fINal; 
	SET fINal; 
	IF BADBRANCH_FLAG = ""; 
RUN; 

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF MISSINGINFO_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF OOS_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF STATE_MISMATCH_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF OPEN_FLAG2 = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF BADPOCODE_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF DECEASED_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF LESSTHAN2_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF DLQ_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF CONPROFILE_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF BK5_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT; 

DATA fINal; 
	SET fINal; 
	IF STATFL_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT; 

DATA fINal; 
	SET fINal; 
	IF TRW_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF DNS_DNH_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF et_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT; 

DATA fINal; 
	SET fINal; 
	IF AUTODELETE_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

DATA fINal; 
	SET fINal; 
	IF RETAILDELETE_FLAG = ""; 
RUN;

PROC SQL; 
	INsert INto COUNT 
	SELECT COUNT(*) AS COUNT 
	FROM fINal; 
QUIT;

data final; 
	set final; 
	if dlqren_flag = ""; 
run;

proc sql; 
	insert into count 
	select count(*) as Count 
	from final; 
quit;

PROC prINt 
	DATA = COUNT noobs; 
RUN;

PROC prINt 
	DATA = waterfALL; 
RUN;

PROC export 
	DATA = fINal OUTFILE = "&FINALEXPORTDROPPED" dbms = tab;
RUN;

*** SEND to DOD -------------------------------------------------- ***;
DATA MLA;
	SET FINAL;
	KEEP SSNO1 DOB LASTNAME FIRSTNAME MIDDLENAME BRACCTNO;
	LASTNAME = compress(LASTNAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	MIDDLENAME = compress(MIDDLENAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	FIRSTNAME = compress(FIRSTNAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	SSNO1_A = compress(SSNO1,"1234567890 " , "kis");
	SSNO1 = put(input(SSNO1_A,best9.),z9.);
	DOB = compress(DOB,"1234567890 " , "kis");
	if DOB = ' ' then delete;
	if DOB < '19000101' then delete;
	
RUN;

DATA MLA;
	SET MLA;
	IDENTIFIER = "S";
RUN;

PROC DATASETS;
	MODIFY MLA;
	RENAME DOB = "Date of Birth"n 
		   SSNO1 = "Social Security Number (SSN)"n
		   LASTNAME = "Last NAME"n 
		   FIRSTNAME = "First NAME"n 
		   MIDDLENAME = "Middle NAME"n 
		   BRACCTNO = "Customer Record ID"n
		   IDENTIFIER = "Person Identifier CODE"n;
RUN;

DATA FINALMLA;
	LENGTH "Social Security Number (SSN)"n $ 9 
		   "Date of Birth"n $ 8
		   "Last NAME"n $ 26
		   "First NAME"n $20
		   "Middle NAME"n $ 20
		   "Customer Record ID"n $ 28
		   "Person Identifier CODE"n $ 1;
	SET MLA;
RUN;

PROC PRINT 
	DATA = FINALMLA(OBS = 10);
RUN;

PROC CONTENTS
	DATA = FINALMLA;
RUN;

DATA _NULL_;
	SET FINALMLA;
	FILE "&EXPORTMLA";
	PUT @ 1 "Social Security Number (SSN)"n 
		@ 10 "Date of Birth"n 
		@ 18 "Last NAME"n 
		@ 44 "First NAME"n 
		@ 64 "Middle NAME"n 
		@ 84 "Customer Record ID"n
		@ 112 "Person Identifier CODE"n;
RUN;

DATA fINalpb;
	SET fINal;
RUN;

*** Step 2: Import FILE FROM DOD, appEND OFfer INFORMATION. ------ ***;
FILEname mla1 "\\mktg-app01\E\Production\MLA\MLA-OUTPUT FILEs FROM WEBSITE\MLA_5_10_PBITA_20210923.txt";

DATA mla1;
	INFILE mla1;
	INPUT SSNO1 $ 1-9 
		  DOB $ 10-17 
		  LASTNAME $ 18-43 
		  FIRSTNAME $ 44-63
		  MIDDLENAME $ 64-83  
		  BRACCTNO $ 84-111 
		  PI_CODE $ 112-120 
		  MLA_DOD $121-145;
	MLA_STATUS = SUBSTR(MLA_DOD, 1, 1);
RUN;

PROC prINt 
	DATA = mla1 (obs = 10);
RUN;

PROC SORT 
	DATA = fINalpb;
	BY BRACCTNO;
RUN;

PROC SORT 
	DATA = mla1;
	BY BRACCTNO;
RUN;

DATA fINalhh;
	MERGE fINalpb(IN = x) mla1;
	BY BRACCTNO;
	IF x;
RUN;

*** COUNT FOR WaterfALL ------------------------------------------ ***;
PROC freq 
	DATA = fINalhh;
	TABLE mla_STATUS;
RUN;

DATA ficos;
	SET fINalhh;
	RENAME CRSCORE = fico;;
RUN;

DATA fINalhh2;
	LENGTH fico_ranGE_25pt $10 
		   campaign_ID $25 
		   Made_Unmade $15 
		   CIFNO $20 
		   custID $20 
		   mgc $20 
		   STATE1 $5 
		   test_code $20;
	SET ficos;
	IF mla_STATUS NE "Y";
	IF fico = 0 THEN fico_ranGE_25pt = "0";
	IF 0 < fico < 500 THEN fico_ranGE_25pt = "<500";
	IF 500 <= fico <= 524 THEN fico_ranGE_25pt = "500-524";
	IF 525 <= fico <= 549 THEN fico_ranGE_25pt = "525-549";
	IF 550 <= fico <= 574 THEN fico_ranGE_25pt = "550-574";
	IF 575 <= fico <= 599 THEN fico_ranGE_25pt = "575-599";
	IF 600 <= fico <= 624 THEN fico_ranGE_25pt = "600-624";
	IF 625 <= fico <= 649 THEN fico_ranGE_25pt = "625-649";
	IF 650 <= fico <= 674 THEN fico_ranGE_25pt = "650-674";
	IF 675 <= fico <= 699 THEN fico_ranGE_25pt = "675-699";
	IF 700 <= fico <= 724 THEN fico_ranGE_25pt = "700-724";
	IF 725 <= fico <= 749 THEN fico_ranGE_25pt = "725-749";
	IF 750 <= fico <= 774 THEN fico_ranGE_25pt = "750-774";
	IF 775 <= fico <= 799 THEN fico_ranGE_25pt = "775-799";
	IF 800 <= fico <= 824 THEN fico_ranGE_25pt = "800-824";
	IF 825 <= fico <= 849 THEN fico_ranGE_25pt = "825-849";
	IF 850 <= fico <= 874 THEN fico_ranGE_25pt = "850-874";
	IF 875 <= fico <= 899 THEN fico_ranGE_25pt = "875-899";
	IF 975 <= fico <= 999 THEN fico_ranGE_25pt = "975-999";
	IF fico = "" THEN fico_ranGE_25pt = "";
	CAMPAIGN_ID = "&PB_ID";
	custID = STRIP(_n_);
	Made_Unmade = madeunmade_FLAG;
	OFfer_segment = "ITA";
	IF STATE1 = "" THEN STATE1 = STATE;
	IF STATE1 = "TX" THEN STATE1 = "";
	amt_given1 = XNO_AVAILCREDIT;
	IF STATE = "AL" & amt_given1 > 6000 THEN amt_given1 = 6000;
	IF STATE NE "AL" & amt_given1 > 7000 THEN amt_given1 = 7000;
	IF STATE = "GA" & amt_given1 > 1499 & amt_given1 <3002 
		THEN amt_given1 = 3100;
RUN;

DATA fINalhh2;
	SET fINalhh2;
	RENAME OWNBR = BRANCH 
		   FIRSTNAME = cFNAME1 
		   MIDDLENAME = cmname1 
		   LASTNAME = cLNAME1 
		   ADR1 = caddr1 
		   ADR2 = caddr2
		   CITY = cCITY 
		   STATE = cst 
		   ZIP = cZIP 
		   SSNO1_RT7 = ssn 
		   CD60 = n_60_dpd 
		   CONPROFILE1 = CONPROFILE;
RUN;

DATA pbita_hh;
	SET fINalhh2;
RUN;

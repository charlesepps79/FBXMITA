OPTIONS MPRINT MLOGIC SYMBOLGEN; /* SET DEBUGGING OPTIONS */

%LET PULLDATE = %SYSFUNC(today(), yymmdd10.);
%PUT "&PULLDATE";

%LET _7yrdate_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-2555);
%LET _7yrdate = %SYSFUNC(putn(&_7yrdate_NUM,yymmdd10.));
%PUT "&_7yrdate";

%LET _6yrdate_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-2190);
%LET _6yrdate = %SYSFUNC(putn(&_6yrdate_NUM,yymmdd10.));
%PUT "&_6yrdate";

%LET _1yrdate_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-365);
%LET _1yrdate = %SYSFUNC(putn(&_1yrdate_NUM,yymmdd10.));
%PUT "&_1yrdate";

%LET yesterday_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-1);
%LET yesterday = %SYSFUNC(putn(&yesterday_NUM,yymmdd10.));
%PUT "&yesterday";

%LET _15month_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-456);
%LET _15month = %SYSFUNC(putn(&_15month_NUM,yymmdd10.));
%PUT "&_15month";

%LET cadence_8 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-243);
%LET cadence_9 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-274);
%LET cadence_10 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-304);
%LET cadence_11 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-335);
%LET cadence_12 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-365);
%LET cadence_13 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-395);
%LET cadence_14 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-426);
%LET cadence_15 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-456);
%LET cadence_16 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-487);
%LET cadence_17 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-517);
%LET cadence_18 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-548);
%LET cadence_19 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-578);
%LET cadence_20 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-608);
%LET cadence_21 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-639);
%LET cadence_22 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-669);
%LET cadence_23 = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-700);
%PUT "&cadence_8";

%PUT "&cadence_8" "&cadence_9" "&cadence_10" "&cadence_11" "&cadence_12"
	 "&cadence_13" "&cadence_14" "&cadence_15" "&cadence_16" 
	 "&cadence_17" "&cadence_18" "&cadence_19" "&cadence_20"
	 "&cadence_21" "&cadence_22" "&cadence_23";

*** Import new cross sell files. Instructions here:                ***;
*** R:\Production\MLA\Files for MLA Processing\XSELL\              ***;
*** XSELL TCI DECSION LENDER.txt. Change dates in the lines        ***;
*** immediately below along with file paths. For the files paths,  ***;
*** you will likely need to create a new folder "ITA" in the       ***;
*** appropriate month file. Do not change the argument to the left ***;
*** of the comma - only change what is to the right of the comma.  ***;

*** Step 1: Pull all data and send to DOD ------------------------ ***;
data _null_;
	call symput ('today', 20200205);
	call symput ('retail_id', 'RetailXSITA3.0_2020');
	call symput ('auto_id', 'AutoXSITA3.0_2020');
	call symput ('fb_id', 'FBITA3.0_2020');

	call symput ('finalexportflagged', 
		'\\mktg-APP01\E\Production\2020\03_March_2020\ITA\FBXS_ITA_20200205flagged.txt');
	call symput ('finalexportdropped', 
		'\\mktg-APP01\E\Production\2020\03_March_2020\ITA\FBXS_ITA_20200205final.txt');
	call symput ('exportMLA1', 
		'\\mktg-APP01\E\Production\MLA\MLA-Input files TO WEBSITE\FB_MITA_20200205p1.txt');
	call symput ('exportMLA2', 
		'\\mktg-APP01\E\Production\MLA\MLA-Input files TO WEBSITE\FB_MITA_20200205p2.txt');
	call symput ('finalexportED', 
		'\\mktg-APP01\E\Production\2020\03_March_2020\ITA\FBXSPB_ITA_20200205final_HH.csv');
	call symput ('finalexportHH', 
		'\\mktg-APP01\E\Production\2020\03_March_2020\ITA\FBXSPB_ITA_20200205final_HH.txt');
	call symput ('finalexportED2', 
		'\\mktg-APP01\E\Production\2020\03_March_2020\ITA\FBXS_ITA_20200205final_HH.csv');
	call symput ('finalexportHH2', 
		'\\mktg-APP01\E\Production\2020\03_March_2020\ITA\FBXS_ITA_20200205final_HH.txt');
run;

%put "&_1yrdate" "&yesterday" "&today";

*** New TCI data - Retail and Auto ------------------------------- ***;

proc import 
	datafile = 
		"\\mktg-APP01\E\Production\2020\03_March_2020\ITA\XS_Mail_Pull.xlsx" 
	dbms = xlsx out = newxs replace;
	range = "XS Mail Pull$A3:0";
	getnames = yes;
run;

data newxs2;
	set newxs;
	if 'loan type'n = "Auto Indirect" then source = "TCICentral";
	if 'loan type'n = "Retail" then source = "TCIRetail";
	if source ne "";

	if find('applicant address'n, "Apt") = 0 then do;
		adr1 = scan('applicant address'n, 1, ",");
		city = scan('applicant address'n, 2, ",");
		state = scan('applicant address'n, 3, ",");
		zip = scan('applicant address'n, 4, ",");
	end;

	if find('applicant address'n, "Apt") ge 1 then do;
		adr1 = scan('applicant address'n, 1, ",");
		adr2 = scan('applicant address'n, 2, ",");
		city = scan('applicant address'n, 3, ",");
		state = scan('applicant address'n,	4,	",");
		zip = scan('applicant address'n, 5, ",");
	end;

	DOB_1 = input('applicant DOB'n, anydtdte32.);
	FORMAT DOB_1 yymmdd10.;
	DOB = PUT(DOB_1, yymmdd10.);
	'application date1'n = put('application date'n, mmddyy10.);
	bracctno = cats("TCI", 'Application Number'n);
	ssno1_rt7 = substrn('applicant ssn'n, max(1, 
		length('applicant ssn'n) - 6), 7);
	drop 'Application Date'n 
		 'Applicant Address'n  
		 'Applicant Address Zip'n 
		 'Applicant DOB'n 
		 'app. work phone'n;
	rename 'application date1'n = 'application date'n 
		   'applicant email'n = email 
		   'Applicant Credit Score'n = crscore 
		   'Applicant First Name'n = Firstname 
		   'Applicant Last Name'n = Lastname 
		   'Applicant SSN'n = ssno1 
		   'Applicant Middle Name'n = Middlename 
		   'app. cell phone'n = cellphone 
		   'app. home phone'n = phone;
run;

data TCI;
	length adr1 $40 
		   city $25 
		   state $4 
		   zip $10 
		   middlename $25 
		   source $11 
		   bracctno $15;
	set newxs2;
	ssno1 = strip(ssno1);
	dob = compress(dob, "-");
	format _character_;
run;

*** pull in XS from loan table, borrower table and merge --------- ***;
data XS_L;
	set dw.vw_loan_NLS(
		keep = ownst purcd xno_availcredit xno_tduepoff cifno bracctno
			   id ssno1 ownbr ssno1_rt7 ssno2 LnAmt FinChg LoanType 
			   EntDate LoanDate ClassID ClassTranslation
			   XNO_TrueDueDate FirstPyDate SrCD pocd POffDate plcd
			   PlDate PlAmt BnkrptDate BnkrptChapter ConProfile1
			   DatePaidLast APRate CrScore CurBal NetLoanAmount);
	where cifno ne "" & 
		  entdate >= "&_1yrdate" & 
		  pocd = "" & 
		  plcd = "" & 
		  pldate = "" & 
		  poffdate = ""  & 
		  bnkrptdate = "" & 
		  classid in (10, 19, 20, 31, 34) & 
		  ownst in ("SC", "NM", "NC", "OK", "VA", "TX", "AL", "GA", 
					"TN", "MO", "WI");
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	if cifno not =: "B";
run;

proc sql;
	create table XS_Ldeduped as
	select *
	from XS_L
	group by cifno
	having entdate = max(entdate);
quit;

data BorrNLS;
	length firstname $20 
		   middlename $20 
		   lastname $30;
	set dw.vw_borrower(
		keep = rmc_updated phone cellphone cifno ssno ssno_rt7 FName
			   LName Adr1 Adr2 City State zip BrNo age Confidential
			   Solicit CeaseandDesist CreditScore);
	where cifno not =: "B";
	FName = strip(fname);
	LName = strip(lname);
	Adr1 = strip(Adr1);
	Adr2 = strip(adr2);
	City = strip(city);
	State = strip(state);
	Zip = strip(zip);

	if find(fname, "JR") ge 1 then do;
		firstname = compress(fname, "JR");
		suffix = "JR";
	end;

	if find(fname, "SR") ge 1 then do;
		firstname = compress(fname, "SR");
		suffix = "SR";
	end;

	if suffix = "" then do;
		firstname = scan(fname, 1, 1);
		middlename = catx(" ", scan(fname, 2, " "), 
							   scan(fname, 3, " "), 
							   scan(fname, 4, " "));
	end;

	nwords = countw(fname, " ");

	if nwords > 2 & suffix ne "" then do;
		firstname = scan(fname, 1, " ");
		middlename = scan(fname, 2, " ");
	end;

	DOB = compress(age, "-");
	lastname = lname;
	drop fname lname nwords age;
	if cifno ne "";
run;

proc sort 
	data = XS_Ldeduped nodupkey; 
	by cifno; 
run;

proc sort 
	data = borrnls; 
	by cifno descending rmc_updated; 
run;

proc sort 
	data = borrnls out = borrnls2 nodupkey; 
	by cifno; 
run;

data loannlsxs;
	merge xs_ldeduped(in = x) borrnls2(in = y);
	by cifno;
	if x and y;
run;

*** modify as needed when more states convert to NLS ------------- ***;
data loanextraXS;
	set dw.vw_loan(
		keep = purcd xno_availcredit xno_tduepoff bracctno id ssno1
			   ownbr ownst ssno1_rt7 ssno2 LnAmt FinChg LoanType 
			   EntDate LoanDate ClassID ClassTranslation 
			   XNO_TrueDueDate FirstPyDate SrCD pocd POffDate plcd 
			   PlDate PlAmt BnkrptDate BnkrptChapter ConProfile1 
			   DatePaidLast APRate CrScore CurBal NetLoanAmount);
	where entdate >= "&_1yrdate" & 
		  pocd = "" & 
		  plcd = "" & 
		  pldate = "" & 
		  poffdate = ""  & 
		  bnkrptdate = "" & 
		  classid in (10, 19, 20, 31, 34) & 
		  ownst in ("SC", "NM", "NC", "OK", "VA", "TX", "AL", "GA", 
					"TN", "MO", "WI") ; 
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	if ssno1 =: "99" then BadSSN = "X"; /* Flag bad ssns */
	if ssno1 =: "98" then BadSSN = "X";
run;

*** identify loans in NLS states that are not in vw_loan_nls ----- ***;
data loan1_2xs;
	set xs_l;
	keep BrAcctNo;
run;

proc sort 
	data = loan1_2xs; 
	by bracctno; 
run;

proc sort 
	data = loanextraxs; 
	by BrAcctNo; 
run;

data loanextra2xs;
	merge loanextraxs(in = x) loan1_2xs(in = y);
	by bracctno;
	if x and not y;
run;

*** modify as states convert. When all states are converted, this  ***;
*** section can be removed --------------------------------------- ***;
data loanparadataXS;
	set dw.vw_loan(
		keep = purcd bracctno xno_availcredit xno_tduepoff id ownbr
			   ownst SSNo1 ssno2 ssno1_rt7 LnAmt FinChg LoanType 
			   EntDate LoanDate ClassID ClassTranslation 
			   XNO_TrueDueDate FirstPyDate SrCD pocd POffDate plcd 
			   PlDate PlAmt BnkrptDate BnkrptChapter DatePaidLast 
			   APRate CrScore NetLoanAmount XNO_AvailCredit 
			   XNO_TDuePOff CurBal conprofile1 NetLoanAmount);
	where entdate >= "&_1yrdate" & 
		  plcd = "" & 
		  pocd = "" & 
		  poffdate = "" & 
		  pldate = "" & 
		  bnkrptdate = "" & 
		  ownst not in ("SC", "NM", "NC", "OK", "VA", "TX", "AL", "GA", 
						"TN", "MO", "WI") & 
		  classid in (10, 19, 20, 31, 34);
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	if ssno1 =: "99" then BadSSN = "X"; /* Flag bad ssns */
	if ssno1 =: "98" then BadSSN = "X"; 
run;

data set1xs;
	set loanparadataxs loanextra2xs;
run;

data BorrParadata;
	length firstname $20 
		   middlename $20 
		   lastname $30;
	set dw.vw_borrower(
		keep = rmc_updated phone cellphone cifno ssno ssno_rt7  FName
			   LName Adr1 Adr2 City State zip BrNo age Confidential
			   Solicit CeaseandDesist CreditScore);
	FName = strip(fname);
	LName = strip(lname);
	Adr1 = strip(Adr1);
	Adr2 = strip(adr2);
	City = strip(city);
	State = strip(state);
	Zip = strip(zip);

	if find(fname, "JR") ge 1 then do;
		firstname = compress(fname, "JR");
		suffix = "JR";
	end;

	if find(fname, "SR") ge 1 then do;
		firstname = compress(fname, "SR");
		suffix = "SR";
	end;

	if suffix = "" then do;
		firstname = scan(fname, 1, 1);
		middlename = catx(" ", scan(fname, 2, " "), 
							   scan(fname, 3, " "), 
							   scan(fname, 4, " "));
	end;

	nwords = countw(fname, " ");

	if nwords > 2 & suffix ne "" then do;
		firstname = scan(fname, 1, " ");
		middlename = scan(fname, 2, " ");
	end;

	DOB = compress(age, "-");
	ss7brstate = cats(ssno_rt7, substr(brno, 1, 2));
	lastname = lname;
	rename ssno_rt7 = ssno1_rt7 
		   ssno = ssno1;
	if ssno =: "99" then BadSSN = "X";  *Flag bad ssns;
	if ssno =: "98" then BadSSN = "X"; 
	drop nwords fname lname age;
run;

data goodssn_lxs badssn_lxs;
	set set1xs;
	if badssn = "X" then output badssn_lxs;
	else output goodssn_lxs;
run;

data goodssn_b badssn_b;
	set borrparadata;
	if badssn = "X" then output badssn_b;
	else output goodssn_b;
run;

proc sort 
	data = goodssn_lxs; 
	by ssno1; 
run;

proc sql;
	create table goodssn_lxs as
	select *
	from goodssn_lxs
	group by ssno1
	having entdate = max(entdate);
quit;

proc sort 
	data = goodssn_lxs nodupkey; 
	by ssno1; 
run;

proc sort 
	data = goodssn_b; 
	by ssno1 descending rmc_updated; 
run;

proc sort 
	data = goodssn_b nodupkey; 
	by ssno1; 
run;

data mergedgoodssnxs;
	merge goodssn_lxs(in = x) goodssn_b(in = y);
	by ssno1;
	if x and y;
run;

proc sort 
	data = badssn_lxs; 
	by ss7brstate; 
run;

proc sql;
	create table badssn_lxs as
	select *
	from badssn_lxs
	group by ss7brstate
	having entdate = max(entdate);
quit;

proc sort 
	data = badssn_lxs nodupkey; 
	by ss7brstate; 
run;

proc sort 
	data = badssn_b; 
	by ss7brstate descending rmc_updated; 
run;

proc sort 
	data = badssn_b nodupkey; 
	by ss7brstate; 
run;

data mergedbadxs;
	merge badssn_lxs(in = x) badssn_b(in = y);
	by ss7brstate;
	if x and y;
run;

proc sort 
	data = mergedbadxs out = mergedbadssnxs nodupkey; 
	by ss7brstate; 
run;

DATA ssns;
	set mergedgoodssnxs mergedbadssnxs;
run;

proc sort 
	data = ssns nodupkey; 
	by bracctno; 
run;

proc sort 
	data = loannlsXS nodupkey; 
	by bracctno; 
run;

data paradata;
	merge loannlsXS(in = x) ssns(in = y);
	by bracctno;
	if not x and y;
run;

data xs;
	set paradata;
run; 

*** Merge XS from our dw with info from TCI sites to identify      ***;
*** mades and pull in unmades ------------------------------------ ***;
proc sort 
	data = XS; 
	by ssno1; 
run;

proc sort 
	data = tci; 
	by ssno1; 
run;

data tcimades;
	set tci;
	drop bracctno;
run;

data mades;
	merge XS(in = x) tcimades(in = y);
	by ssno1;
	if x = 1;
run;

data unmades;
	merge XS(in = x) tci(in = y);
	by ssno1;
	if x = 0 and y = 1;
	made_unmade = "UNMADE";
run;

*** for matched, keep only info from loan and borrower tables ---- ***;
data mades2; 
	set mades(
		keep = bracctno ssno1 id ownbr ssno1_rt7 ssno2 LnAmt FinChg
			   LoanType EntDate LoanDate ClassID ClassTranslation SrCD
			   pocd POffDate purcd plcd PlDate PlAmt BnkrptDate 
			   BnkrptChapter ConProfile1 DatePaidLast APRate CrScore
			   CurBal Adr1 Adr2 City State zip dob Confidential 
			   Solicit CeaseandDesist CreditScore firstname middlename 
			   lastname ss7brstate
			   phone cellphone NetLoanAmount);
	made_unmade = "MADE";
run;

data XStot; /* Append mades and unmades for full XS universe */
	set unmades mades2;
	drop nwords;
run;

data xstot;
	set xstot;
	if ss7brstate = "" then 
		ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	if crscore < 625 then Risk_Segment = "624 and below";
	if 625 <= crscore < 650 then Risk_Segment = "625-649";
	if 650 <= crscore < 851 then Risk_Segment = "650-850";
	if classid in (10, 21, 31) then source_2 = "RETAIL";
	if source = "TCIRetail" then source_2 = "RETAIL";
	if classid in (13, 14, 19, 20, 32, 34, 40, 41, 45, 68, 69, 72, 75,
				   78, 79, 80, 88, 89, 90) then source_2 = "AUTO";
	if source = "TCICentral" then source_2 = "AUTO";
run;

data xs_total;
	length offer_segment $20;
	set xstot;
	if crscore = 0 then BadFico_Flag = "X";
	if crscore = . then BadFico_Flag = "X";
	if crscore > 850 then BadFico_Flag = "X";
	if state = "NC" & 
	   source_2 = "AUTO" & 
	   made_unmade = "UNMADE" then 
		NCAutoUn_Flag = "X";
	if state = "NC" & 
	   source_2 = "AUTO" & 
	   made_unmade = "MADE" then
		offer_segment = "ITA";
	if state in ("GA") then offer_segment = "ITA";
	if state in ("SC","NC","TX","TN","AL","OK","NM", "MO", "WI", 
				 "VA") & 
	   source_2 = "AUTO" then 
		offer_segment = "ITA";
	if state in ("SC","NC","TX","TN","AL","OK","NM", "MO", "WI", 
				 "VA") & 
	   source_2 = "RETAIL" & 
	   Risk_Segment = "624 and below" then 
		offer_segment = "ITA";
run;

*** Dedupe XS ---------------------------------------------------- ***;
data xs_total;
	set xs_total;
	if offer_segment = "ITA"; /* keep only ITAs */
	camp_type = "XS";
run;

*** Pull in data for FBs ----------------------------------------- ***;
data loan_pull;
	set dw.vw_loan_nls(
		keep = cifno bracctno id ownbr ownst ssno1_rt7 ssno1 ssno2
			   LnAmt FinChg ssno1_rt7 LoanType EntDate LoanDate ClassID
			   ClassTranslation XNO_TrueDueDate FirstPyDate SrCD pocd
			   POffDate purcd plcd PlDate PlAmt BnkrptDate 
			   BnkrptChapter DatePaidLast APRate CrScore CurBal 
			   NetLoanAmount);
	where POffDate between "&_15month" and "&yesterday" & 
		  (pocd = "13" or pocd = "10" or pocd = "50") & 
		  ownst in ("SC", "NM", "NC", "OK", "VA", "TX", "AL", "GA",
					"TN", "MO", "WI");
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	if cifno not =: "B";
run;

proc sql;
	create table loan1nlsfb as
	select *
	from loan_pull
	group by cifno
	having entdate = max(entdate);
quit;

proc sort 
	data = loan1nlsfb nodupkey; 
	by cifno; 
run;

data loannlsfb;
	merge loan1nlsfb(in = x) borrnls2(in = y);
	by cifno;
	if x and y;
run;

data loanextrafb; /* Find NLS loans not in vw_nls_loan */
	set dw.vw_loan(
		keep = bracctno xno_availcredit xno_tduepoff id ownbr ownst
			   SSNo1 ssno2 ssno1_rt7 LnAmt FinChg LoanType EntDate
			   LoanDate ClassID ClassTranslation XNO_TrueDueDate
			   FirstPyDate SrCD pocd POffDate purcd plcd PlDate 
			   PlAmt BnkrptDate BnkrptChapter DatePaidLast APRate 
			   CrScore NetLoanAmount XNO_AvailCredit XNO_TDuePOff 
			   CurBal conprofile1);
	where POffDate between "&_15month" and "&yesterday" & 
		  (pocd = "13" or pocd = "10" or pocd = "50") & 
		  ownst in("SC", "NM", "NC", "OK", "VA", "TX", "AL", "GA", 
				   "TN", "MO", "WI");
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	if ssno1 =: "99" then BadSSN = "X"; /* Flag bad ssns */
	if ssno1 =: "98" then BadSSN = "X";
run;

data loan1_2fb;
	set loan_pull;
	keep BrAcctNo;
run;

proc sort 
	data = loan1_2fb; 
	by bracctno; 
run;

proc sort 
	data = loanextrafb; 
	by BrAcctNo; 
run;

data loanextra2fb;
	merge loanextrafb(in = x) loan1_2fb(in = y);
	by bracctno;
	if x and not y;
run;

data loanparadatafb;
	set dw.vw_loan(
		keep = bracctno xno_availcredit xno_tduepoff id ownbr ownst
			   SSNo1 ssno2 ssno1_rt7 LnAmt FinChg LoanType EntDate
			   LoanDate ClassID ClassTranslation XNO_TrueDueDate
			   FirstPyDate SrCD purcd pocd POffDate plcd PlDate PlAmt
			   BnkrptDate BnkrptChapter DatePaidLast APRate CrScore
			   NetLoanAmount XNO_AvailCredit XNO_TDuePOff CurBal
			   conprofile1);
	where POffDate between "&_15month" and "&yesterday" & 
		  (pocd = "13" or pocd = "10" or pocd = "50") & 
		  ownst not in ("SC", "NM", "NC", "OK", "VA", "TX", "AL", "GA",
						"TN", "MO", "WI");
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	if ssno1 =: "99" then BadSSN = "X"; /* Flag bad ssns */
	if ssno1 =: "98" then BadSSN = "X"; 
run;

data set1fb;
	set loanparadatafb loanextra2fb;
run;

data goodssn_lfb badssn_lfb;
	set set1fb;
	if badssn = "X" then output badssn_lfb;
	else output goodssn_lfb;
run;

proc sort 
	data = goodssn_lfb; 
	by ssno1; 
run;

proc sql;
	create table goodssn_lfb as
	select *
	from goodssn_lfb
	group by ssno1
	having entdate = max(entdate);
quit;

proc sort 
	data = goodssn_lfb nodupkey; 
	by ssno1; 
run;

proc sort 
	data = goodssn_b; 
	by ssno1; 
run;

data mergedgoodssnfb;
	merge goodssn_lfb(in = x) goodssn_b(in = y);
	by ssno1;
	if x and y;
run;

proc sql;
	create table badssn_lfb as
	select *
	from badssn_lfb
	group by ss7brstate
	having entdate = max(entdate);
quit;

proc sort 
	data = badssn_lfb nodupkey; 
	by ss7brstate; 
run;

proc sort 
	data = badssn_b; 
	by ss7brstate; 
run;

data mergedbadssnfb;
	merge badssn_lfb(in = x) badssn_b(in = y);
	by ss7brstate;
	if x and y;
run;

proc sort 
	data = mergedbadssnfb nodupkey; 
	by ss7brstate; 
run;

DATA ssnsfb;
	set mergedgoodssnfb mergedbadssnfb;
run;

proc sort 
	data = ssnsfb nodupkey; 
	by bracctno; 
run;

proc sort 
	data = loannlsfb nodupkey; 
	by bracctno; 
run;

data paradata;
	merge loannlsfb(in = x) ssnsfb(in = y);
	by bracctno;
	if not x and y;
run;

data fb;
	set loannlsfb paradata;
	camp_type = "FB";
run; 

*** Append XS to FB ---------------------------------------------- ***;
data merged_l_b_xs_fb;
	set fb xs_total;
run;

proc sort 
	data = merged_l_b_xs_fb out = merged_l_b_xs_fb2 nodupkey; 
	by bracctno; 
run;

data y;
	set dw.exclude_loan(
		keep = BrAcctNo conprofile1);
	rename ConProfile1 = OldCon;
run;

proc sort 
	data = merged_l_b_xs_fb2;
	by bracctno;
run;

proc sort 
	data = y;
	by bracctno;
run;

data merged_l_b_xs_fb2;
	merge merged_l_b_xs_fb2(in = x) y;
	by bracctno;
	if x;
run;

data merged_l_b_xs_fb2;
	set merged_l_b_xs_fb2;
	if coldcon ne "" then conprofile1 = oldcon;
run;

*** Pull in information for statflags ---------------------------- ***;
data Statflags;
	set dw.vw_loan(
		keep = ownbr ssno1_rt7 entdate StatFlags);
	where entdate > "&_7yrdate" & 
		  statflags ne "";
run;

PROC SQL; /* IDENTIFYING BAD STATFLAGS */
 	CREATE TABLE STATFLAGS2 AS
	SELECT * 
	FROM STATFLAGS 
	WHERE STATFLAGS CONTAINS "A" OR STATFLAGS CONTAINS "B" OR
		  STATFLAGS CONTAINS "C" OR STATFLAGS CONTAINS "D" OR
		  STATFLAGS CONTAINS "I" OR STATFLAGS CONTAINS "J" OR
		  STATFLAGS CONTAINS "L" OR STATFLAGS CONTAINS "P" OR
		  STATFLAGS CONTAINS "R" OR STATFLAGS CONTAINS "V" OR
		  STATFLAGS CONTAINS "W" OR STATFLAGS CONTAINS "X" OR
		  STATFLAGS CONTAINS "S";
RUN;

data statflags2; /* tagging bad statflags */
	set statflags2;
	statfl_flag = "X";
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	drop entdate ownbr ssno1_rt7;
	rename statflags = statflags_old;
run;

proc sort 
	data = statflags2 nodupkey; 
	by ss7brstate; 
run;

proc sort 
	data = merged_l_b_xs_fb2; 
	by ss7brstate; 
run;

data Merged_L_B2; /* Merge file with statflag flags */
	merge merged_l_b_xs_fb2(in = x) statflags2;
	by ss7brstate;
	if x = 1;
run;

data merged_l_b2;
	set merged_l_b2;
	if bnkrptdate ne "" then bk5_flag = "X";
	if bnkrptchapter not in (0, .) then bk5_flag = "X";
run;

*** Flag bad TRW status ------------------------------------------- ***;
data trwstatus_fl;
	set dw.vw_loan(
		keep = ownbr ssno1_rt7 EntDate trwstatus);
	where entdate > "&_7yrdate" & 
		  TrwStatus ne "";
run;

data trwstatus_fl; /*flag for bad trw's */
	set trwstatus_fl;
	TRW_flag = "X";
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	drop entdate ssno1_rt7 ownbr;
run;

proc sort 
	data = trwstatus_fl nodupkey; 
	by ss7brstate; 
run;

proc sort 
	data = merged_l_b2; 
	by ss7brstate; 
run;

data Merged_L_B2; /* merge pull with trw flags */
	merge Merged_L_B2(in = x) trwstatus_fl;
	by ss7brstate;
	if x;
run;

*** Identify bad PO Codes ---------------------------------------- ***;
data PO_codes_5yr;
	set dw.vw_loan(
		keep = EntDate pocd ssno1_rt7 ownbr);
	where EntDate > "&_7yrdate" & 
		  pocd in ("49", "50", "61", "62", "63", "64", "66", "68",
				   "93", "97", "PB", "PO");
run;

data po_codes_5yr;
	set po_codes_5yr;
	BadPOcode_flag = "X";
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	drop entdate pocd ssno1_rt7 ownbr;
run;

proc sort 
	data = po_codes_5yr nodupkey; 
	by ss7brstate; 
run;

proc sort 
	data = merged_l_b2; 
	by ss7brstate; 
run;

data merged_l_b2;
	merge merged_l_b2(in = x) po_codes_5yr;
	by ss7brstate;
	if x;
run;

data PO_codes_forever;
	set dw.vw_loan(
		keep = EntDate pocd ssno1_rt7 ownbr);
	where pocd in ("21", "94", "95", "96");
run;

data po_codes_forever;
	set po_codes_forever;
	Deceased_flag = "X";
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	drop entdate pocd ssno1_rt7 ownbr;
run;

proc sort 
	data = po_codes_forever nodupkey; 
	by ss7brstate; 
run;

data merged_l_b2;
	merge merged_l_b2(in = x) po_codes_forever;
	by ss7brstate;
	if x;
run;

data con5yr_fl;
	set dw.vw_loan(
		keep = ownbr ssno1_rt7 EntDate conprofile1);
	where entdate > "&_7yrdate" & 
		  conprofile1 ne "";
run;

data con5yr_fl; /* flag for con5 */
	set con5yr_fl;
	_60 = countc(conprofile1, "2");
	if _60 > 3 then con5yr_flag = "X";
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	drop entdate ssno1_rt7 ownbr conprofile1 _60;
run;

data con5yr_fl_2;
	set con5yr_fl;
	if con5yr_flag = "X";
run;

proc sort 
	data = con5yr_fl_2 nodupkey; 
	by ss7brstate; 
run;

proc sort 
	data = merged_l_b2; 
	by ss7brstate; 
run;

data Merged_L_B2; /* merge pull with con5 flags */
	merge Merged_L_B2(in = x) con5yr_fl_2;
	by ss7brstate;
	if x;
run;

*** Identify if customer currently has an open loan for FB ------- ***;
data openloans;
	set dw.vw_loan(
		keep = ownbr ssno2 ssno1_rt7 pocd plcd poffdate pldate
			   bnkrptdate);
	where pocd = "" & 
		  plcd = "" & 
		  poffdate = "" & 
		  pldate = "" & 
		  bnkrptdate = "";
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
run;

data ssno2s;
	set openloans;
	ss7brstate = cats((substr(ssno2, max(1, length(ssno2) - 6))), 
					   substr(ownbr, 1, 2));
	if ssno2 ne "" then output ssno2s;
run;

data openloans1;
	set openloans ssno2s;
run;

data openloans1;
	set openloans1;
	Open_flag = "X";
	drop pocd ssno1_rt7 OwnBr plcd poffdate pldate bnkrptdate ssno2;
run;

proc sort 
	data = openloans1 nodupkey; 
	by ss7brstate; 
run;

proc sort 
	data = merged_l_b2; 
	by ss7brstate; 
run;

data merged_l_b2;
	merge merged_l_b2(in = x) openloans1;
	by ss7brstate;
	if x;
run;

data merged_l_b2;
	set merged_l_b2;
	if camp_type = "XS" then open_flag = "";
run;

*** Identify if customer currently has an open loan for XS ------- ***;
data openloansxs;
	set dw.vw_loan(
		keep = ssno2 ssno1 pocd plcd poffdate pldate bnkrptdate);
	where pocd = "" & 
		  plcd = "" & 
		  poffdate = "" & 
		  pldate = "" & 
		  bnkrptdate = "";
run;

data ssno2s2;
	set openloansxs;
	if ssno2 ne "" then output ssno2s2;
run;

data ssno2s2;
	set ssno2s2;
	ssno1 = ssno2;
run;

data openloans1xs;
	set openloansxs ssno2s2;
run;

data openloans1xs;
	set openloans1xs;
	Open_flag = "X";
	drop pocd plcd poffdate pldate bnkrptdate ssno2;
run;

proc sort 
	data = openloans1xs nodupkey; 
	by ssno1; 
run;

data unmadesdrop merged_l_b3;
	set merged_l_b2;
	if made_unmade = "UNMADE" then output unmadesdrop;
	else output merged_l_b3;
run;

proc sort 
	data = unmadesdrop; 
	by ssno1; 
run;

data unmadesdrop;
	merge unmadesdrop(in = x) openloans1xs;
	by ssno1;
	if x;
run;

data merged_l_b2;
	set merged_l_b3 unmadesdrop;
run;

data openloans2;
	set dw.vw_loan(
		keep = ownbr ssno2 ssno1_rt7 pocd plcd poffdate pldate
			   bnkrptdate);
	where pocd = "" & 
		  plcd = "" & 
		  poffdate = "" & 
		  pldate = "" & 
		  bnkrptdate = "";
	ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
run;

data ssno2s;
	set openloans2;
	ss7brstate = cats((substr(ssno2, max(1, length(ssno2) - 6))), 
					   substr(ownbr, 1, 2));
	if ssno2 ne "" then output ssno2s;
run;

data openloans3;
	set openloans2 ssno2s;
run;

data openloans4;
	set openloans3;
	Open_flag2 = "X";
	if ss7brstate = "" then 
		ss7brstate = cats(ssno1_rt7, substr(ownbr, 1, 2));
	drop pocd ssno2 ssno1_rt7 OwnBr plcd poffdate pldate bnkrptdate;
run;

proc sort 
	data = openloans4; 
	by ss7brstate; 
run;

data one_open mult_open;
	set openloans4;
	by ss7brstate;
	if first.ss7brstate and last.ss7brstate then output one_open;
	else output mult_open;
run;

proc sort 
	data = mult_open nodupkey; 
	by ss7brstate; 
run;

proc sort 
	data = merged_l_b2; 
	by ss7brstate; 
run;

data merged_l_b2;
	merge merged_l_b2(in = x) mult_open;
	by ss7brstate;
	if x;
run;

*** flag incomplete info                                           ***;
*** flag null DOB                                                  ***;
*** Find states outside of footprint                               ***;
*** Flag DNS DNH                                                   ***;
*** Flag nonmatching branch state and borrower state               ***;
*** Flag bad ssns ------------------------------------------------ ***;

data Merged_L_B2; 
	set Merged_L_B2;
	Adr1 = strip(Adr1);
	Adr2 = strip(adr2);
	City = strip(city);
	State = strip(state);
	Zip = strip(zip);
	confidential = strip(confidential);
	solicit = strip(solicit);
	firstname = compress(firstname, '1234567890!@#$^&*()''"%');
	lastname = compress(lastname, '1234567890!@#$^&*()''"%');
	*** flag incomplete info ------------------------------------- ***;
	if adr1 = "" then MissingInfo_flag = "X"; 
	*** flag incomplete info ------------------------------------- ***;
	if state = "" then MissingInfo_flag = "X"; 
	*** flag incomplete info ------------------------------------- ***;
	if Firstname = "" then MissingInfo_flag = "X"; 
	*** flag incomplete info ------------------------------------- ***;
	if Lastname = "" then MissingInfo_flag = "X"; 
	*** Find states outside of footprint ------------------------- ***;
	if state not in ("SC", "NM", "NC", "OK", "VA", "TX", "AL", "GA",
					 "TN", "MO", "WI") then OOS_flag = "X"; 
	*** Flag Confidential ---------------------------------------- ***;
	if confidential = "Y" then DNS_DNH_flag = "X"; 
	if solicit = "N" then DNS_DNH_flag = "X"; /* Flag DNS */
	if ceaseanddesist = "Y" then DNS_DNH_flag = "X"; /* Flag CandD */
	if ssno1 = "" then ssno1 = ssno;
	if ownbr in ("600" , "9000" , "198" , "1", "0001" , "0198" ,
				 "0600") then BadBranch_flag = "X";
	if substr(ownbr, 3, 2) = "99" then BadBranch_flag = "X";
	_60 = countc(conprofile1, "2");
	_90 = countc(conprofile1, "3");
	_120a = countc(conprofile1, "4");
	_120b = countc(conprofile1, "5");
	_120c = countc(conprofile1, "6");
	_120d = countc(conprofile1, "7");
	_120e = countc(conprofile1, "8");
	_90plus = sum(_90, _120a, _120b, _120c, _120d, _120e);
	if _60 > 2 | _90plus > 2 then conprofile_flag = "X";
	_9s = countc(conprofile1, "9");
	if _9s > 10 then lessthan2_flag = "X";
	XNO_TrueDueDate2 = input(substr(XNO_TrueDueDate, 6, 2) || '/' || 
							 substr(XNO_TrueDueDate, 9, 2) || '/' || 
							 substr(XNO_TrueDueDate, 1, 4), mmddyy10.);
	FirstPyDate2 = input(substr(FirstPyDate, 6, 2) || '/' || 
						 substr(FirstPyDate, 9, 2) || '/' || 
						 substr(FirstPyDate, 1, 4), mmddyy10.);
	Pmt_days = XNO_TrueDueDate2 - FirstPyDate2;
	if pmt_days < 60 then lessthan2_flag = "X";
	if pmt_days = . & _9s < 10 then lessthan2_flag = "";
	*** pmt_days calculation wins over conprofile ---------------- ***;
	if pmt_days > 59 & _9s > 10 then lessthan2_flag = ""; 
	equityt = (XNO_AvailCredit / xno_tduepoff) * 100;
	if equityt < 10 then et_flag = "X";
	if xno_availcredit < 100 then et_flag = "X";
	if purcd in ("011", "020", "015") then dlqren_flag = "X";
	if ownbr = "0251" then ownbr = "0580";
	if ownbr = "0252" then ownbr = "0683";
	if ownbr = "0253" then ownbr = "0581";
	if ownbr = "0254" then ownbr = "0582";
	if ownbr = "0255" then ownbr = "0583";
	if ownbr = "0256" then ownbr = "1103";
	if zip =: "36264" & ownbr = "0877" then ownbr = "0870";
	if ownbr = "0877" then ownbr = "0806";
	if ownbr = "0159" then ownbr = "0132";
	if zip =: "29659" & ownbr = "0152" then ownbr = "0121";
	if ownbr = "0152" then ownbr = "0115";
	if ownbr = "0885" then ownbr = "0802";
	if ownbr = "0302" then ownbr = "0133";
	if ownbr = "0102" then ownbr = "0303";
	if ownbr = "0150" then ownbr = "0105";
	if ownbr = "0890" then ownbr = "0875";
	if ownbr = "1016" then ownbr = "1008";
	if ownbr = "1003" and zip =: "87112" then ownbr = "1013";
	if ownbr = "1018" then ownbr = "1008";
run;

data merged_l_b2;
	set merged_l_b2;
	if camp_type = "FB" then do;
		*** Flag nonmatching branch state and borrower state ----- ***;
		if ownst ne state then State_Mismatch_flag = "X"; 
		lessthan2_flag = "";
		et_flag = "";
	end;
	if camp_type = "XS" & made_unmade = "UNMADE" then et_flag = "";
run;

*** pull and merge dlq info for fbs ------------------------------ ***;
proc format;
	value cdfmt 1 = 'Current'
				2 = '1-29cd'
				3 = '30-59cd'
				4 = '60-89cd'
				5 = '90-119cd'
				6 = '120-149cd'
				7 = '150-179cd'
				8 = '180+cd'
				other = ' ';
run;

data temp;   
	set dw.vw_loan(
		keep = bracctno entdate poffdate pocd classtranslation lnamt
			   conprofile1 brtrffg ssno1_rt7 
			where = (pocd in ("10","13","50") and 
					 poffdate > "&_6yrdate"));
	entdt = input(substr(entdate, 6, 2) || '/' || 
				  substr(entdate, 9, 2) || '/' || 
				  substr(entdate, 1, 4), mmddyy10.);
	podt = input(substr(poffdate, 6, 2) || '/' || 
				 substr(poffdate, 9, 2) || '/' || 
				 substr(poffdate, 1, 4), mmddyy10.);
	if poffdate > "&yesterday" then delete;
	if put(entdt, yymmn6.) = put(podt, yymmn6.) then delete;    
	drop poffdate entdate pocd;
run;

proc sort nodupkey; 
	by bracctno; 
run;

data atb;
	SET dw.vw_AgedTrialBalance(
		KEEP = LoanNumber AGE2 BOM); 
	BRACCTNO = LoanNumber;
	YEARMONTH = BOM; 
	poacctno = bracctno * 1;   
	atbdt = input(substr(yearmonth, 6, 2) || '/' || 
				  substr(yearmonth, 9, 2) || '/' || 
				  substr(yearmonth, 1, 4), mmddyy10.);   
	if age2 =: '1' then age2 = '1.Current';   
	keep atbdt age2 bracctno;
run;

proc sort nodupkey; 
	by bracctno atbdt; 
run;

data temp;     
	merge temp(in = a) atb(in = b);
	by bracctno;
	if a;  
	cd = substr(age2, 1, 1) * 1;   
	age = intck('month', atbdt, podt); 
	if age = 1 then delq1 = cd;
	else if age = 2 then delq2 = cd;
	else if age = 3 then delq3 = cd;
	else if age = 4 then delq4 = cd;
	else if age = 5 then delq5 = cd;
	else if age = 6 then delq6 = cd;
	else if age = 7 then delq7 = cd;
	else if age = 8 then delq8 = cd;
	else if age = 9 then delq9 = cd;
	else if age = 10 then delq10 = cd;
	else if age = 11 then delq11 = cd;
	else if age = 12 then delq12 = cd;
	else delete;
	*** if cd is greater than 60-89 days late, set cd90 to 1 ----  ***;
	if cd > 4 then cd90 = 1; 
	*** if cd is greater than 30-59 days late, set cd60 to 1 ----- ***;
	if cd > 3 then cd60 = 1; 
	*** if cd is greater than 1-29 days late, set cd30 to 1 ------ ***;
	if cd > 2 then cd30 = 1; 

	if age < 7 then do;
		*** note 30-59s in last six months of last open loan ----- ***;
		if cd = 3 then recent6 = 1; 
	end;

	else if 6 < age < 13 then do;
		*** note 30-59s from 7 to 12 months of last open loan ---- ***;
		if cd = 3 then first6 = 1; 
	end;
	format podt entdt atbdt mmddyy10.;
run;

data temp2;
	set temp;
	*** count the number of 30-59s in the last year when fb had    ***;
	*** open loan ------------------------------------------------ ***;
	last12 = sum(recent6, first6); 
run;

proc summary 
	data = temp2 nway missing;
	class classtranslation ssno1_rt7 bracctno entdt podt lnamt
		  conprofile1;
	var delq1-delq12 recent6 last12 first6 cd90 cd60 cd30;
	output out = final(drop = _type_ _freq_) sum = ;
run; 

data fbdlq;
	set final;
	if cd60 > 0 then ever60 = 'Y'; 
	else ever60 = 'N';
	times30 = cd30;
	if times30 = . then times30 = 0;
	drop cd30;
	format delq1-delq12 cdfmt.;
run;

proc sort 
	data = fbdlq; 
	by BrAcctNo; 
run;

data fb;
	set merged_l_b2;
	if camp_type = "FB";
run;

proc sort 
	data = fb; /* sort to merge */ 
	by BrAcctNo; 
run;

data fbwithdlq; /* merge pull and dql information */
	merge fb(in = x) fbdlq(in = y);
	by bracctno;
	if x = 1;
run;

*** -------------------------------------------------------------- ***;
*** pull and merge dlq info for xs ------------------------------- ***;
data atb; 
	SET dw.vw_AgedTrialBalance(
		KEEP = LoanNumber AGE2 BOM 
			where = (BOM between "&_1yrdate" and "&yesterday")); 
	BRACCTNO = LoanNumber;
	YEARMONTH = BOM; 
	atbdt = input(substr(yearmonth, 6, 2) || '/' || 
				  substr(yearmonth, 9, 2) || '/' || 
				  substr(yearmonth, 1, 4), mmddyy10.);
	age = intck('month', atbdt, "&sysdate"d);
	cd = substr(age2, 1, 1) * 1;
	*** i.e. for age = 1: this is most recent month. Fill delq1,   ***;
	*** which is delq for month 1, with delq status (cd) --------- ***;
	if age = 1 then delq1 = cd;
	else if age = 2 then delq2 = cd;
	else if age = 3 then delq3 = cd;
	else if age = 4 then delq4 = cd;
	else if age = 5 then delq5 = cd;
	else if age = 6 then delq6 = cd;
	else if age = 7 then delq7 = cd;
	else if age = 8 then delq8 = cd;
	else if age = 9 then delq9 = cd;
	else if age = 10 then delq10 = cd;
	else if age = 11 then delq11 = cd;
	else if age = 12 then delq12 = cd;
	*** if cd is greater than 60-89 days late, set cd90 to 1 ----- ***;
	if cd > 4 then cd90 = 1; 
	*** if cd is greater than 30-59 days late, set cd60 to 1 ----- ***;
	if cd > 3 then cd60 = 1; 
	*** if cd is greater than 1-29 days late, set cd30 to 1 ------ ***;
	if cd > 2 then cd30 = 1; 

	if age < 7 then do;
		*** note 30-59s in last six months ----------------------- ***;
		if cd = 3 then recent6 = 1; 
	end;

	else if 6 < age < 13 then do;
		*** note 30-59s from 7 to 12 months ago ------------------ ***;
		if cd = 3 then first6 = 1; 
		end;
   keep bracctno delq1-delq12 cd cd30 cd60 cd90 age2 atbdt age first6 recent6;
run;

data atb2;
	set atb;
	*** count the number of 30-59s in the last year -------------- ***;
	last12 = sum(recent6, first6); 
run;

*** count cd30, cd60,recent6,first6 by bracctno (*recall loan      ***;
*** potentially counted for each month) -------------------------- ***;
proc summary 
	data = atb2 nway missing;
	class bracctno;
	var delq1-delq12 recent6 last12 first6 cd90 cd60 cd30;
	output out = atb3(drop = _type_ _freq_) sum = ;
run;

data atb4; /* create new counter variables */
	set atb3;
	if cd60 > 0 then ever60 = 'Y'; 
	else ever60 = 'N';
	times30 = cd30;
	if times30 = . then times30 = 0;
	if recent6 = null then recent6 = 0;
	if first6 = null then first6 = 0;
	if last12 = null then last12 = 0;
	drop cd30;
	format delq1-delq12 cdfmt.;
run;

proc sort 
	data = atb4 nodupkey; 
	by bracctno; 
run; /* sort to merge */

data xsdlq; 
	set atb4; 
	drop null; /* dropping the null column (not nulls in dataset) */
run;

data xs;
	set merged_l_b2;
	if camp_type = "XS";
run;

proc sort 
	data = xs; /* sort to merge */ 
	by BrAcctNo; 
run;

data xswithdlq; /* merge pull and dql information */
	merge xs(in = x) xsdlq(in = y);
	by bracctno;
	if x = 1;
run;

data merged_l_b2;
	set fbwithdlq xswithdlq;
run;

*** Apply all delinquency related flags -------------------------- ***;
data merged_l_b2; /* flag for bad dlqatb */
	set merged_l_b2;
	if cd60 > 1 or cd90 > 1 then DLQ_Flag = "X";
run;
/*
**********************************************************************;
*******************************CADENCE********************************;
**********************************************************************;
data merged_l_b2;
	set merged_l_b2;
	POffDate_dt = input(POffDate, anydtdte10.);
	IF "&cadence_8" > POffDate_dt > "&cadence_9" 
		THEN cadence_FLAG = "X";
	IF "&cadence_10" > POffDate_dt > "&cadence_11" 
		THEN cadence_FLAG = "X";
	IF "&cadence_12" > POffDate_dt > "&cadence_13" 
		THEN cadence_FLAG = "X";
	IF "&cadence_14" > POffDate_dt > "&cadence_15" 
		THEN cadence_FLAG = "X";
	IF "&cadence_15" > POffDate_dt > "&cadence_16" 
		THEN cadence_FLAG = "X";
	IF "&cadence_17" > POffDate_dt > "&cadence_18" 
		THEN cadence_FLAG = "X";
	IF "&cadence_18" > POffDate_dt > "&cadence_19" 
		THEN cadence_FLAG = "X";
	IF "&cadence_20" > POffDate_dt > "&cadence_21" 
		THEN cadence_FLAG = "X";
	IF "&cadence_21" > POffDate_dt > "&cadence_22" 
		THEN cadence_FLAG = "X";
	IF POffDate_dt < "&cadence_23" THEN cadence_FLAG = "X";
run;
**********************************************************************;
*******************************CADENCE********************************;
**********************************************************************;
*/
proc sort 
	data = merged_l_b2 out = deduped nodupkey; 
	by BrAcctNo; 
run;

*** Export Flagged File ------------------------------------------ ***;
proc export data=deduped outfile="&finalexportflagged" dbms=tab;
run;

*** Create final file for drops ---------------------------------- ***;
data final;
	set deduped;
	if entdate = "" then entdate = 1;
run;

data Waterfall;
	length Criteria $50 Count 8.;
	infile datalines dlm = "," truncover;
	input Criteria $ Count;
	datalines;
TCI Data,
XS Total,
FB Total,
XS + FB Total,	
Delete cust in Bad Branches,	
Delete cust with Missing Info,	
Delete cust Outside of Footprint,	
Delete where State/OwnSt Mismatch,
Delete FB With Open Loan,
Delete Any Customer with >1 Loan,
Delete cust with Bad POCODE,
Delete Deceased,
Delete if Less than Two Payments Made,	
Delete for ATB Delinquency,	
Delete for Conprofile Delinquency,
Delete for 5 Yr. Conprofile Delinquency,
Delete for Bankruptcy (5yr),
Delete for Statflag (5yr),
Delete for TRW Status (5yr),
Delete if DNS or DNH,
Delete NC Auto Unmades,	
Delete XS Bad FICOs,
Delete if Equity Threshhold not met,
Delete DLQ Renewal,	
Cadence,
;
run;

proc sql; /* Count obs */ 
	create table count as select count(*) as Count from tci;
quit;

proc sql; 
	insert into count select count(*) as Count from xs_total; 
quit;

proc sql; 
	insert into count select count(*) as Count from fb; 
quit;

proc sql; 
	insert into count select count(*) as Count from Merged_L_B_xs_fb2;
quit;

data final; 
	set final; 
	if BadBranch_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit;

data final; 
	set final; 
	if MissingInfo_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit; 

data final; 
	set final; 
	if OOS_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit; 

data final; 
	set final; 
	if State_Mismatch_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit; 

data final; 
	set final; 
	if open_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit;

data final; 
	set final; 
	if open_flag2 = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit;

data final; 
	set final; 
	if BadPOcode_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit; 

data final; 
	set final; 
	if deceased_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit;

data final; 
	set final; 
	if lessthan2_flag = ""; 
run; 

proc sql; 
	insert into count select count(*) as Count from final; 
quit; 

data final; 
	set final; 
	if dlq_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit;

data final; 
	set final; 
	if conprofile_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit;

data final; 
	set final; 
	if con5yr_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit;  

data final; 
	set final; 
	if bk5_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit; 

data final; 
	set final; 
	if statfl_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit; 

data final; 
	set final; 
	if TRW_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit; 

data final; 
	set final; 
	if DNS_DNH_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit; 

data final; 
	set final; 
	if NCAutoUn_Flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit; 

data final; 
	set final; 
	if badfico_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit;

data final; 
	set final; 
	if et_flag = ""; 
run;

proc sql; 
	insert into count select count(*) as Count from final; 
quit;

data final; 
	set final; 
	if dlqren_flag = ""; 
run;

proc sql; 
	insert into count 
	select count(*) as Count 
	from final; 
quit;

data final; 
	set final; 
	if cadence_FLAG = ""; 
run;

proc sql; 
	insert into count 
	select count(*) as Count 
	from final; 
quit;

proc print 
	data = count noobs; /* Print Final Count Table */
run;

proc print 
	data = waterfall; /* Print Final Count Table */
run;

*** Export Final File -------------------------------------------- ***;
DATA fbxsmita;
	set final;
run;

/*
proc export 
	data = final outfile = "&finalexportdropped" dbms = tab;
run;
*/

*** SEND TO DOD -------------------------------------------------- ***;
DATA MLA;
	SET FINAL;
	KEEP SSNO1 DOB LASTNAME FIRSTNAME MIDDLENAME BRACCTNO DOB_num SSNO1_num;
	LASTNAME = compress(LASTNAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	MIDDLENAME = compress(MIDDLENAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	FIRSTNAME = compress(FIRSTNAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	if SSNO1 = ' ' then delete;
	if SSNO1 = '        .' then delete;
	SSNO1_A = compress(SSNO1,"1234567890" , "kis");
	SSNO1_B = compress(SSNO1_A);
	SSNO1 = put(input(SSNO1_B,best9.),z9.);
	DOB = compress(DOB,"1234567890 " , "kis");
	if DOB = ' ' then delete;
	DOB_num = input(DOB, 8.);
	if DOB_num < 19000101 then delete;
	if DOB_num > "&today" then delete;
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

data split1 split2;
	set finalmla;
	if "Social Security Number (SSN)"n =: "1" | 
	   "Social Security Number (SSN)"n =: "2" then output split1;
	else output split2;
run;

data _null_;
	set split1;
	file "&exportMLA1"; 
	PUT @ 1 "Social Security Number (SSN)"n 
		@ 10 "Date of Birth"n 
		@ 18 "Last NAME"n 
		@ 44 "First NAME"n 
		@ 64 "Middle NAME"n 
		@ 84 "Customer Record ID"n
		@ 112 "Person Identifier CODE"n;
run; 

data _null_;
	set split2;
	file "&exportMLA2";  
	put @ 1 "Social Security Number (SSN)"n 
		@ 10 "Date of Birth"n 
		@ 18 "Last NAME"n 
		@ 44 "First NAME"n 
		@ 64 "Middle NAME"n 
		@ 84 "Customer Record ID"n
		@ 112 "Person Identifier CODE"n;
run; 

*** Step 2: Import file FROM DOD, append offer information, and    ***;
*** append PB if applicable -------------------------------------- ***;
filename mla1 
	"\\mktg-app01\E\Production\MLA\MLA-Output files FROM WEBSITE\MLA_5_3_FB_MITA_20200205p1.txt";

data mla1;
	infile mla1;
	input SSNO1 $ 1-9 
		  DOB $ 10-17 
		  LASTNAME $ 18-43 
		  FIRSTNAME $ 44-63
		  MIDDLENAME $ 64-83  
		  BRACCTNO $ 84-111 
		  PI_CODE $ 112-120 
		  MLA_DOD $121-145;
	MLA_STATUS = SUBSTR(MLA_DOD, 1, 1);
run;

filename mla2 
	"\\mktg-app01\E\Production\MLA\MLA-Output files FROM WEBSITE\MLA_5_3_FB_MITA_20200205p2.txt";

data mla2;
	infile mla2;
	input SSNO1 $ 1-9 
		  DOB $ 10-17 
		  LASTNAME $ 18-43 
		  FIRSTNAME $ 44-63
		  MIDDLENAME $ 64-83  
		  BRACCTNO $ 84-111 
		  PI_CODE $ 112-120 
		  MLA_DOD $121-145;
	MLA_STATUS = SUBSTR(MLA_DOD, 1, 1);
run;

data mla1;
	set mla1 mla2;
run;
	
proc contents 
	data = mla1;
run;					

proc sort 
	data = fbxsmita;
	by BrAcctNo;
run;

proc sort 
	data = mla1;
	by BrAcctNo;
run;

data finalhh;
	merge fbxsmita(in = x) mla1;
	by bracctno;
	if x;
run;

*** Count for Waterfall ------------------------------------------ ***;
proc freq 
	data = finalhh;
	table mla_status;
run;

data ficos;
	set finalhh;
	rename crscore = fico;
run;

data finalhh2;
	length fico_range_25pt $10 
		   campaign_id $25 
		   Made_Unmade $15 
		   cifno $20 
		   custid $20 
		   mgc $20 
		   state1 $5 
		   test_code $20;
	set ficos;
	if mla_status not in ("Y", "");
	if fico = 0 then fico_range_25pt = "0";
	if 0 < fico < 500 then fico_range_25pt = "<500";
	if 500 <= fico <= 524 then fico_range_25pt = "500-524";
	if 525 <= fico <= 549 then fico_range_25pt = "525-549";
	if 550 <= fico <= 574 then fico_range_25pt = "550-574";
	if 575 <= fico <= 599 then fico_range_25pt = "575-599";
	if 600 <= fico <= 624 then fico_range_25pt = "600-624";
	if 625 <= fico <= 649 then fico_range_25pt = "625-649";
	if 650 <= fico <= 674 then fico_range_25pt = "650-674";
	if 675 <= fico <= 699 then fico_range_25pt = "675-699";
	if 700 <= fico <= 724 then fico_range_25pt = "700-724";
	if 725 <= fico <= 749 then fico_range_25pt = "725-749";
	if 750 <= fico <= 774 then fico_range_25pt = "750-774";
	if 775 <= fico <= 799 then fico_range_25pt = "775-799";
	if 800 <= fico <= 824 then fico_range_25pt = "800-824";
	if 825 <= fico <= 849 then fico_range_25pt = "825-849";
	if 850 <= fico <= 874 then fico_range_25pt = "850-874";
	if 875 <= fico <= 899 then fico_range_25pt = "875-899";
	if 975 <= fico <= 999 then fico_range_25pt = "975-999";
	if fico = "" then fico_range_25pt = "";
	if source_2 = "RETAIL" then CAMPAIGN_id = "&retail_id";
	if source_2 = "AUTO" then CAMPAIGN_id = "&auto_id";
	if camp_type = "FB" then CAMPAIGN_id = "&fb_id";
	custid = strip(_n_);
	Made_Unmade = madeunmade_flag;
	offer_segment = "ITA";
	if state1 = "" then state1 = state;
	if state1 = "TX" then state1 = "";
	if entdate = 1 then entdate = "";
run;

data finalhh2;
	set finalhh2;
	rename ownbr = branch 
		   firstname = cfname1 
		   middlename = cmname1 
		   lastname = clname1 
		   adr1 = caddr1 
		   adr2 = caddr2
		   city = ccity 
		   state = cst 
		   zip = czip 
		   ssno1_rt7 = ssn 
		   cd60 = n_60_dpd 
		   conprofile1 = ConProfile;
run;

data finalhh3;
	length From_Offer_Amount 8. 
		   Up_to_Offer 8.;
	set finalhh2;
	if cst = "SC" then From_Offer_Amount = 601;
	if cst = "NC" then From_Offer_Amount = 500;
	if cst = "TN" then From_Offer_Amount = 501;
	if cst = "AL" then From_Offer_Amount = 501;
	if cst = "OK" then From_Offer_Amount = 501;
	if cst = "NM" then From_Offer_Amount = 500;
	if cst = "TX" then From_Offer_Amount = 500;
	if cst = "GA" then From_Offer_Amount = 500;
	if cst = "VA" then From_Offer_Amount = 500;
	if cst = "MO" then From_Offer_Amount = 601;
	if cst = "WI" then From_Offer_Amount = 601;
	if cst = "SC" then up_to_offer = 12000;
	if cst = "NC" then up_to_offer = 7500;
	if cst = "TN" then up_to_offer = 12000;
	if cst = "AL" then up_to_offer = 12000;
	if cst = "OK" then up_to_offer = 12000;
	if cst = "NM" then up_to_offer = 12000;
	if cst = "TX" then up_to_offer = 12000;
	if cst = "GA" then up_to_offer = 12000;
	if cst = "VA" then up_to_offer = 12000;
	if cst = "MO" then up_to_offer = 12000;
	if cst = "WI" then up_to_offer = 12000;
	if from_offer_amount = . then from_offer_amount = 600;
	if up_to_offer = . then up_to_offer = 7000;
run;

data fbxsita_hh;
	length offer_amount 8.;
	set finalhh3;
	IF times30 = 0 and classtranslation in ('Small' 'Checks') 
		then offer_amount = NetLoanAmount + 500;
	IF times30 = 0 and classtranslation  = 'Large' 
		then offer_amount = NetLoanAmount + 1000;
	IF times30 = 1 and classtranslation in ('Small' 'Checks') 
		then offer_amount = NetLoanAmount + 250;
	IF times30 = 1 and classtranslation  = 'Large' 
		then offer_amount = NetLoanAmount + 500;
	IF times30 > 1 
		then offer_amount = NetLoanAmount;
	IF times30 = . 
		then offer_amount = NetLoanAmount;
	IF n_60_dpd = 1 
		then offer_amount = NetLoanAmount;
	IF classtranslation in ('Small' 'Checks') and offer_amount > 2400 
		then offer_amount = 2400;
	IF OWNST = 'TX' and classtranslation in ('Small' 'Checks') 
					and 2500 > offer_amount > 1400 
		then offer_amount = 1400;
	IF OWNST = 'OK' and classtranslation in ('Small' 'Checks') 
					and offer_amount > 1400 
		then offer_amount = 1400;
	IF offer_amount > 6000 
		then offer_amount = 6000;
run;

/*
*** append pbita ------------------------------------------------- ***;
data finalhh3;
	length amt_given1 8. 
		   month_split $15 
		   numpymnts $15 
		   orig_amtid $15 
		   percent $15 
		   From_Offer_Amount 8. 
		   Up_to_Offer 8.;
	set fbxsita_hh pbita_hh;
	if mla_status ne "";
run;

proc sql;
	create table finalesthh as
	select custid, branch, cfname1,	cmname1, clname1, caddr1, caddr2,
		   ccity, cst, czip, ssn, amt_given1, from_offer_amount,
		   up_to_offer, percent,numpymnts, camp_type, orig_amtid, fico,
		   dob, mla_status, n_60_dpd, conprofile, risk_segment,
		   bracctno, cifno, campaign_id, mgc, month_split, made_unmade,
		   fico_range_25pt, state1, test_code, poffdate, phone, 
		   cellphone
	from finalhh3;
quit;

proc export 
	data = finalesthh outfile = "&finalexportHH" dbms = tab;
run;

proc export 
	data = finalesthh outfile = "&finalexportED"  dbms = csv;
run;

proc freq 
	data = finalesthh;
	tables mla_status risk_segment state1 cst;
run;
*/




*** For when pbita isn't included -------------------------------- ***;
data finalhh3;
	length amt_given1 8. 
		   month_split $15 
		   numpymnts $15 
		   orig_amtid $15 
		   percent $15 
		   From_Offer_Amount 8. 
		   Up_to_Offer 8.;
	set fbxsita_hh;
	if mla_status ne "";
run;

proc sql;
	create table finalesthh as
	select custid, branch, cfname1,	cmname1, clname1, caddr1, caddr2,
		   ccity, cst, czip, ssn, amt_given1, from_offer_amount, 
		   up_to_offer, percent,numpymnts, camp_type, orig_amtid, fico,
		   dob, mla_status, risk_segment, n_60_dpd, conprofile, 
		   bracctno, cifno, campaign_id, mgc, month_split, made_unmade,
		   fico_range_25pt, state1, test_code, poffdate, phone,
		   cellphone, offer_amount
	from finalhh3;
quit;

proc export 
	data = finalesthh outfile = "&finalexportHH2" dbms = tab;
run;

proc export 
	data = finalesthh outfile = "&finalexportED2"  dbms = csv;
run;

proc freq 
	data = finalesthh;
	tables mla_status Risk_Segment state1 cst;
run;

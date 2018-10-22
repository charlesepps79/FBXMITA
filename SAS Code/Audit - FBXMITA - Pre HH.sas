
ods excel file = 
	"\\mktg-app01\E\Production\Audits\FBXSPB_ITA_AUDIT_Pre_HH_9.0_2018.xlsx" 
options(sheet_name = "Account History" sheet_interval = "none");

proc tabulate 
	data = final;
	class delq1-delq12;
	tables delq1-delq12,n;
run;

proc tabulate 
	data = fbxsita_hh; /* should produce an empty table! */
	class statflags_old TrwStatus;
	tables statflags_old TrwStatus;
run;

proc tabulate 
	data = fbxsita_hh;
	class camp_type fico_range_25pt;
	tables camp_type * fico_range_25pt,n;
run;

proc tabulate 
	data = fbxsita_hh;
	class camp_type;
	var fico;
	tables camp_type, fico * min fico * max;
run;

*** run if PB is included ---------------------------------------- ***;
/*
proc tabulate 
	data = pbita_hh;
	class statflags_old TrwStatus;
	tables statflags_old TrwStatus;
run;

proc tabulate 
	data = pbita_hh;
	class camp_type fico_range_25pt;
	tables camp_type * fico_range_25pt,n;
run;

proc tabulate 
	data = pbita_hh;
	class camp_type;
	var fico;
	tables camp_type, fico * min fico * max;
run;
*/

ods excel options(sheet_interval = 'table');                         
ods select none; 

data _null_; 
	dcl odsout obj(); 
run; 

ods select all;
ods excel options(sheet_name = "Campaign Info" sheet_interval = "NONE");

proc tabulate 
	data = fbxsita_hh;
	class Made_Unmade camp_type;
	tables camp_type, Made_Unmade;
run;

proc tabulate 
	data = fbxsita_hh;
	class cst camp_type;
	tables cst * (camp_type all) all,n;
run;

proc tabulate 
	data = fbxsita_hh;
	class campaign_id camp_type;
	tables camp_type * campaign_id,n;
run;

*** run if PB is included ---------------------------------------- ***;
proc tabulate 
	data = pbita_hh;
	class Made_Unmade camp_type;
	tables camp_type, Made_Unmade;
run;

proc tabulate 
	data = pbita_hh;
	class cst camp_type;
	tables cst * (camp_type all) all,n;
run;

proc tabulate 
	data = pbita_hh;
	class campaign_id camp_type;
	tables camp_type * campaign_id,n;
run;

ods excel close;
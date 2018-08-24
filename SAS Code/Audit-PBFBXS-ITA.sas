data _null_;
	call symput("outfilex",
		"\\mktg-app01\E\Production\Audits\FBXSPB ITA AUDIT - 9.0 - Final Mail File.xlsx");
	call symput("importfile",
		"WORK.'118646A_RMC_PBFBXS9.0_18ITA_Fina'n");
run;

data auditita;
	set &importfile; /* BranchNumber as string */
run;

proc sql;
	create table namechars as
	select * from auditita
	where name1 like "%*%" or 
		  name1 like "%$%" or 
		  name1 like "%@%" or 
		  name1 like "%#%" or 
		  name1 like "%!%" or 
		  name1 like "%^%" or
		  name1 like "%(%" or 
		  name1 like "%)%" or 
		  name1 eq "";
quit;

data snip;
	set auditita(obs = 4);
run;

*** Check Branch Info -------------------------------------------- ***;
data audit2nbcc;
	set auditita;
	keep BranchNumber 
		 BranchStreetAddress 
		 BranchCity 
		 BranchState 
		 BranchZip 
		 BranchPhone;
run;

proc sort 
	data = audit2nbcc nodupkey;
	by BranchNumber 
	   BranchStreetAddress 
	   BranchCity 
	   BranchState 
	   BranchZip 
	   BranchPhone;
run;

data branchinfo;
	set rmcath.branchinfo;
	branchnumber = branchnumber_txt;
run;

proc sort 
	data = branchinfo;
	by branchnumber;
run;

data branchInfo_Check;
	merge branchinfo audit2nbcc(in = x);
	by branchnumber;
	if x;
run;

data branchinfo_check2;
	set branchinfo_check;
	if Branchstreetaddress ne StreetAddress then Br_Info_Mismatch = 1;
	if Branchcity ne city then Br_Info_Mismatch = 1;
	if branchstate ne state then br_info_mismath = 1;
	if branchzip ne zip_full then br_info_mismatch = 1;
	if branchphone ne phone then br_info_mismatch = 1;
	if br_info_mismatch = 1;
	drop BranchNumber_txt;
	rename BranchNumber_number = Branch;
run;

ods excel file = "&outfilex" options(sheet_name = "Data Snippet" 
									 sheet_interval = "none");

proc summary 
	data = auditita print;
run;

proc print 
	data = snip;
run;

ods excel options(sheet_interval = 'table');                         
ods select none; 

data _null_; 
	dcl odsout obj(); 
run; 

ods select all;
ods excel options(sheet_name = "StateAndCompany Checks" 
				  sheet_interval = "NONE");

proc tabulate 
	data = auditita;
	class state branchstate;
	tables state, branchstate;
run;

proc tabulate 
	data = auditita;
	class state BranchCompany;
	tables state,branchcompany;
run;

proc freq 
	data = auditita;
	table state / nocum nopercent;
run;

ods excel options(sheet_interval = 'table');                         
ods select none; 

data _null_; 
	dcl odsout obj(); 
run; 

ods select all;
ods excel options(sheet_name = "Offer Amounts" 
				  sheet_interval = "none");

proc tabulate 
	data = auditita;
	class state 
		  From_Offer_Amount 
		  up_to_OFFER;
	tables state, From_Offer_Amount 
				  up_to_OFFER;
run;

proc sort 
	data = auditita;
	by HHfilecode;
run;

proc tabulate 
	data = auditita;
class state From_Offer_Amount up_to_OFFER;
tables state, From_Offer_Amount up_to_OFFER;
by HHfilecode;
run;

proc tabulate data=auditita;
class HHfilecode state;
var amt_given1;
tables state, min*amt_given1 max*amt_given1;
where HHfilecode="PB";
run;

ods excel options(sheet_interval='table');                         
ods select none; data _null_; dcl odsout obj(); run; ods select all;
ods excel options(sheet_name="Campaign Info" sheet_interval="none");
proc freq data=auditita;
tables Drop_Date Closed_Date/nocum nopercent;
run;

proc tabulate data=auditita;
var POffDate;
tables min*poffdate*f=date9. max*poffdate*f=date9.;
run;

ods excel options(sheet_interval='table');                         
ods select none; data _null_; dcl odsout obj(); run; ods select all;
ods excel options(sheet_name="Name Check" sheet_interval="none");
proc print data=namechars;
run;

ods excel options(sheet_interval='table');                         
ods select none; data _null_; dcl odsout obj(); run; ods select all;
ods excel options(sheet_name="Branch Info Check" sheet_interval="none");
proc print data=branchinfo_check2 noobs;
run;
ods excel close;
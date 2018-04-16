### FBXMITA

1. Find instructions for downloading latest XS information from TCI here:
    - R:\Production\MLA\Files for MLA Processing\XSELL\XSELL TCI DECSION LENDER.txt
    - Follow instructions in above text file.
2. Open SAS
3. At top ribbon, click Program > Open Program > Pull – FBXMITA
4. See what is highlighted below for the segments of each line that needs to be modified. When going into a new month, you will need to create a folder called “ITA” to send the files to. As seen here, 10-16 would be the day of the pull. Generally, this is the only part of the date you will change as year obviously changes once a year.
5. Go down to approximately line 1149 and type `“/*”` to comment out what is below this line.
6. Hit F3 to run the program.
7. You will see the below after the run. Copy the first table for the waterfall. The rest of the output is to note that everything executed as expected. R:Production\MLA\Waterfall_02)FB ITA Monthly.xlsx
8.	Open up Internet Explorer
    - Go to:  https://mla.dmdc.osd.mil/mla/#/home
    - At the top ribbon, Click “Multiple Record Requests”
    - Enter in your username and password information.
    - Click “Add.” Add, one at a time, the MLA input files for the current pull. (R:Production\MLA\MLA-Input files TO WEBSITE\ FB_MITA_20171016p1 and R:Production\MLA\MLA-Input files TO WEBSITE\ FB_MITA_20171016p2). The “20171016” portion changes according to how you changed the date in the pull code.
    - Select “Yes” for “Do you require certificates for the uploaded files?”
    - Check both boxes beneath as shown below.
    - Click “Upload.”

### TCI RMC
### Retail and Auto 4.0
### Source 2

https://decisionlender.solutions/tci/#/auth/login/default 
- Company Id: regi301
- User Id   : "Your user id"
- Password: "Your password"

1. Click on reports
2. From Drop-down, select "XS Mail Pull"
3. Set date range to 1 year from the date of the pull. (Ex. If pull date is 01/01/2018, then date range should be 01/01/2017-01/01/2018) 
4. Set **Decision Status** filter to **Auto Approved**, **Approved**, and **Counter Offered**
5. Set **Loan Type** filter to **Auto Indirect** and **Retail**
6. Click "Run Report"
8. At top right, click "Download (Combined)" and select Excel
9. From Downloads (click "Show in Folder after clicking on the downloaded file on bottom left), 
copy file to \\mktg-app01\E\Production\MLA\Files for MLA Processing\XSELL\ and rename file to "XS_Mail_Pull"

***Note that later in the year, the file might not load from TCI. In this case. download in two tries and name one "XS_Mail_Pull_1" and the other "XS_Mail_Pull_2"

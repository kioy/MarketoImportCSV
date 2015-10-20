# MarketoImportCSV
A shell script for import leads data (csv file) via ReST API of Marketo.

# Usage
1. Setup Marketo ReST API on your Marketo instance

   http://developers.marketo.com/blog/quick-start-guide-for-marketo-rest-api/

2. Revise Variables in the script

   MARKETO_END_POINT: Marketo ReST API end point, e.g. https://999-nnn-999.mktorest.com
   CLIENT_ID: Client ID for ReST access, you can retrieve it through step.1 above.
   CLIENT_SECRET: Client Secret key for ReST access
   CSV_FILE_PATH: path for target CSV files (You can use wildcard.)

3. Run importCSV2Marketo.sh


# Required

  CSV Files: 
      If your CSV file is over 10MB, you have to split it into less than 10MB files. All CSV files must have column names at the first row.

  Other commands: jq 1.4, curl 7.43.0

# License
This source is licensed under an MIT License, see the LICENSE file for full details. If you use this code, it would be great to hear from you.


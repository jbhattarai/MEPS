/**********************************************************************************
 PROGRAM:  C:\MEPS\SAS\Exercise_1\EXERCISE1.SAS

DESCRIPTION:  THIS PROGRAM GENERATES THE FOLLOWING ESTIMATES ON NATIONAL HEALTH CARE EXPENSES BY TYPE OF SERVICE, 2015:

               (1) PERCENTAGE DISTRIBUTION OF EXPENSES BY TYPE OF SERVICE
               (2) PERCENTAGE OF PERSONS WITH AN EXPENSE, BY TYPE OF SERVICE
               (3) MEAN EXPENSE PER PERSON WITH AN EXPENSE, BY TYPE OF SERVICE

              DEFINED SERVICE CATEGORIES ARE:
                 HOSPITAL INPATIENT
                 AMBULATORY SERVICE: OFFICE-BASED & HOSPITAL OUTPATIENT VISITS
                 PRESCRIBED MEDICINES
                 DENTAL VISITS
                 EMERGENCY ROOM
                 HOME HEALTH CARE (AGENCY & NON-AGENCY) AND OTHER (TOTAL EXPENDITURES - ABOVE EXPENDITURE CATEGORIES)

             NOTE: EXPENSES INCLUDE BOTH FACILITY AND PHYSICIAN EXPENSES.

 INPUT FILE:   C:\MEPS\SAS\DATA\H181.SAS7BDAT (2015 FULL-YEAR FILE)

 *********************************************************************************/
OPTIONS LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
FILENAME MYLOG "U:\MEPS\SAS\Exercise_1\Exercise1_log.TXT";
FILENAME MYPRINT "U:\MEPS\SAS\Exercise_1\Exercise1_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;

LIBNAME CDATA 'C:\MEPS\SAS\DATA';
*LIBNAME CDATA "\\programs.ahrq.local\programs\meps\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_&curr_yr\SAS\Data";

 PROC FORMAT;
  VALUE AGEF
      0-  64 = '0-64'
     65-HIGH = '65+';

  VALUE AGECAT
      .  = 'All Ages'
       1 = '0-64'
       2 = '65+';

    VALUE GTZERO
      0         = '$0'
      0 <- HIGH = '>$0';

    VALUE FLAG
      .         = 'No or any expense'
      0         = 'No expense'
      1         = 'Any expense';

 RUN;

TITLE1 '2018 AHRQ MEPS DATA USERS WORKSHOP';
TITLE2 "EXERCISE1.SAS: NATIONAL HEALTH CARE EXPENSES, 2015";



 /* READ IN DATA FROM 2015 CONSOLIDATED DATA FILE (HC-181) */
 DATA PUF181;
   SET CDATA.H181 (KEEP= TOTEXP15 IPDEXP15 IPFEXP15 OBVEXP15 RXEXP15
                          OPDEXP15 OPFEXP15 DVTEXP15 ERDEXP15 ERFEXP15
                          HHAEXP15 HHNEXP15 OTHEXP15 VISEXP15 AGE15X AGE42X AGE31X
                          VARSTR   VARPSU   PERWT15f );


   /* Define expenditure variables by type of service  */


   TOTAL                = TOTEXP15;
   HOSPITAL_INPATIENT   = IPDEXP15 + IPFEXP15;
   AMBULATORY           = OBVEXP15 + OPDEXP15 + OPFEXP15 + ERDEXP15 + ERFEXP15;
   PRESCRIBED_MEDICINES = RXEXP15;
   DENTAL               = DVTEXP15;
   HOME_HEALTH_OTHER    = HHAEXP15 + HHNEXP15 + OTHEXP15 + VISEXP15;


  /*QC CHECK IF THE SUM OF EXPENDITURES BY TYPE OF SERVICE IS EQUAL TO TOTAL*/


   DIFF = TOTAL-HOSPITAL_INPATIENT - AMBULATORY   - PRESCRIBED_MEDICINES
              - DENTAL            - HOME_HEALTH_OTHER        ;


  /* CREATE FLAG (1/0) VARIABLES FOR PERSONS WITH AN EXPENSE, BY TYPE OF SERVICE  */
   ARRAY EXX  (6) TOTAL     HOSPITAL_INPATIENT   AMBULATORY     PRESCRIBED_MEDICINES
                  DENTAL    HOME_HEALTH_OTHER      ;


   ARRAY ANYX (6) X_ANYSVCE X_HOSPITAL_INPATIENT X_AMBULATORY    X_PRESCRIBED_MEDICINES
                  X_DENTAL  X_HOME_HEALTH_OTHER    ;


   DO II=1 TO 6;
     ANYX(II) = 0;
     IF EXX(II) > 0 THEN ANYX(II) = 1;
   END;
   DROP II;

   /* CREATE A SUMMARY VARIABLE FROM END OF YEAR, 42, AND 31 VARIABLES*/


        IF AGE15X >= 0 THEN AGE = AGE15X ;
   ELSE IF AGE42X >= 0 THEN AGE = AGE42X ;
   ELSE IF AGE31X >= 0 THEN AGE = AGE31X ;

        IF 0 LE AGE LE 64 THEN AGECAT=1 ;
   ELSE IF      AGE  > 64 THEN AGECAT=2 ;
  ;


 RUN;
 TITLE3 "Supporting crosstabs for the flag variables";
 PROC FREQ DATA=PUF181;
    TABLES X_ANYSVCE              * TOTAL
           X_HOSPITAL_INPATIENT   * HOSPITAL_INPATIENT
           X_AMBULATORY           * AMBULATORY
           X_PRESCRIBED_MEDICINES * PRESCRIBED_MEDICINES
           X_DENTAL               * DENTAL
           X_HOME_HEALTH_OTHER    * HOME_HEALTH_OTHER
           AGECAT*AGE
           DIFF/LIST MISSING;

    FORMAT TOTAL
           HOSPITAL_INPATIENT
           AMBULATORY
           PRESCRIBED_MEDICINES
           DENTAL
           HOME_HEALTH_OTHER   gtzero.
           AGE  agef.
           X_ANYSVCE
           X_HOSPITAL_INPATIENT
           X_AMBULATORY
           X_PRESCRIBED_MEDICINES
           X_DENTAL
           X_HOME_HEALTH_OTHER flag.
           AGECAT agecat.
  ;
RUN;
 ods graphics off;
  TITLE3 'PERCENTAGE DISTRIBUTION OF EXPENSES BY TYPE OF SERVICE (STAT BRIEF #491 FIGURE 1)';
 PROC SURVEYMEANS DATA=PUF181 sum ;
    STRATUM VARSTR;
    CLUSTER VARPSU;
    WEIGHT PERWT15f;
    VAR   HOSPITAL_INPATIENT
         AMBULATORY
         PRESCRIBED_MEDICINES
          DENTAL
         HOME_HEALTH_OTHER
         TOTAL ;
    RATIO  HOSPITAL_INPATIENT
          AMBULATORY
          PRESCRIBED_MEDICINES
          DENTAL
          HOME_HEALTH_OTHER   / TOTAL ;
 RUN;
TITLE3 'PERCENTAGE OF PERSONS WITH AN EXPENSE, BY TYPE OF SERVICE';
PROC SURVEYMEANS DATA= PUF181 NOBS MEAN STDERR SUM;
    STRATUM VARSTR ;
    CLUSTER VARPSU ;
    WEIGHT  PERWT15f ;
    VAR X_ANYSVCE
        X_HOSPITAL_INPATIENT
        X_AMBULATORY
        X_PRESCRIBED_MEDICINES
        X_DENTAL
        X_HOME_HEALTH_OTHER;
        RUN;


 TITLE3 'MEAN TOTAL EXPENSE PER PERSON WITH AN EXPENSE, AGE 0-64, AND AGE 65+ (via ODS Output)';
  *ods trace on;
 PROC SURVEYMEANS DATA= PUF181 MEAN NOBS SUMWGT STDERR SUM;
    STRATUM VARSTR ;
    CLUSTER VARPSU ;
    VAR  TOTAL;
    DOMAIN  AGECAT AGECAT*X_ANYSVCE('1');
    WEIGHT  PERWT15f ;
    FORMAT  AGECAT agecat.;
    ods output Statistics=work.Overall_results
               domain= work.domain_results;
RUN;
data combine;
  set work.Overall_results
      work.domain_results;
run;
proc print data= combine noobs split='*';
 var AGECAT  X_ANYSVCE N  SumWgt  mean StdErr  Sum stddev;
 label AGECAT = 'Age Group'
       X_ANYSVCE = 'Expense*Category*(Flag)'
       SumWgt = 'Population*Size'
       mean = 'Mean($)'
       StdErr = 'SE of Mean($)'
       Sum = 'Total*Expense ($)'
       Stddev = 'SE of*Total Expense($)';
       format N SumWgt Comma12. mean comma7. stderr 7.3 sum Stddev comma17.
        X_ANYSVCE flag.;
run;

TITLE3 'MEAN HOSPITAL INPATIENT EXPENSE PER PERSON WITH AN INPATIENT EXPENSE, AGE 0-64, AND AGE 65+';
PROC SURVEYMEANS DATA= PUF181 NOBS MEAN SUMWGT STDERR SUM ;
    STRATUM VARSTR ;
    CLUSTER VARPSU ;
    WEIGHT  PERWT15f ;
    VAR  HOSPITAL_INPATIENT;
    DOMAIN  X_HOSPITAL_INPATIENT('1') AGECAT*X_HOSPITAL_INPATIENT ('1');
    FORMAT  AGECAT agecat. ;
RUN;

TITLE3 'MEAN AMBULATORY EXPENSE PER PERSON WITH AN AMBULATORY EXPENSE, AGE 0-64, AND AGE 65+';
PROC SURVEYMEANS DATA= PUF181 NOBS MEAN SUMWGT STDERR SUM ;
    STRATUM VARSTR ;
    CLUSTER VARPSU ;
    WEIGHT  PERWT15f ;
    VAR  AMBULATORY;
    DOMAIN  X_AMBULATORY('1')  AGECAT*X_AMBULATORY('1') ;
    FORMAT  AGECAT agecat.;
 RUN;

 TITLE3 'MEAN PRESCRIPTION MEDICINE EXPENSE PER PERSON WITH A PRESCRIPTION MEDICINE EXPENSE, AGE 0-64, AND AGE 65+';
PROC SURVEYMEANS DATA= PUF181 MEAN NOBS SUMWGT STDERR SUM ;
    STRATUM VARSTR ;
    CLUSTER VARPSU ;
    WEIGHT  PERWT15f ;
    VAR  PRESCRIBED_MEDICINES;
    DOMAIN  X_PRESCRIBED_MEDICINES('1') AGECAT*X_PRESCRIBED_MEDICINES('1');
    FORMAT  AGECAT agecat.;
 RUN;

 TITLE3 'MEAN DENTAL EXPENSE PER PERSON WITH A DENATL EXPENSE, AGE 0-64, AND AGE 65+';
PROC SURVEYMEANS DATA= PUF181 MEAN NOBS SUMWGT STDERR SUM ;
    STRATUM VARSTR ;
    CLUSTER VARPSU ;
    WEIGHT  PERWT15f ;
    VAR  DENTAL;
    DOMAIN   X_DENTAL('1') AGECAT*X_DENTAL('1') ;
    FORMAT  AGECAT agecat.;
 RUN;

TITLE3 'MEAN  OTHER EXPENSE (INCLUDING HOME HEALTH EXPENSE) PER PERSON WITH AN OTHER  EXPENSE, AGE 0-64, AND AGE 65+';
 PROC SURVEYMEANS DATA= PUF181 MEAN NOBS SUMWGT STDERR SUM ;
    STRATUM VARSTR ;
    CLUSTER VARPSU ;
    WEIGHT  PERWT15f ;
    VAR  HOME_HEALTH_OTHER;
    DOMAIN  X_HOME_HEALTH_OTHER('1') AGECAT*X_HOME_HEALTH_OTHER('1') ;
    FORMAT  AGECAT agecat.;
 RUN;
 PROC PRINTTO;
 RUN;

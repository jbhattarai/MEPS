/**********************************************************************************

PROGRAM:      C:\MEPS\SAS\Exercise_6\EXERCISE6.SAS

DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS DATA FILES FROM DIFFERENT YEARS
              THE EXAMPLE USED IS POPULATION AGE 26-30 WHO ARE UNINSURED BUT HAVE HIGH INCOME

	         DATA FROM 2014 AND 2015 ARE POOLED.

              VARIABLES WITH YEAR-SPECIFIC NAMES MUST BE RENAMED BEFORE COMBINING FILES.  
              IN THIS PROGRAM THE INSURANCE COVERAGE VARIABLES 'INSCOV14' AND 'INSCOV15' ARE RENAMED TO 'INSCOV'.

	         SEE HC-036 (1996-2015 POOLED ESTIMATION FILE) FOR
              INSTRUCTIONS ON POOOLING AND CONSIDERATIONS FOR VARIANCE
	         ESTIMATION FOR PRE-2002 DATA.

INPUT FILE:   (1) C:\MEPS\SAS\DATA\H181.SAS7BDAT (2015 FULL-YEAR FILE)
	          (2) C:\MEPS\SAS\DATA\H171.SAS7BDAT (2014 FULL-YEAR FILE)

*********************************************************************************/;
OPTIONS LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
FILENAME MYLOG "U:\MEPS\SAS\Exercise_6\Exercise6_log.TXT";
FILENAME MYPRINT "U:\MEPS\SAS\Exercise_6\Exercise6_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;

LIBNAME CDATA 'C:\MEPS\SAS\DATA';
*LIBNAME CDATA "\\programs.ahrq.local\programs\meps\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018\SAS\Data";


TITLE1 '2018 AHRQ MEPS DATA USERS WORKSHOP';
TITLE2 'EXERCISE6.SAS: POOL MEPS DATA FILES FROM DIFFERENT YEARS (2014 and 2015)';

PROC FORMAT;
	VALUE POVCAT 
    1 = '1 POOR/NEGATIVE'
    2 = '2 NEAR POOR'
    3 = '3 LOW INCOME'
    4 = '4 MIDDLE INCOME'
    5 = '5 HIGH INCOME'
    ;

	VALUE INSF
	1 = '1 ANY PRIVATE'
	2 = '2 PUBLIC ONLY'
	3 = '3 UNINSURED';

    VALUE AGE
    26-30='26-30'
    0-25='0-25'
    31-HIGH='31+';
run;
/* FREQUENCY OF 2014 */
DATA YR1;
	SET CDATA.H171 (KEEP= DUPERSID INSCOV14 PERWT14F VARSTR VARPSU POVCAT14 AGELAST TOTSLF14);
     IF PERWT14F>0;
RUN;
/* FREQUENCY OF 2015*/
DATA YR2;
	SET CDATA.H181 (KEEP= DUPERSID INSCOV15 PERWT15F VARSTR VARPSU POVCAT15 AGELAST TOTSLF15);
     IF PERWT15F>0;
run;
TITLE3 'UNWEIGHTED FREQUENCY FOR 2014 FY PERSONS WITH AGE 26-30';
PROC FREQ DATA= YR1 (WHERE=(26 LE AGELAST LE 30));
	TABLES POVCAT14*INSCOV14/ LIST MISSING ;
	FORMAT INSCOV14 INSF.  POVCAT14 POVCAT.;
RUN;

TITLE3 'UNWEIGHTED FREQUENCY FOR 2015 FY PERSONS WITH AGE 26-30';
PROC FREQ DATA= YR2 (WHERE=(26 LE AGELAST LE 30));
	TABLES POVCAT15*INSCOV15/ LIST MISSING ;
	FORMAT INSCOV15 INSF.  POVCAT15 POVCAT.;
RUN;


/* RENAME YEAR SPECIFIC VARIABLES PRIOR TO COMBINING FILES */
DATA YR1X;
	SET YR1 (RENAME=(INSCOV14=INSCOV PERWT14F=PERWT POVCAT14=POVCAT TOTSLF14=TOTSLF));
RUN;

DATA YR2X;
	SET YR2 (RENAME=(INSCOV15=INSCOV PERWT15F=PERWT POVCAT15=POVCAT TOTSLF15=TOTSLF));
RUN;

DATA POOL;
     LENGTH INSCOV AGELAST POVCAT VARSTR VARPSU 8;
	SET YR1X YR2X;
     POOLWT = PERWT/2 ;
   
     IF 26 LE AGELAST LE 30 AND POVCAT=5 AND INSCOV=3 THEN SUBPOP=1;
     ELSE SUBPOP=2;

     LABEL SUBPOP='POPULATION WITH AGE=26-30, UNINSURED WHOLE YEAR, AND HIGH INCOME'
           TOTSLF='TOTAL AMT PAID BY SELF/FAMILY';
RUN;

TITLE3 "CHECK MISSING VALUES ON THE COMBINED DATA";
PROC MEANS DATA=POOL N NMISS;
RUN;

TITLE3 'SUPPORTING CROSSTAB FOR THE CREATION OF THE SUBPOP FLAG';
PROC FREQ DATA=POOL;
	TABLES SUBPOP SUBPOP*AGELAST*POVCAT*INSCOV/ LIST MISSING ;
	FORMAT  AGELAST AGE. ;
RUN;
ODS GRAPHICS OFF;
TITLE3 'WEIGHTED ESTIMATE ON TOTSLF FOR COMBINED DATA W/AGE=26-30, UNINSURED WHOLE YEAR, AND HIGH INCOME';
PROC SURVEYMEANS DATA=POOL NOBS MEAN STDERR;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  POOLWT;
	DOMAIN  SUBPOP;
	VAR  TOTSLF;
RUN;
PROC PRINTTO; 
RUN;


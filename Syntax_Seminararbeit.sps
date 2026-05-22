* Encoding: UTF-8.
DATASET ACTIVATE DataSet1.

*Deskriptive Statistik – kategoriale Variablen.

FREQUENCIES VARIABLES=
  GEN
  EDU
  EDU_other
  JOB
  JOB_other
  SUB
  /BARCHART FREQ
  /ORDER=ANALYSIS.

*Deskriptive Statistik – metrische Variable Alter.

DESCRIPTIVES VARIABLES=AGE
  /STATISTICS=MEAN STDDEV MIN MAX.



*umcodierung_AGE

RECODE AGE (19 thru 24=1) (25 thru 37=2) (38 thru 49=3) (50 thru 60=4) (61 thru 78=5) (ELSE=SYSMIS) 
    INTO AGE_gruppe.
VARIABLE LABELS  AGE_gruppe 'Altersgruppe (Jahre)'.
EXECUTE.

*AGE_gruppe deskriptive Statistik 

FREQUENCIES VARIABLES=AGE_gruppe
  /ORDER=ANALYSIS.

*Interne Konsistenz Gewissenhaftigkeit

RELIABILITY
  /VARIABLES=PERS_01 PERS_03 PERS_05 Pers_07kod Pers_12kod PERS_09
  /SCALE('ALL VARIABLES') ALL
  /MODEL=ALPHA
  /STATISTICS=DESCRIPTIVE SCALE
  /SUMMARY=TOTAL.

*Interne Konsistenz Verträglichkeit

RELIABILITY
  /VARIABLES=PERS_02 PERS_04 PERS_06 pers_08kod PERS_10 PERS_11
  /SCALE('ALL VARIABLES') ALL
  /MODEL=ALPHA
  /STATISTICS=DESCRIPTIVE SCALE
  /SUMMARY=TOTAL.

*Interne Konsistenz biosphärische Werte

RELIABILITY
  /VARIABLES=VAL_01 VAL_02 VAL_03 VAL_04
  /SCALE('ALL VARIABLES') ALL
  /MODEL=ALPHA
  /STATISTICS=DESCRIPTIVE SCALE
  /SUMMARY=TOTAL.

*Interne Konsistenz altruistische Werte

RELIABILITY
  /VARIABLES=VAL_05 VAL_06 VAL_07 VAL_08
  /SCALE('ALL VARIABLES') ALL
  /MODEL=ALPHA
  /STATISTICS=DESCRIPTIVE SCALE
  /SUMMARY=TOTAL.

*interne Konsistenz umweltförderliches Verhalten

RELIABILITY
  /VARIABLES=ENV_01 ENV_02 ENV_03 ENV_04 ENV_05 ENV_06 ENV_07
  /SCALE('ALL VARIABLES') ALL
  /MODEL=ALPHA
  /STATISTICS=DESCRIPTIVE SCALE
  /SUMMARY=TOTAL.

*Gewissenhaftigkeitsskala für Korrelation (Mean)

COMPUTE Gewissenhaftigkeit_m=MEAN(PERS_01, PERS_03, PERS_05, Pers_07kod, PERS_09, Pers_12kod).
EXECUTE.

*Verträglichkeitsskala für Korrelation (Mean)

COMPUTE Verträglichkeit_M=MEAN(PERS_02, PERS_04, PERS_06, pers_08kod, PERS_10, PERS_11).
EXECUTE.

*Biosphärische Werteskala für Korrelation (Mean)

COMPUTE Biosphärische_Werte_M=MEAN(VAL_01, VAL_02, VAL_03, VAL_04).
EXECUTE.

*Altruistische Werteskala für Korrelation (Mean)
    
 COMPUTE Altruismus_Werte_M=MEAN(VAL_05, VAL_06, VAL_07, VAL_08).
EXECUTE.

*Umweltverhalten Werteskala für Korrelation (Mean)

COMPUTE Umweltverhalten_M=MEAN(ENV_01, ENV_02, ENV_03, ENV_04, ENV_05, ENV_06, ENV_07).
EXECUTE.

*bivariate Pearsonkorrelation 

CORRELATIONS
  /VARIABLES=Gewissenhaftigkeit_m Verträglichkeit_M Biosphärische_Werte_M Altruismus_Werte_M 
    Umweltverhalten_M
  /PRINT=TWOTAIL NOSIG FULL
  /STATISTICS DESCRIPTIVES
  /MISSING=PAIRWISE.

*Umkodierung der Bildungsvariable, sodass die Personen die sonstiges eingegeben haben noch zu universität oder maximal matura zugeteilt werden können

COMPUTE EDU_new = 0.
IF EDU = 1 EDU_new = 1.
IF EDU = 2 EDU_new = 2.
IF EDU = 3 EDU_new = 3.
IF EDU = 4 EDU_new = 4.
IF EDU = 5 EDU_new = 5.
IF EDU = 6 EDU_new = 6.
IF id = 91 OR id = 54 EDU_new = 6.
IF id = 89 OR id = 65 EDU_new = 5.
EXECUTE.

* Aufteilung der Bildung in alle bis maximal matura, und alle mit uni oder mehr

RECODE EDU_new (1=0) (2=0) (3=0) (4=0) (5=0) (6=1) INTO EDU_kod.
VARIABLE LABELS  EDU_kod 'sonstige, matura und uni'.
EXECUTE.



*die differenz zwischen start und abgabe berechnen für jede person

DATASET ACTIVATE DataSet1.
COMPUTE time_diff_sec=submitdate - startdate.
VARIABLE LABELS  time_diff_sec 'Zeitdifferenz zwischen start und Abgabe'.
EXECUTE.

*Datensatz sortieren nach bearbeitungszeit 

SORT CASES BY time_diff_sec(A).


*Regression der Hauptmerkmale (ohne explorative Fragestellungen)

REGRESSION
  /DESCRIPTIVES MEAN STDDEV CORR SIG N
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS CI(95) R ANOVA COLLIN TOL ZPP
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT Umweltverhalten_M
  /METHOD=ENTER Gewissenhaftigkeit_m Verträglichkeit_M Biosphärische_Werte_M Altruismus_Werte_M
  /PARTIALPLOT ALL
  /SCATTERPLOT=(*SRESID ,*ZPRED)
  /RESIDUALS DURBIN HISTOGRAM(ZRESID) NORMPROB(ZRESID)
  /CASEWISE PLOT(ZRESID) OUTLIERS(3)
  /SAVE MAHAL COOK LEVER.



* multiple lineare Regressionsanalyse 

REGRESSION
  /DESCRIPTIVES MEAN STDDEV CORR SIG N
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS CI(95) R ANOVA COLLIN TOL ZPP
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT Umweltverhalten_M
  /METHOD=ENTER Gewissenhaftigkeit_m Verträglichkeit_M Biosphärische_Werte_M Altruismus_Werte_M 
    EDU_kod GEN AGE
  /PARTIALPLOT ALL
  /SCATTERPLOT=(*SRESID ,*ZPRED)
  /RESIDUALS DURBIN HISTOGRAM(ZRESID) NORMPROB(ZRESID)
  /CASEWISE PLOT(ZRESID) OUTLIERS(3)
  /SAVE MAHAL COOK LEVER.

*hierarchische Regressionsanalyse (wurde in der Seminararbeit verwendet)

REGRESSION
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS CI(95) R ANOVA COLLIN TOL CHANGE ZPP
  /CRITERIA=PIN(.05) POUT(.10) TOLERANCE(.0001)
  /NOORIGIN 
  /DEPENDENT Umweltverhalten_M
  /METHOD=ENTER Gewissenhaftigkeit_m Verträglichkeit_M Biosphärische_Werte_M Altruismus_Werte_M
  /METHOD=ENTER GEN AGE EDU_kod
  /PARTIALPLOT ALL
  /SCATTERPLOT=(*SRESID ,*ZPRED)
  /RESIDUALS DURBIN HISTOGRAM(ZRESID) NORMPROB(ZRESID)
  /CASEWISE PLOT(ZRESID) OUTLIERS(3)
   /SAVE MAHAL COOK LEVER.

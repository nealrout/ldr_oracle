BEGIN
    INSERT INTO STG_INPUT_01 (FIELD_001, FIELD_002, FIELD_003, FIELD_004, FIELD_005, FIELD_006, FIELD_007) VALUES ('ACCT_NBR_01', 'US_ACCT_01', 'STG_INPUT_01 01421412123124123', TO_CLOB(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF TZR')), '11', 'NOTMAPPED1','US_VA_01');
    INSERT INTO STG_INPUT_01 (FIELD_001, FIELD_002, FIELD_003, FIELD_004, FIELD_005, FIELD_006, FIELD_007) VALUES ('ACCT_NBR_02', 'US_ACCT_02', 'STG_INPUT_01 02', TO_CLOB(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF TZR')), '12', 'NOTMAPPED1','US_VA_01');
    INSERT INTO STG_INPUT_01 (FIELD_001, FIELD_002, FIELD_003, FIELD_004, FIELD_005, FIELD_006, FIELD_007) VALUES ('ACCT_NBR_03', 'US_ACCT_03', 'STG_INPUT_01 03', TO_CLOB(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF TZR')), '13', 'NOTMAPPED1','US_VA_01');
    INSERT INTO STG_INPUT_01 (FIELD_001, FIELD_002, FIELD_003, FIELD_004, FIELD_005, FIELD_006, FIELD_007) VALUES ('ACCT_NBR_04', 'US_ACCT_04', 'STG_INPUT_01 04', TO_CLOB(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF TZR')), '1h1', 'NOTMAPPED1','US_VA_01');
    INSERT INTO STG_INPUT_01 (FIELD_001, FIELD_002, FIELD_003, FIELD_004, FIELD_005, FIELD_006, FIELD_007) VALUES ('ACCT_NBR_05', 'US_ACCT_05', 'STG_INPUT_01 05', TO_CLOB(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF TZR')), '11123', 'NOTMAPPED1','US_NC_01');
    INSERT INTO STG_INPUT_01 (FIELD_001, FIELD_002, FIELD_003, FIELD_004, FIELD_005, FIELD_006, FIELD_007) VALUES ('ACCT_NBR_06', 'US_ACCT_06', 'STG_INPUT_01 06', TO_CLOB(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF TZR')), '14211', 'NOTMAPPED1','US_SC_01');
    INSERT INTO STG_INPUT_01 (FIELD_001, FIELD_002, FIELD_003, FIELD_004, FIELD_005, FIELD_006, FIELD_007) VALUES ('ACCT_NBR_07', 'US_ACCT_07', 'STG_INPUT_01 07', TO_CLOB(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF TZR')), '1c1', 'NOTMAPPED1','US_NC_01');
    INSERT INTO STG_INPUT_01 (FIELD_001, FIELD_002, FIELD_003, FIELD_004, FIELD_005, FIELD_006, FIELD_007) VALUES ('ACCT_NBR_08', 'US_ACCT_08', 'STG_INPUT_01 08', TO_CLOB(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF TZR')), '11124', 'NOTMAPPED1','US_NY_01');
    INSERT INTO STG_INPUT_01 (FIELD_001, FIELD_002, FIELD_003, FIELD_004, FIELD_005, FIELD_006, FIELD_007) VALUES ('ACCT_NBR_09', 'US_ACCT_09', 'STG_INPUT_01 09', TO_CLOB(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF TZR')), '1a1', 'NOTMAPPED1','US_CA_01');
    INSERT INTO STG_INPUT_01 (FIELD_001, FIELD_002, FIELD_003, FIELD_004, FIELD_005, FIELD_006, FIELD_007) VALUES ('ACCT_NBR_10', 'US_ACCT_10', 'STG_INPUT_01 10', TO_CLOB(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF TZR')), '1124241', 'NOTMAPPED1','US_WV_01');
    
    COMMIT;
END;

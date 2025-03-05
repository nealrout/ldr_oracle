BEGIN

    /*************************************************************************************
    *                               ACCOUNT LOAD CONFIG
    *************************************************************************************/
    /* VALIDATE EXECUTES EACH VALIDATION AGAINST THE FIEILD IN THE WHERE CLAUSE.  FOR EXAMPLE BELOW
        WE ARE TESTING THAT FIELD_003 IS LESS THAN 20 CHARACTERS, AND FIELD_005 AND FIELD_007 ARE NUMERIC
        ANY REJECTIONS WILL BE KICKED TO THE ERR_VALIDATION TABLE*/
    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('ACCOUNT', 'VALIDATE', 'STG_INPUT_01', 'ERR_VALIDATION', 
            '{"validations":
                [
                    {"fieldName": "FIELD_003", "validation":"DBMS_LOB.GETLENGTH(STATIC_FIELD_NAME) < 20"}, 
                    {"fieldName": "FIELD_005", "validation":"REGEXP_LIKE(DBMS_LOB.SUBSTR(STATIC_FIELD_NAME, 100, 1), ''^[+-]?\\d+(\\.\\d+)?$'')"},
                    {"fieldName": "FIELD_007", "validation":"REGEXP_LIKE(DBMS_LOB.SUBSTR(STATIC_FIELD_NAME, 100, 1), ''^[+-]?\\d+(\\.\\d+)?$'')"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);

    /* THESE ARE SIMPLE MAPPINGS FROM ONE FIELD TO ANOTHER.  YOU CAN MAP A SINGLE FIELD TO MULTIPLE OUTPUT FIELDS
    WHICH CAN THEN BE MODIFIED IN FUTURE TRANSFORMATIONS*/
    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('ACCOUNT', 'MAP_FIELDS', 'STG_INPUT_01', 'STG_MAP_01', 
            '{"mappings":
                [
                    {"srcField":"FIELD_001","tgtField":"FIELD_001"},
                    {"srcField":"FIELD_002","tgtField":"FIELD_002"},
                    {"srcField":"FIELD_003","tgtField":"FIELD_003"},
                    {"srcField":"FIELD_004","tgtField":"FIELD_004"},
                    {"srcField":"FIELD_005","tgtField":"FIELD_005"},
                    {"srcField":"FIELD_007","tgtField":"FIELD_007"},
                    {"srcField":"FIELD_007","tgtField":"FIELD_008"},
                    {"srcField":"FIELD_007","tgtField":"FIELD_009"},
                    {"srcField":"FIELD_007","tgtField":"FIELD_010"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);

    /* TRANSFORM_INLINE ARE INLINE FUNCTIONS USED IN THE SELECT.  BELOW WE ARE TRIMING, LOWERING, AND TRANSLATING THE FIELD.*/
    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('ACCOUNT', 'TRANSFORM_INLINE', 'STG_MAP_01', 'STG_TRANSFORM_01', 
            '{"transformations":
                [
                    {"fieldName":"FIELD_002","transformation":"TRANSLATE(LOWER(TRIM(STATIC_FIELD_NAME)),''_'',''-'')"},
                    {"fieldName":"FIELD_003","transformation":"TRANSLATE(LOWER(TRIM(STATIC_FIELD_NAME)),''_'',''-'')"},
                    {"fieldName":"FIELD_004","transformation":"TRANSLATE(LOWER(TRIM(STATIC_FIELD_NAME)),''_'',''-'')"},
                    {"fieldName":"FIELD_005","transformation":"TRIM(STATIC_FIELD_NAME)"},
                    {"fieldName":"FIELD_007","transformation":"TRIM(STATIC_FIELD_NAME)"},
                    {"fieldName":"FIELD_008","transformation":"REGEXP_SUBSTR(STATIC_FIELD_NAME, ''^[^_]+'')"},
                    {"fieldName":"FIELD_009","transformation":"REGEXP_SUBSTR(STATIC_FIELD_NAME, ''_([^_]+)_'', 1, 1, NULL, 1)"},
                    {"fieldName":"FIELD_010","transformation":"REGEXP_SUBSTR(STATIC_FIELD_NAME, ''_([^_]+)$'', 1, 1, NULL, 1)"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);

    /* TRANSFORM_AGGREGATE ARE AGGREAGET SUCH AS SUM, COUNT, MAX, ETC.  ANY GROUP BY SHOULD WORK
        THE FIRST FIELD THAT IS GROUPED BY WILL BE USED TO MATCH THE UNIQUEIDENTIFIER WHEN UPDATING .
        BELOW WE ARE GETTING THE COUNT OF FACILITIES PER ACCOUNT.  ACCOUNT IS THE 01 DOMAIN, AND FACILITY IS 02*/
    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('ACCOUNT', 'TRANSFORM_AGGREGATE', 'STG_TRANSFORM_02', 'STG_TRANSFORM_01', 
            '{"transformations":
                [
                    {"fieldName":"FIELD_011"
                    ,"transformation":"SELECT ACCOUNT.FIELD_001, COUNT(*) AS FACILITY_COUNT 
                                        FROM STG_TRANSFORM_02 FACILITY
                                        JOIN STG_TRANSFORM_01 ACCOUNT ON FACILITY.FIELD_002 = ACCOUNT.FIELD_001
                                        GROUP BY ACCOUNT.FIELD_001"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);

    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('ACCOUNT', 'LDR', 'STG_TRANSFORM_01', 'LDR_01', '', SYSTIMESTAMP);

    /*************************************************************************************
    *                               FACILITY LOAD CONFIG
    *************************************************************************************/

    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('FACILITY', 'MAP_FIELDS', 'STG_INPUT_02', 'STG_MAP_02', 
            '{"mappings":
                [
                    {"srcField":"FIELD_001","tgtField":"FIELD_001"},
                    {"srcField":"FIELD_002","tgtField":"FIELD_002"},
                    {"srcField":"FIELD_003","tgtField":"FIELD_003"},
                    {"srcField":"FIELD_004","tgtField":"FIELD_004"},
                    {"srcField":"FIELD_005","tgtField":"FIELD_005"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);

    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('FACILITY', 'TRANSFORM_INLINE', 'STG_MAP_02', 'STG_TRANSFORM_02', 
            '{"transformations":
                [
                    {"fieldName":"FIELD_002","transformation":"TRIM(STATIC_FIELD_NAME)"},
                    {"fieldName":"FIELD_003","transformation":"TRIM(STATIC_FIELD_NAME)"},
                    {"fieldName":"FIELD_004","transformation":"TRIM(STATIC_FIELD_NAME)"},
                    {"fieldName":"FIELD_005","transformation":"TRIM(STATIC_FIELD_NAME)"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);
    COMMIT;

    -- REMOVE CARRIAGE RETURN AND LINE FEED CHARACTERS FROM CONFIG
    UPDATE LOAD_CONFIG SET CONFIG = REPLACE(REPLACE(CONFIG, CHR(13), ''), CHR(10), ' ') ;
    -- REPLACE MULTIPLE SPACES WITH A SINGLE SPACE
    UPDATE LOAD_CONFIG SET CONFIG = REGEXP_REPLACE(CONFIG, ' {2,}', ' ');
    COMMIT;

END;

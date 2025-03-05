BEGIN

    /*************************************************************************************
    *                               ACCOUNT LOAD CONFIG
    *************************************************************************************/

    INSERT INTO LOAD_CONFIG(STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('VALIDATE', 'STG_INPUT_01', 'ERR_VALIDATION', 
            '{"validations":
                [
                    {"fieldName": "FIELD_003", "validation":"DBMS_LOB.GETLENGTH(STATIC_FIELD_NAME) < 20"}, 
                    {"fieldName": "FIELD_005", "validation":"REGEXP_LIKE(DBMS_LOB.SUBSTR(STATIC_FIELD_NAME, 100, 1), ''^[+-]?\\d+(\\.\\d+)?$'')"},
                    {"fieldName": "FIELD_007", "validation":"REGEXP_LIKE(DBMS_LOB.SUBSTR(STATIC_FIELD_NAME, 100, 1), ''^[+-]?\\d+(\\.\\d+)?$'')"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);

    INSERT INTO LOAD_CONFIG(STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('MAP_FIELDS', 'STG_INPUT_01', 'STG_MAP_01', 
            '{"mappings":
                [
                    {"srcField":"FIELD_001","tgtField":"FIELD_001"},
                    {"srcField":"FIELD_002","tgtField":"FIELD_002"},
                    {"srcField":"FIELD_003","tgtField":"FIELD_003"},
                    {"srcField":"FIELD_004","tgtField":"FIELD_004"},
                    {"srcField":"FIELD_005","tgtField":"FIELD_005"},
                    {"srcField":"FIELD_007","tgtField":"FIELD_007"},
                    {"srcField":"FIELD_007","tgtField":"FIELD_008"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);

    INSERT INTO LOAD_CONFIG(STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('TRANSFORM_INLINE', 'STG_MAP_01', 'STG_TRANSFORM_01', 
            '{"transformations":
                [
                    {"fieldName":"FIELD_002","transformation":"TRANSLATE(LOWER(TRIM(STATIC_FIELD_NAME)),''_'',''-'')"},
                    {"fieldName":"FIELD_003","transformation":"TRANSLATE(LOWER(TRIM(STATIC_FIELD_NAME)),''_'',''-'')"},
                    {"fieldName":"FIELD_004","transformation":"TRANSLATE(LOWER(TRIM(STATIC_FIELD_NAME)),''_'',''-'')"},
                    {"fieldName":"FIELD_005","transformation":"TRIM(STATIC_FIELD_NAME)"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);

    /* THE FIELD THAT IS GROUPED BY WILL BE USED TO MATCH THE UNIQUEIDENTIFIER WHEN UPDATING */
    INSERT INTO LOAD_CONFIG(STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('TRANSFORM_AGGREGATE', 'STG_TRANSFORM_02', 'STG_TRANSFORM_01', 
            '{"transformations":
                [
                    {"fieldName":"FIELD_006"
                    ,"transformation":"SELECT ACCOUNT.FIELD_001, COUNT(*) AS FACILITY_COUNT 
                                        FROM STG_TRANSFORM_02 FACILITY
                                        JOIN STG_TRANSFORM_01 ACCOUNT ON FACILITY.FIELD_002 = ACCOUNT.FIELD_001
                                        GROUP BY ACCOUNT.FIELD_001"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);

    /*************************************************************************************
    *                               FACILITY LOAD CONFIG
    *************************************************************************************/

    INSERT INTO LOAD_CONFIG(STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('MAP_FIELDS', 'STG_INPUT_02', 'STG_MAP_02', 
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

    INSERT INTO LOAD_CONFIG(STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('TRANSFORM_INLINE', 'STG_MAP_02', 'STG_TRANSFORM_02', 
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

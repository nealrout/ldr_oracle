BEGIN

    /*************************************************************************************
    *                               ASSET LOAD CONFIG
    *************************************************************************************/

    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, STEP_ORDER, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('ASSET', 'VALIDATE', 3, 'STG_INPUT_03', 'ERR_VALIDATION', 
            '{"validations":
                [
                    {"fieldName": "FIELD_001", "validation":"DBMS_LOB.GETLENGTH(STATIC_FIELD_NAME) < 250"}, 
                    {"fieldName": "FIELD_002", "validation":"DBMS_LOB.GETLENGTH(STATIC_FIELD_NAME) < 250"}, 
                    {"fieldName": "FIELD_003", "validation":"DBMS_LOB.GETLENGTH(STATIC_FIELD_NAME) < 250"},
                    {"fieldName": "FIELD_004", "validation":"DBMS_LOB.GETLENGTH(STATIC_FIELD_NAME) < 250"}
                ],
            "uniqueIdentifier":"FIELD_002"
            }', 
            SYSTIMESTAMP);

    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, STEP_ORDER, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('ASSET', 'MAP_FIELDS', 3, 'STG_INPUT_03', 'STG_MAP_03', 
            '{"mappings":
                [
                    {"srcField":"FIELD_001","tgtField":"FIELD_001"},
                    {"srcField":"FIELD_002","tgtField":"FIELD_002"},
                    {"srcField":"FIELD_003","tgtField":"FIELD_003"},
                    {"srcField":"FIELD_004","tgtField":"FIELD_004"},
                    {"srcField":"FIELD_005","tgtField":"FIELD_005"}
                ],
            "uniqueIdentifier":"FIELD_002"
            }', 
            SYSTIMESTAMP);

    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, STEP_ORDER, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('ASSET', 'TRANSFORM_INLINE', 3, 'STG_MAP_03', 'STG_TRANSFORM_03', 
            '{"transformations":
                [
                    {"fieldName":"FIELD_001","transformation":"UPPER(TRIM(STATIC_FIELD_NAME))"},
                    {"fieldName":"FIELD_002","transformation":"UPPER(TRIM(STATIC_FIELD_NAME))"},
                    {"fieldName":"FIELD_003","transformation":"TRIM(STATIC_FIELD_NAME)"},
                    {"fieldName":"FIELD_004","transformation":"TRIM(STATIC_FIELD_NAME)"},
                    {"fieldName":"FIELD_005","transformation":"TRIM(STATIC_FIELD_NAME)"}
                ],
            "uniqueIdentifier":"FIELD_002"
            }', 
            SYSTIMESTAMP);

    -- INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, STEP_ORDER, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    -- VALUES ('ASSET', 'TRANSFORM_AGGREGATE', 3, 'STG_TRANSFORM_02', 'STG_TRANSFORM_01', 
    --         '{"transformations":
    --             [
    --                 {"fieldName":"FIELD_011"
    --                 ,"transformation":"SELECT ACCOUNT.FIELD_001, COUNT(*) AS FACILITY_COUNT 
    --                                     FROM STG_TRANSFORM_02 FACILITY
    --                                     JOIN STG_TRANSFORM_01 ACCOUNT ON FACILITY.FIELD_002 = ACCOUNT.FIELD_001
    --                                     GROUP BY ACCOUNT.FIELD_001"}
    --             ],
    --         "uniqueIdentifier":"FIELD_002"
    --         }', 
    --         SYSTIMESTAMP);

    /* CONFIGURATION TO DRIVE THE HASH FIELDS ON THE LDR TABLES.  THIS IS HOW WE DETERMINE IF AN "IS_CHANGED" IS FLAGGED */
    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, STEP_ORDER, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('ASSET', 'LDR', 3, 'STG_TRANSFORM_03', 'LDR_03', 
            '{
                "hashColumns":["FIELD_002","FIELD_003","FIELD_004"]
            }
            ', 
            SYSTIMESTAMP);

    /* CONFIGURATION TO DRIVE THE FINAL MAPPING TO THE TARGET TABLE.  THIS IS WHERE WE MAP THE FIELDS TO THE FINAL TABLE */
    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, STEP_ORDER, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('ASSET', 'OUT', 3, 'LDR_03', 'ASSET', 
            '{"mappings":
                [
                    {"srcField":"FIELD_002","tgtField":"ASSET_NBR", "tgtType":"VARCHAR(250)"},
                    {"srcField":"FIELD_003","tgtField":"ASSET_CODE", "tgtType":"VARCHAR(250)"},
                    {"srcField":"FIELD_004","tgtField":"SYS_ID", "tgtType":"VARCHAR(250)"}
                ],
                "uniqueIdentifier":"ASSET_NBR",
                "fkTable":"FACILITY",
                "fkSrcField":"FIELD_001",
                "fkTgtFieldName":"FACILITY_NBR",
                "fkTgtFieldNameId":"FACILITY_ID"
            }
            ', 
            SYSTIMESTAMP);

    COMMIT;

    -- REMOVE CARRIAGE RETURN AND LINE FEED CHARACTERS FROM CONFIG
    UPDATE LOAD_CONFIG SET CONFIG = REPLACE(REPLACE(CONFIG, CHR(13), ''), CHR(10), ' ') ;
    -- REPLACE MULTIPLE SPACES WITH A SINGLE SPACE
    UPDATE LOAD_CONFIG SET CONFIG = REGEXP_REPLACE(CONFIG, ' {2,}', ' ');
    COMMIT;

END;

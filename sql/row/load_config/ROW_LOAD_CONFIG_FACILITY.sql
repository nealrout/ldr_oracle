BEGIN
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

    /* CONFIGURATION TO DRIVE THE HASH FIELDS ON THE LDR TABLES.  THIS IS HOW WE DETERMINE IF AN "IS_CHANGED" IS FLAGGED */
    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('FACILITY', 'LDR', 'STG_TRANSFORM_02', 'LDR_02', 
            '{
                "hashColumns":["FIELD_001","FIELD_002","FIELD_003","FIELD_004","FIELD_005"]
            }
            ', 
            SYSTIMESTAMP);

    /* CONFIGURATION TO DRIVE THE FINAL MAPPING TO THE TARGET TABLE.  THIS IS WHERE WE MAP THE FIELDS TO THE FINAL TABLE */
    INSERT INTO LOAD_CONFIG(ALIAS, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('FACILITY', 'OUT', 'LDR_02', 'FACILITY', 
            '{"mappings":
                [
                    {"srcField":"FIELD_001","tgtField":"FACILITY_NBR", "tgtType":"VARCHAR(250)"},
                    {"srcField":"FIELD_003","tgtField":"FACILITY_CODE", "tgtType":"VARCHAR(250)"},
                    {"srcField":"FIELD_004","tgtField":"FACILITY_NAME", "tgtType":"VARCHAR(250)"}
                ],
                "uniqueIdentifier":"FACILITY_NBR",
                "fkTable":"ACCOUNT",
                "fkSrcField":"FIELD_002",
                "fkTgtField":"ACCOUNT_NBR"
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

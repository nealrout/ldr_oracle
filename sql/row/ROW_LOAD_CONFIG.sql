BEGIN
    INSERT INTO LOAD_CONFIG(STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('VALIDATE', 'STG_INPUT_01', 'ERR_VALIDATION', 
            '{"validations":
                [
                    {"fieldName": "FIELD_003", "validation":"DBMS_LOB.GETLENGTH(STATIC_FIELD_NAME) < 20"}, 
                    {"fieldName": "FIELD_005", "validation":"REGEXP_LIKE(DBMS_LOB.SUBSTR(STATIC_FIELD_NAME, 100, 1), ''^[+-]?\\d+(\\.\\d+)?$'')"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);

    INSERT INTO LOAD_CONFIG(STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
    VALUES ('PROCESS_MAPPED', 'STG_INPUT_01', 'STG_MAP_01', 
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
    COMMIT;
END;

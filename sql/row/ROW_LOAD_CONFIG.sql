BEGIN
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
    VALUES ('VALIDATE', 'STG_INPUT_01', 'ERR_VALIDATION', 
            '{"validations":
                [
                    {"fieldName": "FIELD_003", "validation":"DBMS_LOB.GETLENGTH(FIELD_003) < 20"}, 
                    {"fieldName": "FIELD_005", "validation":"REGEXP_LIKE(DBMS_LOB.SUBSTR(FIELD_005, 100, 1), ''^[+-]?\\d+(\\.\\d+)?$'')"}
                ],
            "uniqueIdentifier":"FIELD_001"
            }', 
            SYSTIMESTAMP);


    COMMIT;
END;

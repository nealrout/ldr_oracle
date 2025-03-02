BEGIN
INSERT INTO LOAD_CONFIG(STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG, CREATE_TS)
VALUES ('PROCESS_MAPPED', 'STG_INPUT_01', 'LDR_01', 
        '{"mappings":
        [
            {"srcField":"FIELD_001","tgtField":"FIELD_001"},
            {"srcField":"FIELD_002","tgtField":"FIELD_002"},
            {"srcField":"FIELD_003","tgtField":"FIELD_003"},
            {"srcField":"FIELD_004","tgtField":"FIELD_004"}
        ],
        "uniqueIdentifier":"FIELD_001"}', 
        SYSTIMESTAMP);

    COMMIT;
END;

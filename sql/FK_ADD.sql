BEGIN
    FOR c IN (SELECT COUNT(*) cnt
              FROM user_constraints
              WHERE constraint_name = 'FK_LOAD_LOG_DETAIL_LOAD_LOG_ID'
              AND table_name = 'LOAD_LOG_DETAIL') LOOP
        IF c.cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE LOAD_LOG_DETAIL
                               ADD CONSTRAINT FK_LOAD_LOG_DETAIL_LOAD_LOG_ID
                               FOREIGN KEY (LOAD_LOG_ID) REFERENCES LOAD_LOG(ID)';
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_LOG_DETAIL_LOAD_LOG_ID has been added.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_LOG_DETAIL_LOAD_LOG_ID already exists.');
        END IF;
    END LOOP;

    FOR c IN (SELECT COUNT(*) cnt
              FROM user_constraints
              WHERE constraint_name = 'FK_LOAD_STATUS_LOAD_LOG_STATUS_CODE'
              AND table_name = 'LOAD_LOG') LOOP
        IF c.cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE LOAD_LOG
                               ADD CONSTRAINT FK_LOAD_STATUS_LOAD_LOG_STATUS_CODE
                               FOREIGN KEY (STATUS_CODE) REFERENCES LOAD_STATUS(STATUS_CODE)';
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_STATUS_LOAD_LOG_STATUS_CODE has been added.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_STATUS_LOAD_LOG_STATUS_CODE already exists.');
        END IF;
    END LOOP;

    FOR c IN (SELECT COUNT(*) cnt
              FROM user_constraints
              WHERE constraint_name = 'FK_LOAD_STATUS_LOAD_LOG_DETAIL_STATUS_CODE'
              AND table_name = 'LOAD_LOG_DETAIL') LOOP
        IF c.cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE LOAD_LOG_DETAIL
                               ADD CONSTRAINT FK_LOAD_STATUS_LOAD_LOG_DETAIL_STATUS_CODE
                               FOREIGN KEY (STATUS_CODE) REFERENCES LOAD_STATUS(STATUS_CODE)';
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_STATUS_LOAD_LOG_DETAIL_STATUS_CODE has been added.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_STATUS_LOAD_LOG_DETAIL_STATUS_CODE already exists.');
        END IF;
    END LOOP;

    FOR c IN (SELECT COUNT(*) cnt
              FROM user_constraints
              WHERE constraint_name = 'FK_LOAD_STEP_LOAD_LOG_DETAIL_STEP_CODE'
              AND table_name = 'LOAD_LOG_DETAIL') LOOP
        IF c.cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE LOAD_LOG_DETAIL
                               ADD CONSTRAINT FK_LOAD_STEP_LOAD_LOG_DETAIL_STEP_CODE
                               FOREIGN KEY (STEP_CODE) REFERENCES LOAD_STEP(STEP_CODE)';
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_STEP_LOAD_LOG_DETAIL_STEP_CODE has been added.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_STEP_LOAD_LOG_DETAIL_STEP_CODE already exists.');
        END IF;
    END LOOP;

    FOR c IN (SELECT COUNT(*) cnt
              FROM user_constraints
              WHERE constraint_name = 'FK_LOAD_CONFIG_LOAD_TYPE_LOAD_TYPE_CODE'
              AND table_name = 'LOAD_CONFIG') LOOP
        IF c.cnt = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE LOAD_CONFIG
                               ADD CONSTRAINT FK_LOAD_CONFIG_LOAD_TYPE_LOAD_TYPE_CODE
                               FOREIGN KEY (STEP_CODE) REFERENCES LOAD_STEP(STEP_CODE)';
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_CONFIG_LOAD_TYPE_LOAD_TYPE_CODE has been added.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_CONFIG_LOAD_TYPE_LOAD_TYPE_CODE already exists.');
        END IF;
    END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_FACILITY_ID_ASSET'
    --           AND table_name = 'ASSET') LOOP
    --     IF c.cnt = 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE asset
    --                            ADD CONSTRAINT fk_facility_id_asset
    --                            FOREIGN KEY (facility_id) REFERENCES facility(id)';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_facility_id_asset has been added.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_facility_id already exists.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_FACILITY_ID_USERFACILITY'
    --           AND table_name = 'USERFACILITY') LOOP
    --     IF c.cnt = 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE userfacility
    --                            ADD CONSTRAINT fk_facility_id_userfacility
    --                            FOREIGN KEY (facility_id) REFERENCES facility(id)';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_facility_id_userfacility has been added.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_facility_id_userfacility already exists.');
    --     END IF;
    -- END LOOP;

    -- -- FOR c IN (SELECT COUNT(*) cnt
    -- --           FROM user_constraints
    -- --           WHERE constraint_name = 'FK_USER_ID'
    -- --           AND table_name = 'USERFACILITY') LOOP
    -- --     IF c.cnt = 0 THEN
    -- --         EXECUTE IMMEDIATE 'ALTER TABLE userfacility
    -- --                            ADD CONSTRAINT fk_user_id
    -- --                            FOREIGN KEY (user_id) REFERENCES auth_user(id)';
    -- --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_user_id has been added.');
    -- --     ELSE
    -- --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_user_id already exists.');
    -- --     END IF;
    -- -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_ASSET_ID'
    --           AND table_name = 'SERVICE') LOOP
    --     IF c.cnt = 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE service
    --                            ADD CONSTRAINT fk_asset_id
    --                            FOREIGN KEY (asset_id) REFERENCES asset(id)';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_asset_id has been added.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_asset_id already exists.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_SERVICE_STATUS_STATUS_CODE'
    --           AND table_name = 'SERVICE') LOOP
    --     IF c.cnt = 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE service
    --                            ADD CONSTRAINT fk_service_status_status_code
    --                            FOREIGN KEY (status_code) REFERENCES service_status(status_code)';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_service_status_status_code has been added.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_service_status_status_code already exists.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_ASSET_STATUS_STATUS_CODE'
    --           AND table_name = 'ASSET') LOOP
    --     IF c.cnt = 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE asset
    --                            ADD CONSTRAINT fk_asset_status_status_code
    --                            FOREIGN KEY (status_code) REFERENCES asset_status(status_code)';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_asset_status_status_code has been added.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_asset_status_status_code already exists.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_INDEX_LOG_STATUS_CODE'
    --           AND table_name = 'INDEX_LOG') LOOP
    --     IF c.cnt = 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE index_log
    --                            ADD CONSTRAINT fk_index_log_status_code
    --                            FOREIGN KEY (status_code) REFERENCES index_status(status_code)';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_index_log_status_code has been added.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_index_log_status_code already exists.');
    --     END IF;
    -- END LOOP;

END;
BEGIN
    FOR c IN (SELECT COUNT(*) cnt
              FROM user_constraints
              WHERE constraint_name = 'FK_LOAD_STATUS_LOAD_LOG_STATUS_CODE'
              AND table_name = 'LOAD_LOG') LOOP
        IF c.cnt > 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE LOAD_LOG DROP CONSTRAINT FK_LOAD_STATUS_LOAD_LOG_STATUS_CODE';
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_STATUS_LOAD_LOG_STATUS_CODE has been dropped.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_STATUS_LOAD_LOG_STATUS_CODE does not exist.');
        END IF;
    END LOOP;

    FOR c IN (SELECT COUNT(*) cnt
              FROM user_constraints
              WHERE constraint_name = 'FK_LOAD_STATUS_LOAD_LOG_DETAIL_STATUS_CODE'
              AND table_name = 'LOAD_LOG_DETAIL') LOOP
        IF c.cnt > 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE LOAD_LOG_DETAIL DROP CONSTRAINT FK_LOAD_STATUS_LOAD_LOG_DETAIL_STATUS_CODE';
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_STATUS_LOAD_LOG_DETAIL_STATUS_CODE has been dropped.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint FK_LOAD_STATUS_LOAD_LOG_DETAIL_STATUS_CODE does not exist.');
        END IF;
    END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_ACCOUNT_ID'
    --           AND table_name = 'FACILITY') LOOP
    --     IF c.cnt > 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE facility DROP CONSTRAINT fk_account_id';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_account_id has been dropped.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_account_id does not exist.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_FACILITY_ID_ASSET'
    --           AND table_name = 'ASSET') LOOP
    --     IF c.cnt > 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE asset DROP CONSTRAINT fk_facility_id_asset';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_facility_id_asset has been dropped.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_facility_id_asset does not exist.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_FACILITY_ID_USERFACILITY'
    --           AND table_name = 'USERFACILITY') LOOP
    --     IF c.cnt > 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE userfacility DROP CONSTRAINT fk_facility_id_userfacility';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_facility_id_userfacility has been dropped.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_facility_id_userfacility does not exist.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_USER_ID'
    --           AND table_name = 'USERFACILITY') LOOP
    --     IF c.cnt > 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE userfacility DROP CONSTRAINT fk_user_id';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_user_id has been dropped.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_user_id does not exist.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_ASSET_ID'
    --           AND table_name = 'SERVICE') LOOP
    --     IF c.cnt > 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE service DROP CONSTRAINT fk_asset_id';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_asset_id has been dropped.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_asset_id does not exist.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_SERVICE_STATUS_STATUS_CODE'
    --           AND table_name = 'SERVICE') LOOP
    --     IF c.cnt > 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE service DROP CONSTRAINT fk_service_status_status_code';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_service_status_status_code has been dropped.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_service_status_status_code does not exist.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_ASSET_STATUS_STATUS_CODE'
    --           AND table_name = 'ASSET') LOOP
    --     IF c.cnt > 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE asset DROP CONSTRAINT fk_asset_status_status_code';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_asset_status_status_code has been dropped.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_asset_status_status_code does not exist.');
    --     END IF;
    -- END LOOP;

    -- FOR c IN (SELECT COUNT(*) cnt
    --           FROM user_constraints
    --           WHERE constraint_name = 'FK_INDEX_LOG_STATUS_CODE'
    --           AND table_name = 'INDEX_LOG') LOOP
    --     IF c.cnt > 0 THEN
    --         EXECUTE IMMEDIATE 'ALTER TABLE index_log DROP CONSTRAINT fk_index_log_status_code';
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_index_log_status_code has been dropped.');
    --     ELSE
    --         DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_index_log_status_code does not exist.');
    --     END IF;
    -- END LOOP;


END;
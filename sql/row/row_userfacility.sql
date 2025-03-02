BEGIN
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM all_tables
        WHERE table_name = 'AUTH_USER' AND owner = 'DAAS'; 
        
        IF v_count > 0 THEN
            EXECUTE IMMEDIATE '
                INSERT INTO userfacility (user_id, facility_id, create_ts)
                SELECT au.id, f.id, SYSTIMESTAMP
                FROM auth_user au
                CROSS JOIN facility f  -- FULL OUTER JOIN equivalent in Oracle using CROSS JOIN
                WHERE 
                    au.username = ''daas''
                    AND NOT EXISTS 
                        (SELECT 1 
                         FROM userfacility uf2
                         JOIN auth_user au2 ON uf2.user_id = au2.id
                         AND uf2.facility_id = f.id
                         AND au2.id = au.id)';
        ELSE
            DBMS_OUTPUT.PUT_LINE('Table auth_user does not exist.');
        END IF;
    END;
END;
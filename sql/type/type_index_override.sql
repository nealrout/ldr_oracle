BEGIN
    -- Drop the types if they exist
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE index_override_table';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE index_override_record';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    -- Create the types
    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE index_override_record AS OBJECT (
            id NUMBER,
            domain VARCHAR2(255),
            index_source_ts TIMESTAMP WITH TIME ZONE,
            index_target_ts TIMESTAMP WITH TIME ZONE
        )';

    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE index_override_table AS TABLE OF index_override_record';
END;
/

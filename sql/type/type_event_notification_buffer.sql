BEGIN
    -- Drop the types if they exist
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE event_notification_buffer_table';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE event_notification_buffer_record';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    -- Create the types
    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE event_notification_buffer_record AS OBJECT (
            id NUMBER,
            channel VARCHAR2(255),
            payload VARCHAR2(255),
            create_ts TIMESTAMP WITH TIME ZONE
        )';

    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE event_notification_buffer_table AS TABLE OF event_notification_buffer_record';
END;
/

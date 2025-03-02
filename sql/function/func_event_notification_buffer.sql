CREATE OR REPLACE FUNCTION get_event_notification_buffer(
    p_channel_name VARCHAR2
) RETURN event_notification_buffer_table PIPELINED
IS
BEGIN
    FOR rec IN (
	    SELECT 
			b.id, b.channel, b.payload, b.create_ts
		FROM 
			event_notification_buffer b
		WHERE
			b.channel = p_channel_name
		ORDER BY
			b.create_ts ASC
    ) LOOP
        PIPE ROW(event_notification_buffer_record(
            rec.id, rec.channel, rec.payload, rec.create_ts
        ));
    END LOOP;
END;
/
CREATE OR REPLACE PROCEDURE clean_event_notification_buffer(
    p_json_in CLOB,
    p_channel VARCHAR2
)
IS
BEGIN
    DELETE FROM event_notification_buffer b
    WHERE EXISTS (
        SELECT 1 
        FROM (
            SELECT b_in.id, b_in.channel, b_in.payload
            FROM event_notification_buffer b_in
            JOIN JSON_TABLE(p_json_in, '$.domain_nbr[*]' 
                COLUMNS (value VARCHAR2(255) PATH '$')) j 
            ON b_in.payload = j.value 
            AND b_in.channel = p_channel
        ) q
        WHERE b.channel = q.channel 
        AND b.payload = q.payload
    );
    
    COMMIT;
END;
/

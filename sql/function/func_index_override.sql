CREATE OR REPLACE FUNCTION get_index_override(
    p_domain VARCHAR2
) RETURN index_override_table PIPELINED
IS
BEGIN
    FOR rec IN (
	    SELECT i.id, i.domain, i.index_source_ts, i.index_target_ts
	    from index_override i
	    WHERE UPPER(i.domain) = UPPER(p_domain)
    ) LOOP
        PIPE ROW(index_override_record(
            rec.id, rec.domain, rec.index_source_ts, rec.index_target_ts
        ));
    END LOOP;
END;
/
CREATE OR REPLACE PROCEDURE clean_index_override(
    p_domain VARCHAR2
)
IS
BEGIN

    INSERT INTO index_override_history (domain, index_source_ts, index_target_ts)
    SELECT i.domain, i.index_source_ts, i.index_target_ts
    FROM index_override i
    WHERE UPPER(i.domain) = UPPER(p_domain);

    DELETE FROM index_override i
    WHERE UPPER(i.domain) = UPPER(p_domain);

    COMMIT; 
END;
/


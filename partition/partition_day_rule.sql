CREATE OR REPLACE FUNCTION almart_partition_trigger()
RETURNS TRIGGER AS $$
DECLARE date_text TEXT;
DECLARE insert_statement TEXT;
BEGIN
	SELECT to_char(NEW.date_key, 'YYYY_MM_DD') INTO date_text;
	insert_statement := 'INSERT INTO almart_'
		|| date_text
		||' VALUES ($1.*)';
	EXECUTE insert_statement USING NEW;
	RETURN NULL;
	EXCEPTION
	WHEN UNDEFINED_TABLE
	THEN
		EXECUTE
			'CREATE TABLE IF NOT EXISTS almart_'
			|| date_text
			|| '(CHECK (date_key = '''
			|| date_text
			|| ''')) INHERITS (almart)';
		RAISE NOTICE 'CREATE NON-EXISTANT TABLE almart_%', date_text;
		EXECUTE
			'CREATE INDEX almart_date_key_'
			|| date_text
			|| ' ON almart_'
			|| date_text
			|| '(date_key)';
		EXECUTE insert_statement USING NEW;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

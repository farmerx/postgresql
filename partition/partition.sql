-- Function: chat_info_table_partition_function()

-- DROP FUNCTION chat_info_table_partition_function();

CREATE OR REPLACE FUNCTION chat_info_table_partition_function()
  RETURNS trigger AS
$BODY$
DECLARE
	_tablename text;
	_enddate text;
BEGIN
	--_tablename := 'chat_'||NEW.chat_time::DATE;   --- 按天分表
	--_tablename := 'chat_'||NEW.chat_time::DATE;   --- 按周分表
  /*
    根据用户user_id 分表
  */
  _tablename := 'father_table'||(abs(cast ((('x'||md5(NEW.user_id))::bit(64)::BIGINT)%100 as char(2))));
  -- 	_tablename := 'tbChatInfor_'||to_char(NEW."Chat_Time", 'YYYY-MM'); --- 按月分表
	-- Check if the partition needed for the current record exists
	PERFORM 1 FROM  pg_catalog.pg_class c
	JOIN   pg_catalog.pg_namespace n ON n.oid = c.relnamespace
	WHERE  c.relkind = 'r'
	AND    c.relname = _tablename;

	IF NOT FOUND THEN
		--_enddate:= NEW.chat_time::DATE + INTERVAL '1 day'; --- 按天分表
		-- _enddate:= NEW.chat_time::DATE + INTERVAL '1 week'; --- 按周分表
		_enddate:= NEW."Chat_Time"::DATE + INTERVAL '1 month'; --- 按月分表
		EXECUTE 'CREATE TABLE ' || quote_ident(_tablename) || '() INHERITS ("father_tatble")';

		-- Table permissions are not inherited from the parent.
		-- If permissions change on the master be sure to change them on the child also.
		EXECUTE 'ALTER TABLE ' || quote_ident(_tablename) || ' OWNER TO admin';
		EXECUTE 'GRANT ALL ON TABLE ' || quote_ident(_tablename) || ' TO admin';

		-- Indexes are defined per child, so we assign a default index that uses the partition columns
		EXECUTE 'CREATE INDEX ' || quote_ident(_tablename||'_uid_idx') || ' ON ' || quote_ident(_tablename) || ' USING btree ("user_id","is_read")';
		EXECUTE 'CREATE INDEX ' || quote_ident(_tablename||'_fid_idx') || ' ON ' || quote_ident(_tablename) || ' USING btree ("friend_id","is_read")';
	END IF;

	-- Insert the current record into the correct partition, which we are sure will now exist.
	EXECUTE 'INSERT INTO ' || quote_ident(_tablename) || ' VALUES ($1.*)' USING NEW;
	RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION chat_info_table_partition_function()
  OWNER TO admin;

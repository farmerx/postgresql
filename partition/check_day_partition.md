## 创建表结构
```
/*
 Navicat Premium Data Transfer

 Source Server         : daxiong
 Source Server Type    : PostgreSQL
 Source Server Version : 90409
 Source Host           : daxiong.liuliu.net
 Source Database       : skylar_audit
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 90409
 File Encoding         : utf-8

 Date: 07/28/2017 10:34:15 AM
*/

-- ----------------------------
--  Table structure for audit_event
-- ----------------------------
DROP TABLE IF EXISTS "public"."audit_event";
CREATE TABLE "public"."audit_event" (
	"id" int4 NOT NULL DEFAULT nextval('audit_event_id_seq'::regclass),
	"sip" inet,
	"terminal" char(255) COLLATE "default",
	"time_event" timestamp(6) NOT NULL DEFAULT now(),
	"event_msg_body" jsonb DEFAULT '{}'::jsonb,
	"tsvector_search" tsvector DEFAULT ''::tsvector,
	"gid" int4 DEFAULT 0
)
WITH (OIDS=FALSE);
ALTER TABLE "public"."audit_event" OWNER TO "postgres";

-- ----------------------------
--  Primary key structure for table audit_event
-- ----------------------------
ALTER TABLE "public"."audit_event" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Indexes structure for table audit_event
-- ----------------------------
CREATE INDEX  "audit_event_gid" ON "public"."audit_event" USING btree(gid "pg_catalog"."int4_ops" ASC NULLS LAST);
CREATE INDEX  "audit_event_sip" ON "public"."audit_event" USING btree(sip "pg_catalog"."inet_ops" ASC NULLS LAST);
CREATE INDEX  "audit_event_terminal" ON "public"."audit_event" USING btree(terminal COLLATE "default" "pg_catalog"."bpchar_ops" ASC NULLS LAST);
CREATE INDEX  "audit_event_time_event" ON "public"."audit_event" USING btree(time_event "pg_catalog"."timestamp_ops" ASC NULLS LAST);
CREATE INDEX  "audit_event_tsvector_search" ON "public"."audit_event" USING gin(tsvector_search "pg_catalog"."tsvector_ops") WITH (FASTUPDATE = NO);

-- ----------------------------
--  Triggers structure for table audit_event
-- ----------------------------
CREATE TRIGGER "auto_insert_into_audit_event_tbl_partiton" BEFORE INSERT ON "public"."audit_event" FOR EACH ROW EXECUTE PROCEDURE "audit_event_partition_trigger"();
COMMENT ON TRIGGER "auto_insert_into_audit_event_tbl_partiton" ON "public"."audit_event" IS NULL;


```
## 创建触发器方法
```
CREATE OR REPLACE FUNCTION audit_event_partition_trigger()
RETURNS TRIGGER AS $$
DECLARE date_text TEXT;
DECLARE end_date_text TEXT;
DECLARE insert_statement TEXT;
BEGIN
	SELECT to_char(NEW.time_event, 'YYYY_MM_DD') INTO date_text;
	SELECT to_char(NEW.time_event + INTERVAL '1 DAY', 'YYYY_MM_DD') INTO end_date_text;
	insert_statement := 'INSERT INTO audit_event_' || date_text || ' VALUES($1.*)';
	EXECUTE insert_statement USING NEW;
	RETURN NULL;
	EXCEPTION
	WHEN UNDEFINED_TABLE
	THEN
		EXECUTE 
			'CREATE TABLE IF NOT EXISTS audit_event_' || date_text || '(CHECK ( time_event >= ''' || date_text || ''' AND  time_event < '''|| end_date_text ||''')) INHERITS (audit_event)';
		RAISE NOTICE 'CREATE NON-EXISTANT TABLE audit_event_%', date_text;
		EXECUTE
			
			
			'CREATE INDEX audit_event_' || date_text || '_tsvector_search ON audit_event_' || date_text || ' USING gin(tsvector_search); ' 
			|| 'CREATE INDEX audit_event_' || date_text || '_sip ON audit_event_' || date_text || ' USING btree(sip);' 
		        || 'CREATE INDEX audit_event_' || date_text || '_gid ON audit_event_' || date_text || ' USING btree(gid);' 
			|| 'CREATE INDEX audit_event_' || date_text || '_terminal ON audit_event_' || date_text || ' USING btree(terminal);' 
			|| 'CREATE INDEX audit_event_' || date_text || '_time_event ON audit_event_' || date_text || ' USING btree(time_event);' ;
		EXECUTE insert_statement USING NEW;
	RETURN NULL;
END;
$$
LANGUAGE plpgsql
```
## 创建触发器
```
create trigger auto_insert_into_audit_event_tbl_partiton 
	BEFORE INSERT ON audit_event FOR EACH ROW
	EXECUTE PROCEDURE audit_event_partition_trigger()
```


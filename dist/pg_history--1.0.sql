/*
=================== ARRAY_EXCEPT =================== 
*/
CREATE FUNCTION array_except ("a" ANYARRAY, "b" ANYARRAY)
    RETURNS ANYARRAY
    AS $$
DECLARE
    "length" CONSTANT INT = array_length("b", 1);
    "index" INT;
BEGIN
    IF "a" IS NULL THEN
        RETURN NULL;
    END IF;
    "index" = 1;
    WHILE "index" <= "length" LOOP
            "a" = array_remove("a","b"["index"]);
            "index" = "index" + 1;
        END LOOP;
    RETURN "a";
END;
$$
LANGUAGE plpgsql
IMMUTABLE;

COMMENT ON FUNCTION array_except (ANYARRAY, ANYARRAY) IS '$1 EXCEPT $2';

CREATE OPERATOR - (
    LEFTARG = ANYARRAY, RIGHTARG = ANYARRAY, FUNCTION = array_except
);

COMMENT ON OPERATOR - (ANYARRAY, ANYARRAY) IS '$1 EXCEPT $2';

/*
=================== GET_PRIMARY_KEY =================== 
*/
CREATE FUNCTION get_primary_key ("relid" OID)
    RETURNS TEXT[]
    AS $$
BEGIN
    -- https://postgresql.org/docs/current/catalog-pg-index.html
    -- https://postgresql.org/docs/current/catalog-pg-attribute.html
    RETURN (
        SELECT array_agg(a."attname")
        FROM "pg_index" i
            INNER JOIN "pg_attribute" a ON i."indrelid" = a."attrelid"
                AND a."attnum" = ANY (i."indkey")
        WHERE i."indrelid" = "relid"
            AND i."indisprimary");
END
$$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

COMMENT ON FUNCTION get_primary_key (OID) IS 'get table primary key columns';

/*
=================== JSONB_EXCEPT =================== 
*/
CREATE FUNCTION jsonb_except ("a" JSONB, "b" JSONB)
    RETURNS JSONB
    AS $$
BEGIN
    RETURN (
        SELECT jsonb_object_agg(key, value)
        FROM (
            SELECT "key", "value"
            FROM jsonb_each("a")
            EXCEPT
            SELECT "key", "value"
            FROM jsonb_each("b")
            ) "table" ("key", "value"));
END;
$$
LANGUAGE plpgsql
IMMUTABLE;

COMMENT ON FUNCTION jsonb_except (JSONB, JSONB) IS '$1 EXCEPT $2';

CREATE OPERATOR - (
    LEFTARG = JSONB, RIGHTARG = JSONB, FUNCTION = jsonb_except
);

COMMENT ON OPERATOR - (JSONB, JSONB) IS '$1 EXCEPT $2';

/*
=================== JSONB_OBJECT_FIELDS =================== 
*/
CREATE FUNCTION jsonb_object_fields ("value" JSONB, "paths" TEXT[])
    RETURNS JSONB
    AS $$
BEGIN
    RETURN "value" - (ARRAY (SELECT jsonb_object_keys("value")) OPERATOR ( @extschema@.- ) "paths");
END
$$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

COMMENT ON FUNCTION jsonb_object_fields (JSONB, TEXT[]) IS 'get json object fields';

CREATE OPERATOR -> (
    LEFTARG = JSONB, RIGHTARG = TEXT[], FUNCTION = jsonb_object_fields
);

COMMENT ON OPERATOR -> (JSONB, TEXT[]) IS 'get json object fields';

/*
=================== JSONB_SET_NULL_FIELDS =================== 
*/
CREATE FUNCTION jsonb_set_null_fields ("value" JSONB, "paths" TEXT[])
    RETURNS JSONB
    AS $$
DECLARE
    "column" TEXT;
BEGIN
    FOREACH "column" IN ARRAY COALESCE("paths", ARRAY []::TEXT[])
    LOOP
        IF "value" ? "column" THEN
            "value" = jsonb_set("value", ARRAY ["column"]::TEXT[], 'null'::JSONB);
        END IF;
    END LOOP;
    RETURN "value";
END
$$
LANGUAGE plpgsql
IMMUTABLE;

COMMENT ON FUNCTION jsonb_set_null_fields (JSONB, TEXT[]) IS 'set json fields to null';

CREATE OPERATOR -/ (
    LEFTARG = JSONB, RIGHTARG = TEXT[], FUNCTION = jsonb_set_null_fields
);

COMMENT ON OPERATOR -/ (JSONB, TEXT[]) IS 'set json fields to null';
/*
=================== DML =================== 
*/
CREATE TYPE DML AS ENUM (
    'INSERT', 'UPDATE', 'DELETE'
    );

COMMENT ON TYPE DML IS 'Data Manipulation Language';
/*
=================== HISTORY =================== 
*/
CREATE TABLE "history"
(
    "primary_key" JSONB
        CONSTRAINT "check_primary_key" CHECK ( ("dml" = 'INSERT' AND "primary_key" IS NULL) OR ("primary_key" IS NOT NULL AND "primary_key" != '{}' AND jsonb_typeof("primary_key") = 'object') ),
    "dml"         @extschema@.DML       NOT NULL,
    "data"        JSONB
        CONSTRAINT "check_data" CHECK ( ("dml" = 'DELETE' AND "data" IS NULL) OR ("data" IS NOT NULL AND "data" != '{}' AND jsonb_typeof("data") = 'object') ),
    "timestamp"   TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE "history" IS 'history table parent';

CREATE RULE "history__insert" AS ON INSERT TO "history"
    DO INSTEAD
    NOTHING;
/*
=================== CREATE_HISTORY_TABLE =================== 
*/
CREATE FUNCTION create_history_table("history_schema" REGNAMESPACE, "table_schema" TEXT, "table_name" TEXT)
    RETURNS REGCLASS
AS
$$
DECLARE
    "target_table_name" CONSTANT TEXT NOT NULL = "table_schema" || '.' || "table_name" || to_char(CURRENT_DATE, '__yyyy_mm');
    "target_table"      CONSTANT TEXT NOT NULL = format('%s.%I', "history_schema", "target_table_name");
BEGIN
    -- https://postgresql.org/docs/current/catalog-pg-class.html
    IF NOT EXISTS(SELECT "relname" FROM pg_class c WHERE c."relnamespace" = "history_schema" AND c."relname" = "target_table_name") THEN
        EXECUTE format('CREATE TABLE %1s() INHERITS (@extschema@."history");
                        CREATE RULE "%2s__update" AS ON UPDATE TO %3s DO INSTEAD NOTHING;
                        CREATE RULE "%4s__delete" AS ON DELETE TO %5s DO INSTEAD NOTHING;',
                       "target_table",
                       "target_table_name", "target_table",
                       "target_table_name", "target_table");
    END IF;

    RETURN "target_table"::REGCLASS;
END
$$
    LANGUAGE plpgsql
    VOLATILE
    RETURNS NULL ON NULL INPUT;

/*
=================== HISTORY_DELETE =================== 
*/
CREATE FUNCTION history_delete("target_table" REGCLASS, "relid" OID, "old_record" JSONB)
    RETURNS JSONB
AS
$$
DECLARE
    "pk_columns"  CONSTANT TEXT[] NOT NULL = @extschema@.get_primary_key("relid");
    "primary_key" CONSTANT JSONB NOT NULL  = "old_record" OPERATOR ( @extschema@.-> ) "pk_columns";
BEGIN
    RETURN @extschema@.insert_into_history("target_table", "primary_key", 'DELETE'::@extschema@.DML, NULL::JSONB);
END
$$
    LANGUAGE plpgsql
    VOLATILE
    RETURNS NULL ON NULL INPUT;

/*
=================== HISTORY_UPDATE =================== 
*/
CREATE FUNCTION history_update("target_table" REGCLASS, "relid" OID, "old_record" JSONB, "new_record" JSONB, "hidden_columns" TEXT[] = NULL)
    RETURNS JSONB
AS
$$
DECLARE
    "pk_columns"             CONSTANT TEXT[] NOT NULL = @extschema@.get_primary_key("relid");
    "primary_key"            CONSTANT JSONB NOT NULL  = "old_record" OPERATOR ( @extschema@.-> ) "pk_columns";
    "chanced_record"         CONSTANT JSONB           = "new_record" OPERATOR ( @extschema@.- ) "old_record";
    "history_chanced_record" CONSTANT JSONB           = "chanced_record" OPERATOR ( @extschema@.-/ ) "hidden_columns";
BEGIN
    IF "history_chanced_record" IS NOT NULL AND "history_chanced_record" != '{}' THEN
        RETURN @extschema@.insert_into_history("target_table", "primary_key", 'UPDATE'::@extschema@.DML, "history_chanced_record");
    END IF;

    RETURN NULL;
END
$$
    LANGUAGE plpgsql
    VOLATILE;

/*
=================== INSERT_INTO_HISTORY =================== 
*/
CREATE FUNCTION insert_into_history("target_table" REGCLASS, "primary_key" JSONB, "dml" @extschema@.DML, "data" JSONB, "timestamp" TIMESTAMP = localtimestamp)
    RETURNS JSONB
AS
$$
DECLARE
    "result" JSONB NOT NULL = '{}';
BEGIN
    EXECUTE format('INSERT INTO %1s ("primary_key", "dml", "data", "timestamp") VALUES (%2L,%3L,%4L,%5L) RETURNING to_json(%1s.*);',
                   "target_table",
                   "primary_key", "dml", "data", "timestamp",
                   "target_table"
        ) INTO "result";

    RETURN "result";
END
$$
    LANGUAGE plpgsql
    VOLATILE;

/*
=================== HISTORY =================== 
*/
CREATE FUNCTION trigger_history()
    RETURNS TRIGGER
AS
$$
DECLARE
    "target_table"    CONSTANT REGCLASS NOT NULL = @extschema@.create_history_table(TG_ARGV[0]::REGNAMESPACE, TG_TABLE_SCHEMA, TG_TABLE_NAME);
    "hidden_columns"  CONSTANT TEXT[]            = TG_ARGV[1];
    "unsaved_columns" CONSTANT TEXT[]            = TG_ARGV[2];
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM @extschema@.insert_into_history("target_table", NULL::JSONB, 'INSERT'::@extschema@.DML, (to_jsonb(NEW) - "unsaved_columns") OPERATOR ( @extschema@.-/ ) "hidden_columns");
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM @extschema@.history_update("target_table", TG_RELID, to_jsonb(OLD) - "unsaved_columns", to_jsonb(NEW) - "unsaved_columns", "hidden_columns");
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM @extschema@.history_delete("target_table", TG_RELID, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END
$$
    LANGUAGE plpgsql
    VOLATILE;


/*
=================== ARRAY_EXCEPT ===================
*/
CREATE FUNCTION @extschema@.array_except ("a" ANYARRAY, "b" ANYARRAY)
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

COMMENT ON FUNCTION @extschema@.array_except (ANYARRAY, ANYARRAY) IS '$1 EXCEPT $2';

CREATE OPERATOR @extschema@.- (
    LEFTARG = ANYARRAY, RIGHTARG = ANYARRAY, FUNCTION = @extschema@.array_except
);

COMMENT ON OPERATOR @extschema@.- (ANYARRAY, ANYARRAY) IS '$1 EXCEPT $2';

/*
=================== GET_PRIMARY_KEY_COLUMNS ===================
*/
CREATE FUNCTION @extschema@.get_primary_key_columns ("relid" OID)
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

COMMENT ON FUNCTION @extschema@.get_primary_key_columns (OID) IS 'get table primary key columns';

/*
=================== JSONB_EXCEPT ===================
*/
CREATE FUNCTION @extschema@.jsonb_except ("a" JSONB, "b" JSONB)
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

COMMENT ON FUNCTION @extschema@.jsonb_except (JSONB, JSONB) IS '$1 EXCEPT $2';

CREATE OPERATOR @extschema@.- (
    LEFTARG = JSONB, RIGHTARG = JSONB, FUNCTION = @extschema@.jsonb_except
);

COMMENT ON OPERATOR @extschema@.- (JSONB, JSONB) IS '$1 EXCEPT $2';

/*
=================== JSONB_OBJECT_FIELDS ===================
*/
CREATE FUNCTION @extschema@.jsonb_object_fields ("value" JSONB, "paths" TEXT[])
    RETURNS JSONB
    AS $$
BEGIN
    RETURN "value" - (ARRAY (SELECT jsonb_object_keys("value")) OPERATOR ( @extschema@.- ) "paths");
END
$$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

COMMENT ON FUNCTION @extschema@.jsonb_object_fields (JSONB, TEXT[]) IS 'get json object fields';

CREATE OPERATOR @extschema@.-> (
    LEFTARG = JSONB, RIGHTARG = TEXT[], FUNCTION = @extschema@.jsonb_object_fields
);

COMMENT ON OPERATOR @extschema@.-> (JSONB, TEXT[]) IS 'get json object fields';

/*
=================== JSONB_SET_NULL_FIELDS ===================
*/
CREATE FUNCTION @extschema@.jsonb_set_null_fields ("value" JSONB, "paths" TEXT[])
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

COMMENT ON FUNCTION @extschema@.jsonb_set_null_fields (JSONB, TEXT[]) IS 'set json fields to null';

CREATE OPERATOR @extschema@.-/ (
    LEFTARG = JSONB, RIGHTARG = TEXT[], FUNCTION = @extschema@.jsonb_set_null_fields
);

COMMENT ON OPERATOR @extschema@.-/ (JSONB, TEXT[]) IS 'set json fields to null';
/*
=================== DML ===================
*/
CREATE TYPE @extschema@.DML AS ENUM (
    'INSERT', 'UPDATE', 'DELETE'
    );

COMMENT ON TYPE @extschema@.DML IS 'Data Manipulation Language';
/*
=================== HISTORY ===================
*/
CREATE TABLE @extschema@."history"
(
    "primary_key" JSONB NOT NULL,
    "dml"         @extschema@.DML NOT NULL,
    "data"        JSONB
        CONSTRAINT "check_data" CHECK ( ("dml" = 'DELETE' AND "data" IS NULL) OR ("data" IS NOT NULL AND "data" != '{}' AND jsonb_typeof("data") = 'object') ),
    "timestamp"   TIMESTAMP NOT NULL DEFAULT localtimestamp
);

COMMENT ON TABLE @extschema@."history" IS 'history table parent';

CREATE RULE "history__insert" AS ON INSERT TO @extschema@."history"
    DO INSTEAD
    NOTHING;
CREATE RULE "history__update" AS ON UPDATE TO @extschema@."history"
    DO INSTEAD
    NOTHING;
CREATE RULE "history__delete" AS ON DELETE TO @extschema@."history"
    DO INSTEAD
    NOTHING;
/*
=================== CREATE_HISTORY_TABLE ===================
*/
CREATE FUNCTION @extschema@.create_history_table("relid" OID, "option" @extschema@.DML, "changed_data" JSONB, "args" VARIADIC TEXT[])
    RETURNS REGCLASS
    AS $$
DECLARE
    "history_schema"         CONSTANT REGNAMESPACE NOT NULL = @extschema@.get_history_schema_name("relid","option", "changed_data", VARIADIC "args")::REGNAMESPACE;
    "target_table_name"      CONSTANT TEXT NOT NULL         = @extschema@.get_history_table_name("relid","option", "changed_data", VARIADIC "args");
    -- %I - вставляется как идентификатора SQL, экранируется при необходимости
    "target_table_full_name" CONSTANT TEXT NOT NULL         = format('%I.%I', "history_schema", "target_table_name");
BEGIN
    -- https://postgresql.org/docs/current/catalog-pg-class.html
    IF NOT EXISTS(SELECT "relname" FROM pg_class c WHERE c."relnamespace" = "history_schema" AND c."relname" = "target_table_name") THEN
        EXECUTE format('CREATE TABLE %1s() INHERITS (@extschema@."history");
                        CREATE RULE "%2s__update" AS ON UPDATE TO %3s DO INSTEAD NOTHING;
                        CREATE RULE "%4s__delete" AS ON DELETE TO %5s DO INSTEAD NOTHING;',
                       "target_table_full_name",
                       "target_table_name", "target_table_full_name",
                       "target_table_name", "target_table_full_name");
    END IF;

    RETURN "target_table_full_name"::REGCLASS;
END
$$
LANGUAGE plpgsql
VOLATILE;
/*
=================== GET_HISTORY_DATA ===================
*/
CREATE FUNCTION @extschema@.get_history_data ("relid" OID, "option" @extschema@.DML, "changed_data" JSONB, "args" VARIADIC TEXT[])
    RETURNS JSONB
    AS $$
DECLARE
    "hidden_columns"  CONSTANT TEXT[] = "args"[0];
    "unsaved_columns" CONSTANT TEXT[] = "args"[1];
BEGIN
    IF "option" = 'DELETE' THEN
        RETURN NULL;
    END IF;

    RETURN ("changed_data" - "unsaved_columns") OPERATOR ( @extschema@.-/ ) "hidden_columns";
END
$$
LANGUAGE plpgsql
IMMUTABLE; -- функция не может модифицировать базу данных и всегда возвращает один и тот же результат
/*
=================== NAMES ===================
*/
CREATE FUNCTION @extschema@.get_history_schema_name ("relid" OID, "option" @extschema@.DML, "changed_data" JSONB, "args" VARIADIC TEXT[])
    RETURNS TEXT
    AS $$
BEGIN
    RETURN 'history';
END
$$
LANGUAGE plpgsql
IMMUTABLE ; -- функция не может модифицировать базу данных и всегда возвращает один и тот же результат

CREATE FUNCTION @extschema@.get_history_table_name ("relid" OID, "option" @extschema@.DML, "changed_data" JSONB, "args" VARIADIC TEXT[])
    RETURNS TEXT
    AS $$
BEGIN
    RETURN (
        -- %s - вставляется как простая строка
        SELECT format('%1s.%2s', n.nspname, c.relname || to_char(CURRENT_DATE, '__yyyy_mm'))
        FROM pg_class c JOIN pg_namespace n on c.relnamespace = n.oid
        WHERE c.oid = "relid");
END
$$
LANGUAGE plpgsql
IMMUTABLE; -- функция не может модифицировать базу данных и всегда возвращает один и тот же результат
/*
=================== HISTORY ===================
*/
CREATE FUNCTION @extschema@.trigger_history()
    RETURNS TRIGGER
    AS $$
DECLARE
    "dml"          CONSTANT @extschema@.DML NOT NULL = TG_OP::@extschema@.DML;
    "new_data"     CONSTANT JSONB               = to_jsonb(NEW);
    "old_data"     CONSTANT JSONB               = to_jsonb(OLD);
    "changed_data" CONSTANT JSONB               = "new_data" OPERATOR ( @extschema@.- ) "old_data";
    "target_table" CONSTANT REGCLASS NOT NULL   = @extschema@.create_history_table(TG_RELID, "dml", "changed_data", VARIADIC TG_ARGV);
    "pk_columns"   CONSTANT TEXT[]   NOT NULL   = @extschema@.get_primary_key_columns(TG_RELID);
    "primary_key"  CONSTANT JSONB    NOT NULL   = COALESCE("old_data", "new_data") OPERATOR ( @extschema@.-> ) "pk_columns";
    "data"         CONSTANT JSONB               = @extschema@.get_history_data(TG_RELID, "dml", "changed_data", VARIADIC TG_ARGV);
BEGIN
    IF "dml" = 'UPDATE' AND ("data" IS NULL OR "data" = '{}'::JSONB) THEN
        RETURN NEW;
    END IF;

    EXECUTE format('INSERT INTO %1s ("dml", "primary_key", "data") VALUES (%2L,%3L,%4L);',
                   "target_table",
                   "dml", "primary_key", "data"
        );
    RETURN NEW;
END
$$
LANGUAGE plpgsql
VOLATILE;

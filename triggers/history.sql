CREATE OR REPLACE FUNCTION history.trigger_history()
    RETURNS TRIGGER
AS
$$
DECLARE
    "old_record"        CONSTANT JSONB                 = to_jsonb(OLD); -- for UPDATE & DELETE - NOT NULL
    "pk_columns"        CONSTANT TEXT[] NOT NULL       = get_primary_key(TG_RELID);
    "primary_key"       CONSTANT JSONB                 = "old_record" -> "pk_columns"; -- for UPDATE & DELETE - NOT NULL
    "new_record"        CONSTANT JSONB NOT NULL        = to_jsonb(NEW);
    "columns"           CONSTANT TEXT[] NOT NULL       = TG_ARGV[1];
    "chanced_record"    CONSTANT JSONB                 = ("new_record" - "old_record") -> "columns";
    --
    "history_schema"    CONSTANT REGNAMESPACE NOT NULL = TG_ARGV[0];
    "target_table_name" CONSTANT TEXT NOT NULL         = TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || to_char(CURRENT_DATE, '__yyyy_mm');
    "target_table"      CONSTANT TEXT NOT NULL         = format('%s.%I', "history_schema", "target_table_name");
    "sql"               CONSTANT TEXT NOT NULL         = 'INSERT INTO %s ("primary_key", "dml", "data", "timestamp") VALUES (%L,%L,%L,%L);';
BEGIN
    -- https://postgresql.org/docs/current/catalog-pg-class.html
    IF NOT EXISTS(SELECT "relname" FROM pg_class c WHERE c."relnamespace" = "history_schema" AND c."relname" = "target_table_name") THEN
        EXECUTE format('CREATE TABLE %s() INHERITS ("history");', "target_table");
    END IF;

    IF TG_OP = 'INSERT' THEN
        -- RAISE EXCEPTION USING MESSAGE =
        EXECUTE format("sql", "target_table", "primary_key", 'INSERT', "new_record", NOW());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF "chanced_record" IS NOT NULL THEN
            EXECUTE format("sql", "target_table", "primary_key", 'UPDATE', "chanced_record", NOW());
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        EXECUTE format("sql", "target_table", "primary_key", 'DELETE', "old_record", NOW());
        RETURN OLD;
    END IF;
END
$$
    LANGUAGE plpgsql
    VOLATILE
    SECURITY DEFINER;


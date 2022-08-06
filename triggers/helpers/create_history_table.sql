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
        EXECUTE format('CREATE TABLE %1s() INHERITS ("history");
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


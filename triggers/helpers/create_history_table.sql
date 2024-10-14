CREATE FUNCTION public.create_history_table("relid" OID, "option" public.DML, "change_data" JSONB, "args" VARIADIC TEXT[])
    RETURNS REGCLASS
    AS $$
DECLARE
    "history_schema"         CONSTANT REGNAMESPACE NOT NULL = public.get_history_schema_name("relid","option", "change_data", VARIADIC "args")::REGNAMESPACE;
    "target_table_name"      CONSTANT TEXT NOT NULL         = public.get_history_table_name("relid","option", "change_data", VARIADIC "args");
    -- %I - вставляется как идентификатора SQL, экранируется при необходимости
    "target_table_full_name" CONSTANT TEXT NOT NULL         = format('%I.%I', "history_schema", "target_table_name");
BEGIN
    -- https://postgresql.org/docs/current/catalog-pg-class.html
    IF NOT EXISTS(SELECT "relname" FROM pg_class c WHERE c."relnamespace" = "history_schema" AND c."relname" = "target_table_name") THEN
        EXECUTE format('CREATE TABLE %1s() INHERITS (public."history");
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

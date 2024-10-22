CREATE FUNCTION public.trigger_history()
    RETURNS TRIGGER
    AS $$
DECLARE
    "dml"          CONSTANT public.DML NOT NULL = TG_OP::public.DML;
    "new_data"     CONSTANT JSONB               = to_jsonb(NEW);
    "old_data"     CONSTANT JSONB               = to_jsonb(OLD);
    "changed_data" CONSTANT JSONB               = "new_data" OPERATOR ( public.- ) "old_data";
    "target_table" CONSTANT REGCLASS NOT NULL   = public.create_history_table(TG_RELID, "dml", "changed_data", VARIADIC TG_ARGV);
    "pk_columns"   CONSTANT TEXT[]   NOT NULL   = public.get_primary_key_columns(TG_RELID);
    "primary_key"  CONSTANT JSONB    NOT NULL   = COALESCE("old_data", "new_data") OPERATOR ( public.-> ) "pk_columns";
    "data"         CONSTANT JSONB               = public.get_history_data(TG_RELID, "dml", "changed_data", VARIADIC TG_ARGV);
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

CREATE FUNCTION public.trigger_history()
    RETURNS TRIGGER
AS
$$
DECLARE
    "target_table"    CONSTANT REGCLASS NOT NULL = public.create_history_table(TG_ARGV[0]::REGNAMESPACE, TG_TABLE_SCHEMA, TG_TABLE_NAME);
    "hidden_columns"  CONSTANT TEXT[]            = TG_ARGV[1];
    "unsaved_columns" CONSTANT TEXT[]            = TG_ARGV[2];
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM public.insert_into_history("target_table", NULL::JSONB, 'INSERT'::public.DML, (to_jsonb(NEW) - "unsaved_columns") OPERATOR ( public.-/ ) "hidden_columns");
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM public.history_update("target_table", TG_RELID, to_jsonb(OLD) - "unsaved_columns", to_jsonb(NEW) - "unsaved_columns", "hidden_columns");
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM public.history_delete("target_table", TG_RELID, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END
$$
    LANGUAGE plpgsql
    VOLATILE;


CREATE FUNCTION trigger_history()
    RETURNS TRIGGER
AS
$$
DECLARE
    "target_table"   CONSTANT REGCLASS NOT NULL = create_history_table(TG_ARGV[0]::REGNAMESPACE, TG_TABLE_SCHEMA, TG_TABLE_NAME);
    "columns"        CONSTANT TEXT[]            = TG_ARGV[1];
    "hidden_columns" CONSTANT TEXT[]            = TG_ARGV[2];
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM insert_into_history("target_table", NULL::JSONB, 'INSERT'::DML, to_jsonb(NEW) -/ "hidden_columns");
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM history_update("target_table", TG_RELID, to_jsonb(OLD), to_jsonb(NEW), "columns", "hidden_columns");
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM history_delete("target_table", TG_RELID, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END
$$
    LANGUAGE plpgsql
    VOLATILE;


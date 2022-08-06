CREATE FUNCTION history_update("target_table" REGCLASS, "relid" OID, "old_record" JSONB, "new_record" JSONB, "hidden_columns" TEXT[] = NULL)
    RETURNS JSONB
AS
$$
DECLARE
    "pk_columns"             CONSTANT TEXT[] NOT NULL = get_primary_key("relid");
    "primary_key"            CONSTANT JSONB NOT NULL  = "old_record" -> "pk_columns";
    "chanced_record"         CONSTANT JSONB           = "new_record" - "old_record";
    "history_chanced_record" CONSTANT JSONB           = "chanced_record" -/ "hidden_columns";
BEGIN
    IF "history_chanced_record" IS NOT NULL AND "history_chanced_record" != '{}' THEN
        RETURN insert_into_history("target_table", "primary_key", 'UPDATE'::DML, "history_chanced_record");
    END IF;

    RETURN NULL;
END
$$
    LANGUAGE plpgsql
    VOLATILE;


CREATE OR REPLACE FUNCTION history_update("target_table" REGCLASS, "relid" OID, "old_record" JSONB, "new_record" JSONB, "columns" TEXT[] = NULL)
    RETURNS JSONB
AS
$$
DECLARE
    "pk_columns"             CONSTANT TEXT[] NOT NULL = get_primary_key("relid");
    "primary_key"            CONSTANT JSONB NOT NULL  = "old_record" -> "pk_columns";
    "chanced_record"         CONSTANT JSONB           = "new_record" - "old_record";
    "history_chanced_record" CONSTANT JSONB           = CASE WHEN ("columns" IS NOT NULL) THEN "chanced_record" -> "columns" ELSE "chanced_record" END;
BEGIN
    IF "history_chanced_record" IS NOT NULL THEN
        RETURN insert_into_history("target_table", "primary_key", 'UPDATE'::DML, "history_chanced_record");
    END IF;

    RETURN NULL;
END
$$
    LANGUAGE plpgsql
    VOLATILE;


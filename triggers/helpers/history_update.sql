CREATE FUNCTION public.history_update("target_table" REGCLASS, "relid" OID, "old_record" JSONB, "new_record" JSONB, "hidden_columns" TEXT[] = NULL)
    RETURNS JSONB
AS
$$
DECLARE
    "pk_columns"             CONSTANT TEXT[] NOT NULL = public.get_primary_key("relid");
    "primary_key"            CONSTANT JSONB NOT NULL  = "old_record" OPERATOR ( public.-> ) "pk_columns";
    "chanced_record"         CONSTANT JSONB           = "new_record" OPERATOR ( public.- ) "old_record";
    "history_chanced_record" CONSTANT JSONB           = "chanced_record" OPERATOR ( public.-/ ) "hidden_columns";
BEGIN
    IF "history_chanced_record" IS NOT NULL AND "history_chanced_record" != '{}' THEN
        RETURN public.insert_into_history("target_table", "primary_key", 'UPDATE'::public.DML, "history_chanced_record");
    END IF;

    RETURN NULL;
END
$$
    LANGUAGE plpgsql
    VOLATILE;


CREATE FUNCTION public.history_delete("target_table" REGCLASS, "relid" OID, "old_record" JSONB)
    RETURNS JSONB
AS
$$
DECLARE
    "pk_columns"  CONSTANT TEXT[] NOT NULL = public.get_primary_key("relid");
    "primary_key" CONSTANT JSONB NOT NULL  = "old_record" OPERATOR ( public.-> ) "pk_columns";
BEGIN
    RETURN public.insert_into_history("target_table", "primary_key", 'DELETE'::public.DML, NULL::JSONB);
END
$$
    LANGUAGE plpgsql
    VOLATILE
    RETURNS NULL ON NULL INPUT;


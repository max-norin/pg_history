CREATE FUNCTION history_delete("target_table" REGCLASS, "relid" OID, "old_record" JSONB)
    RETURNS JSONB
AS
$$
DECLARE
    "pk_columns"  CONSTANT TEXT[] NOT NULL = get_primary_key("relid");
    "primary_key" CONSTANT JSONB NOT NULL  = "old_record" -> "pk_columns";
BEGIN
    RETURN insert_into_history("target_table", "primary_key", 'DELETE'::DML, NULL::JSONB);
END
$$
    LANGUAGE plpgsql
    VOLATILE
    RETURNS NULL ON NULL INPUT;


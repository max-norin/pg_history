CREATE FUNCTION insert_into_history("target_table" REGCLASS, "primary_key" JSONB, "dml" @extschema@.DML, "data" JSONB, "timestamp" TIMESTAMP = localtimestamp)
    RETURNS JSONB
AS
$$
DECLARE
    "result" JSONB NOT NULL = '{}';
BEGIN
    EXECUTE format('INSERT INTO %1s ("primary_key", "dml", "data", "timestamp") VALUES (%2L,%3L,%4L,%5L) RETURNING to_json(%1s.*);',
                   "target_table",
                   "primary_key", "dml", "data", "timestamp",
                   "target_table"
        ) INTO "result";

    RETURN "result";
END
$$
    LANGUAGE plpgsql
    VOLATILE;


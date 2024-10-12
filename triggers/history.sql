CREATE FUNCTION public.trigger_history()
    RETURNS TRIGGER
AS
$$
DECLARE
    "target_table"    CONSTANT REGCLASS NOT NULL   = public.create_history_table(TG_RELID);
    "hidden_columns"  CONSTANT TEXT[]              = TG_ARGV[0];
    "unsaved_columns" CONSTANT TEXT[]              = TG_ARGV[1];
    "pk_columns"      CONSTANT TEXT[] NOT NULL     = public.get_primary_key(TG_RELID);
    "dml"             CONSTANT public.DML NOT NULL = TG_OP::public.DML;
    "primary_key"              JSONB;
    "data"                     JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        "primary_key" = to_jsonb(NEW) OPERATOR ( public.-> ) "pk_columns";
        "data" = public.get_history_data(to_jsonb(NEW), "unsaved_columns", "hidden_columns");
        --"data" = to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        "primary_key" = to_jsonb(OLD) OPERATOR ( public.-> ) "pk_columns";
        "data"  = public.get_history_data(to_jsonb(NEW) OPERATOR ( public.- ) to_jsonb(OLD), "unsaved_columns", "hidden_columns");
    ELSIF TG_OP = 'DELETE' THEN
        "primary_key" = to_jsonb(OLD) OPERATOR ( public.-> ) "pk_columns";
    ELSE
        -- TODO вызвать ошибку
    END IF;

    EXECUTE format('INSERT INTO %1s ("primary_key", "dml", "data") VALUES (%2L,%3L,%4L);',
                   "target_table",
                   "primary_key", "dml", "data"
        );
    RETURN NEW;
END
$$
    LANGUAGE plpgsql
    VOLATILE;


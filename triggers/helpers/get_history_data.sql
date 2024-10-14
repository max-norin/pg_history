CREATE FUNCTION public.get_history_data ("relid" OID, "option" public.DML, "changed_data" JSONB, "args" VARIADIC TEXT[])
    RETURNS JSONB
    AS $$
DECLARE
    "hidden_columns"  CONSTANT TEXT[] = "args"[0];
    "unsaved_columns" CONSTANT TEXT[] = "args"[1];
BEGIN
    IF "option" = 'DELETE' THEN
        RETURN NULL;
    END IF;

    RETURN ("changed_data" - "unsaved_columns") OPERATOR ( public.-/ ) "hidden_columns";
END
$$
LANGUAGE plpgsql
IMMUTABLE; -- функция не может модифицировать базу данных и всегда возвращает один и тот же результат

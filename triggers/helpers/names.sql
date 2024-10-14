CREATE FUNCTION public.get_history_schema_name ("relid" OID, "option" public.DML, "changed_data" JSONB, "args" VARIADIC TEXT[])
    RETURNS TEXT
    AS $$
BEGIN
    RETURN 'history';
END
$$
LANGUAGE plpgsql
IMMUTABLE ; -- функция не может модифицировать базу данных и всегда возвращает один и тот же результат

CREATE FUNCTION public.get_history_table_name ("relid" OID, "option" public.DML, "changed_data" JSONB, "args" VARIADIC TEXT[])
    RETURNS TEXT
    AS $$
BEGIN
    RETURN (
        -- %s - вставляется как простая строка
        SELECT format('%1s.%2s', n.nspname, c.relname || to_char(CURRENT_DATE, '__yyyy_mm'))
        FROM pg_class c JOIN pg_namespace n on c.relnamespace = n.oid
        WHERE c.oid = "relid");
END
$$
LANGUAGE plpgsql
IMMUTABLE; -- функция не может модифицировать базу данных и всегда возвращает один и тот же результат

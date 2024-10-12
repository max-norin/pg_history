CREATE FUNCTION public.get_history_schema_name ("relid" OID)
    RETURNS TEXT
    AS $$
BEGIN
    RETURN 'history';
END
$$
LANGUAGE plpgsql
STABLE -- функция не может модифицировать базу данных и всегда возвращает один и тот же результат при определённых значениях аргументов внутри одного SQL запроса
RETURNS NULL ON NULL INPUT; -- функция всегда возвращает NULL, получив NULL в одном из аргументов

CREATE FUNCTION public.get_history_table_name ("relid" OID)
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
    STABLE -- функция не может модифицировать базу данных и всегда возвращает один и тот же результат при определённых значениях аргументов внутри одного SQL запроса
    RETURNS NULL ON NULL INPUT; -- функция всегда возвращает NULL, получив NULL в одном из аргументов

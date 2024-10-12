CREATE FUNCTION public.jsonb_except ("a" JSONB, "b" JSONB)
    RETURNS JSONB
    AS $$
BEGIN
    RETURN (
        SELECT jsonb_object_agg(key, value)
        FROM (
            SELECT "key", "value"
            FROM jsonb_each("a")
            EXCEPT
            SELECT "key", "value"
            FROM jsonb_each("b")
            ) "table" ("key", "value"));
END;
$$
LANGUAGE plpgsql
IMMUTABLE;

COMMENT ON FUNCTION public.jsonb_except (JSONB, JSONB) IS '$1 EXCEPT $2';

CREATE OPERATOR public.- (
    LEFTARG = JSONB, RIGHTARG = JSONB, FUNCTION = public.jsonb_except
);

COMMENT ON OPERATOR public.- (JSONB, JSONB) IS '$1 EXCEPT $2';


CREATE FUNCTION public.jsonb_set_null_fields ("value" JSONB, "paths" TEXT[])
    RETURNS JSONB
    AS $$
DECLARE
    "column" TEXT;
BEGIN
    FOREACH "column" IN ARRAY COALESCE("paths", ARRAY []::TEXT[])
    LOOP
        IF "value" ? "column" THEN
            "value" = jsonb_set("value", ARRAY ["column"]::TEXT[], 'null'::JSONB);
        END IF;
    END LOOP;
    RETURN "value";
END
$$
LANGUAGE plpgsql
IMMUTABLE;

COMMENT ON FUNCTION public.jsonb_set_null_fields (JSONB, TEXT[]) IS 'set json fields to null';

CREATE OPERATOR public.-/ (
    LEFTARG = JSONB, RIGHTARG = TEXT[], FUNCTION = public.jsonb_set_null_fields
);

COMMENT ON OPERATOR public.-/ (JSONB, TEXT[]) IS 'set json fields to null';

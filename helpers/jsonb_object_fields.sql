CREATE FUNCTION public.jsonb_object_fields ("value" JSONB, "paths" TEXT[])
    RETURNS JSONB
    AS $$
BEGIN
    RETURN "value" - (ARRAY (SELECT jsonb_object_keys("value")) OPERATOR ( public.- ) "paths");
END
$$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

COMMENT ON FUNCTION public.jsonb_object_fields (JSONB, TEXT[]) IS 'get json object fields';

CREATE OPERATOR public.-> (
    LEFTARG = JSONB, RIGHTARG = TEXT[], FUNCTION = public.jsonb_object_fields
);

COMMENT ON OPERATOR public.-> (JSONB, TEXT[]) IS 'get json object fields';


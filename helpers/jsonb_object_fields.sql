CREATE FUNCTION public.jsonb_object_fields ("value" JSONB, "paths" TEXT[])
    RETURNS JSONB
    AS $$
BEGIN
    RETURN "value" - (public.jsonb_object_keys_to_array("value") OPERATOR ( public.- ) "paths");
END
$$
LANGUAGE plpgsql
IMMUTABLE;

COMMENT ON FUNCTION public.jsonb_object_fields (JSONB, TEXT[]) IS 'get json object fields';

CREATE OPERATOR public.-> (
    LEFTARG = JSONB, RIGHTARG = TEXT[], FUNCTION = public.jsonb_object_fields
);

COMMENT ON OPERATOR public.-> (JSONB, TEXT[]) IS 'get json object fields';


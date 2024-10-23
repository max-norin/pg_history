CREATE FUNCTION public.jsonb_object_keys_to_array ("value" JSONB)
    RETURNS TEXT[]
    AS $$
BEGIN
    RETURN ARRAY (SELECT jsonb_object_keys("value"));
END
$$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE FUNCTION public.get_history_data("obj" JSONB, "drop_properties" TEXT[], "hidden_properties" TEXT[])
    RETURNS JSONB
AS
$$
BEGIN
    RETURN  ("obj" - "drop_properties") OPERATOR ( public.-/ ) "hidden_properties";
END
$$
    LANGUAGE plpgsql
    IMMUTABLE;

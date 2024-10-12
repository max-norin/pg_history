CREATE TYPE public.DML AS ENUM (
    'INSERT', 'UPDATE', 'DELETE'
    );

COMMENT ON TYPE public.DML IS 'Data Manipulation Language';

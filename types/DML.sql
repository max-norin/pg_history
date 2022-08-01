CREATE TYPE DML AS ENUM (
    'INSERT', 'UPDATE', 'DELETE'
    );

COMMENT ON TYPE DML IS 'Data Manipulation Language';

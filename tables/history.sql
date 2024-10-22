CREATE TABLE public."history"
(
    "primary_key" JSONB NOT NULL,
    "dml"         public.DML NOT NULL,
    "data"        JSONB
        CONSTRAINT "check_data" CHECK ( ("dml" = 'DELETE' AND "data" IS NULL) OR ("data" IS NOT NULL AND "data" != '{}' AND jsonb_typeof("data") = 'object') ),
    "timestamp"   TIMESTAMP NOT NULL DEFAULT localtimestamp
);

COMMENT ON TABLE public."history" IS 'history table parent';

CREATE RULE "history__insert" AS ON INSERT TO public."history"
    DO INSTEAD
    NOTHING;
CREATE RULE "history__update" AS ON UPDATE TO public."history"
    DO INSTEAD
    NOTHING;
CREATE RULE "history__delete" AS ON DELETE TO public."history"
    DO INSTEAD
    NOTHING;

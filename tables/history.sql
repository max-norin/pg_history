CREATE TABLE "history"
(
    "primary_key" JSONB
        CONSTRAINT "check_primary_key" CHECK ( ("dml" = 'INSERT' AND "primary_key" IS NULL) OR ("primary_key" IS NOT NULL AND "primary_key" != '{}' AND jsonb_typeof("primary_key") = 'object') ),
    "dml"         DML       NOT NULL,
    "data"        JSONB
        CONSTRAINT "check_data" CHECK ( ("dml" = 'DELETE' AND "data" IS NULL) OR ("data" IS NOT NULL AND "data" != '{}' AND jsonb_typeof("data") = 'object') ),
    "timestamp"   TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE "history" IS '';

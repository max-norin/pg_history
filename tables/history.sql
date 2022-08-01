CREATE TABLE "history"
(
    "primary_key" JSONB,
    "dml"         DML       NOT NULL,
    "data"        JSONB     NOT NULL, -- TODO ADD CHECKS
    "timestamp"   TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE "history" IS '';

-- TODO REFERENCE ON UPDATE CASCADE ???

CREATE TABLE "users"
(
    "id"         SERIAL PRIMARY KEY,
    "nickname"   VARCHAR(255) NOT NULL UNIQUE,
    "password"   VARCHAR(255) NOT NULL,
    "created_at" TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('{ password }', '{ created_at }');

CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history();

INSERT INTO users("nickname","password") VALUES ('max', '123');
UPDATE users SET password = '321' WHERE id = 1;
UPDATE users SET password = '312' WHERE id = 1;
DELETE FROM users WHERE id = 1;

CREATE TABLE "users"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(255) NOT NULL UNIQUE,
    "password" VARCHAR(255) NOT NULL
);

CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('history', '{ id, nickname, password }', '{ password }');

CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('history');



INSERT INTO "users"("nickname")
VALUES ('test8');

UPDATE "users"
SET ("id", "nickname") = ROW (0, '7test')
WHERE "nickname" = '7test';

DELETE
FROM "users"
WHERE "nickname" = 'test';


SELECT *
FROM history."public.users__2022_08";

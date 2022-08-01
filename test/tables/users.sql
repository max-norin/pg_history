CREATE TABLE "users"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(255) NOT NULL UNIQUE
);

CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('history', '{id,nickname}');



INSERT INTO "users"("nickname")
VALUES ('test');

UPDATE "users"
SET ("id", "nickname") = ROW (0, 'test')
WHERE "nickname" = '_test';

DELETE
FROM "users"
WHERE "nickname" = 'test';


SELECT *
FROM history."public.users__2022_08";

CREATE TABLE "public"."posts"
(
    "id"      SERIAL PRIMARY KEY,
    "user_id" INTEGER NOT NULL REFERENCES users ("id") ON UPDATE CASCADE,
    "title"   TEXT    NOT NULL
);

CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('history', '{id,user_id,title}');



INSERT INTO "posts" (user_id, title)
VALUES (1, 'title');

SELECT *
FROM history."public.posts__2022_08";


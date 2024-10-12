CREATE TABLE posts
(
    "id"      SERIAL PRIMARY KEY,
    "user_id" INTEGER NOT NULL REFERENCES users ("id") ON UPDATE CASCADE,
    "title"   TEXT    NOT NULL
);

CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON posts
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history();



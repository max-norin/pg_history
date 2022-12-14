# pg_history

> The extension allows storing the history of data changes.

[README in Russian](./README.ru.md)

## Getting Started

### Install

Download the files from [dist](./dist) to your `extension` folder PostgreSQL and run the following commands.

Create a new schema for convenience.

```postgresql
CREATE SCHEMA "history";
ALTER ROLE "postgres" SET search_path TO "public", "history";
```

Install the extension.

```postgresql
CREATE EXTENSION "pg_history"
    SCHEMA "history"
    VERSION '1.0';
```

[More about the extension and the control file](https://www.postgresql.org/docs/current/extend-extensions.html)

### Example table `history."public.users__2022_08"`

| \# | primary_key | dml    | data                                             | timestamp                  |
| -- | ----------- | ------ | ------------------------------------------------ | -------------------------- |
| 1  |             | INSERT | {"id": 4, "nickname": "Max", "password": null}   | 2022-08-06 12:18:02.613552 |
| 2  | {"id": 4}   | UPDATE | {"nickname": "Max N"}                            | 2022-08-06 12:18:13.486149 |
| 3  | {"id": 4}   | UPDATE | {"nickname": "Max NM", "password": null}         | 2022-08-06 12:18:20.433618 |
| 4  | {"id": 4}   | DELETE |                                                  | 2022-08-06 12:18:22.118845 |

### Usage

To store data changes, you need to add a `trigger_history()` trigger from the extension to the table.

```postgresql
CREATE TRIGGER history
  AFTER INSERT OR UPDATE OR DELETE
  ON users
  FOR EACH ROW
EXECUTE PROCEDURE trigger_history('history');
-- OR
CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('history', '{ password }');
-- OR
CREATE TRIGGER history
  AFTER INSERT OR UPDATE OR DELETE
  ON users
  FOR EACH ROW
EXECUTE PROCEDURE trigger_history('history', '{ password }', '{ created_at, updated_at }');
```

Function `trigger_history("history_schema" TEXT[, "hidden_columns" TEXT[] = NULL][, "unsaved_columns" TEXT = NULL])`, where:

- `"history_schema"` a schema where a table will be created to store the history of changes, inherited from the `"history"` table;
- `"hidden_columns"` array of columns that values cannot be saved;
- `"unsaved_columns"` array of columns that cannot be saved.


## Files

- `helpers/*.sql` helper functions
    - [array_except](./helpers/array_except.sql)
    - [get_columns](./helpers/get_columns.sql)
    - [get_primary_key](./helpers/get_primary_key.sql)
    - [jsonb_except](./helpers/jsonb_except.sql)
    - [jsonb_object_fields](./helpers/jsonb_object_fields.sql)
    - [jsonb_set_null_fields](./helpers/jsonb_set_null_fields.sql)
- [types/DML.sql](./types/DML.sql) Data Manipulation Language
- [tables/history.sql](./tables/history.sql) parent table for change history
- `triggers/*.sql`
    - [helpers](./triggers/helpers) trigger helper functions
    - [history](triggers/history.sql)
- [test/*.sql](./test) test files

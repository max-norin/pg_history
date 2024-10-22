# pg_history

100% works on PostgreSQL version 16, I didn't check the rest.
If you have any information that works on earlier versions, please let me know.

> Extension for PostgreSQL, allowing storing history of data changes

[README in Russian](./README.ru.md)

# Installation

## Classic

Download the files from [dist](./dist) and move them to the `extension`
folder of the PostgreSQL application.
For windows, the folder can be located in
`C:\Program Files\PostgreSQL\16\share\extension`.
Next, run the following commands.

Create the new schema for convenience.

```sql
CREATE SCHEMA "history";
ALTER ROLE "postgres" SET search_path TO "public", "history";
```

Install the extension.

```sql
CREATE EXTENSION "pg_history"
    SCHEMA "history"
    VERSION '2.0';
```

[Learn more about an extension and control file](https://postgrespro.ru/docs/postgresql/current/extend-extensions)

# Example table `history."public.users__2022_08"`

| \# | primary_key | dml    | data                                           | timestamp                  |
|----|-------------|--------|------------------------------------------------|----------------------------|
| 1  | {"id": 4}   | INSERT | {"id": 4, "nickname": "Max", "password": null} | 2022-08-06 12:18:02.613552 |
| 2  | {"id": 4}   | UPDATE | {"nickname": "Max N"}                          | 2022-08-06 12:18:13.486149 |
| 3  | {"id": 4}   | UPDATE | {"nickname": "Max NM", "password": null}       | 2022-08-06 12:18:20.433618 |
| 4  | {"id": 4}   | DELETE |                                                | 2022-08-06 12:18:22.118845 |

# Usage

To store data changes, you need to add a `trigger_history()` trigger from the extension to the table.

```postgresql
CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history();
-- OR
CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('{ password }');
-- OR
CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('{ password }', '{ created_at, updated_at }');
```

Function `trigger_history("hidden_columns" TEXT[] = NULL, "unsaved_columns" TEXT = NULL)`, where:

- `"hidden_columns"` array of columns that values cannot be saved;
- `"unsaved_columns"` array of columns that cannot be saved.

# Advanced Usage

During trigger execution, functions are called that you can override for your tasks.

- `get_history_schema_name()` - function that returns the table schema for storing the change history.
  By default, `"history"`.
- `get_history_table_name()` - function that returns the name of the table for storing the change history.
  By default, `"public.users__2022_08"`.
- `create_history_table()` - function that creates a new table for storing the change history.
  By default, a new table is created every month.
- `get_history_data()` - function that returns a jsonb object of data that will be stored in the change history.
  By default, a function is specified that has the ability to null out columns (`"hidden_columns"`) and
  delete columns (`"unsaved_columns"`).

All functions accept the following parameters:

- `"relid" OID` - the table in which the trigger fired.
- `"option" DML` - the action that caused the trigger (`INSERT`, `UPDATE`, `DELETE`).
- `"changed_data" JSONB` - changed table data.
- `"args" VARIADIC TEXT[]` - arguments passed to the trigger when created.

More details about the functions can be found in the [./triggers/helpers](./triggers/helpers) folder.

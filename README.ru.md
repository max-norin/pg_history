# pg_history

> Расширение для хранения истории изменения данных

## Основное

### Установка

Скачайте себе в папку `extension` PostgreSQL файлы из [dist](./dist) и выполните следующие команды.

Создайте новую схему для удобства.

```postgresql
CREATE SCHEMA "history";
ALTER ROLE "postgres" SET search_path TO "public", "history";
```

Установите расширение.

```postgresql
CREATE EXTENSION "pg_history"
    SCHEMA "history"
    VERSION '1.0';
```

### Пример таблицы `history."public.users__2022_08"`

| \# | primary_key | dml    | data                                             | timestamp                  |
| -- | ----------- | ------ | ------------------------------------------------ | -------------------------- |
| 1  |             | INSERT | {"id": 4, "nickname": "Max", "password": null}   | 2022-08-06 12:18:02.613552 |
| 2  | {"id": 4}   | UPDATE | {"nickname": "Max N"}                            | 2022-08-06 12:18:13.486149 |
| 3  | {"id": 4}   | UPDATE | {"nickname": "Max NM", "password": null}         | 2022-08-06 12:18:20.433618 |
| 4  | {"id": 4}   | DELETE |                                                  | 2022-08-06 12:18:22.118845 |

### Использование

Чтобы хранить изменения данных, нужно к таблице добавить триггер `trigger_history()` из расширения.

```postgresql
CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('history', '{ id, nickname, password }', '{ password }');
-- ИЛИ
CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('history');
-- ИЛИ
CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('history', get_columns('users'::REGCLASS) - ARRAY ['id', 'created_at', 'updated_at']::TEXT[]);
```

Функция `trigger_history("history_schema" TEXT[, "columns" TEXT[] = NULL][, "hidden_columns" TEXT = NULL])`, где:

- `"history_schema"` схема, где будет создана таблица для хранения истории изменений, наследованная от таблицы "history";
- `"columns"` массив колонок, которые будут записаны при обновлении;
- `"hidden_columns"` массив колонок, значение которых хранить нельзя.

Функция `get_columns("relid" OID)` возвращает массив колонок таблицы `"relid"`.

## Файлы

- `helpers/*.sql` вспомогательные функции
    - [array_except](./helpers/array_except.sql)
    - [get_columns](./helpers/get_columns.sql)
    - [get_primary_key](./helpers/get_primary_key.sql)
    - [jsonb_except](./helpers/jsonb_except.sql)
    - [jsonb_object_fields](./helpers/jsonb_object_fields.sql)
    - [jsonb_set_null_fields](./helpers/jsonb_set_null_fields.sql)
- [types/DML.sql](./types/DML.sql) язык управления (манипулирования) данными
- [tables/history.sql](./tables/history.sql) родительская таблица для истории изменений
- `triggers/*.sql`
    - [helpers](./triggers/helpers) вспомогательные функции триггеров
    - [history](triggers/history.sql)
- [test/*.sql](./test) тестовые файлы

## Полезное

- [Pseudotypes](https://www.postgresql.org/docs/current/datatype-pseudo.html)
- [Functions with Variable Numbers of Arguments](https://www.postgresql.org/docs/current/xfunc-sql.html#XFUNC-SQL-VARIADIC-FUNCTIONS)
- [Object Identifier Types](https://www.postgresql.org/docs/current/datatype-oid.html#DATATYPE-OID-TABLE)

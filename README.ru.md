# pg_history

> Расширение для PostgreSQL, позволяющее хранения историю изменения данных

# Установка

## Классическая

Скачайте файлы из [dist](./dist) и переместите их в папку `extension`
приложения PostgreSQL. Для windows папка может располагаться в
`C:\Program Files\PostgreSQL\16\share\extension`.
Далее выполните следующие команды.

Создайте новую схему для удобства.

```sql
CREATE SCHEMA "history";
ALTER ROLE "postgres" SET search_path TO "public", "history";
```

Установите расширение.

```sql
CREATE EXTENSION "pg_history"
    SCHEMA "history"
    VERSION '2.0';
```

[Подробнее про расширение и файл control](https://postgrespro.ru/docs/postgresql/current/extend-extensions)

## Обходной путь

Если нет возможности добавить расширение в PostgreSQL, то есть другой вариант.
Скопировать в текстовый редактор содержание файлов с расширением `.sql`
из [dist](./dist). Заменить выражение `@extschema@` на схему,
в которую будет добавлены необходимые функции, например `abstract`.
Скопировать в консоль PostgreSQL и запустить.

# Пример таблицы `history."public.users__2022_08"`

| \# | primary_key | dml    | data                                           | timestamp                  |
|----|-------------|--------|------------------------------------------------|----------------------------|
| 1  | {"id": 4}   | INSERT | {"id": 4, "nickname": "Max", "password": null} | 2022-08-06 12:18:02.613552 |
| 2  | {"id": 4}   | UPDATE | {"nickname": "Max N"}                          | 2022-08-06 12:18:13.486149 |
| 3  | {"id": 4}   | UPDATE | {"nickname": "Max NM", "password": null}       | 2022-08-06 12:18:20.433618 |
| 4  | {"id": 4}   | DELETE |                                                | 2022-08-06 12:18:22.118845 |

# Использование

Чтобы хранить изменения данных, нужно к таблице добавить триггер `trigger_history()` из расширения.

```postgresql
CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history();
-- ИЛИ
CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('{ password }');
-- ИЛИ
CREATE TRIGGER history
    AFTER INSERT OR UPDATE OR DELETE
    ON users
    FOR EACH ROW
EXECUTE PROCEDURE trigger_history('{ password }', '{ created_at, updated_at }');
```

Функция `trigger_history("hidden_columns" TEXT[] = NULL, "hidden_columns" TEXT = NULL)`, где:

- `"hidden_columns"` массив колонок, значение которых хранить нельзя;
- `"unsaved_columns"` массив колонок, которых хранить нельзя.

# Расширенное использование

Во время выполнения триггера вызываются функции, которые вы можете переопределить под свои задачи.

- `get_history_schema_name()` - функция возвращающая схему таблицы для хранения истории изменений.
  По умолчанию `"history"`.
- `get_history_table_name()` - функция возвращающая название таблицы для хранения истории изменений.
  По умолчанию `"public.users__2022_08"`.
- `create_history_table()` - функция создания новой таблицы для хранения истории изменений.
  По умолчанию каждый месяц создается новая таблица.
- `get_history_data()` - функция возвращающая jsonb объект данных, которые будут храниться в истории изменений.
  По умолчанию указана функция, которая имеет возможность обнулять колонки (`"hidden_columns"`) и
  удалять колонки (`"unsaved_columns"`).

Все функции принимают следующие параметры:

- `"relid" OID` - таблица, в которой сработал триггер.
- `"option" DML` - действие, которое вызвало триггер (`INSERT`, `UPDATE`, `DELETE`).
- `"changed_data" JSONB` - измененные данные таблицы.
- `"args" VARIADIC TEXT[]` - аргументы переданные в триггер при создании.

Подробнее с функциями можно ознакомиться в папке [./triggers/helpers](./triggers/helpers).

# Полезное

- [Pseudotypes](https://www.postgresql.org/docs/current/datatype-pseudo.html)
- [Functions with Variable Numbers of Arguments](https://www.postgresql.org/docs/current/xfunc-sql.html#XFUNC-SQL-VARIADIC-FUNCTIONS)
- [Object Identifier Types](https://www.postgresql.org/docs/current/datatype-oid.html#DATATYPE-OID-TABLE)

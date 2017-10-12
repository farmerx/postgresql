# pg_trgm 使用笔记
------

## About pg_trgm
> pg_trgm模块提供函数和操作符测定字母数字文本基于三元模型匹配的相似性， 还有支持快速搜索相似字符串的索引操作符类。

## 开启pg_trgm
`CREATE EXTENSION IF NOT EXISTS pg_trgm;`

## pg_trgm 索引支持
> pg_trgm模块提供GiST和GIN索引操作符类， 该操作符类允许你为了非常快速的相似性搜索在文本字段上创建一个索引。 这些索引类型支持上面描述的相似性操作符，并且额外支持基于三元模型的索引搜索： LIKE， ILIKE，~ 和 ~*查询。 （这些索引并不支持相等也不支持简单的比较操作符，所以你可能也需要一个普通的B-tree索引。）

示例：
```
CREATE TABLE test_trgm (t text);
CREATE INDEX trgm_idx ON test_trgm USING gist (t gist_trgm_ops);
```
或
```
CREATE INDEX trgm_idx ON test_trgm USING gin (t gin_trgm_ops);
```

## 封装添加pg_trgm索引方法

```
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE OR REPLACE FUNCTION create_gin_trgm_index_if_not_exists(table_name text, column_names anyarray, unique_str text, index_type text) RETURNS void AS $BODY$
DECLARE
  full_index_name varchar;
  schema_name varchar;
BEGIN
full_index_name = table_name || '_' || array_to_string(column_names, '_') || '_idx';
full_index_name = replace(full_index_name, ' ', '');
schema_name     = 'public';
IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = full_index_name
    AND    n.nspname = schema_name
    ) THEN
    execute 'CREATE ' || unique_str || ' INDEX ' || full_index_name || ' ON ' || schema_name || '.' || table_name || ' USING '|| index_type ||' (' || array_to_string(column_names, ',') || ' gin_trgm_ops) ';
END IF;
END
$BODY$ LANGUAGE plpgsql;

```

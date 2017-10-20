# 百万数据巧妙获取count近似值
------

## postgresql软肋-count
> 在9.2以前全表的count只能通过扫描全表来得到, 即使有pk也必须扫描全表. 
9.2版本增加了index only scan的功能, count(*)可以通过仅仅扫描pk就可以得到. 
但是如果是一个比较大的表, pk也是很大的, 扫描pk也是个不小的开销. 

## 思考如下问题
  * count会扫一遍数据，然后取数据又会扫描一遍数据，重复劳动
  
## 问题解决
  * 问题一优化：
      使用评估行数，方法如下
      创建一个函数，从explain中抽取返回的记录数
      
```sql
CREATE FUNCTION count_estimate(query text) RETURNS INTEGER AS
$$
DECLARE
    rec   record;
    ROWS  INTEGER;
BEGIN
    FOR rec IN EXECUTE 'EXPLAIN ' || query LOOP
        ROWS := SUBSTRING(rec."QUERY PLAN" FROM ' rows=([[:digit:]]+)');
        EXIT WHEN ROWS IS NOT NULL;
    END LOOP;

    RETURN ROWS;
END
$$ 
LANGUAGE plpgsql;
```

> 评估的行数和实际的行数相差不大，精度和柱状图有关。 
PostgreSQL autovacuum进程会根据表的数据量变化比例自动对表进行统计信息的更新。
而且可以配置表级别的统计信息更新频率以及是否开启更新。

```
postgres=# select count_estimate('select * from sbtest1 where id between 100 and 100000');
 count_estimate 
----------------
         102166
(1 row)

postgres=# explain select * from sbtest1 where id between 100 and 100000;
                                      QUERY PLAN                                       
---------------------------------------------------------------------------------------
 Index Scan using sbtest1_pkey on sbtest1  (cost=0.43..17398.14 rows=102166 width=190)
   Index Cond: ((id >= 100) AND (id <= 100000))
(2 rows)

postgres=# select count(*) from sbtest1 where id between 100 and 100000;
 count 
-------
 99901
(1 row)
```

> 这样做就不需要扫描表了，性能提升尤为可观。

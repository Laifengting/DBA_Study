# 查询出指定库和指定表中的所有索引使用情况
SELECT *
    FROM `sys`.`schema_index_statistics`
    WHERE `table_schema` NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND `table_schema` = 'bzbh'
      AND `table_name` = 'orders';
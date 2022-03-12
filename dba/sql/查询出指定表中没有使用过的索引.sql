# 查询出指定表中没有使用过的索引
SELECT *
    FROM `sys`.`schema_unused_indexes`
    WHERE `object_schema` NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND `object_name` = 'orders';
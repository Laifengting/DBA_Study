# 索引字段过多(多于3个)
SELECT `database_name`, `table_name`, `index_name`, COUNT(*)
    FROM `mysql`.`innodb_index_stats`
    WHERE `database_name` NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
      AND `stat_name` NOT IN ('size', 'n_leaf_pages')
    GROUP BY `database_name`, `table_name`, `index_name`
    HAVING COUNT(*) - 1 > 3;
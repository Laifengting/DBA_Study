# 查询出索引过多的自定库表
SELECT `database_name`, `table_name`, COUNT(*)
    FROM `mysql`.`innodb_index_stats`
    WHERE `database_name` NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
      AND `stat_description` = 'Number of pages in the index'
    GROUP BY `database_name`, `table_name`
    HAVING COUNT(*) > 6;
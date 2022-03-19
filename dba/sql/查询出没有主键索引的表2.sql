# 查询出没有主键索引的表
SELECT `table_schema`, `table_name`
    FROM (
         SELECT `c`.`table_schema`, `c`.`table_name`, CASE WHEN `column_key` = 'PRI' THEN 1 ELSE 0 END AS `pk_flag`
             FROM (
                  SELECT `table_schema`, `table_name`
                      FROM `information_schema`.`columns`
                      WHERE `table_schema` NOT IN ('information_schema', 'mysql', 'sys', 'performance_schema')
                        AND `ordinal_position` = 1
                        AND `column_key` != 'PRI') `t`,
                  `information_schema`.`columns`   `c`
             WHERE `t`.`table_schema` = `c`.`table_schema` AND `t`.`table_name` = `c`.`table_name`) `i`
    GROUP BY `table_schema`, `table_name`
    HAVING SUM(`pk_flag`) = 0;
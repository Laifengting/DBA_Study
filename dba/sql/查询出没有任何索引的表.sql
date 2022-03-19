# 查询出没有任何索引的表
SELECT `t`.`table_schema`, `t`.`table_name`, `t`.`table_type`, `s`.`index_name`, `s`.`index_type`
    FROM `information_schema`.`tables`              `t`
        LEFT JOIN `information_schema`.`statistics` `s`
                      ON `t`.`table_schema` = `s`.`table_schema`
                          AND `t`.`table_name` = `s`.`table_name`
    WHERE `t`.`table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
      AND `table_type` = 'BASE TABLE'
      AND `s`.`index_name` IS NULL;
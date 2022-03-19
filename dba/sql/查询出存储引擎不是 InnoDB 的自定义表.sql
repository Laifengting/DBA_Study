#### 查询出存储引擎不是 Innodb 的自定义的表
SELECT `table_schema`, `table_name`, `engine`, `sys`.`format_bytes`(`data_length`) AS `data_size`
    FROM `information_schema`.`tables`
    WHERE `engine` <> 'InnoDB'
      AND `table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema');
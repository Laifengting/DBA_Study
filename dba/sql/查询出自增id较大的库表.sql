# 查询出自增id较大的库表
SELECT `tbl`.`table_schema`, `tbl`.`table_name`, `tbl`.`auto_increment`, `col`.`column_type`
    FROM `information_schema`.`tables`      `tbl`
        JOIN `information_schema`.`columns` `col`
                 ON `tbl`.`table_schema` = `col`.`table_schema` AND `tbl`.`table_name` = `col`.`table_name`
    WHERE `tbl`.`table_schema` NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
      AND `extra` = 'auto_increment'
      AND `col`.`column_type` LIKE 'int%)'
      AND `tbl`.`auto_increment` > 1500000000
UNION
SELECT `tbl`.`table_schema`, `tbl`.`table_name`, `tbl`.`auto_increment`, `col`.`column_type`
    FROM `information_schema`.`tables`      `tbl`
        JOIN `information_schema`.`columns` `col`
                 ON `tbl`.`table_schema` = `col`.`table_schema` AND `tbl`.`table_name` = `col`.`table_name`
    WHERE `tbl`.`table_schema` NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
      AND `extra` = 'auto_increment'
      AND `col`.`column_type` LIKE 'int%unsigned'
      AND `tbl`.`auto_increment` > 3500000000;
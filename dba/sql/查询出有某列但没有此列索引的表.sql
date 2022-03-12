# mysql 查询出有某列但没有此列索引的表
SELECT `col`.`table_schema` AS `db_name`, `col`.`table_name`, `col`.`column_name`
    FROM `information_schema`.`columns`             `col`
        LEFT JOIN (
                  # 修改为要查询的字段名
                  SELECT 'age' `column_name`)       `query_col`
                      ON `col`.`column_name` = `query_col`.`column_name`
        LEFT JOIN `information_schema`.`statistics` `sta`
                      ON `col`.`table_schema` = `sta`.`table_schema`
                          AND `col`.`table_name` = `sta`.`table_name`
                          AND `col`.`column_name` = `sta`.`column_name`
        # 修改为要查询的表
    WHERE `col`.`table_schema` IN ('bzbh')
      AND `query_col`.`column_name` IS NOT NULL
      AND `sta`.`seq_in_index` IS NULL;

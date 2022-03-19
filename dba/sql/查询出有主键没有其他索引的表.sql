# 查询出有主键没有其他索引的表
SELECT `t`.`table_schema`, `t`.`table_name`, `t`.`table_type`, `s`.`index_name`, `s`.`index_type`
    FROM `information_schema`.`tables`              `t`
        LEFT JOIN `information_schema`.`statistics` `s`
                      ON `t`.`table_schema` = `s`.`table_schema`
                          AND `t`.`table_name` = `s`.`table_name`
    WHERE `t`.`table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
      AND `t`.`table_name` IN (
                              SELECT `s2`.`table_name`
                                  FROM `information_schema`.`statistics` `s2`
                                  WHERE `s2`.`index_name` = 'PRIMARY')
      AND `t`.`table_name` NOT IN (
                                  SELECT `s3`.`table_name`
                                      FROM `information_schema`.`statistics` `s3`
                                      WHERE `s3`.`index_name` <> 'PRIMARY');
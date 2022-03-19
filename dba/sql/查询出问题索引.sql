# 找出可能创建的索引是问题索引
# information_schema.STATISTICS.CARDINALITY / information_schema.TABLES.TABLE_ROWS < 10% 的可以认为是问题索引
SELECT CONCAT(`s`.`table_schema`, '.', `s`.`table_name`) AS `tbl_name`,
       `s`.`index_name`,
       `s`.`cardinality`,
       `t`.`table_rows`,
       (`s`.`cardinality` / `t`.`table_rows`)            AS `selectivity`
    FROM `information_schema`.`statistics`      `s`
        LEFT JOIN `information_schema`.`tables` `t`
                      ON `t`.`table_schema` = `s`.`table_schema`
                          AND `t`.`table_name` = `s`.`table_name`
    WHERE (`s`.`cardinality` / `t`.`table_rows`) < 0.1
      AND `t`.`table_rows` != 0
      AND `s`.`seq_in_index` = 1
      AND `s`.`table_schema` NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
    ORDER BY `selectivity`;
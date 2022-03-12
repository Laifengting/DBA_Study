# 查询出大表
SELECT `table_schema`,
       `table_name`,
       ROUND(SUM(`data_length` + `index_length`) / 1024 / 1024 / 1024, 1) AS `data_size_gb`,
       ROUND(`data_free` / 1024 / 1024, 1)                                AS `chip_size_mb`
    FROM `information_schema`.`tables`
    GROUP BY `table_schema`,
             `table_name`,
             `chip_size_mb`
    HAVING `data_size_gb` > 0
    ORDER BY `data_size_gb` DESC;
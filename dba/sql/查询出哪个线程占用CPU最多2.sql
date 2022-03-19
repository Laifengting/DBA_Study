# sys.session 表中也能看到部分 # 检查出系统中哪个线程占用CPU最多。是执行的什么语句
SELECT `s`.`thd_id`,
       `s`.`conn_id`,
       `s`.`user`,
       `s`.`db`,
       `s`.`command`,
       `s`.`time`,
       `s`.`current_statement`,
       `s`.`statement_latency`,
       `s`.`lock_latency`
    FROM `sys`.`session` `s`
    WHERE `db` NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
    ORDER BY `time` DESC;
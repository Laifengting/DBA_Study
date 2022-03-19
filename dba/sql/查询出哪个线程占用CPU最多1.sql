# 检查出系统中哪个线程占用CPU最多。是执行的什么语句
SELECT `t`.`name`,
       `t`.`type`,
       `t`.`thread_os_id`,
       `t`.`processlist_id`,
       `t`.`processlist_user`,
       `t`.`processlist_host`,
       `t`.`processlist_db`,
       `t`.`processlist_command`,
       `t`.`processlist_time`,
       `t`.`processlist_state`,
       `t`.`processlist_info`,
       `p`.`rows_sent`,
       `p`.`rows_examined`
    FROM `performance_schema`.`threads`              `t`
        LEFT JOIN `information_schema`.`processlist` `p`
                      ON `t`.`processlist_id` = `p`.`id`
    WHERE `t`.`processlist_db` NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
    ORDER BY `t`.`processlist_time` DESC;
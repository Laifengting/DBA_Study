## 查看所有线程的所在会话的隔离级别
SELECT `vbt`.`thread_id`,
       `vbt`.`variable_name`,
       `vbt`.`variable_value`,
       `t`.`name`,
       `t`.`type`,
       `t`.`processlist_id`,
       `t`.`processlist_user`,
       `t`.`processlist_host`,
       `t`.`processlist_db`,
       `t`.`processlist_command`,
       `t`.`processlist_time`,
       `t`.`processlist_state`,
       `t`.`processlist_info`,
       `t`.`connection_type`,
       `t`.`thread_os_id`
    FROM `performance_schema`.`variables_by_thread` `vbt`
        LEFT JOIN `performance_schema`.`threads`    `t`
                      ON `vbt`.`thread_id` = `t`.`thread_id`
    WHERE `vbt`.`variable_name` = 'transaction_isolation';
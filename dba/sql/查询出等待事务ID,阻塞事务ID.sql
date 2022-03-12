# 查询出等待事务ID，等待的线程，等待的查询优化语句，阻塞的事务ID，阻塞的线程，阻塞的查询
SELECT `r`.`trx_id`              AS `waiting_trx_id`,
       `r`.`trx_mysql_thread_id` AS `waiting_thread`,
       `r`.`trx_query`           AS `waiting_query`,
       `b`.`trx_id`              AS `blocking_trx_id`,
       `b`.`trx_mysql_thread_id` AS `blocking_thread`,
       `b`.`trx_query`           AS `blocking_query`
    FROM `sys`.`innodb_lock_waits`                   `w`
        INNER JOIN `information_schema`.`innodb_trx` `b`
                       ON `b`.`trx_id` = `w`.`blocking_trx_id`
        INNER JOIN `information_schema`.`innodb_trx` `r`
                       ON `r`.`trx_id` = `w`.`waiting_trx_id`;

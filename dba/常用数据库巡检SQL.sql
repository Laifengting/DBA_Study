#### 建库语句
CREATE DATABASE `test` /*!40100 DEFAULT CHARACTER SET `utf8mb4` DEFAULT COLLATE `utf8mb4_general_ci` */;

#### 建表语句1
CREATE TABLE `db_name`.`tbl_name` (
    `id`           INT AUTO_INCREMENT     NOT NULL COMMENT '主键',
    `name`         VARCHAR(100)           NOT NULL COMMENT '姓名',
    `age`          INT UNSIGNED           NOT NULL COMMENT '年龄',
    `created_time` DATETIME DEFAULT NOW() NOT NULL COMMENT '创建时间',
    `updated_time` DATETIME DEFAULT NOW() NOT NULL COMMENT '修改时间',
    CONSTRAINT `pk_id` PRIMARY KEY (`id`))
    ENGINE = InnoDB
    DEFAULT CHARSET = `utf8mb4`
    COLLATE = `utf8mb4_general_ci`
    AUTO_INCREMENT = 333333;

#### 创建索引
CREATE INDEX `idx_id_name_age_date` USING BTREE ON `db_name`.`tbl_name` (`id`, `age`, `name`, `created_time`, `updated_time`);

#### 建表语句2
CREATE TABLE `db_name`.`tbl_name` (
    `id`           INT(11)          NOT NULL AUTO_INCREMENT COMMENT '主键',
    `name`         VARCHAR(100)     NOT NULL COMMENT '姓名',
    `age`          INT(10) UNSIGNED NOT NULL COMMENT '年龄',
    `created_time` DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time` DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_id_name_age_date` (`id`, `age`, `name`, `created_time`, `updated_time`) USING BTREE)
    ENGINE = InnoDB
    AUTO_INCREMENT = 333333
    DEFAULT CHARSET = `utf8mb4`;

#### 查询出存储引擎不是 Innodb 的自定义的表
SELECT `table_schema`, `table_name`, `engine`, `sys`.`format_bytes`(`data_length`) AS `data_size`
    FROM `information_schema`.`tables`
    WHERE `engine` <> 'InnoDB'
      AND `table_schema` NOT IN ('mysql');

#       AND `table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema');

#### 查询出字符集不是 utf8mb4 的定义义的表
SELECT `table_schema`, `table_name`, `column_name`, `character_set_name`
    FROM `information_schema`.`columns`
    WHERE `character_set_name` <> 'utf8mb4'
      AND `table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys');

#### 查询出字符集不是 utf8mb4 的定义义的表（优化）
SELECT CONCAT(`table_schema`, '.', `table_name`)   AS `tbl_name`,
       `character_set_name`,
       GROUP_CONCAT(`column_name` SEPARATOR ' : ') AS `column_list`
    FROM `information_schema`.`columns`
    WHERE `data_type` IN ('varchar', 'longtext', 'text', 'mediumtext', 'char')
      AND `character_set_name` <> 'utf8mb4'
      AND `table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
    GROUP BY `tbl_name`, `character_set_name`;

#### 仅将表字符集改为 utf8mb4，以后新增的列是 utf8mb4，但原有的列的字符集并未改变。
ALTER TABLE `db_name`.`tbl_name`
    CHARSET = `utf8mb4`;

#### 修改表默认字符集，并且修改所有列原有数字的字符集
ALTER TABLE `db_name`.`tbl_name`
    CONVERT TO CHARACTER SET `utf8mb4`;

#### 修改库database_name的字符集为utf8mb4，排序规则为utf8mb4_general_ci
#### 连接mysql后，不用选择库，把database_name替换成目标库名字，直接执行这一句SQL。
ALTER DATABASE `db_name` CHARACTER SET `utf8mb4` COLLATE `utf8mb4_general_ci`;



#### 创建批量修改表字符集和排序规则的存储过程（很慢，推荐使用 pt-online-schema-change，它是把一个大事务，拆解成多个小事务）
#### 表的字符集修改utf8mb4，排序规则为utf8mb4_general_ci
USE `db_name`;

DROP PROCEDURE IF EXISTS `up_change_utf8mb4`; DELIMITER $$
CREATE PROCEDURE `up_change_utf8mb4`()
    COMMENT '将当前数据库中所有表的字符集和排序规则修改为 utf8mb4'
BEGIN
    # 声明一个变量用于计数
    DECLARE `$i` INT;
    # 声明一个变量用于统计要修改的表的总数
    DECLARE `$cnt` INT;
    # 声明一个变量用于存储每次修改的表名
    DECLARE `$name` VARCHAR(200);

    #创建临时表，代替游标
    DROP TABLE IF EXISTS `tmp_table_name`;
    CREATE TEMPORARY TABLE `tmp_table_name` (
        `id`         INT          NOT NULL AUTO_INCREMENT,
        `table_name` VARCHAR(200) NOT NULL,
        PRIMARY KEY (`id`));

    # 插入要处理的表名到临时表中
    INSERT INTO `tmp_table_name`
        (`table_name`) (
                       SELECT CONCAT(
                                      `table_schema`,
                                      '.',
                                      `table_name`) AS `table_name`
                           FROM `information_schema`.`columns`
                           WHERE `data_type` IN (
                                                 'varchar',
                                                 'longtext',
                                                 'text',
                                                 'mediumtext',
                                                 'char')
                             AND `character_set_name` <> 'utf8mb4'
                             AND `table_schema` = DATABASE()
                           GROUP BY `table_name`);

    # 统计要修改的表的总数
    SELECT COUNT(1)
        INTO `$cnt`
        FROM `tmp_table_name`;

    #循环处理每一张表，改表的字符集
    SET `$i` = 1;
    WHILE `$i` <= `$cnt`
        DO
            SELECT `table_name`
                INTO `$name`
                FROM `tmp_table_name`
                WHERE `id` = `$i`;
            # 先修改表结构
            SET @`asql` = CONCAT('ALTER TABLE ', `$name`, ' CHARSET utf8mb4 COLLATE utf8mb4_general_ci; ');
            PREPARE `asql` FROM @`asql`;
            EXECUTE `asql`;
            SET @`asql` = CONCAT('ALTER TABLE ', `$name`, ' CONVERT TO CHARSET utf8mb4 COLLATE utf8mb4_general_ci; ');
            PREPARE `asql` FROM @`asql`;
            SELECT @`asql`;
            EXECUTE `asql`;
            SET `$i` = `$i` + 1;
        END WHILE;
    DEALLOCATE PREPARE `asql`;
    DROP TABLE `tmp_table_name`;
END$$ DELIMITER ;

#### 执行存储过程修改当前选中的数据库中所有的表。
CALL `up_change_utf8mb4`();

#### 显示全局所有相关字符集的变量
SHOW GLOBAL VARIABLES WHERE `variable_name` LIKE 'char%' OR `variable_name` LIKE 'collation%';
#### 显示会话所有相关字符集的变量
SHOW VARIABLES WHERE `variable_name` LIKE 'char%' OR `variable_name` LIKE 'collation%';

SHOW VARIABLES LIKE 'character%';

#### 显示所有字符集
SHOW CHARACTER SET;

#### 自动初始化行号
SELECT @`a` := @`a` + 1 AS `rownum`, `emp_no`, `birth_date`, `first_name`, `last_name`, `gender`, `hire_date`
    FROM `emp`.            `employees`,
         (
         SELECT @`a` := 0) `a`
    LIMIT 10;

#### 超级行号(逻辑思维很强，不建议，带上排序分组后效率超级慢)
SELECT (
       -- 相关子查询，效率很慢
       SELECT COUNT(1)
           FROM `emp`.`dept_emp` `t2`
           WHERE `t2`.`emp_no` <= `t1`.`emp_no`) AS `row_num`,
       `emp_no`
    FROM `emp`.`employees` `t1`
    ORDER BY `row_num`
             -- LIMIT 是随机挑选出结果
    LIMIT 10;

# 查询出没有主键索引的表
SELECT `t`.`table_schema`, `t`.`table_name`, `t`.`table_type`, `s`.`index_name`, `s`.`index_type`
    FROM `information_schema`.`tables`              `t`
        LEFT JOIN `information_schema`.`statistics` `s`
                      ON `t`.`table_schema` = `s`.`table_schema`
                          AND `t`.`table_name` = `s`.`table_name`
                          AND `s`.`index_name` = 'PRIMARY'
    WHERE `t`.`table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
      AND `table_type` = 'BASE TABLE'
      AND `s`.`index_name` IS NULL;

# 查询出没有任何索引的表
SELECT `t`.`table_schema`, `t`.`table_name`, `t`.`table_type`, `s`.`index_name`, `s`.`index_type`
    FROM `information_schema`.`tables`              `t`
        LEFT JOIN `information_schema`.`statistics` `s`
                      ON `t`.`table_schema` = `s`.`table_schema`
                          AND `t`.`table_name` = `s`.`table_name`
    WHERE `t`.`table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
      AND `table_type` = 'BASE TABLE'
      AND `s`.`index_name` IS NULL;

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

# 查询出指定表中没有使用过的索引
SELECT *
    FROM `sys`.`schema_unused_indexes`
    WHERE `object_schema` NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND `object_name` = 'orders';

# 查询出指定库和指定表中的所有索引使用情况
SELECT *
    FROM `sys`.`schema_index_statistics`
    WHERE `table_schema` NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND `table_schema` = 'bzbh'
      AND `table_name` = 'orders';


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

# 检查出当前事务id,线程id,查询语句，阻塞事务id,阻塞线程id,阻塞查询语句
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

#查询出所有自定义的数据库对象，存储过程，函数，视图，触发器，定时器
SELECT `db` AS `db_name`, `name` AS `object_name`, LOWER(`type`) AS `db_type`
    FROM `mysql`.`proc`
    WHERE `db` NOT IN ('sys', 'information_schema', 'performance_schema', 'mysql')
UNION ALL
SELECT `table_schema`, `table_name`, 'view'
    FROM `information_schema`.`views`
    WHERE `table_schema` NOT IN ('sys', 'information_schema', 'performance_schema', 'mysql')
UNION ALL
SELECT `trigger_schema`, `trigger_name`, 'trigger'
    FROM `information_schema`.`triggers`
    WHERE `trigger_schema` NOT IN ('sys', 'information_schema', 'performance_schema', 'mysql')
UNION ALL
SELECT `event_schema`, `event_name`, 'event'
    FROM `information_schema`.`events`
    WHERE `event_schema` NOT IN ('sys', 'information_schema', 'performance_schema', 'mysql');

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

# 查询出索引过多的自定库表
SELECT `database_name`, `table_name`, COUNT(*)
    FROM `mysql`.`innodb_index_stats`
    WHERE `database_name` NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
      AND `stat_description` = 'Number of pages in the index'
    GROUP BY `database_name`, `table_name`
    HAVING COUNT(*) > 6;

# 索引字段过多(多于3个)
SELECT `database_name`, `table_name`, `index_name`, COUNT(*)
    FROM `mysql`.`innodb_index_stats`
    WHERE `database_name` NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
      AND `stat_name` NOT IN ('size', 'n_leaf_pages')
    GROUP BY `database_name`, `table_name`, `index_name`
    HAVING COUNT(*) - 1 > 3;

# 无主键表
SELECT `table_schema`, `table_name`
    FROM (
         SELECT `c`.`table_schema`, `c`.`table_name`, CASE WHEN `column_key` = 'PRI' THEN 1 ELSE 0 END AS `pk_flag`
             FROM (
                  SELECT `table_schema`, `table_name`
                      FROM `information_schema`.`columns`
                      WHERE `table_schema` NOT IN ('information_schema', 'mysql', 'sys', 'performance_schema')
                        AND `ordinal_position` = 1
                        AND `column_key` != 'PRI') `t`,
                  `information_schema`.`columns`   `c`
             WHERE `t`.`table_schema` = `c`.`table_schema` AND `t`.`table_name` = `c`.`table_name`) `i`
    GROUP BY `table_schema`, `table_name`
    HAVING SUM(`pk_flag`) = 0;

#### 查询出从机上并行回放（复制）的执行线程数
SELECT *
    FROM `information_schema`.`processlist`
    WHERE `user` = 'system user' AND `state` = 'System lock';

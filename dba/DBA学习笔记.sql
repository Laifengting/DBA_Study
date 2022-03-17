# 查询员工表中员工对应的职业表中最新职位名称（派生表）
-- 第 3 步 再查询出 员工号，员工姓名，最新职称
SELECT `e`.`emp_no`, `e`.`last_name`, `t`.`title`
    FROM `emp`.`employees`                 `e`,
         ( -- 第 2 步查询出最新的工作日期在子查询中的员工号和职称
         SELECT `emp_no`, `title`
             FROM `emp`.`titles`
             WHERE (`emp_no`, `to_date`) IN
                   ( -- 第 1 步先查询出每个员工最新的工作日期
                   SELECT `emp_no`, MAX(`to_date`)
                       FROM `titles`
                       GROUP BY `emp_no`)) `t`
    WHERE `e`.`emp_no` = `t`.`emp_no`
    LIMIT 10;

# 查询出员工的最新职业，工资，部门号，部门名称
SELECT `e`.`emp_no`, `e`.`last_name`, `t`.`title`, `s`.`salary`, `d`.`dept_no`, `d`.`dept_name`
    FROM `emp`.`employees`                 `e`,
         ( -- 第 2 步查询出所有员工对应的最新职称（派生表1）
         SELECT `emp_no`, `title`
             FROM `emp`.`titles`
             WHERE (`emp_no`, `to_date`) IN
                   ( -- 第 1 步先查询出每个员工最新的工作日期
                   SELECT `emp_no`, MAX(`to_date`)
                       FROM `emp`.`titles`
                       GROUP BY `emp_no`)) `t`,
         ( -- 第 3 步查询出所有员工对应的最新工资（派生表2）
         SELECT `emp_no`, `salary`
             FROM `emp`.`salaries`
             WHERE (`emp_no`, `from_date`, `to_date`) IN
                   ( -- 第 1 步先查询出每个员工最新的工作日期
                   SELECT `emp_no`, MAX(`from_date`), MAX(`to_date`)
                       FROM `emp`.`salaries`
                       GROUP BY `emp_no`)) `s`,
         ( -- 第 4 步查询出所有员工对应的最新部门号和部门名称（派生表3）
         SELECT `d1`.`emp_no`, `d1`.`dept_no`, `d2`.`dept_name`
             FROM `emp`.`dept_manager`         `d1`
                 LEFT JOIN `emp`.`departments` `d2`
                               ON `d1`.`dept_no` = `d2`.`dept_no`
             WHERE (`d1`.`emp_no`, `d1`.`to_date`) IN
                   ( -- 第 1 步先查询出每个员工最新的工作日期
                   SELECT `emp_no`, MAX(`to_date`)
                       FROM `emp`.`dept_manager`
                       GROUP BY `emp_no`)) `d`
    WHERE `e`.`emp_no` = `t`.`emp_no`
      AND `e`.`emp_no` = `s`.`emp_no`
      AND `e`.`emp_no` = `d`.`emp_no`
    LIMIT 10;

# 查询出员工的最新职业，工资，部门号，部门名称
SELECT `e`.`emp_no`, `e`.`last_name`, `t`.`title`, `s`.`salary`, `d`.`dept_no`, `d`.`dept_name`
    FROM `emp`.`employees`                 `e`,
         ( -- 第 2 步查询出所有员工对应的最新职称（派生表1）
         SELECT `emp_no`, `title`
             FROM `emp`.`titles`
             WHERE (`emp_no`, `to_date`) IN
                   ( -- 第 1 步先查询出每个员工最新的工作日期
                   SELECT `emp_no`, MAX(`to_date`)
                       FROM `emp`.`titles`
                       GROUP BY `emp_no`)) `t`,
         ( -- 第 3 步查询出所有员工对应的最新工资（派生表2）
         -- 求最新薪水，使用 GROUP_CONCAT（排序后合并再分组），再用 SUBSTRING_INDEX(从字符串中，以','为分隔符，取一个元素)原始类型是数值型。再使用 CAST()转换为整型
         SELECT `emp_no`,
                CAST(SUBSTRING_INDEX(GROUP_CONCAT(`salary` ORDER BY `to_date` DESC, `from_date` DESC), ',', 1) AS UNSIGNED) AS `salary`
             FROM `emp`.`salaries`
             GROUP BY `emp_no`) AS         `s`,
         ( -- 第 4 步查询出所有员工对应的最新部门号和部门名称（派生表3）
         SELECT `d1`.`emp_no`, `d1`.`dept_no`, `d2`.`dept_name`
             FROM `emp`.`dept_manager`         `d1`
                 LEFT JOIN `emp`.`departments` `d2`
                               ON `d1`.`dept_no` = `d2`.`dept_no`
             WHERE (`d1`.`emp_no`, `d1`.`to_date`) IN
                   ( -- 第 1 步先查询出每个员工最新的工作日期
                   SELECT `emp_no`, MAX(`to_date`)
                       FROM `emp`.`dept_manager`
                       GROUP BY `emp_no`)) `d`
    WHERE `e`.`emp_no` = `t`.`emp_no` AND `e`.`emp_no` = `s`.`emp_no` AND `e`.`emp_no` = `d`.`emp_no`
    LIMIT 10;

SHOW DATABASES;

USE `dbt3`;

SHOW TABLES;

-- 返回客户是加拿大的，但是 1997 年内没有产生订单的客户
EXPLAIN
    SELECT `c`.`c_name`, `c`.`c_phone`, `c`.`c_address`, `n`.`n_name`
        FROM `dbt3`.`customer`                                `c`
            LEFT JOIN (
                      -- 注意要先把97年的所有订单查询出来。产生的派生表再关联查询
                      SELECT *
                          FROM `dbt3`.`orders`
                          WHERE `o_orderdate` >= '1997-01-01'
                            AND `o_orderdate` < '1998-01-01') `o`
                          ON `c`.`c_custkey` = `o`.`o_custkey`
            LEFT JOIN `dbt3`.`nation`                         `n`
                          ON `c`.`c_nationkey` = `n`.`n_nationkey`
        WHERE `o`.`o_orderkey` IS NULL
          AND `n`.`n_name` = 'CANADA';

-- 返回客户是加拿大的，但是 1997 年内没有产生订单的客户
EXPLAIN
    SELECT `c`.`c_name`, `c`.`c_phone`, `c`.`c_address`, `n`.`n_name`
        FROM `dbt3`.`customer`        `c`
            LEFT JOIN `dbt3`.`orders` `o`
                          -- 如果不使用派生表，关联的时候就进行过滤
                          ON `c`.`c_custkey` = `o`.`o_custkey`
                              AND `o`.`o_orderdate` >= '1997-01-01'
                              AND `o`.`o_orderdate` < '1998-01-01'
            LEFT JOIN `dbt3`.`nation` `n`
                          ON `c`.`c_nationkey` = `n`.`n_nationkey`
        WHERE `o`.`o_orderkey` IS NULL
          AND `n`.`n_name` = 'CANADA';

-- 行号问题
SELECT *
    FROM `emp`.`employees`
    LIMIT 10;

-- 定论一个变量
SET @`a` := 0;

-- 每取一个行号变量+1;
SELECT @`a` := @`a` + 1 AS `rownum`, `emp_no`, `birth_date`, `first_name`, `last_name`, `gender`, `hire_date`
    FROM `emp`.`employees`
    LIMIT 10;

-- 自动初始化行号
SELECT @`a` := @`a` + 1 AS `rownum`, `emp_no`, `birth_date`, `first_name`, `last_name`, `gender`, `hire_date`
    FROM `emp`.            `employees`,
         (
         SELECT @`a` := 0) `a`
    LIMIT 10;

-- 超级行号
SELECT (
       -- 相关子查询，效率很慢
       SELECT COUNT(1)
           FROM `emp`.`dept_emp` `t2`
           WHERE `t2`.`emp_no` <= `t1`.`emp_no`) AS `row_num`,
       `emp_no`
    FROM `emp`.`employees` `t1`
    ORDER BY `row_num` ASC
             -- LIMIT 是随机挑选出结果
    LIMIT 10;

-- Prepare SQL 语法
SET @`s` = 'SELECT * FROM employees WHERE emp_no = ?';

SET @`a` = 100080;

PREPARE `stmt` FROM @`s`;

EXECUTE `stmt` USING @`a`;

DEALLOCATE PREPARE `stmt`;

-- SQL 注入
SELECT *
    FROM `emp`.`employees`
    WHERE `emp_no` = 100080 OR 1 = 1;


SET @`s` = 'SELECT * FROM employees WHERE emp_no = ?';

SET @`a` = '100080 or 1=1';

PREPARE `stmt` FROM @`s`;

EXECUTE `stmt` USING @`a`;

DEALLOCATE PREPARE `stmt`;

DESC `emp`.`employees`;

-- 实例：性别是 m 生日是 1960 年以后的
SET @`s` = 'SELECT * FROM employees WHERE 1=1';

SET @`s` = CONCAT(@`s`, ' AND gender = "m"');

SET @`s` = CONCAT(@`s`, ' AND birth_date >= "1960-01-01"');

SET @`s` = CONCAT(@`s`, 'LIMIT 10');

PREPARE `stmt` FROM @`s`;

EXECUTE `stmt`;

DEALLOCATE PREPARE `stmt`;

-- 实例：性别是 m 生日是 1960 年以后的,带分布
SET @`s` = 'SELECT * FROM employees WHERE 1=1';

SET @`s` = CONCAT(@`s`, ' AND gender = "m"');

SET @`s` = CONCAT(@`s`, ' AND birth_date >= "1960-01-01"');

SET @`s` = CONCAT(@`s`, ' ORDER BY emp_no LIMIT ? , ?');

SET @`page_no` = 0;

SET @`page_count` = 10;

PREPARE `stmt` FROM @`s`;

EXECUTE `stmt` USING @`page_no`,@`page_count`;

DEALLOCATE PREPARE `stmt`;

-- 显示当前数据库的所有表
SHOW TABLES;

-- 创建新表
CREATE TABLE IF NOT EXISTS `y` (
    `a` INT,
    `b` INT);

-- 插入数据的语法使用
INSERT INTO `x`
    VALUES
        (4, 50),
        (5, 60),
        (6, 70);

-- 另外一种插入语法
INSERT INTO `x`
SET `a`=8,
    `b`=90;

-- 查询出 x 表中的所有内容
SELECT *
    FROM `x`;

-- 将别的表中的数据插入到当前表中
INSERT INTO `y`
SELECT *
    FROM `x`;

SELECT *
    FROM `x`;

SELECT *
    FROM `y`;

-- 删除在 x 表中不在 y 表中的数据(使用 LEFT JOIN)
BEGIN;

DELETE `x`,`y`
    FROM `x`
        LEFT JOIN `y`
                      ON `x`.`a` = `y`.`a`
    WHERE `y`.`a` IS NULL;

ROLLBACK;


SELECT @`a` := @`a` + 1 AS `row_no`, `a`, `b`, @`a` := @`a` + 1 AS `row_no2`
    FROM `x`,
         (
         SELECT @`a` := 0) AS `row`;

SELECT 3
    FROM `dual`;

CREATE TEMPORARY TABLE `a` (
    `id` INT);

SHOW CREATE TABLE `a`;

SHOW VARIABLES LIKE '%tmp%';

-- 存储过程
-- 删除临时表
DROP TABLE IF EXISTS `tbl_proc_test`;
-- 删除存在的存储过程
DROP PROCEDURE IF EXISTS `proc_test1`;
-- 创建临时表
CREATE TEMPORARY TABLE `tbl_proc_test` (
    `num` BIGINT);
-- 指定结束符
DELIMITER //
-- 创建存储过程 IN 入参，OUT 出参
CREATE PROCEDURE `proc_test1`(IN `total` INT, OUT `res` INT)
BEGIN
    DECLARE `i` INT;
    SET `i` = 1;
    SET `res` = 1;
    IF `total` <= 0
    THEN
        SET `total` = 1;
    END IF;
    WHILE `i` <= `total`
        DO
            SET `res` = `res` * `i`;
            INSERT INTO `tbl_proc_test`(`num`)
                VALUES
                    (`res`);
            SET `i` = `i` + 1;
        END WHILE;
END;

//
DELIMITER ;
-- 调用存储过程
CALL `proc_test1`(10, @`a`);
-- 获取出参
SELECT @`a`;
-- 查询临时表
SELECT *
    FROM `tbl_proc_test`;

-- 显示存储过程的状态
SHOW PROCEDURE STATUS LIKE 'proc_test1';

-- 使用信息库
USE `information_schema`;
-- 检查所有表
SHOW TABLES;
-- 查看 routines 详情
DESC `routines`;

SELECT *
    FROM `routines`
    WHERE `routine_name` = 'proc_test1';

-- 当存储过程的 definer 定义者被删除时，是不是调用该存储过程的
-- 可以在 mysql 库中修改 proc 表中的定义信息

USE `mysql`;

DESC `proc`;

SELECT *
    FROM `proc`
    WHERE `name` = 'proc_test1';

UPDATE `proc`
SET `definer` = 'root@%'
    WHERE `name` = 'proc_test1';

-- 自定函数
DROP FUNCTION IF EXISTS `func_test1`;
DELIMITER $$
CREATE FUNCTION `func_test1`(`total` INT) RETURNS BIGINT
BEGIN
    DECLARE `i` INT;
    DECLARE `res` INT;
    SET `i` = 1;
    SET `res` = 1;
    IF `total` <= 0
    THEN
        SET `total` = 1;
    END IF;
    WHILE `i` <= `total`
        DO
            SET `res` = `res` * `i`;
            SET `i` = `i` + 1;
        END WHILE;
    RETURN `res`;
END$$

DELIMITER ;
SELECT `func_test1`(10);

-- 触发器的例子
CREATE TABLE `stu` (
    `name`   VARCHAR(50),
    `course` VARCHAR(50),
    `score`  INT(11),
    PRIMARY KEY (`name`))
    ENGINE = InnoDB;

DELIMITER $$
CREATE TRIGGER `trg_upd_score`
    BEFORE UPDATE
    ON `stu`
    FOR EACH ROW
BEGIN
    IF `new`.`score` < 0
    THEN
        SET `new`.`score` = 0;
    ELSEIF `new`.`score` > 100
    THEN
        SET `new`.`score` = 100;
    END IF;
END$$
DELIMITER ;

SELECT *
    FROM `stu`;

INSERT INTO `stu`
    VALUES
        ('张三', '语文', 80);

UPDATE `stu`
SET `score` = -10
    WHERE `name` = '张三';


-- 视图创建
CREATE VIEW `v_emp`
AS
    SELECT *
        FROM `employees`
        LIMIT 200;

-- 从视图中查询
SELECT *
    FROM `v_emp`;

-- 事件
SHOW VARIABLES LIKE '%event%';


# Copyright 2015 Yahoo Inc. Licensed under the terms of Apache License 2.0. Please see the LICENSE file for terms.

# MySQL 分区管理器

DROP PROCEDURE IF EXISTS `partition_manager`;

DELIMITER ;;
CREATE
    DEFINER = `root`@`localhost` PROCEDURE `partition_manager`()
BEGIN

    DECLARE `done` TINYINT UNSIGNED;
    DECLARE `p_table`,`p_column` VARCHAR(64) CHARACTER SET `latin1`;
    DECLARE `p_granularity`,`p_increment`,`p_retain`,`p_buffer` INT UNSIGNED;
    DECLARE `run_timestamp`,`current_val` INT UNSIGNED;
    DECLARE `partition_list` TEXT CHARACTER SET `latin1`;

    DECLARE `cur_table_list` CURSOR FOR SELECT `s`.`table`, `s`.`column`, `s`.`granularity`, `s`.`increment`, `s`.`retain`, `s`.`buffer`
                                            FROM `partition_manager_settings` `s`;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET `done` = 1;

    SET SESSION group_concat_max_len = 65535;

    SET `run_timestamp` = UNIX_TIMESTAMP();

    OPEN `cur_table_list`;
    `manage_partitions_loop`:
    LOOP
        SET `done` = 0;
        FETCH `cur_table_list` INTO `p_table`,`p_column`,`p_granularity`,`p_increment`,`p_retain`,`p_buffer`;
        IF `done` = 1
        THEN
            LEAVE `manage_partitions_loop`;
        END IF;

        # verification

        SELECT IF(`t`.`create_options` LIKE '%partitioned%', NULL,
                  CEIL(UNIX_TIMESTAMP() / IFNULL(`p_increment`, 1)) * IFNULL(`p_increment`, 1))
            FROM `information_schema`.`tables` `t`
            WHERE `t`.`table_schema` = DATABASE()
              AND `t`.`table_name` = `p_table`
            INTO `current_val`;

        IF `current_val` IS NOT NULL
        THEN
            SET `partition_list` := '';
            IF `p_retain` IS NOT NULL
            THEN
                WHILE `current_val` > `run_timestamp` - `p_retain`
                    DO
                        SET `current_val` := `current_val` - `p_increment`;
                        SET `partition_list` := CONCAT('partition p_', FLOOR(`current_val` / `p_granularity`), ' values less than (',
                                                       FLOOR(`current_val` / `p_granularity`), '),', `partition_list`);
                    END WHILE;
            END IF;

            SET @`sql` :=
                    CONCAT('alter table ', `p_table`, ' partition by range (', `p_column`, ') (partition p_START values less than (0),',
                           `partition_list`, 'partition p_END values less than MAXVALUE)');
            PREPARE `stmt` FROM @`sql`;
            EXECUTE `stmt`;
            DEALLOCATE PREPARE `stmt`;
        END IF;

        # add

        IF `p_buffer` IS NOT NULL
        THEN
            SELECT IFNULL(MAX(`p`.`partition_description`) * `p_granularity`, FLOOR(UNIX_TIMESTAMP() / `p_increment`) * `p_increment`)
                FROM `information_schema`.`partitions` `p`
                WHERE `p`.`table_schema` = DATABASE()
                  AND `p`.`table_name` = `p_table`
                  AND `p`.`partition_description` > 0
                INTO `current_val`;

            SET `partition_list` := '';
            WHILE `current_val` < `run_timestamp` + `p_buffer`
                DO
                    SET `current_val` := `current_val` + `p_increment`;
                    SET `partition_list` := CONCAT(`partition_list`, 'partition p_', FLOOR(`current_val` / `p_granularity`),
                                                   ' values less than (',
                                                   FLOOR(`current_val` / `p_granularity`), '),');
                END WHILE;

            IF `partition_list` > ''
            THEN
                SET @`sql` := CONCAT('ALTER TABLE ', `p_table`, ' REORGANIZE PARTITION p_END into (', `partition_list`,
                                     'partition p_END values less than maxvalue)');
                PREPARE `stmt` FROM @`sql`;
                EXECUTE `stmt`;
                DEALLOCATE PREPARE `stmt`;
            END IF;
        END IF;

        # purge

        IF `p_retain` IS NOT NULL
        THEN
            SET `partition_list` = '';
            SELECT GROUP_CONCAT(`p`.`partition_name` SEPARATOR ',')
                FROM `information_schema`.`partitions` `p`
                WHERE `p`.`table_schema` = DATABASE()
                  AND `p`.`table_name` = `p_table`
                  AND `p`.`partition_description` <= FLOOR((`run_timestamp` - `p_retain`) / `p_granularity`)
                  AND `p`.`partition_description` > 0
                INTO `partition_list`;
            IF `partition_list` > ''
            THEN
                SET @`sql` := CONCAT('ALTER TABLE ', `p_table`, ' DROP PARTITION ', `partition_list`);
                PREPARE `stmt` FROM @`sql`;
                EXECUTE `stmt`;
                DEALLOCATE PREPARE `stmt`;
            END IF;
        END IF;
    END LOOP;
    CLOSE `cur_table_list`;

    # confirm schedule for next run

    CALL `schedule_partition_manager`(); /* 5.6.29+/5.7.11+ only - mysql bug 77288 */

END;;
DELIMITER ;

DROP EVENT IF EXISTS `run_partition_manager`;

DELIMITER ;;
CREATE DEFINER =`root`@`localhost` EVENT `run_partition_manager` ON SCHEDULE EVERY 86400 SECOND STARTS '2000-01-01 00:00:00' ON COMPLETION PRESERVE ENABLE DO
    BEGIN
        IF @@`global.read_only` = 0
        THEN
            CALL `partition_manager`();
        END IF;
    END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `schedule_partition_manager`;

DELIMITER ;;
CREATE
    DEFINER = `root`@`localhost` PROCEDURE `schedule_partition_manager`()
BEGIN

    DECLARE `min_increment` INT UNSIGNED;

    SET `min_increment` = NULL;
    SELECT MIN(`s`.`increment`)
        FROM `partition_manager_settings` `s`
        INTO `min_increment`;

    IF `min_increment` IS NOT NULL
    THEN
        ALTER DEFINER =`root`@`localhost` EVENT `run_partition_manager` ON SCHEDULE EVERY `min_increment` SECOND STARTS '2000-01-01 00:00:00' ENABLE;
    END IF;

END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `install_partition_manager`;

DELIMITER ;;
CREATE
    DEFINER = `root`@`localhost` PROCEDURE `install_partition_manager`()
BEGIN

    DROP TABLE IF EXISTS `partition_manager_settings_new`;

    CREATE TABLE `partition_manager_settings_new` (
        `table`       VARCHAR(64)      NOT NULL COMMENT 'table name',
        `column`      VARCHAR(64)      NOT NULL COMMENT 'numeric column with time info',
        `granularity` INT(10) UNSIGNED NOT NULL COMMENT 'granularity of column, i.e. 1=seconds, 60=minutes...',
        `increment`   INT(10) UNSIGNED NOT NULL COMMENT 'seconds per individual partition',
        `retain`      INT(10) UNSIGNED NULL COMMENT 'seconds of data to retain, null for infinite',
        `buffer`      INT(10) UNSIGNED NULL COMMENT 'seconds of empty future partitions to create',
        PRIMARY KEY (`table`))
        ENGINE = InnoDB
        DEFAULT CHARSET = `latin1`
        ROW_FORMAT = DYNAMIC;

    SET @`sql` = NULL;
    SELECT CONCAT('insert into partition_manager_settings_new (', GROUP_CONCAT(CONCAT('`', `cn`.`column_name`, '`')), ') select ',
                  GROUP_CONCAT(CONCAT('so.', `cn`.`column_name`)), ' from partition_manager_settings so')
        FROM `information_schema`.`columns`     `cn`
            JOIN `information_schema`.`columns` `co`
                     ON `co`.`table_schema` = `cn`.`table_schema` AND `co`.`column_name` = `cn`.`column_name`
        WHERE `cn`.`table_name` = 'partition_manager_settings_new'
          AND `co`.`table_name` = 'partition_manager_settings'
        INTO @`sql`;

    IF @`sql` IS NOT NULL
    THEN
        PREPARE `stmt` FROM @`sql`;
        EXECUTE `stmt`;
        DEALLOCATE PREPARE `stmt`;
    END IF;

    DROP TABLE IF EXISTS `partition_manager_settings`;

    RENAME TABLE `partition_manager_settings_new` TO `partition_manager_settings`;

    CALL `schedule_partition_manager`(); /* 5.6.29+/5.7.11+ only - mysql bug 77288 */

END;;
DELIMITER ;

CALL `install_partition_manager`;

DROP PROCEDURE IF EXISTS `install_partition_manager`;



SHOW VARIABLES LIKE 'innodb%max%';

SET GLOBAL INNODB_ONLINE_ALTER_LOG_MAX_SIZE = 512 * 1024 * 1024;

SET GLOBAL INNODB_PAGE_SIZE = `16k`;

-- 默认 InnoDB 存储引擎默认的填充因子 100
SHOW VARIABLES LIKE 'innodb%fill%';

SHOW VARIABLES LIKE '%LOG_OUTPUT%';

SET GLOBAL LOG_OUTPUT = 'TABLE,FILE';

FLUSH SLOW LOGS;

USE `sys`;

SHOW TABLES LIKE 'statement_analysis';

SELECT *
    FROM `statement_analysis`;

SHOW DATABASES;

USE `information_schema`;

SHOW TABLES;

DESC `statistics`;

SELECT *
    FROM `statistics`;

USE `sys`;

SHOW TABLES;

SHOW COLUMNS FROM `host_summary`;

DESC `host_summary`;

DESCRIBE `host_summary`;

SHOW GRANTS FOR `root`;

SHOW WARNINGS;

SHOW STORAGE ENGINES;

SHOW INDEX FROM `host_summary`;

SHOW PLUGINS;

SHOW STATUS;

SELECT *
    FROM `statistics`;

DESC `tables`;

SELECT *
    FROM `information_schema`.`tables` AS `main_table`
    WHERE `table_schema` = 'dbt3'
      -- ============================================================================
      -- FIND TABLES WITH A PRIMARY KEY
      -- ============================================================================
      AND `table_name` IN (
                          SELECT `table_name`
                              FROM (
                                   SELECT `table_name`, `index_name`, COUNT(`index_name`) AS `test`
                                       FROM `information_schema`.`statistics`
                                       WHERE `table_schema` = 'dbt3'
                                         AND `index_name` = 'PRIMARY'
                                       GROUP BY `table_name`, `index_name`) AS `tab_ind_cols`
                              GROUP BY `table_name`)
      -- ============================================================================
      -- FIND TABLES WITH OUT ANY INDICES
      -- ============================================================================
      AND `table_name` NOT IN (
                              SELECT `table_name`
                                  FROM (
                                       SELECT `table_name`, `index_name`, COUNT(`index_name`) AS `test`
                                           FROM `information_schema`.`statistics`
                                           WHERE `table_schema` = 'dbt3'
                                             AND `index_name` <> 'PRIMARY'
                                           GROUP BY `table_name`, `index_name`) AS `tab_ind_cols`
                                  GROUP BY `table_name`
    );


SHOW DATABASES;

USE `bzbh`;

SHOW TABLES;

DESCRIBE `orderitems`;



USE `dbt3`;

EXPLAIN
    SELECT *
        FROM `orders`
        WHERE `o_custkey` = 1
        ORDER BY `o_orderdate`, `o_orderstatus`;



EXPLAIN
    SELECT `s_name`, `s_address`
        FROM `supplier`, `nation`
        WHERE `s_suppkey` IN (
                             SELECT DISTINCT `ps_suppkey`
                                 FROM `partsupp`, `part`
                                 WHERE `ps_partkey` = `p_partkey`
                                   AND `p_name` LIKE 'orchid%'
                                   AND `ps_availqty` > (
                                                       SELECT 0.5 * SUM(`l_quantity`)
                                                           FROM `lineitem`
                                                           WHERE `l_partkey` = `ps_partkey`
                                                             AND `l_suppkey` = `ps_suppkey`
                                                             AND `l_shipdate` >= '1996-01-01'
                                                             AND `l_shipdate` < DATE_ADD('1996-01-01', INTERVAL 1 YEAR)))
          AND `s_nationkey` = `n_nationkey`
          AND `n_name` = 'ALGERIA'
        ORDER BY `s_name`;

DESC `orders`;

ALTER TABLE `orders`
    ADD COLUMN `o_orderdate2` INT GENERATED ALWAYS AS (DATEDIFF('2099-01-01', `o_orderdate`)) VIRTUAL;


ALTER TABLE `orders`
    ADD INDEX `idx_cust_date_status` (`o_custkey`, `o_orderdate2`, `o_orderstatus`);

# 查询出没有主键索引的表
SELECT *
    FROM `information_schema`.`tables` `t`
        LEFT JOIN
    `information_schema`.`statistics`  `s`
        ON `t`.`table_schema` = `s`.`table_schema`
            AND `t`.`table_name` = `s`.`table_name`
            AND `s`.`index_name` = 'PRIMARY'
    WHERE `t`.`table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
      AND `table_type` = 'BASE TABLE'
      AND `s`.`index_name` IS NULL;

# 查询出没有主键索引的表
SELECT *
    FROM `information_schema`.`tables` `t`
        LEFT JOIN
    `information_schema`.`statistics`  `s`
        ON `t`.`table_schema` = `s`.`table_schema`
            AND `t`.`table_name` = `s`.`table_name`
            AND `s`.`index_name` = 'PRIMARY'
    WHERE `t`.`table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
      AND `table_type` = 'BASE TABLE'
      AND `s`.`index_name` IS NULL;

# 查询出没有主键索引的表
SELECT *
    FROM `information_schema`.`tables` `t`
        LEFT JOIN
    `information_schema`.`statistics`  `s`
        ON `t`.`table_schema` = `s`.`table_schema`
            AND `t`.`table_name` = `s`.`table_name`
            AND `s`.`index_name` = 'PRIMARY'
    WHERE `t`.`table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
      AND `table_type` = 'BASE TABLE'
      AND `s`.`index_name` IS NULL;

# 查询出所有表中有主键索引但没有其余索引的表
-- ============================================================================
-- TABLES WITHOUT INDICES BUT HAVE A PRIMARY KEY
-- ============================================================================
USE `information_schema`;

SELECT *
    FROM `information_schema`.`tables` AS `main_table`
    WHERE `table_schema` = 'dbt3' -- WHERE table_schema IN ('bzbh', 'dbt3', 'emp')
      -- ============================================================================
      -- FIND TABLES WITH A PRIMARY KEY
      -- ============================================================================
      AND `table_name` IN (
                          SELECT `table_name`
                              FROM (
                                   SELECT `table_name`, `index_name`, COUNT(`index_name`) AS `test`
                                       FROM `information_schema`.`statistics`
                                       WHERE `table_schema` = 'dbt3' -- WHERE table_schema IN ('bzbh', 'dbt3', 'emp') NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
                                         AND `index_name` = 'PRIMARY'
                                       GROUP BY `table_name`, `index_name`) AS `tab_ind_cols`
                              GROUP BY `table_name`)
      -- ============================================================================
      -- FIND TABLES WITH OUT ANY INDICES
      -- ============================================================================
      AND `table_name` NOT IN (
                              SELECT `table_name`
                                  FROM (
                                       SELECT `table_name`, `index_name`, COUNT(`index_name`) AS `test`
                                           FROM `information_schema`.`statistics`
                                           WHERE `table_schema` = 'dbt3' -- WHERE table_schema IN ('bzbh', 'dbt3', 'emp') NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
                                             AND `index_name` <> 'PRIMARY'
                                           GROUP BY `table_name`, `index_name`) AS `tab_ind_cols`
                                  GROUP BY `table_name`);

# 查询出没有主键索引的表
SELECT `t`.`table_schema`, `t`.`table_name`, `t`.`table_type`, `s`.`index_name`, `s`.`index_type`
    FROM `information_schema`.`tables` `t`
        LEFT JOIN
    `information_schema`.`statistics`  `s`
        ON `t`.`table_schema` = `s`.`table_schema`
            AND `t`.`table_name` = `s`.`table_name`
            AND `s`.`index_name` = 'PRIMARY'
    WHERE `t`.`table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
      AND `table_type` = 'BASE TABLE'
      AND `s`.`index_name` IS NULL;

# 查询出没有任何索引的表
SELECT `t`.`table_schema`, `t`.`table_name`, `t`.`table_type`, `s`.`index_name`, `s`.`index_type`
    FROM `information_schema`.`tables` `t`
        LEFT JOIN
    `information_schema`.`statistics`  `s`
        ON `t`.`table_schema` = `s`.`table_schema`
            AND `t`.`table_name` = `s`.`table_name`
    WHERE `t`.`table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
      AND `table_type` = 'BASE TABLE'
      AND `s`.`index_name` IS NULL;

# 查询出有主键没有其他索引的表
EXPLAIN
    SELECT `t`.`table_schema`, `t`.`table_name`, `t`.`table_type`, `s`.`index_name`, `s`.`index_type`
        FROM `information_schema`.`tables`              `t`
            LEFT JOIN `information_schema`.`statistics` `s`
                          ON `t`.`table_schema` = `s`.`table_schema` AND `t`.`table_name` = `s`.`table_name`
            # 		WHERE t.table_schema NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
        WHERE `t`.`table_schema` IN ('bzbh')
          AND `t`.`table_name` IN (
                                  SELECT `s2`.`table_name`
                                      FROM `information_schema`.`statistics` `s2`
                                      WHERE `s2`.`index_name` = 'PRIMARY')
          AND `t`.`table_name` NOT IN (
                                      SELECT `s3`.`table_name`
                                          FROM `information_schema`.`statistics` `s3`
                                          WHERE `s3`.`index_name` <> 'PRIMARY');

SELECT *
    FROM `information_schema`.`statistics`;

# mysql 查询出有某列但没有此列索引的表
USE `information_schema`;

EXPLAIN
    SELECT `col`.`table_schema` AS `db_name`, `col`.`table_name`, `col`.`column_name`
        FROM `information_schema`.`columns`             `col`
            LEFT JOIN (
                      SELECT 'age' AS `column_name`)    `query_col`
                          ON `col`.`column_name` = `query_col`.`column_name`
            LEFT JOIN `information_schema`.`statistics` `sta`
                          ON `col`.`table_schema` = `sta`.`table_schema`
                              AND `col`.`table_name` = `sta`.`table_name`
                              AND `col`.`column_name` = `sta`.`column_name`
            # 	WHERE col.table_schema NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
        WHERE `col`.`table_schema` IN ('bzbh')
          AND `query_col`.`column_name` IS NOT NULL
          AND `sta`.`seq_in_index` IS NULL;



EXPLAIN
    SELECT `s_name`, `s_address`
        FROM `dbt3`.`supplier`, `dbt3`.`nation`
        WHERE `s_suppkey` IN (
                             SELECT DISTINCT `ps_suppkey`
                                 FROM `dbt3`.`partsupp`, `dbt3`.`part`
                                 WHERE `ps_partkey` = `p_partkey`
                                   AND `p_name` LIKE 'orchid%'
                                   AND `ps_availqty` > (
                                                       SELECT 0.5 * SUM(`l_quantity`)
                                                           FROM `dbt3`.`lineitem`
                                                           WHERE `l_partkey` = `ps_partkey`
                                                             AND `l_suppkey` = `ps_suppkey`
                                                             AND `l_shipdate` >= '1996-01-01'
                                                             AND `l_shipdate` < DATE_ADD('1996-01-01', INTERVAL 1 YEAR)))
          AND `s_nationkey` = `n_nationkey`
          AND `n_name` = 'ALGERIA'
        ORDER BY `s_name`;



CREATE TABLE `nodes` (
    `id`        BIGINT(20)  DEFAULT NULL,
    `geom`      GEOMETRY NOT NULL,
    `user`      VARCHAR(50) DEFAULT NULL,
    `version`   INT(11)     DEFAULT NULL,
    `timestamp` VARCHAR(20) DEFAULT NULL,
    `uid`       INT(11)     DEFAULT NULL,
    `chagesset` INT(11)     DEFAULT NULL,
    UNIQUE KEY `i_nodeids` (`id`),
    SPATIAL KEY `i_geomidx` (`geom`))
    ENGINE = InnoDB
    DEFAULT CHARSET = `utf8mb4`;

LOAD DATA LOCAL INFILE '/mdata/nodes.txt'
    INTO TABLE `nodes` (`id`, @`lon`, @`lat`, `user`, `version`, `timestamp`, `uid`, `changeset`)
    SET `geom` = POINT(@`lon`, @`lat`);

ALTER TABLE `nodes`
    ADD COLUMN `tags` TEXT,
    ADD FULLTEXT INDEX (`tags`);

UPDATE `nodes`
SET `tags` = (
             SELECT GROUP_CONCAT(CONCAT(`k`, '=', `v`) SEPARATOR ',')
                 FROM `nodetags`
                 WHERE `nodetags`.`id` = `nodes`.`id`
                 GROUP BY `nodes`.`id`);

SELECT `id`, ST_DISTANCE_SPHERE(POINT(-73.951368, 40.716743), `geom`) AS `distance_in_meters`, `tags`, ST_ASTEXT(`geom`)
    FROM `nodes`
    WHERE ST_CONTAINS(ST_MAKEENVELOPE(
                              POINT((-73951368 + (20 / 111)), (40.716743 + (20 / 111))),
                              POINT((-73951368 + (20 / 111)), (40.716743 + (20 / 111)))), `geom`)
      AND MATCH(`tags`) AGAINST('+thai +restaurant' IN BOOLEAN MODE)
    ORDER BY `distance_in_meters`
    LIMIT 10;

#### MySQL 8.0 GIS 应用
## 建库
DROP DATABASE IF EXISTS `gis`;

CREATE DATABASE `gis` /*!40100 DEFAULT CHARACTER SET `utf8mb4` DEFAULT COLLATE `utf8mb4_general_ci` */;

## 建表
DROP TABLE IF EXISTS `gis`.`test`;

CREATE TABLE `gis`.`test` (
    `a`    INT      NOT NULL,
    `geom` GEOMETRY NOT NULL /*!80003 SRID 4326 */,
    PRIMARY KEY (`a`),
    SPATIAL KEY `geom` (`geom`))
    ENGINE = InnoDB
    DEFAULT CHARSET = `utf8mb4`
    COLLATE = `utf8mb4_0900_ai_ci`;

## 插入数据
# 专用语法
INSERT INTO `test`
    VALUES
        (12, ST_SRID(POINT(3, 3), 4326));

INSERT INTO `test`
    VALUES
        (2, ST_SRID(LINESTRING(POINT(1, 1), POINT(2, 2)), 4326));

SET @`g` = 'POINT(4 4)';

INSERT INTO `gis`.`test`
    VALUES
        (4, ST_SRID(ST_POINTFROMTEXT(@`g`), 4326));

SET @`g` = 'LINESTRING(0 0,1 1,2 2)';

INSERT INTO `gis`.`test`
    VALUES
        (5, ST_SRID(ST_LINESTRINGFROMTEXT(@`g`), 4326));

SET @`g` = 'POLYGON((0 0,10 0,10 10,0 10,0 0),(5 5,7 5,7 7,5 7, 5 5))';

INSERT INTO `gis`.`test`
    VALUES
        (6, ST_SRID(ST_POLYGONFROMTEXT(@`g`), 4326));

SET @`g` =
        'GEOMETRYCOLLECTION(POINT(1 1),LINESTRING(0 0,1 1,2 2,3 3,4 4))';

INSERT INTO `gis`.`test`
    VALUES
        (7, ST_SRID(ST_GEOMCOLLFROMTEXT(@`g`), 4326));

# 通用语法
SET @`g` =
        'GEOMETRYCOLLECTION(POINT(1 1),LINESTRING(0 0,1 1,2 2,3 3,4 4))';

INSERT INTO `gis`.`test`
    VALUES
        (8, ST_SRID(ST_GEOMFROMTEXT(@`g`), 4326));

SET @`g` =
        'POLYGON((0 0,10 0,10 10,0 10,0 0),(5 5,7 5,7 7,5 7, 5 5))';

INSERT INTO `gis`.`test`
    VALUES
        (9, ST_SRID(ST_GEOMFROMTEXT(@`g`), 4326));

SET @`g` = 'LINESTRING(0 0,1 1,2 2)';

INSERT INTO `gis`.`test`
    VALUES
        (10, ST_SRID(ST_GEOMFROMTEXT(@`g`), 4326));

SET @`g` = 'POINT(4 4)';

INSERT INTO `gis`.`test`
    VALUES
        (11, ST_SRID(ST_GEOMFROMTEXT(@`g`), 4326));

## 查询数据
SELECT `a`, ST_ASTEXT(`geom`)
    FROM `test`;

SELECT `a`, ST_ASBINARY(`geom`)
    FROM `test`;

## 创建空间索引
# 创建空间索引语法1
ALTER TABLE `gis`.`test`
    ADD SPATIAL INDEX `sp_idx_geom1` (`geom`);

# 创建空间索引语法2
CREATE SPATIAL INDEX `sp_idx_geom2` ON `gis`.`test` (`geom`);

# 删除空间索引语法1
ALTER TABLE `gis`.`test`
    DROP INDEX `sp_idx_geom1`;

# 删除空间索引语法2
DROP INDEX `sp_idx_geom2` ON `gis`.`test`;

## 显示建表语文
SHOW CREATE TABLE `gis`.`test`;


SET @`id` = FLOOR(RAND() * 1000000);

SELECT *
    FROM `sbtest`.`sbtest1`
    WHERE `id` = @`id`;

#### 事务
## 方式1
## 开启事务
BEGIN;

INSERT INTO `test`.`z`
    VALUES
        (50);

INSERT INTO `test`.`z`
    VALUES
        (60);

INSERT INTO `test`.`z`
    VALUES
        (70);

COMMIT;

## 方式2
START TRANSACTION;

INSERT INTO `test`.`z`
    VALUES
        (80);

INSERT INTO `test`.`z`
    VALUES
        (90);

INSERT INTO `test`.`z`
    VALUES
        (100);

ROLLBACK;

## 方式3
SHOW VARIABLES LIKE 'auto%';

SET AUTOCOMMIT = `off`;

INSERT INTO `test`.`z`
    VALUES
        (110);

INSERT INTO `test`.`z`
    VALUES
        (120);

COMMIT;

INSERT INTO `test`.`z`
    VALUES
        (130);

INSERT INTO `test`.`z`
    VALUES
        (140);

ROLLBACK;

## 方式4
# 设置保存点
SAVEPOINT `s1`;

INSERT INTO `test`.`z`
    VALUES
        (170);

INSERT INTO `test`.`z`
    VALUES
        (180);

# 事务并未提交。只是回滚到事务中之前保存点。
ROLLBACK TO `s1`;

# 事务提交之后保存点就没有了。
COMMIT;


SELECT *
    FROM `test`.`z`;


SHOW PROCESSLIST;



SHOW ENGINE innodb MUTEX;

CREATE TABLE `tbl_lock` (
    `a` INT PRIMARY KEY,
    `b` INT,
    `c` INT,
    `d` INT,
    KEY (`b`));



SHOW GLOBAL VARIABLES LIKE 'transaction_isolation';

SET `transaction_isolation` = `read-uncommitted`;

SET `transaction_isolation` = `read-committed`;

SET `transaction_isolation` = `repeatable-read`;

SET `transaction_isolation` = `serializable`;


SHOW VARIABLES LIKE 'innodb_flush_log%';


XA START 'a';

INSERT INTO `test`.`z`
    VALUES
        (1000);

INSERT INTO `test`.`z`
    VALUES
        (2000);

XA END 'a';

XA PREPARE 'a';

XA RECOVER;

XA COMMIT 'a';

XA ROLLBACK 'a';

#### mysqldump 备份原理
# 第1步 设置普通日志输出到表
SET GLOBAL log_output = `table`;

# 第2步 清空一下 GENERAL_LOG 表
TRUNCATE `mysql`.`general_log`;

# 第3步 设置开启普通日志
SET GLOBAL general_log = 1;

# 第4步 执行备份语句
`mysqldump -uroot -pLft123456~ --single-transaction --master-data=1 --triggers --events --routines -B db1_name db2_name > backup.sql`

# 第5步 关闭普通日志

SET GLOBAL general_log = 0;

# 第6步 查询。默认普通日志记录是使用16进制字符记录。转换为 utf8 编码
SELECT `thread_id`, LEFT(CONVERT(`argument` USING `utf8mb4`), 128)
    FROM `mysql`.`general_log`
    WHERE `thread_id` = 20;

#### mydumper 多线程一致性备份的原理
## 给所有表的加上只读锁。也就是将库锁成只读的。
FLUSH TABLE `with` READ LOCK;

## 确保每一个备份线程的事务隔离级别是 RR
SET `transaction_isolation` = 'REPEATABLE-READ';

## 开启事务
START TRANSACTION WITH CONSISTENT SNAPSHOT;

## 每个线程备份的数据是一致的。
## 如何备份同一张表的不同数据。此时就必须要有一个唯一索引。
SELECT /*! 40001 AS `sql_no_cache` */ *
    FROM `db_name`.`tbl_name`
    WHERE `id` IS NULL OR (`id` >= 1 AND `id` < 555550);

SELECT /*! 40001 AS `sql_no_cache` */ *
    FROM `db_name`.`tbl_name`
    WHERE `id` IS NULL OR (`id` >= 555550 AND `id` < 1000000);

## 备份完之后
UNLOCK TABLES;

## 完整备份语句
# 查询需要备份的字段
SELECT `col1`,
       TO_BASE64(`col2`),
       `col3`,
       `col4`,
       `col5`
       # 备份文件的路径和文件名称
    INTO OUTFILE '/tmp/tbl1_backup.dat'
        # 字段分隔符
        FIELDS TERMINATED BY ','
        # 字段可选的关闭字符
        OPTIONALLY ENCLOSED BY '"'
        # 行结束符
        LINES TERMINATED BY '\r\n'
        # 要备份的表
    FROM `tbl1`;

# 完整恢复语句
LOAD DATA LOCAL INFILE '/tmp/tbl1_backup.dat' INTO TABLE `tbl2`
    # 字段分隔符
    FIELDS TERMINATED BY ','
    # 字段可选的关闭字符
    OPTIONALLY ENCLOSED BY '"'
    # 行结束符
    LINES TERMINATED BY '\r\n'
    (`col1`, @`col2`, `col3`, `col4`, `col5`)
    SET `col2` = FROM_BASE64(@`col2`);

## 删除表中重复数据
# 建表
CREATE TABLE `animal` (
    `id`   INT(11) NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(20) DEFAULT NULL,
    `age`  INT(11)     DEFAULT NULL,
    PRIMARY KEY (`id`)) ENGINE = InnoDB
                        AUTO_INCREMENT = 6
                        DEFAULT CHARSET = `utf8mb4`;

# 插入数据
INSERT INTO `animal`
    VALUES
        (1, 'dog', 12);

INSERT INTO `animal`
    VALUES
        (2, 'cat', 13);

INSERT INTO `animal`
    VALUES
        (3, 'camel', 14);

INSERT INTO `animal`
    VALUES
        (4, 'cat', 15);

INSERT INTO `animal`
    VALUES
        (5, 'dog', 16);

# 查询重复数据
SELECT *
    FROM `test`.`animal`
    WHERE `name` IN (
                    # 派生表1
                    SELECT `t`.`name`
                        FROM (
                             SELECT `name`
                                 FROM `test`.`animal`
                                 GROUP BY `name`
                                 HAVING COUNT(1) > 1) `t`)
      AND `id` NOT IN (
                      # 派生表2
                      SELECT `t1`.`id`
                          FROM (
                               SELECT MIN(`id`) AS `id`
                                   FROM `test`.`animal`
                                   GROUP BY `name`) `t1`);

# 删除重复数据
DELETE
    FROM `animal`
    WHERE `name` IN (
                    SELECT `t`.`name`
                        FROM (
                             SELECT `name`
                                 FROM `animal`
                                 GROUP BY `name`
                                 HAVING COUNT(1) > 1) `t`)
      AND `id` NOT IN (
                      SELECT `t1`.`id`
                          FROM (
                               SELECT MIN(`id`) AS `id`
                                   FROM `animal`
                                   GROUP BY `name`) `t1`);

# 查询所有表的注释
SELECT `table_name`, `table_comment`
    FROM `information_schema`.`tables`
    WHERE `table_schema` = 'mysql'
    ORDER BY `table_name`;


SHOW FULL COLUMNS FROM `mysql`.`user`;

# 查询所有字段的注释
SELECT `column_name`, `column_type`, `column_comment`
    FROM `information_schema`.`columns`
    WHERE `table_schema` = 'mysql' AND `table_name` = 'user'
    ORDER BY `table_name`;

# 【MySQL 5.7 8.0 通用】查询出等待事务ID，等待的线程，等待的查询优化语句，阻塞的事务ID，阻塞的线程，阻塞的查询
SELECT `w`.`locked_table`,
       `w`.`locked_index`,
       `w`.`locked_type`,
       `w`.`waiting_pid`,
       `b`.`thread_id` AS `waiting_thread_id`,
       `w`.`waiting_trx_id`,
       `w`.`waiting_query`,
       `w`.`waiting_lock_mode`,
       `w`.`waiting_trx_rows_locked`,
       `w`.`waiting_trx_rows_modified`,
       `w`.`blocking_pid`,
       `r`.`thread_id` AS `blocking_thread_id`,
       `w`.`blocking_trx_id`,
       `s`.`sql_text`  AS `blocking_query`,
       `w`.`blocking_lock_mode`,
       `w`.`blocking_trx_rows_locked`,
       `w`.`blocking_trx_rows_modified`,
       `w`.`sql_kill_blocking_query`
    FROM `sys`.`innodb_lock_waits`                                  `w`
        INNER JOIN `performance_schema`.`threads`                   `b`
                       ON `b`.`processlist_id` = `w`.`waiting_pid`
        INNER JOIN `performance_schema`.`threads`                   `r`
                       ON `r`.`processlist_id` = `w`.`blocking_pid`
        INNER JOIN `performance_schema`.`events_statements_current` `s`
                       ON `r`.`thread_id` = `s`.`thread_id`;

# 【MySQL 8.0】查询出等待事务ID，等待的线程，等待的查询优化语句，阻塞的事务ID，阻塞的线程，阻塞的查询
SELECT `b`.`processlist_id`                   AS `waiting_pid`,
       `b`.`thread_id`                        AS `waiting_thread_id`,
       `w`.`requesting_engine_transaction_id` AS `waiting_trx_id`,
       `b`.`processlist_info`                 AS `waiting_query`,
       `b`.`type`,
       `r`.`processlist_id`                   AS `blocking_pid`,
       `r`.`thread_id`                        AS `blocking_thread_id`,
       `w`.`blocking_engine_transaction_id`   AS `blocking_trx_id`,
       `s`.`sql_text`                         AS `blocking_query`
    FROM `performance_schema`.`data_lock_waits`                     `w`
        INNER JOIN `performance_schema`.`threads`                   `b`
                       ON `b`.`thread_id` = `w`.`requesting_thread_id`
        INNER JOIN `performance_schema`.`threads`                   `r`
                       ON `r`.`thread_id` = `w`.`blocking_thread_id`
        INNER JOIN `performance_schema`.`events_statements_current` `s`
                       ON `r`.`thread_id` = `s`.`thread_id`;


#### 反范式优化
## 创建库
CREATE DATABASE `lft`;
## 使用库
USE `lft`;
## 创建学生表
CREATE TABLE `student` (
    `stu_id`      INT PRIMARY KEY AUTO_INCREMENT,
    `stu_name`    VARCHAR(25),
    `create_time` DATETIME);
## 课程评论表
CREATE TABLE `class_comment` (
    `comment_id`   INT PRIMARY KEY AUTO_INCREMENT,
    `class_id`     INT,
    `comment_text` VARCHAR(35),
    `comment_time` DATETIME,
    `stu_id`       INT);
## 创建存储过程向学生表中添加数据
DELIMITER //
CREATE PROCEDURE `batch_insert_student`(IN `start` INT(10), IN `max_num` INT(10))
BEGIN
    DECLARE `i` INT DEFAULT 0;
    DECLARE `date_start` DATETIME DEFAULT ('2017-01-01 00:00:00');
    DECLARE `date_temp` DATETIME;
    SET `date_temp` = `date_start`;
    SET AUTOCOMMIT = 0;
    REPEAT
        SET `i` = `i` + 1;
        SET `date_temp` = DATE_ADD(`date_temp`, INTERVAL RAND() * 60 SECOND);
        INSERT INTO `student`(`stu_id`, `stu_name`, `create_time`)
            VALUES
                ((`start` + `i`), CONCAT('stu_', `i`), `date_temp`);
    UNTIL `i` = `max_num`
        END REPEAT;
    COMMIT;
END //
DELIMITER ;

## 调用存储过程，学生id 从10001
CALL `batch_insert_student`(10000, 1000000);

## 创建存储过程向学生评论表中添加数据
DELIMITER //
CREATE PROCEDURE `batch_insert_class_comments`(IN `start` INT(10), IN `max_num` INT(10))
BEGIN
    DECLARE `i` INT DEFAULT 0;
    DECLARE `date_start` DATETIME DEFAULT ('2018-01-01 00:00:00');
    DECLARE `date_temp` DATETIME;
    DECLARE `comment_text` VARCHAR(25);
    DECLARE `stu_id` INT;
    SET `date_temp` = `date_start`;
    SET AUTOCOMMIT = 0;
    REPEAT
        SET `i` = `i` + 1;
        SET `date_temp` = DATE_ADD(`date_temp`, INTERVAL RAND() * 60 SECOND);
        SET `comment_text` = SUBSTR(MD5(RAND()), 1, 20);
        SET `stu_id` = FLOOR(RAND() * 100000);
        INSERT INTO `class_comment`(`comment_id`, `class_id`, `comment_text`, `comment_time`, `stu_id`)
            VALUES
                ((`start` + `i`), 10001, `comment_text`, `date_temp`, `stu_id`);
    UNTIL `i` = `max_num`
        END REPEAT;
    COMMIT;
END //
DELIMITER ;

## 调用存储过程 学生id 从10001
CALL `batch_insert_class_comments`(10000, 1000000);

## 查看源代码下学生表的数量
SELECT COUNT(*)
    FROM `student`;

SELECT *
    FROM `student`
    LIMIT 1;

SELECT *
    FROM `class_comment`
    LIMIT 100;

# 查询出每个学生的评论内容，时间，学生名字，使用外连接
SELECT SQL_NO_CACHE `cc`.`comment_text`, `cc`.`comment_time`, `s`.`stu_name`
    FROM `lft`.`class_comment`    `cc`
        LEFT JOIN `lft`.`student` `s`
                      ON `s`.`stu_id` = `cc`.`stu_id`
    WHERE `cc`.`class_id` = 10001
    ORDER BY `cc`.`comment_id` DESC
    LIMIT 100000;

# 反范式表创建
CREATE TABLE `class_comment1` AS
    SELECT *
        FROM `class_comment`;

# 添加索引
ALTER TABLE `class_comment1`
    ADD PRIMARY KEY (`comment_id`);

# 查看索引
SHOW INDEX FROM `class_comment1`;

# 添加列
ALTER TABLE `class_comment1`
    ADD `stu_name` VARCHAR(25);

# 修改数据
UPDATE `class_comment1` `c`
SET `c`.`stu_name` = (
                     SELECT `s`.`stu_name`
                         FROM `student` `s`
                         WHERE `c`.`stu_id` = `s`.`stu_id`);

# 查询同样需求
SELECT SQL_NO_CACHE `comment_text`, `comment_time`, `stu_name`
    FROM `class_comment1`
    WHERE `class_id` = 10001
    ORDER BY `comment_id` DESC
    LIMIT 100000;


# 创建视图
CREATE VIEW `com_txt_time_stu` AS
    SELECT SQL_NO_CACHE `cc`.`comment_text`, `cc`.`comment_time`, `s`.`stu_name`
        FROM `lft`.`class_comment`    `cc`
            LEFT JOIN `lft`.`student` `s`
                          ON `s`.`stu_id` = `cc`.`stu_id`
        WHERE `cc`.`class_id` = 10001
        ORDER BY `cc`.`comment_id` DESC
        LIMIT 100000;

# 走视图中查询
SELECT *
    FROM `com_txt_time_stu`;

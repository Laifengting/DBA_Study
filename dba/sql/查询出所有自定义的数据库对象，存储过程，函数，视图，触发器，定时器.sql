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
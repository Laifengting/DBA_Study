#### ��ѯ���洢���治�� Innodb ���Զ���ı�
SELECT `table_schema`, `table_name`, `engine`, `sys`.`format_bytes`(`data_length`) AS `data_size`
    FROM `information_schema`.`tables`
    WHERE `engine` <> 'InnoDB'
      AND `table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema');
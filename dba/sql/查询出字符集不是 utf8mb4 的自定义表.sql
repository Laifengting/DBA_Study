#### ��ѯ���ַ������� utf8mb4 �Ķ�����ı��Ż���
SELECT CONCAT(`table_schema`, '.', `table_name`)   AS `tbl_name`,
       `character_set_name`,
       GROUP_CONCAT(`column_name` SEPARATOR ' : ') AS `column_list`
    FROM `information_schema`.`columns`
    WHERE `data_type` IN ('varchar', 'longtext', 'text', 'mediumtext', 'char')
      AND `character_set_name` <> 'utf8mb4'
      AND `table_schema` NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
    GROUP BY `tbl_name`, `character_set_name`;
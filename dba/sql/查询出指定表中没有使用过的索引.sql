# ��ѯ��ָ������û��ʹ�ù�������
SELECT *
    FROM `sys`.`schema_unused_indexes`
    WHERE `object_schema` NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND `object_name` = 'orders';
# sys.session ����Ҳ�ܿ������� # ����ϵͳ���ĸ��߳�ռ��CPU��ࡣ��ִ�е�ʲô���
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
SHOW DATABASES;
USE bzbh;

SHOW CREATE DATABASE bzbh;

SHOW TABLES;

SELECT order_num
	FROM orderitems
	WHERE prod_id = 'TNT2';

SELECT cust_id
	FROM orders
	WHERE order_num IN (
					   SELECT order_num
						   FROM orderitems
						   WHERE prod_id = 'TNT2');

EXPLAIN
	SELECT *
		FROM customers
		WHERE cust_id IN (
						 SELECT cust_id
							 FROM orders
							 WHERE order_num IN (
												SELECT order_num
													FROM orderitems
													WHERE prod_id = 'TNT2'));


DESC customers;

# 需要显示customers 表中每个客户的订单总数。
SELECT cust_name, cust_state,
	   (
	   SELECT COUNT(*)
		   FROM orders
		   WHERE orders.cust_id = customers.cust_id) orders
	FROM customers
	ORDER BY cust_name;

SELECT cust_name, cust_state, cust_id,
	   (
	   SELECT COUNT(*)
		   FROM orders
		   WHERE orders.cust_id = customers.cust_id)
	FROM customers
	ORDER BY cust_name;

USE information_schema;

SELECT table_schema, table_name, engine, sys.format_bytes(data_length) data_size
	FROM tables
	WHERE engine <> 'InnoDB'
	  AND table_schema NOT IN ('mysql', 'performance_schema', 'information_schema');

DESC tables;

SELECT *
	FROM tables;


SELECT CONCAT(table_schema,'.',table_name) name,
	   character_set_name,
	   GROUP_CONCAT(column_name SEPARATOR ' : ') column_list
	FROM information_schema.columns
	WHERE data_type IN ('varchar', 'longtext', 'text', 'mediumtext', 'char')
	  AND character_set_name <> 'utf8mb4'
	  AND table_schema NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys')
	GROUP BY name, character_set_name;


-- ============================================================================
-- TABLES WITHOUT INDICES BUT HAVE A PRIMARY KEY
-- ============================================================================
SELECT *
	FROM information_schema.tables AS main_table
	WHERE table_schema = 'dbt3'
	  -- ============================================================================
	  -- FIND TABLES WITH A PRIMARY KEY
	  -- ============================================================================
	  AND table_name IN (
						SELECT table_name
							FROM (
								 SELECT table_name, index_name, COUNT(index_name) test
									 FROM information_schema.statistics
									 WHERE table_schema = 'dbt3'
									   AND index_name = 'PRIMARY'
									 GROUP BY table_name, index_name) AS tab_ind_cols
							GROUP BY table_name)
	  -- ============================================================================
	  -- FIND TABLES WITH OUT ANY INDICES
	  -- ============================================================================
	  AND table_name NOT IN (
							SELECT table_name
								FROM (
									 SELECT table_name, index_name, COUNT(index_name) test
										 FROM information_schema.statistics
										 WHERE table_schema = 'dbt3'
										   AND index_name <> 'PRIMARY'
										 GROUP BY table_name, index_name) AS tab_ind_cols
								GROUP BY table_name
	);


SELECT *
	FROM information_schema.tables AS main_table
	WHERE table_schema = 'dbt3' AND
		  table_name NOT IN (
							SELECT table_name
								FROM (
									 SELECT table_name, index_name, COUNT(index_name) test
										 FROM information_schema.statistics
										 WHERE table_schema = 'dbt3'
										   AND index_name <> 'PRIMARY'
										 GROUP BY table_name, index_name) AS tab_ind_cols
								GROUP BY table_name
		  );


SELECT a.table_schema db_name, a.table_name, a.column_name
	FROM information_schema.columns           a
	LEFT JOIN (
			  SELECT 'etl_stamp' column_name) b
			  ON a.column_name = b.column_name
	LEFT JOIN information_schema.statistics   c
			  ON a.table_schema = c.table_schema
				  AND a.table_name = c.table_name
				  AND a.column_name = c.column_name
	WHERE a.table_schema IN ('bzbh', 'dbt3', 'emp')
	  AND b.column_name IS NOT NULL
	  AND c.seq_in_index IS NULL;

# 查询出没有任何索引的表
SELECT *
	FROM information_schema.tables AS main_table
	WHERE table_schema IN ('bzbh', 'dbt3', 'emp') AND
		  table_name NOT IN (
							SELECT table_name
								FROM (
									 SELECT table_name, index_name, COUNT(index_name) test
										 FROM information_schema.statistics
										 WHERE table_schema IN ('bzbh', 'dbt3', 'emp')
										   AND index_name <> 'PRIMARY'
										 GROUP BY table_name, index_name) AS tab_ind_cols
								GROUP BY table_name);

USE sys;
SHOW TABLES;
SELECT *
	FROM schema_unused_indexes;


USE information_schema;
EXPLAIN
	SELECT s.table_schema db_name, s.table_name, s.index_name, s.cardinality, t.table_rows, (s.cardinality / t.table_rows) threshold
		FROM statistics  s
		LEFT JOIN tables t
				  ON t.table_schema = s.table_schema
					  AND t.table_name = s.table_name
					  AND t.table_catalog = s.table_catalog
		WHERE s.cardinality / t.table_rows < 0.1
		  AND s.table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys');


EXPLAIN
	SELECT *
		FROM part
		WHERE p_partkey IN (
						   SELECT l_partkey
							   FROM lineitem
							   WHERE l_shipdate BETWEEN '1997-01-01' AND '1997-01-07')
		ORDER BY p_retailprice DESC
		LIMIT 10;

EXPLAIN
	SELECT p.*
		FROM part                                                             p
		LEFT JOIN (
				  SELECT DISTINCT l_partkey
					  FROM lineitem
					  WHERE l_shipdate BETWEEN '1997-01-01' AND '1997-01-07') b
				  ON p.p_partkey = b.l_partkey
		ORDER BY p.p_retailprice DESC
		LIMIT 10;

EXPLAIN
	SELECT a.*
		FROM part                                                        a,
			 (
			 SELECT DISTINCT l_partkey
				 FROM lineitem
				 WHERE l_shipdate BETWEEN '1997-01-01' AND '1997-01-07') b
		WHERE a.p_partkey = b.l_partkey
		ORDER BY a.p_retailprice DESC
		LIMIT 10;



EXPLAIN
	SELECT MAX(l_extendedprice)
		FROM orders, lineitem
		WHERE o_orderdate BETWEEN '1995-01-01' AND '1995-01-31' AND l_orderkey = o_orderkey;

EXPLAIN
	SELECT *
		FROM lineitem
		WHERE l_shipdate <= '1995-12-31'
	UNION
	SELECT *
		FROM lineitem
		WHERE l_shipdate >= '1997-01-01';


EXPLAIN
	SELECT emp_no, dept_no,
		   (
		   SELECT COUNT(1)
			   FROM emp.dept_emp t2
			   WHERE t1.emp_no <= t2.emp_no) row_num
		FROM emp.dept_emp t1;

EXPLAIN
	SELECT *
		FROM orders
		WHERE o_orderdate IN (
							 SELECT MAX(l_shipdate)
								 FROM lineitem
								 GROUP BY (DATE_FORMAT(l_shipdate,'%Y%M')));


SELECT p1.prod_id, p1.prod_name
	FROM products p1, products p2
	WHERE p1.vend_id = p2.vend_id
	  AND p2.prod_id = 'DTNTR';

SELECT *
	FROM products;

SELECT vend_name, prod_name, prod_price
	FROM vendors, products
	WHERE vendors.vend_id = products.vend_id;

SELECT vend_name, prod_name, prod_price
	FROM vendors
	INNER JOIN products
			   ON vendors.vend_id = products.vend_id;

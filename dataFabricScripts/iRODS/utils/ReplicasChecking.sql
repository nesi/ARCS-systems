SELECT A2.data_owner_name, SUBSTRING(A2.data_path FROM POSITION('ARCS' in A2.data_path)-1) FROM (((SELECT DISTINCT data_id FROM r_data_main) EXCEPT (SELECT 
data_id FROM r_data_main WHERE data_repl_num > 0)) AS A1 INNER JOIN (SELECT data_id, data_owner_name, data_path FROM r_data_main) AS A2 ON A1.data_id = A2.data_id) WHERE 
A2.data_path NOT LIKE '%/trash/%' GROUP BY A2.data_owner_name,  A2.data_path ORDER BY A2.data_owner_name,  A2.data_path;

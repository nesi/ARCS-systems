SELECT A2.data_owner_name, A2.resc_name, A3.coll_name||'/'||A2.data_name FROM ((SELECT DISTINCT data_id FROM 
r_data_main) EXCEPT (SELECT data_id FROM r_data_main WHERE data_repl_num > 0)) AS A1 INNER JOIN (SELECT data_id, 
coll_id, data_name, data_owner_name, resc_name FROM r_data_main WHERE data_path NOT LIKE '%/trash/%') AS A2 ON
A1.data_id = A2.data_id INNER JOIN (SELECT coll_id, coll_name FROM r_coll_main WHERE coll_name NOT LIKE 
'/ARCS/trash/%') as A3 on A2.coll_id = A3.coll_id GROUP BY A2.data_owner_name, A2.resc_name, A3.coll_name, 
A2.data_name ORDER BY A2.data_owner_name, A2.resc_name, A3.coll_name, A2.data_name;

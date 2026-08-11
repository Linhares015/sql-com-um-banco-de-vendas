SET TIME ZONE 'UTC';
SELECT status_logistico,count(*) pedidos FROM pedidos GROUP BY 1 ORDER BY 1;

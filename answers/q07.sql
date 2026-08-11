SET TIME ZONE 'UTC';
SELECT extract(year FROM data_pedido AT TIME ZONE 'America/Sao_Paulo')::int ano,count(*) pedidos FROM pedidos GROUP BY 1 ORDER BY 1;

SET TIME ZONE 'UTC';
SELECT regiao,count(*) clientes FROM clientes GROUP BY regiao ORDER BY regiao;

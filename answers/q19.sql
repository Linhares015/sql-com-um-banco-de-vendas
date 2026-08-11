SET TIME ZONE 'UTC';
SELECT c.cliente_id,c.codigo_cliente,c.nome FROM clientes c WHERE NOT EXISTS (SELECT 1 FROM pedidos p WHERE p.cliente_id=c.cliente_id AND p.status_logistico<>'CANCELADO') ORDER BY c.codigo_cliente;

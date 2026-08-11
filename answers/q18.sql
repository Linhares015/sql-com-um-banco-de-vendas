SET TIME ZONE 'UTC';
SELECT r.produto_id,r.sku,r.nome FROM produtos r WHERE NOT EXISTS (SELECT 1 FROM itens_pedido i JOIN pedidos p USING(pedido_id) WHERE i.produto_id=r.produto_id AND p.status_logistico<>'CANCELADO') ORDER BY r.sku;

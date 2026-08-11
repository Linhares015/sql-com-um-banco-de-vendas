SET TIME ZONE 'UTC';
SELECT p.pedido_id,p.numero_pedido,sum(i.quantidade*i.desconto_unitario) desconto_mercadoria FROM pedidos p JOIN itens_pedido i USING(pedido_id) WHERE p.status_logistico<>'CANCELADO' GROUP BY p.pedido_id,p.numero_pedido ORDER BY p.numero_pedido;

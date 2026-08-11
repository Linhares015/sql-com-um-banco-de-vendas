SET TIME ZONE 'UTC';
SELECT p.pedido_id,p.numero_pedido,sum(i.quantidade*(i.preco_unitario-i.desconto_unitario)) receita_mercadoria_liquida FROM pedidos p JOIN itens_pedido i USING(pedido_id) WHERE p.status_logistico<>'CANCELADO' GROUP BY p.pedido_id,p.numero_pedido ORDER BY p.numero_pedido;

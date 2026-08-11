SET TIME ZONE 'UTC';
SELECT pedido_id,numero_pedido,(data_pedido AT TIME ZONE 'America/Sao_Paulo')::date data_pedido_civil FROM pedidos WHERE cliente_id IS NULL ORDER BY data_pedido,pedido_id;

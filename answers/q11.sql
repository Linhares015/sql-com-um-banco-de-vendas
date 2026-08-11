SET TIME ZONE 'UTC';
SELECT i.item_pedido_id,i.pedido_id,i.numero_item,i.produto_id,i.quantidade,i.preco_unitario,i.quantidade*i.preco_unitario valor_bruto_item FROM itens_pedido i ORDER BY i.pedido_id,i.numero_item;

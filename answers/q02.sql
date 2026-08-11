SET TIME ZONE 'UTC';
SELECT produto_id,sku,nome,preco_lista_atual FROM produtos WHERE preco_lista_atual BETWEEN 50.00 AND 100.00 ORDER BY preco_lista_atual,sku;

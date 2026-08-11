SET TIME ZONE 'UTC';
SELECT produto_id,sku,nome,preco_lista_atual FROM produtos WHERE ativo ORDER BY preco_lista_atual DESC,sku LIMIT 10;

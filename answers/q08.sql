SET TIME ZONE 'UTC';
SELECT min(preco_lista_atual) preco_minimo,max(preco_lista_atual) preco_maximo,avg(preco_lista_atual) preco_medio FROM produtos;

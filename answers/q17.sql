SET TIME ZONE 'UTC';
SELECT c.categoria_id,c.nome categoria,coalesce(sum(v.receita_mercadoria_pre_devolucao),0) receita_mercadoria_liquida FROM categorias c LEFT JOIN produtos r USING(categoria_id) LEFT JOIN vw_itens_venda v ON v.produto_id=r.produto_id AND v.elegivel GROUP BY c.categoria_id,c.nome ORDER BY receita_mercadoria_liquida DESC,c.nome;

SET TIME ZONE 'UTC';
SELECT c.categoria_id,c.nome categoria,coalesce(sum(v.quantidade_devolvida_concluida),0) unidades_devolvidas FROM categorias c LEFT JOIN produtos r USING(categoria_id) LEFT JOIN vw_itens_venda v ON v.produto_id=r.produto_id AND v.elegivel GROUP BY c.categoria_id,c.nome ORDER BY unidades_devolvidas DESC,c.nome;

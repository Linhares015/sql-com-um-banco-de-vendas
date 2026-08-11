SET TIME ZONE 'UTC';
SELECT v.vendedor_id,v.matricula,v.nome,v.equipe FROM vendedores v WHERE NOT EXISTS (SELECT 1 FROM pedidos p WHERE p.vendedor_id=v.vendedor_id AND p.status_logistico<>'CANCELADO') ORDER BY v.matricula;

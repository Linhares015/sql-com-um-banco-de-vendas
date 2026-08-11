SET TIME ZONE 'UTC';
SELECT date_trunc('month',p.data_pedido AT TIME ZONE 'America/Sao_Paulo')::date mes,sum(v.receita_mercadoria_pos_devolucao) receita_mercadoria_pos_devolucao FROM vw_itens_venda v JOIN pedidos p USING(pedido_id) WHERE v.elegivel GROUP BY 1 ORDER BY 1;

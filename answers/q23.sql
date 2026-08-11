SET TIME ZONE 'UTC';
SELECT date_trunc('month',p.data_pedido AT TIME ZONE 'America/Sao_Paulo')::date mes,sum(v.desconto) desconto_mercadoria,sum(v.bruto) receita_bruta,100*sum(v.desconto)/nullif(sum(v.bruto),0) desconto_efetivo_pct FROM vw_itens_venda v JOIN pedidos p USING(pedido_id) WHERE v.elegivel GROUP BY 1 ORDER BY 1;

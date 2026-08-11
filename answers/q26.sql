SET TIME ZONE 'UTC';
SELECT c.codigo,c.nome,count(p.pedido_id) pedidos,count(p.pedido_id) FILTER(WHERE p.status_logistico='CANCELADO') pedidos_cancelados,100::numeric*count(p.pedido_id) FILTER(WHERE p.status_logistico='CANCELADO')/nullif(count(p.pedido_id),0) taxa_cancelamento_pct FROM canais c LEFT JOIN pedidos p USING(canal_id) GROUP BY c.canal_id,c.codigo,c.nome ORDER BY c.codigo;

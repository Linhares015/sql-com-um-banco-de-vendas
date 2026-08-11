SET TIME ZONE 'UTC';
SELECT p.numero_pedido,c.saldo_financeiro,c.total_esperado,c.diferenca FROM vw_pagamentos_conciliacao c JOIN pedidos p USING(pedido_id) ORDER BY p.numero_pedido;

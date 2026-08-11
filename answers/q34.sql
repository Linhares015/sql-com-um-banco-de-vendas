SET TIME ZONE 'UTC';
SELECT date_trunc('month',d.data_encerramento AT TIME ZONE 'America/Sao_Paulo')::date mes,sum(i.valor_reembolso) reembolso_concluido FROM devolucoes d JOIN itens_devolucao i USING(devolucao_id) WHERE d.status='CONCLUIDA' GROUP BY 1 ORDER BY 1;

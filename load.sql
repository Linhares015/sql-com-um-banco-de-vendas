\set ON_ERROR_STOP on
SET TIME ZONE 'UTC'; BEGIN;
\copy categorias(nome,descricao,ativa) FROM '/workspace/build/categorias.csv' CSV HEADER
\copy produtos(sku,nome,categoria_id,preco_lista_atual,custo_padrao_atual,data_lancamento,data_descontinuacao,ativo) FROM '/workspace/build/produtos.csv' CSV HEADER NULL ''
\copy clientes(codigo_cliente,nome,email,data_nascimento,cidade,uf,regiao,data_cadastro,aceita_marketing) FROM '/workspace/build/clientes.csv' CSV HEADER NULL ''
\copy canais(codigo,nome,tipo,data_inicio_operacao) FROM '/workspace/build/canais.csv' CSV HEADER
\copy vendedores(matricula,nome,equipe,data_admissao,data_desligamento) FROM '/workspace/build/vendedores.csv' CSV HEADER NULL ''
\copy pedidos(numero_pedido,data_pedido,cliente_id,canal_id,vendedor_id,status_logistico,status_devolucao,cidade_entrega,uf_entrega,valor_frete_cotado,data_faturamento,data_entrega,motivo_cancelamento) FROM '/workspace/build/pedidos.csv' CSV HEADER NULL ''
\copy itens_pedido(pedido_id,numero_item,produto_id,quantidade,preco_unitario,desconto_unitario,custo_unitario) FROM '/workspace/build/itens_pedido.csv' CSV HEADER
\copy devolucoes(pedido_id,protocolo,data_solicitacao,status,motivo,data_encerramento) FROM '/workspace/build/devolucoes.csv' CSV HEADER NULL ''
\copy itens_devolucao(devolucao_id,item_pedido_id,quantidade_devolvida,valor_reembolso) FROM '/workspace/build/itens_devolucao.csv' CSV HEADER
\copy pagamentos(pedido_id,sequencia,data_pagamento,meio_pagamento,tipo_evento,status,valor,parcelas,pagamento_origem_id,devolucao_id) FROM '/workspace/build/pagamentos.csv' CSV HEADER NULL ''
COMMIT; ANALYZE;

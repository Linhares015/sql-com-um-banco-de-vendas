# Matriz de contratos das respostas

Fonte das perguntas: `OUTLINE-v2.md`. Os contratos explicitamente reescritos em `DATASET-DESIGN-v1.2.md` prevalecem (Q24, Q29, Q32, Q35–Q40). As linhas esperadas são as do snapshot v1.2 congelado em `results/manifest.json`.

| Q | Pergunta literal | Grão | População e métricas | Ordem/desempate | Arquivo | Linhas |
|---|---|---|---|---|---|---:|
| 01 | Quais categorias estão ativas? | categoria | `ativa`; atributos da categoria | nome, id | q01.sql | 8 |
| 02 | Quais produtos custam entre R$ 50 e R$ 100 no preço atual? | SKU | preço atual 50–100 inclusivo | preço, SKU | q02.sql | 37 |
| 03 | Quais produtos foram descontinuados? | SKU | descontinuação não nula | data, SKU | q03.sql | 0 |
| 04 | Quantos clientes existem em cada região? | região | todos os clientes; contagem | região | q04.sql | 5 |
| 05 | Quantos clientes informaram data de nascimento? | total | datas não nulas; `count(data_nascimento)` | única linha | q05.sql | 1 |
| 06 | Quais pedidos foram feitos como convidado? | pedido | `cliente_id IS NULL` | data, id | q06.sql | 1440 |
| 07 | Quantos pedidos foram criados em cada ano? | ano civil SP | todos os pedidos; contagem | ano | q07.sql | 3 |
| 08 | Qual é o menor, o maior e o preço médio atual dos produtos? | total | catálogo; min/max/média de preço atual | única linha | q08.sql | 1 |
| 09 | Quais são os 10 produtos atuais mais caros? | SKU | catálogo com `ativo = true`; preço atual | preço desc, SKU | q09.sql | 10 |
| 10 | Quantos pedidos há em cada status? | status | todos os pedidos; contagem | status | q10.sql | 4 |
| 11 | Qual foi o valor bruto de cada item vendido? | item de pedido | todas as 27.600 linhas; qtd×preço | pedido, número item | q11.sql | 27600 |
| 12 | Qual é o valor líquido de mercadoria de cada pedido não cancelado? | pedido | não cancelados; Σ qtd×(preço−desconto) | número | q12.sql | 11160 |
| 13 | Quanto foi concedido em desconto por pedido? | pedido | não cancelados; Σ qtd×desconto | número | q13.sql | 11160 |
| 14 | Qual foi a receita líquida de mercadorias por mês do pedido? | mês civil SP | itens elegíveis; receita pré-devolução | mês | q14.sql | 36 |
| 15 | Quantos pedidos e quanta receita cada canal gerou? | canal | não cancelados; pedidos e receita pré | código | q15.sql | 5 |
| 16 | Qual é o ticket médio por canal? | canal | não cancelados; receita/pedidos, sem frete | código | q16.sql | 5 |
| 17 | Quais categorias geraram mais receita líquida antes de devoluções? | categoria | itens elegíveis; Σ receita pré | receita desc, nome | q17.sql | 8 |
| 18 | Quais produtos nunca foram vendidos? | SKU | sem item elegível | SKU | q18.sql | 8 |
| 19 | Quais clientes cadastrados nunca compraram? | cliente | sem pedido não cancelado | código | q19.sql | 400 |
| 20 | Quais vendedores não fizeram vendas? | vendedor | sem pedido não cancelado | matrícula | q20.sql | 2 |
| 21 | Qual vendedor gerou mais receita em cada equipe? | equipe/vendedor | venda assistida elegível; maior receita; `ROW_NUMBER` por equipe | receita desc, matrícula asc; uma linha por equipe | q21.sql | 3 |
| 22 | Qual é a participação percentual de cada canal na receita? | canal | receita pré elegível / total oficial | código | q22.sql | 5 |
| 23 | Qual foi o percentual efetivo de desconto por mês? | mês civil SP | Σ desconto / Σ bruto elegível | mês | q23.sql | 36 |
| 24 | Quais pedidos tiveram mais de um meio de pagamento aprovado? | pedido | contrato v1.2: 2 cobranças e 2 meios, total pré+frete | número | q24.sql | 480 |
| 25 | O saldo dos pagamentos confere com pedidos e reembolsos? | pedido | conciliação financeira; diferença exata | número | q25.sql | 12000 |
| 26 | Qual é a taxa de cancelamento por canal? | canal | cinco canais; `count(pedido_id)` e `100::numeric × cancelados / pedidos` | código | q26.sql | 5 |
| 27 | Quantos clientes compraram uma vez, duas vezes e três ou mais? | faixa | compradores identificados não cancelados | faixa 1/2/3+ | q27.sql | 3 |
| 28 | Qual é a taxa de recompra oficial de 2023–2025? | total | 3.600 compradores; ≥2 / total; taxa `numeric` exata e apresentação arredondada | única linha | q28.sql | 1 |
| 29 | Quais clientes estão inativos há 90 dias em 31/12/2025? | cliente | compradores; última compra antes do corte v1.2 | última compra, id | q29.sql | 2479 |
| 30 | Qual foi o intervalo médio entre a primeira e a segunda compra? | total | identificados com segunda compra; diferença civil SP | única linha | q30.sql | 1 |
| 31 | Quantas unidades foram devolvidas por categoria? | categoria | devoluções concluídas; unidades | unidades desc, nome | q31.sql | 8 |
| 32 | Qual é a taxa de devolução por unidades de cada produto? | SKU | 120 produtos; concluídas/vendidas, `NULL` sem venda | taxa desc nulls last, SKU | q32.sql | 120 |
| 33 | Qual foi a receita líquida pós-devolução por mês do pedido? | mês civil SP | itens elegíveis; receita pós | mês | q33.sql | 36 |
| 34 | Quanto foi reembolsado por mês da devolução? | mês civil SP | devoluções concluídas; valor reembolso | mês | q34.sql | 13 |
| 35 | Qual é a margem de mercadoria por produto? | SKU | 120 produtos no período civil 2023–2025; receita pós−custo histórico mantido, contagem e valor original das linhas de margem unitária negativa | margem desc, SKU | q35.sql | 120 |
| 36 | Qual é o ranking de produtos dentro de cada categoria? | SKU/categoria | receita pré elegível; `dense_rank` | categoria, posição, receita, SKU | q36.sql | 120 |
| 37 | Como cada mês cresceu ou caiu contra o mesmo mês do ano anterior? | mês civil SP | série densa; receita pré e LAG 12 | mês | q37.sql | 36 |
| 38 | Qual é a média móvel de três meses da receita? | mês civil SP | série densa; janela 2 precedentes | mês | q38.sql | 36 |
| 39 | Que parcela da receita de cada mês vem de clientes recorrentes? | mês civil SP | v1.2: convidado/primeira/recorrente, pré; total e percentuais | mês | q39.sql | 36 |
| 40 | Qual combinação de mês, canal e categoria merece investigação por queda simultânea de receita e margem? | mês/canal/categoria | v1.2: self-join mesma chave e mês−1 ano; 20 maiores quedas | score, quedas, mês, canal, categoria | q40.sql | 20 |

## Resolução Q14/Q17

O achado antigo chamava de Q14 uma consulta por categoria e encontrou fanout. Pela numeração oficial, Q14 é mensal; por isso foi realinhada ao mês, usando a receita no grão de item antes da agregação. O corte por categoria pertence a Q17 e também parte do item. `verify-canonical-results.sh` confere Q14 e Q17 contra os resultados versionados; as duas somas reconciliam com o mesmo total oficial.

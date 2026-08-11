# Briefing executável do projeto final

## Escopo da entrega

Monte o projeto em um diretório local de trabalho. O objetivo é permitir que outra pessoa reproduza a análise, revise cada etapa e confira os números antes de qualquer uso externo.

A pergunta final é: quais combinações de mês civil do pedido, canal e categoria entram primeiro numa investigação por queda simultânea de receita pós-devolução e margem de mercadoria contra o mesmo mês do ano anterior?

A resposta é uma fila, não uma atribuição de causa.

## Definições e corte

Registre estas definições em `docs/DEFINITIONS.md`:

- dataset: Aurora Casa & Co., versão de desenho 1.2, dados sintéticos;
- seed: `20260810`;
- SGBD: PostgreSQL 16 ou superior;
- imagem aprovada: `postgres@sha256:95206741a5b214807675e14165369d05b93a9cf692223b616d07cca227e74b0b`;
- período civil dos pedidos: `2023-01-01` a `2025-12-31`, inclusive;
- calendário analítico: `America/Sao_Paulo`;
- corte operacional do dataset: instante imediatamente anterior a `2026-02-15 00:00:00` em São Paulo;
- população comercial: itens de pedidos não cancelados (`vw_itens_venda.elegivel`);
- receita: `receita_mercadoria_pos_devolucao`, com reembolso concluído atribuído ao mês do pedido original e sem frete;
- custo: `custo_mercadoria_mantida`, calculado com `itens_pedido.custo_unitario` histórico e apenas unidades mantidas;
- margem de mercadoria: receita pós-devolução menos custo histórico das unidades mantidas;
- grão comparado: `(mes, canal_id, categoria_id)`;
- par anual: mesmas chaves, com mês anterior exatamente doze meses antes;
- candidato: há unidades elegíveis nos dois meses, e receita e margem atuais são estritamente menores que as anteriores;
- materialidade: `score_investigacao = queda_receita_abs + queda_margem_abs`;
- ordenação: score desc, queda de receita desc, queda de margem desc, mês asc, código do canal asc, nome da categoria asc;
- nomes de canal e categoria entram somente depois da comparação por chaves.

Use sempre “margem de mercadoria”. O projeto não calcula lucro nem margem de contribuição.

## Estrutura sugerida

```text
projeto-final/
├── README.md
├── docs/
│   ├── DEFINITIONS.md
│   ├── RECONCILIATIONS.md
│   ├── CHECKS.md
│   └── EXECUTIVE-COMMENT.md
├── sql/
│   ├── 01-base-pedido.sql
│   ├── 02-base-item-liquido.sql
│   ├── 03-q40-fila-investigacao.sql
│   ├── 04-reconciliacoes.sql
│   └── 05-checagens.sql
├── results/
│   ├── q40.csv
│   └── q40-candidates-count.txt
└── manifests/
    ├── DATASET-VERSION.md
    └── SHA256SUMS
```

`README.md` deve informar a ordem de execução e o grão de cada arquivo SQL. Não inclua credenciais, host ou dados de conexão.

## Duas consultas-base

### Uma linha por pedido

Salve como `sql/01-base-pedido.sql`:

```sql
SET TIME ZONE 'UTC';

SELECT
    m.pedido_id,
    m.numero_pedido,
    date_trunc(
        'month',
        m.data_pedido AT TIME ZONE 'America/Sao_Paulo'
    )::date AS mes,
    m.cliente_id,
    m.canal_id,
    m.receita_mercadoria_pos_devolucao,
    m.custo_mercadoria_mantida,
    m.margem_mercadoria
FROM vw_pedidos_metricas AS m
WHERE m.status_logistico <> 'CANCELADO'
ORDER BY m.pedido_id;
```

Grão: um pedido não cancelado. Critério mínimo: `pedido_id` não pode repetir. Esta base serve para cortes cujos atributos pertencem ao pedido. Ela não atribui um total de pedido a uma categoria.

### Uma linha por item líquido

Salve como `sql/02-base-item-liquido.sql`:

```sql
SET TIME ZONE 'UTC';

SELECT
    v.item_pedido_id,
    v.pedido_id,
    p.canal_id,
    r.categoria_id,
    date_trunc(
        'month',
        p.data_pedido AT TIME ZONE 'America/Sao_Paulo'
    )::date AS mes,
    v.produto_id,
    v.quantidade,
    v.quantidade_mantida,
    v.receita_mercadoria_pos_devolucao,
    v.custo_mercadoria_mantida,
    v.margem_mercadoria
FROM vw_itens_venda AS v
JOIN pedidos AS p USING (pedido_id)
JOIN produtos AS r USING (produto_id)
WHERE v.elegivel
ORDER BY v.item_pedido_id;
```

Grão: uma linha de item de pedido elegível. Critério mínimo: `item_pedido_id` não pode repetir. Esta é a base da consulta final, pois a categoria pertence ao produto. Preço, desconto e custo históricos já estão incorporados às métricas da view.

## Consulta final

Copie `answers/q40.sql` sem alteração semântica para `sql/03-q40-fila-investigacao.sql`. A consulta deve:

1. agregar a base por mês, `canal_id` e `categoria_id`;
2. conservar receita pós-devolução, margem de mercadoria e unidades;
3. comparar as mesmas chaves com `mes - interval '1 year'`;
4. exigir unidades positivas nos dois lados e quedas simultâneas;
5. calcular valores absolutos, percentuais protegidos por `NULLIF` e score;
6. trazer nomes depois das chaves;
7. aplicar a ordenação contratada e então `LIMIT 20`.

Para revisar a CTE `atual`, troque temporariamente o `SELECT` final por `SELECT * FROM atual`. Faça o mesmo com `candidatos`. Restaure a consulta canônica antes de gerar o CSV entregue.

Registre `377` em `results/q40-candidates-count.txt` somente após obter a contagem da CTE `candidatos` no snapshot aprovado. A saída final deve conter 20 linhas de dados.

## Reconciliações

Salve as consultas e os resultados em `docs/RECONCILIATIONS.md`. Os números esperados pertencem ao snapshot aprovado; divergência exige interromper a entrega e verificar versão, filtros e junções.

### Totais da base por item

```sql
SELECT
    sum(v.receita_mercadoria_pos_devolucao) AS receita_pos_devolucao,
    sum(v.custo_mercadoria_mantida) AS custo_mercadoria_mantida,
    sum(v.margem_mercadoria) AS margem_mercadoria
FROM vw_itens_venda AS v
WHERE v.elegivel;
```

Esperado:

- receita pós-devolução: `11187854.10`;
- custo histórico mantido: `6365868.15`;
- margem de mercadoria: `4821985.95`;
- receita menos custo: exatamente margem de mercadoria.

### Por mês, canal e categoria

Use a mesma CTE `atual` da consulta final e some suas colunas:

```sql
WITH atual AS (
    SELECT
        date_trunc(
            'month',
            p.data_pedido AT TIME ZONE 'America/Sao_Paulo'
        )::date AS mes,
        p.canal_id,
        r.categoria_id,
        sum(v.receita_mercadoria_pos_devolucao) AS receita,
        sum(v.margem_mercadoria) AS margem
    FROM vw_itens_venda AS v
    JOIN pedidos AS p USING (pedido_id)
    JOIN produtos AS r USING (produto_id)
    WHERE v.elegivel
    GROUP BY 1, 2, 3
)
SELECT
    sum(receita) AS receita,
    sum(margem) AS margem
FROM atual;
```

O corte combinado deve reconciliar com `11187854.10` de receita e `4821985.95` de margem de mercadoria. Repita a soma após reagrupar somente por mês, somente por canal e somente por categoria. Os totais não mudam.

## Checagens de duplicação e ausência

Salve como `sql/05-checagens.sql`. Uma saída vazia é esperada nas buscas de problema.

### Chave duplicada na base agregada

```sql
WITH atual AS (
    SELECT
        date_trunc(
            'month',
            p.data_pedido AT TIME ZONE 'America/Sao_Paulo'
        )::date AS mes,
        p.canal_id,
        r.categoria_id,
        sum(v.receita_mercadoria_pos_devolucao) AS receita,
        sum(v.margem_mercadoria) AS margem,
        sum(v.quantidade) AS unidades
    FROM vw_itens_venda AS v
    JOIN pedidos AS p USING (pedido_id)
    JOIN produtos AS r USING (produto_id)
    WHERE v.elegivel
    GROUP BY 1, 2, 3
)
SELECT
    mes,
    canal_id,
    categoria_id,
    count(*) AS linhas
FROM atual
GROUP BY mes, canal_id, categoria_id
HAVING count(*) > 1;
```

### Pedido ou item repetido nas consultas-base

Na base de pedido, agrupe por `pedido_id` e filtre `count(*) > 1`. Na base de item, faça o mesmo com `item_pedido_id`. As duas buscas devem retornar zero linhas.

### Candidato sem par anual

Na etapa `candidatos`, a junção interna já exige o par. Para documentar a checagem, projete `a.mes`, `a.canal_id`, `a.categoria_id` e as chaves de `b`; procure chaves de `b` nulas numa versão diagnóstica com `LEFT JOIN`. Nenhuma linha aceita como candidata pode ter par ausente.

### Queda incompleta

Sobre a CTE `candidatos`, procure:

```sql
SELECT *
FROM candidatos
WHERE receita >= receita_anterior
   OR margem >= margem_anterior;
```

Esperado: zero linhas.

### Cardinalidade e ordem

- CTE `candidatos`: 377 linhas;
- resultado entregue: 20 linhas;
- primeira linha: `2024-11-01, MARKETPLACE, Organização`;
- primeiro score: `51723.99`;
- último score do top 20: `16624.74`;
- cada linha posterior respeita todos os critérios da ordenação, inclusive os desempates.

Não preencha combinações ausentes com zero. Ausência de linha não equivale a venda observada de valor zero no contrato desta pergunta.

## Comentário executivo

Salve em `docs/EXECUTIVE-COMMENT.md`, com até 250 palavras. Inclua:

- tamanho da população candidata e regra do top 20;
- primeira combinação da fila, com valores atuais, anteriores e score;
- um padrão descritivo visível na tabela, se houver;
- quais registros precisam ser abertos na investigação;
- uma frase explícita de que a consulta não determina causa.

Evite verbos causais como “provocou”, “gerou a queda” ou “explica”. Campanha, concorrência, mídia e motivo operacional não estão registrados. Não transforme associação temporal em explicação.

## Versão e hashes

Registre em `manifests/DATASET-VERSION.md`:

- repositório oficial: `https://github.com/Linhares015/sql-com-um-banco-de-vendas`;
- pacote local: raiz do repositório clonado;
- integridade do pacote: executar `sha256sum -c MANIFEST.sha256` na raiz;
- SHA-256 de `build/manifest.json`: `0151dc42d6807a8ac3acca734b6904c3eb220c6b9bc5e3de9ef70df34a4c7fbc`;
- SHA-256 de `results/manifest.json`: `7948eb44067d1590830a15ff4991c80cca793fbded82846d7b8bcadc4f599a4c`;
- versão da referência: `v1.2-remediation-v3`;
- SHA-256 de `contracts/canonical-results-v1.2.json`: `27039ccc1bfb3893b372e2c23fee069a05f34c59bddb9d83cc708d818fdec9f6`;
- SHA-256 do SQL canônico Q40: `e87d64d974a01130a29a9d752f1e73aeff73e7de2c4bbbe50581730f85ab4576`;
- SHA-256 do CSV canônico Q40: `b340acf5dc36ee354edb61b80a80c08e7e6c92c844b264a3e5103d8dfb3ba7ce`.

Gere `manifests/SHA256SUMS` para os arquivos efetivamente entregues somente depois de fechá-los. O hash de um arquivo local alterado não deve ser apresentado como hash canônico.

## Critérios de aceite

A entrega está pronta para revisão quando:

1. todos os arquivos da estrutura existem e o `README.md` indica a ordem de execução;
2. definições, período, corte, calendário, população, grãos e fórmulas estão explícitos;
3. as duas consultas-base não repetem suas chaves;
4. a consulta final preserva os SQLs e a semântica canônicos;
5. a CTE agregada reconcilia receita, custo e margem de mercadoria com os totais aprovados;
6. há 377 candidatos e o top 20 coincide por colunas, valores, `NULL`, ordem e hash com `results/q40.csv`;
7. checagens de duplicação, par anual e quedas incompletas não encontram problemas;
8. o comentário tem no máximo 250 palavras e não atribui causa;
9. versões e hashes estão registrados e `SHA256SUMS` confere com o pacote local;
10. nenhuma credencial foi incluída.

Se um critério falhar, mantenha o pacote em revisão e registre a divergência. Não ajuste números ou texto para forçar coincidência.

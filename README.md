# SQL com um Banco de Vendas — arquivos complementares

Arquivos complementares oficiais do livro **SQL com um Banco de Vendas**, de **Tiago Linhares**.

Este pacote permite recriar o dataset sintético Aurora em PostgreSQL 16+, executar as consultas Q01–Q40 e comparar os resultados com a referência canônica. Não contém dados pessoais reais nem credenciais de usuário. A senha em `docker-compose.yml` pertence somente ao banco local descartável, exposto em `127.0.0.1`.

## Pré-requisitos

- Linux, macOS ou Windows com ambiente compatível com Bash;
- Python 3, somente com a biblioteca padrão;
- Docker Engine com o plugin Compose;
- utilitários `timeout` e `sha256sum`;
- porta local `55432` disponível.

## Verificar a integridade

Na raiz do repositório:

```bash
sha256sum -c MANIFEST.sha256
```

A verificação deve terminar com `OK` para todas as entradas, sem arquivos ausentes ou hashes divergentes.

## Execução rápida

### 1. Iniciar o PostgreSQL descartável

```bash
docker compose up -d --wait
```

### 2. Recriar schema, dataset e carga

```bash
./recreate.sh
```

Esse comando recria o schema, gera os CSVs com seed fixo e carrega o banco. O gerador substitui o diretório `build/`; execute-o em uma cópia de trabalho se quiser preservar os bytes e timestamps distribuídos.

### 3. Executar Q01–Q40 e comparar com a referência

```bash
./verify-canonical-results.sh
```

A mensagem de sucesso esperada é:

```text
I38 passou: Q01–Q40 conferem contra a referência canônica versionada.
```

Para executar apenas Q01:

```bash
docker compose exec -T db psql -q -X -v ON_ERROR_STOP=1 \
  -U aurora -d aurora --csv -P null=NULL \
  -f /workspace/answers/q01.sql
```

Os resultados congelados estão em `results/q01.csv` até `results/q40.csv`.

### 4. Encerrar e limpar o ambiente

```bash
docker compose down -v --remove-orphans
```

## Estrutura

```text
.
├── README.md
├── LICENSE-STATUS.md
├── MANIFEST.sha256
├── docker-compose.yml
├── schema.sql
├── generate.py
├── load.sql
├── recreate.sh
├── freeze-results.sh
├── verify-canonical-results.sh
├── ANSWERS-CONTRACT.md
├── answers/
│   ├── generate.py
│   └── q01.sql ... q40.sql
├── build/
│   ├── manifest.json
│   └── 10 CSVs do dataset
├── results/
│   ├── manifest.json
│   └── q01.csv ... q40.csv
└── contracts/
    └── canonical-results-v1.2.json
```

## Manifestos especializados

- `build/manifest.json`: hashes e cardinalidades dos CSVs gerados;
- `results/manifest.json`: resultados Q01–Q40 e hashes das consultas;
- `contracts/canonical-results-v1.2.json`: contrato canônico de colunas, linhas, formatos e hashes.

## Licença e suporte

Leia `LICENSE-STATUS.md`. O pacote serve para estudo e reprodução dos exemplos do livro. Não inclui suporte a produção, administração de banco, migração para outro SGBD ou adaptação para versões diferentes.

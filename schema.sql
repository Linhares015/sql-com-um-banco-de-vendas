\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
-- Este arquivo é destrutivo somente para o banco/usuário isolados do protótipo.
SELECT current_database() = 'aurora' AND current_user = 'aurora' AS aurora_target \gset
\if :aurora_target
\else
  \echo 'Recusa: schema.sql exige banco aurora e usuário aurora.'
  \quit 3
\endif
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
CREATE TABLE categorias (categoria_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,nome varchar(60) NOT NULL UNIQUE CHECK(btrim(nome)<>''),descricao varchar(240),ativa boolean NOT NULL DEFAULT true);
CREATE TABLE produtos (produto_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,sku varchar(12) NOT NULL UNIQUE CHECK(sku~'^AUR-[0-9]{8}$'),nome varchar(100) NOT NULL CHECK(btrim(nome)<>''),categoria_id bigint NOT NULL REFERENCES categorias ON UPDATE RESTRICT ON DELETE RESTRICT,preco_lista_atual numeric(10,2) NOT NULL CHECK(preco_lista_atual>0),custo_padrao_atual numeric(10,2) NOT NULL CHECK(custo_padrao_atual>=0 AND custo_padrao_atual<=preco_lista_atual),data_lancamento date NOT NULL CHECK(data_lancamento BETWEEN DATE '2018-01-01' AND DATE '2025-12-31'),data_descontinuacao date CHECK(data_descontinuacao IS NULL OR data_descontinuacao>=data_lancamento),ativo boolean NOT NULL,CHECK((data_descontinuacao IS NULL)=ativo));
CREATE TABLE clientes (cliente_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,codigo_cliente varchar(12) NOT NULL UNIQUE CHECK(codigo_cliente~'^CLI-[0-9]{8}$'),nome varchar(100) NOT NULL CHECK(btrim(nome)<>''),email varchar(160) NOT NULL CHECK(email~'^cliente[0-9]{4}@aurora\.example$'),data_nascimento date CHECK(data_nascimento IS NULL OR extract(year from data_nascimento) BETWEEN 1940 AND 2007),cidade varchar(80) NOT NULL CHECK(btrim(cidade)<>''),uf char(2) NOT NULL CHECK(uf IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO')),regiao varchar(12) NOT NULL CHECK(regiao IN ('Norte','Nordeste','Centro-Oeste','Sudeste','Sul')),data_cadastro timestamptz NOT NULL,aceita_marketing boolean NOT NULL);
CREATE UNIQUE INDEX uq_clientes_email_lower ON clientes(lower(email));
CREATE TABLE canais (canal_id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,codigo varchar(20) NOT NULL UNIQUE CHECK(btrim(codigo)<>''),nome varchar(40) NOT NULL UNIQUE CHECK(btrim(nome)<>''),tipo varchar(12) NOT NULL CHECK(tipo IN ('DIGITAL','FISICO','ASSISTIDO')),data_inicio_operacao date NOT NULL);
CREATE TABLE vendedores (vendedor_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,matricula varchar(10) NOT NULL UNIQUE CHECK(matricula~'^VND-[0-9]{6}$'),nome varchar(100) NOT NULL CHECK(btrim(nome)<>''),equipe varchar(30) NOT NULL CHECK(equipe IN ('Curitiba','São Paulo','Televendas')),data_admissao date NOT NULL CHECK(data_admissao>=DATE '2018-01-01'),data_desligamento date CHECK(data_desligamento IS NULL OR data_desligamento>=data_admissao));
CREATE TABLE pedidos (pedido_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,numero_pedido varchar(20) NOT NULL UNIQUE CHECK(numero_pedido~'^PED-(2023|2024|2025)-[0-9]{6}$'),data_pedido timestamptz NOT NULL CHECK((data_pedido AT TIME ZONE 'America/Sao_Paulo')::date BETWEEN DATE '2023-01-01' AND DATE '2025-12-31'),cliente_id bigint REFERENCES clientes ON UPDATE RESTRICT ON DELETE RESTRICT,canal_id smallint NOT NULL REFERENCES canais ON UPDATE RESTRICT ON DELETE RESTRICT,vendedor_id bigint REFERENCES vendedores ON UPDATE RESTRICT ON DELETE RESTRICT,status_logistico varchar(12) NOT NULL CHECK(status_logistico IN ('CANCELADO','FATURADO','ENVIADO','ENTREGUE')),status_devolucao varchar(14) NOT NULL CHECK(status_devolucao IN ('NAO_APLICAVEL','SEM_DEVOLUCAO','PARCIAL','TOTAL')),cidade_entrega varchar(80),uf_entrega char(2),valor_frete_cotado numeric(10,2) NOT NULL CHECK(valor_frete_cotado>=0),data_faturamento timestamptz,data_entrega timestamptz,motivo_cancelamento varchar(80),CHECK((status_logistico='CANCELADO' AND data_faturamento IS NULL AND data_entrega IS NULL AND motivo_cancelamento IS NOT NULL AND btrim(motivo_cancelamento)<>'' AND status_devolucao='NAO_APLICAVEL') OR (status_logistico IN ('FATURADO','ENVIADO') AND data_faturamento IS NOT NULL AND data_entrega IS NULL AND motivo_cancelamento IS NULL AND status_devolucao='SEM_DEVOLUCAO') OR (status_logistico='ENTREGUE' AND data_faturamento IS NOT NULL AND data_entrega IS NOT NULL AND motivo_cancelamento IS NULL)),CHECK(data_faturamento IS NULL OR data_pedido<=data_faturamento),CHECK(data_entrega IS NULL OR data_faturamento<=data_entrega),CHECK((data_entrega IS NULL) OR data_entrega < TIMESTAMPTZ '2026-01-16 03:00:00+00'));
CREATE TABLE itens_pedido (item_pedido_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,pedido_id bigint NOT NULL REFERENCES pedidos ON UPDATE RESTRICT ON DELETE RESTRICT,numero_item smallint NOT NULL CHECK(numero_item BETWEEN 1 AND 6),produto_id bigint NOT NULL REFERENCES produtos ON UPDATE RESTRICT ON DELETE RESTRICT,quantidade smallint NOT NULL CHECK(quantidade BETWEEN 1 AND 8),preco_unitario numeric(10,2) NOT NULL CHECK(preco_unitario>0),desconto_unitario numeric(10,2) NOT NULL CHECK(desconto_unitario>=0 AND desconto_unitario<preco_unitario),custo_unitario numeric(10,2) NOT NULL CHECK(custo_unitario>=0),UNIQUE(pedido_id,numero_item),UNIQUE(pedido_id,produto_id));
CREATE TABLE devolucoes (devolucao_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,pedido_id bigint NOT NULL UNIQUE REFERENCES pedidos ON UPDATE RESTRICT ON DELETE RESTRICT,protocolo varchar(18) NOT NULL UNIQUE CHECK(protocolo~'^DEV-(2023|2024|2025|2026)-[0-9]{6}$'),data_solicitacao timestamptz NOT NULL,status varchar(12) NOT NULL CHECK(status IN ('SOLICITADA','RECUSADA','CONCLUIDA')),motivo varchar(30) NOT NULL CHECK(motivo IN ('ARREPENDIMENTO','AVARIA','ITEM_INCORRETO','ATRASO','OUTRO')),data_encerramento timestamptz,CHECK((status='SOLICITADA' AND data_encerramento IS NULL) OR (status IN ('RECUSADA','CONCLUIDA') AND data_encerramento IS NOT NULL AND data_solicitacao<=data_encerramento)),CHECK(data_solicitacao<TIMESTAMPTZ '2026-02-15 03:00:00+00'),CHECK(data_encerramento IS NULL OR data_encerramento<TIMESTAMPTZ '2026-02-15 03:00:00+00'));
CREATE TABLE itens_devolucao (item_devolucao_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,devolucao_id bigint NOT NULL REFERENCES devolucoes ON UPDATE RESTRICT ON DELETE RESTRICT,item_pedido_id bigint NOT NULL REFERENCES itens_pedido ON UPDATE RESTRICT ON DELETE RESTRICT,quantidade_devolvida smallint NOT NULL CHECK(quantidade_devolvida>0),valor_reembolso numeric(12,2) NOT NULL CHECK(valor_reembolso>=0),UNIQUE(devolucao_id,item_pedido_id));
CREATE TABLE pagamentos (pagamento_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,pedido_id bigint NOT NULL REFERENCES pedidos ON UPDATE RESTRICT ON DELETE RESTRICT,sequencia smallint NOT NULL CHECK(sequencia>0),data_pagamento timestamptz NOT NULL CHECK(data_pagamento<TIMESTAMPTZ '2026-02-15 03:00:00+00'),meio_pagamento varchar(20) NOT NULL CHECK(meio_pagamento IN ('PIX','CARTAO_CREDITO','CARTAO_DEBITO','BOLETO','DINHEIRO','VALE')),tipo_evento varchar(12) NOT NULL CHECK(tipo_evento IN ('COBRANCA','ESTORNO')),status varchar(12) NOT NULL CHECK(status IN ('APROVADO','RECUSADO')),valor numeric(12,2) NOT NULL CHECK(valor>0),parcelas smallint NOT NULL CHECK(parcelas BETWEEN 1 AND 12),pagamento_origem_id bigint REFERENCES pagamentos DEFERRABLE INITIALLY DEFERRED,devolucao_id bigint REFERENCES devolucoes DEFERRABLE INITIALLY DEFERRED,UNIQUE(pedido_id,sequencia),CHECK((tipo_evento='COBRANCA' AND pagamento_origem_id IS NULL AND devolucao_id IS NULL) OR (tipo_evento='ESTORNO' AND status='APROVADO' AND pagamento_origem_id IS NOT NULL)),CHECK(meio_pagamento='CARTAO_CREDITO' OR parcelas=1));
CREATE UNIQUE INDEX uq_estorno_devolucao ON pagamentos(devolucao_id) WHERE devolucao_id IS NOT NULL;
CREATE INDEX ON pedidos(data_pedido); CREATE INDEX ON pedidos(cliente_id,data_pedido,pedido_id); CREATE INDEX ON pedidos(canal_id); CREATE INDEX ON itens_pedido(pedido_id); CREATE INDEX ON itens_pedido(produto_id); CREATE INDEX ON pagamentos(pedido_id); CREATE INDEX ON pagamentos(pagamento_origem_id); CREATE INDEX ON devolucoes(pedido_id,status); CREATE INDEX ON itens_devolucao(devolucao_id); CREATE INDEX ON itens_devolucao(item_pedido_id);

CREATE OR REPLACE FUNCTION validar_pedido(x bigint) RETURNS void LANGUAGE plpgsql AS $$
DECLARE sold int; returned int; expected text;
BEGIN
 PERFORM 1 FROM pedidos WHERE pedido_id=x FOR UPDATE;
 IF NOT FOUND THEN RETURN; END IF;
 IF EXISTS(SELECT 1 FROM pedidos p JOIN clientes c USING(cliente_id) WHERE p.pedido_id=x AND c.data_cadastro>p.data_pedido) THEN RAISE EXCEPTION 'I06'; END IF;
 IF EXISTS(SELECT 1 FROM pedidos p JOIN canais c USING(canal_id) WHERE p.pedido_id=x AND c.data_inicio_operacao>(p.data_pedido AT TIME ZONE 'America/Sao_Paulo')::date) THEN RAISE EXCEPTION 'I07'; END IF;
 IF EXISTS(SELECT 1 FROM pedidos p JOIN canais c USING(canal_id) JOIN vendedores v USING(vendedor_id) WHERE p.pedido_id=x AND ((c.codigo IN ('SITE','MARKETPLACE') AND p.vendedor_id IS NOT NULL) OR (c.codigo='LOJA_CURITIBA' AND v.equipe<>'Curitiba') OR (c.codigo='LOJA_SAO_PAULO' AND v.equipe<>'São Paulo') OR (c.codigo='TELEVENDAS' AND v.equipe<>'Televendas'))) OR EXISTS(SELECT 1 FROM pedidos p JOIN canais c USING(canal_id) WHERE p.pedido_id=x AND c.codigo NOT IN ('SITE','MARKETPLACE') AND p.vendedor_id IS NULL) THEN RAISE EXCEPTION 'I10'; END IF;
 IF EXISTS(SELECT 1 FROM pedidos p JOIN canais c USING(canal_id) WHERE p.pedido_id=x AND ((c.tipo='FISICO' AND (p.cidade_entrega IS NOT NULL OR p.uf_entrega IS NOT NULL)) OR (c.tipo<>'FISICO' AND (p.cidade_entrega IS NULL OR p.uf_entrega IS NULL)))) THEN RAISE EXCEPTION 'I11'; END IF;
 IF EXISTS(SELECT 1 FROM itens_pedido i JOIN pedidos p USING(pedido_id) JOIN produtos r USING(produto_id) WHERE i.pedido_id=x AND (r.data_lancamento>(p.data_pedido AT TIME ZONE 'America/Sao_Paulo')::date OR r.data_descontinuacao<(p.data_pedido AT TIME ZONE 'America/Sao_Paulo')::date)) THEN RAISE EXCEPTION 'I08'; END IF;
 IF EXISTS(SELECT 1 FROM pedidos p JOIN vendedores v USING(vendedor_id) WHERE p.pedido_id=x AND (v.data_admissao>(p.data_pedido AT TIME ZONE 'America/Sao_Paulo')::date OR v.data_desligamento<(p.data_pedido AT TIME ZONE 'America/Sao_Paulo')::date)) THEN RAISE EXCEPTION 'I09'; END IF;
 IF (SELECT count(*) FROM itens_pedido WHERE pedido_id=x) NOT BETWEEN 1 AND 6 OR EXISTS(SELECT 1 FROM itens_pedido WHERE pedido_id=x GROUP BY pedido_id HAVING min(numero_item)<>1 OR max(numero_item)<>count(*)) THEN RAISE EXCEPTION 'I13'; END IF;
 IF EXISTS(SELECT 1 FROM devolucoes d JOIN pedidos p USING(pedido_id) WHERE d.pedido_id=x AND (p.status_logistico<>'ENTREGUE' OR d.data_solicitacao<=p.data_entrega OR d.data_solicitacao>p.data_entrega+interval '30 days')) THEN RAISE EXCEPTION 'I17'; END IF;
 IF EXISTS(SELECT 1 FROM itens_devolucao z JOIN devolucoes d USING(devolucao_id) JOIN itens_pedido i USING(item_pedido_id) WHERE d.pedido_id=x AND (i.pedido_id<>x OR z.quantidade_devolvida>i.quantidade OR z.valor_reembolso<>z.quantidade_devolvida*(i.preco_unitario-i.desconto_unitario))) THEN RAISE EXCEPTION 'I15/I19/I20'; END IF;
 SELECT coalesce(sum(quantidade),0) INTO sold FROM itens_pedido WHERE pedido_id=x;
 SELECT coalesce(sum(z.quantidade_devolvida),0) INTO returned FROM devolucoes d JOIN itens_devolucao z USING(devolucao_id) WHERE d.pedido_id=x AND d.status='CONCLUIDA';
 SELECT CASE WHEN status_logistico='CANCELADO' THEN 'NAO_APLICAVEL' WHEN returned=0 THEN 'SEM_DEVOLUCAO' WHEN returned=sold THEN 'TOTAL' WHEN returned<sold THEN 'PARCIAL' ELSE 'INVALIDO' END INTO expected FROM pedidos WHERE pedido_id=x;
 IF expected='INVALIDO' OR NOT EXISTS(SELECT 1 FROM pedidos WHERE pedido_id=x AND status_devolucao=expected) THEN RAISE EXCEPTION 'I21/I22'; END IF;
END $$;
CREATE OR REPLACE FUNCTION validar_pagamentos(x bigint) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 PERFORM validar_pedido(x);
 -- I25: a cobrança de origem é uma âncora adicional.  O bloqueio é obtido
 -- depois do pedido (a ordem global do desenho) e antes do saldo agregado.
 PERFORM pagamento_id FROM pagamentos
  WHERE pagamento_id IN (SELECT pagamento_origem_id FROM pagamentos WHERE pedido_id=x AND pagamento_origem_id IS NOT NULL)
  ORDER BY pagamento_id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM pagamentos a JOIN pedidos p USING(pedido_id) WHERE a.pedido_id=x AND a.data_pagamento<p.data_pedido) THEN RAISE EXCEPTION 'I24a'; END IF;
 IF EXISTS(SELECT 1 FROM pagamentos e JOIN pagamentos o ON o.pagamento_id=e.pagamento_origem_id WHERE e.pedido_id=x AND (o.pedido_id<>x OR o.tipo_evento<>'COBRANCA' OR o.status<>'APROVADO' OR o.meio_pagamento<>e.meio_pagamento OR e.data_pagamento<=o.data_pagamento OR e.valor>(o.valor-(SELECT coalesce(sum(z.valor),0) FROM pagamentos z WHERE z.pagamento_origem_id=o.pagamento_id AND z.status='APROVADO' AND z.pagamento_id<>e.pagamento_id)))) THEN RAISE EXCEPTION 'I24/I25'; END IF;
 IF EXISTS(SELECT 1 FROM pagamentos e LEFT JOIN devolucoes d ON d.devolucao_id=e.devolucao_id WHERE e.pedido_id=x AND e.devolucao_id IS NOT NULL AND (d.status<>'CONCLUIDA' OR d.pedido_id<>x OR e.data_pagamento<d.data_encerramento)) THEN RAISE EXCEPTION 'I26/I24a'; END IF;
 IF EXISTS(SELECT 1 FROM vw_pagamentos_conciliacao WHERE pedido_id=x AND diferenca<>0) THEN RAISE EXCEPTION 'I27'; END IF;
END $$;
CREATE OR REPLACE FUNCTION validar_pedidos_afetados(ids bigint[], origens_extras bigint[] DEFAULT ARRAY[]::bigint[]) RETURNS void LANGUAGE plpgsql AS $$
DECLARE r record; origens bigint[];
BEGIN
 -- A ordem global é pedidos e, depois, cobranças de origem; ambos deduplicados.
 PERFORM 1 FROM pedidos WHERE pedido_id=ANY(ids) ORDER BY pedido_id FOR UPDATE;
 SELECT array_agg(DISTINCT pagamento_origem_id ORDER BY pagamento_origem_id) INTO origens
 FROM (
   SELECT pagamento_origem_id FROM pagamentos WHERE pedido_id=ANY(ids) AND pagamento_origem_id IS NOT NULL
   UNION SELECT unnest(coalesce(origens_extras,ARRAY[]::bigint[]))
 ) s;
 PERFORM 1 FROM pagamentos WHERE pagamento_id=ANY(coalesce(origens,ARRAY[]::bigint[])) ORDER BY pagamento_id FOR UPDATE;
 FOR r IN SELECT pedido_id FROM pedidos WHERE pedido_id=ANY(ids) ORDER BY pedido_id LOOP
   PERFORM validar_pedido(r.pedido_id); PERFORM validar_pagamentos(r.pedido_id);
 END LOOP;
END $$;
CREATE OR REPLACE FUNCTION ct_integridade() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN
 IF TG_OP='INSERT' THEN PERFORM validar_pedidos_afetados(ARRAY[NEW.pedido_id]);
 ELSIF TG_OP='DELETE' THEN PERFORM validar_pedidos_afetados(ARRAY[OLD.pedido_id]);
 ELSE PERFORM validar_pedidos_afetados(ARRAY[OLD.pedido_id,NEW.pedido_id]); END IF;
 RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER ct_pedidos AFTER INSERT OR UPDATE OR DELETE ON pedidos DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ct_integridade();
CREATE CONSTRAINT TRIGGER ct_itens AFTER INSERT OR UPDATE OR DELETE ON itens_pedido DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ct_integridade();
CREATE CONSTRAINT TRIGGER ct_devolucoes AFTER INSERT OR UPDATE OR DELETE ON devolucoes DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ct_integridade();
CREATE OR REPLACE FUNCTION ct_item_devolucao() RETURNS trigger LANGUAGE plpgsql AS $$ DECLARE ids bigint[]; dids bigint[]; BEGIN
 IF TG_OP='INSERT' THEN dids:=ARRAY[NEW.devolucao_id]; ELSIF TG_OP='DELETE' THEN dids:=ARRAY[OLD.devolucao_id]; ELSE dids:=ARRAY[OLD.devolucao_id,NEW.devolucao_id]; END IF;
 SELECT array_agg(DISTINCT pedido_id) INTO ids FROM devolucoes WHERE devolucao_id=ANY(dids);
 PERFORM validar_pedidos_afetados(coalesce(ids,ARRAY[]::bigint[])); RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER ct_itens_devolucao AFTER INSERT OR UPDATE OR DELETE ON itens_devolucao DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ct_item_devolucao();
CREATE OR REPLACE FUNCTION ct_pagamentos() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN
 IF TG_OP='INSERT' THEN PERFORM validar_pedidos_afetados(ARRAY[NEW.pedido_id],ARRAY[NEW.pagamento_origem_id]);
 ELSIF TG_OP='DELETE' THEN PERFORM validar_pedidos_afetados(ARRAY[OLD.pedido_id],ARRAY[OLD.pagamento_origem_id]);
 ELSE PERFORM validar_pedidos_afetados(ARRAY[OLD.pedido_id,NEW.pedido_id],ARRAY[OLD.pagamento_origem_id,NEW.pagamento_origem_id]); END IF;
 RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER ct_pagamentos AFTER INSERT OR UPDATE OR DELETE ON pagamentos DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ct_pagamentos();
-- Os CTs são diferidos para validar o estado final.  Estes triggers por
-- instrução adquirem antes os locks de TODAS as âncoras tocadas pela
-- instrução, em uma ordem global.  Assim um UPDATE/DELETE multirow não
-- depende da ordem física em que os constraint triggers por linha rodarem.
CREATE OR REPLACE FUNCTION bloquear_pedidos_afetados(ids bigint[], origens_extras bigint[] DEFAULT ARRAY[]::bigint[]) RETURNS void LANGUAGE plpgsql AS $$
DECLARE pedidos_ids bigint[]; origem_ids bigint[];
BEGIN
 SELECT array_agg(DISTINCT id ORDER BY id) INTO pedidos_ids FROM unnest(coalesce(ids,ARRAY[]::bigint[])) id WHERE id IS NOT NULL;
 PERFORM 1 FROM pedidos WHERE pedido_id=ANY(coalesce(pedidos_ids,ARRAY[]::bigint[])) ORDER BY pedido_id FOR UPDATE;
 SELECT array_agg(DISTINCT id ORDER BY id) INTO origem_ids FROM (
   SELECT pagamento_origem_id id FROM pagamentos WHERE pedido_id=ANY(coalesce(pedidos_ids,ARRAY[]::bigint[])) AND pagamento_origem_id IS NOT NULL
   UNION SELECT unnest(coalesce(origens_extras,ARRAY[]::bigint[]))
 ) fontes WHERE id IS NOT NULL;
 PERFORM 1 FROM pagamentos WHERE pagamento_id=ANY(coalesce(origem_ids,ARRAY[]::bigint[])) ORDER BY pagamento_id FOR UPDATE;
END $$;
CREATE OR REPLACE FUNCTION st_lock_pedidos_ins() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM new_rows)); RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION st_lock_pedidos_del() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM old_rows)); RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION st_lock_pedidos_upd() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM new_rows UNION SELECT pedido_id FROM old_rows)); RETURN NULL; END $$;
CREATE TRIGGER st_lock_pedidos_ins AFTER INSERT ON pedidos REFERENCING NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_pedidos_ins();
CREATE TRIGGER st_lock_pedidos_del AFTER DELETE ON pedidos REFERENCING OLD TABLE AS old_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_pedidos_del();
CREATE TRIGGER st_lock_pedidos_upd AFTER UPDATE ON pedidos REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_pedidos_upd();
CREATE OR REPLACE FUNCTION st_lock_itens_ins() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM new_rows)); RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION st_lock_itens_del() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM old_rows)); RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION st_lock_itens_upd() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM new_rows UNION SELECT pedido_id FROM old_rows)); RETURN NULL; END $$;
CREATE TRIGGER st_lock_itens_ins AFTER INSERT ON itens_pedido REFERENCING NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_itens_ins();
CREATE TRIGGER st_lock_itens_del AFTER DELETE ON itens_pedido REFERENCING OLD TABLE AS old_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_itens_del();
CREATE TRIGGER st_lock_itens_upd AFTER UPDATE ON itens_pedido REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_itens_upd();
CREATE OR REPLACE FUNCTION st_lock_devolucoes_ins() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM new_rows)); RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION st_lock_devolucoes_del() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM old_rows)); RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION st_lock_devolucoes_upd() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM new_rows UNION SELECT pedido_id FROM old_rows)); RETURN NULL; END $$;
CREATE TRIGGER st_lock_devolucoes_ins AFTER INSERT ON devolucoes REFERENCING NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_devolucoes_ins();
CREATE TRIGGER st_lock_devolucoes_del AFTER DELETE ON devolucoes REFERENCING OLD TABLE AS old_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_devolucoes_del();
CREATE TRIGGER st_lock_devolucoes_upd AFTER UPDATE ON devolucoes REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_devolucoes_upd();
CREATE OR REPLACE FUNCTION st_lock_itens_devolucao_ins() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT d.pedido_id FROM devolucoes d JOIN new_rows n USING(devolucao_id))); RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION st_lock_itens_devolucao_del() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT d.pedido_id FROM devolucoes d JOIN old_rows o USING(devolucao_id))); RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION st_lock_itens_devolucao_upd() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT d.pedido_id FROM devolucoes d JOIN (SELECT devolucao_id FROM new_rows UNION SELECT devolucao_id FROM old_rows) x USING(devolucao_id))); RETURN NULL; END $$;
CREATE TRIGGER st_lock_itens_devolucao_ins AFTER INSERT ON itens_devolucao REFERENCING NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_itens_devolucao_ins();
CREATE TRIGGER st_lock_itens_devolucao_del AFTER DELETE ON itens_devolucao REFERENCING OLD TABLE AS old_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_itens_devolucao_del();
CREATE TRIGGER st_lock_itens_devolucao_upd AFTER UPDATE ON itens_devolucao REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_itens_devolucao_upd();
CREATE OR REPLACE FUNCTION st_lock_pagamentos_ins() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM new_rows),ARRAY(SELECT pagamento_origem_id FROM new_rows)); RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION st_lock_pagamentos_del() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM old_rows),ARRAY(SELECT pagamento_origem_id FROM old_rows)); RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION st_lock_pagamentos_upd() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM bloquear_pedidos_afetados(ARRAY(SELECT pedido_id FROM new_rows UNION SELECT pedido_id FROM old_rows),ARRAY(SELECT pagamento_origem_id FROM new_rows UNION SELECT pagamento_origem_id FROM old_rows)); RETURN NULL; END $$;
CREATE TRIGGER st_lock_pagamentos_ins AFTER INSERT ON pagamentos REFERENCING NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_pagamentos_ins();
CREATE TRIGGER st_lock_pagamentos_del AFTER DELETE ON pagamentos REFERENCING OLD TABLE AS old_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_pagamentos_del();
CREATE TRIGGER st_lock_pagamentos_upd AFTER UPDATE ON pagamentos REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION st_lock_pagamentos_upd();
-- Propaga mudanças nas dimensões para os pedidos já existentes.  Sem estes
-- disparos um UPDATE posterior no lado referenciado poderia contornar I06-I10.
CREATE OR REPLACE FUNCTION ct_clientes() RETURNS trigger LANGUAGE plpgsql AS $$ DECLARE r record; BEGIN
 FOR r IN SELECT pedido_id FROM pedidos WHERE cliente_id=coalesce(NEW.cliente_id,OLD.cliente_id) ORDER BY pedido_id LOOP PERFORM validar_pagamentos(r.pedido_id); END LOOP; RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION ct_canais() RETURNS trigger LANGUAGE plpgsql AS $$ DECLARE r record; BEGIN
 FOR r IN SELECT pedido_id FROM pedidos WHERE canal_id=coalesce(NEW.canal_id,OLD.canal_id) ORDER BY pedido_id LOOP PERFORM validar_pagamentos(r.pedido_id); END LOOP; RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION ct_vendedores() RETURNS trigger LANGUAGE plpgsql AS $$ DECLARE r record; BEGIN
 FOR r IN SELECT pedido_id FROM pedidos WHERE vendedor_id=coalesce(NEW.vendedor_id,OLD.vendedor_id) ORDER BY pedido_id LOOP PERFORM validar_pagamentos(r.pedido_id); END LOOP; RETURN NULL; END $$;
CREATE OR REPLACE FUNCTION ct_produtos() RETURNS trigger LANGUAGE plpgsql AS $$ DECLARE r record; BEGIN
 FOR r IN SELECT DISTINCT i.pedido_id FROM itens_pedido i WHERE i.produto_id=coalesce(NEW.produto_id,OLD.produto_id) ORDER BY pedido_id LOOP PERFORM validar_pagamentos(r.pedido_id); END LOOP; RETURN NULL; END $$;
CREATE CONSTRAINT TRIGGER ct_clientes_referenciados AFTER UPDATE OR DELETE ON clientes DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ct_clientes();
CREATE CONSTRAINT TRIGGER ct_canais_referenciados AFTER UPDATE OR DELETE ON canais DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ct_canais();
CREATE CONSTRAINT TRIGGER ct_vendedores_referenciados AFTER UPDATE OR DELETE ON vendedores DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ct_vendedores();
CREATE CONSTRAINT TRIGGER ct_produtos_referenciados AFTER UPDATE OR DELETE ON produtos DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ct_produtos();
CREATE VIEW vw_itens_venda AS SELECT i.*,p.status_logistico<>'CANCELADO' AS elegivel,i.quantidade*i.preco_unitario AS bruto,i.quantidade*i.desconto_unitario AS desconto,i.quantidade*(i.preco_unitario-i.desconto_unitario) AS receita_mercadoria_pre_devolucao,coalesce(r.q,0) AS quantidade_devolvida_concluida,coalesce(r.v,0) AS reembolso_mercadoria_concluido,i.quantidade-coalesce(r.q,0) AS quantidade_mantida,i.quantidade*(i.preco_unitario-i.desconto_unitario)-coalesce(r.v,0) AS receita_mercadoria_pos_devolucao,(i.quantidade-coalesce(r.q,0))*i.custo_unitario AS custo_mercadoria_mantida,i.quantidade*(i.preco_unitario-i.desconto_unitario)-coalesce(r.v,0)-(i.quantidade-coalesce(r.q,0))*i.custo_unitario AS margem_mercadoria FROM itens_pedido i JOIN pedidos p USING(pedido_id) LEFT JOIN LATERAL (SELECT sum(z.quantidade_devolvida) q,sum(z.valor_reembolso) v FROM devolucoes d JOIN itens_devolucao z USING(devolucao_id) WHERE d.status='CONCLUIDA' AND z.item_pedido_id=i.item_pedido_id) r ON true;
CREATE VIEW vw_pedidos_metricas AS SELECT p.*,coalesce(sum(v.bruto) FILTER(WHERE v.elegivel),0) receita_bruta_mercadoria,coalesce(sum(v.desconto) FILTER(WHERE v.elegivel),0) desconto_mercadoria,coalesce(sum(v.receita_mercadoria_pre_devolucao) FILTER(WHERE v.elegivel),0) receita_mercadoria_pre_devolucao,coalesce(sum(v.reembolso_mercadoria_concluido) FILTER(WHERE v.elegivel),0) reembolso_mercadoria_concluido,coalesce(sum(v.receita_mercadoria_pos_devolucao) FILTER(WHERE v.elegivel),0) receita_mercadoria_pos_devolucao,case when p.status_logistico='CANCELADO' then 0 else p.valor_frete_cotado end frete_cobrado_elegivel,coalesce(sum(v.receita_mercadoria_pos_devolucao) FILTER(WHERE v.elegivel),0)+case when p.status_logistico='CANCELADO' then 0 else p.valor_frete_cotado end total_pedido_pos_reembolso,coalesce(sum(v.custo_mercadoria_mantida) FILTER(WHERE v.elegivel),0) custo_mercadoria_mantida,coalesce(sum(v.margem_mercadoria) FILTER(WHERE v.elegivel),0) margem_mercadoria,count(v.item_pedido_id) itens_distintos,coalesce(sum(v.quantidade),0) unidades FROM pedidos p LEFT JOIN vw_itens_venda v USING(pedido_id) GROUP BY p.pedido_id;
CREATE VIEW vw_pagamentos_conciliacao AS SELECT m.pedido_id,coalesce(sum(p.valor) FILTER(WHERE p.tipo_evento='COBRANCA' AND p.status='APROVADO'),0) cobranca_aprovada,coalesce(sum(p.valor) FILTER(WHERE p.tipo_evento='ESTORNO' AND p.status='APROVADO'),0) estorno_aprovado,coalesce(sum(case when p.tipo_evento='COBRANCA' AND p.status='APROVADO' then p.valor when p.tipo_evento='ESTORNO' AND p.status='APROVADO' then -p.valor else 0 end),0) saldo_financeiro,m.total_pedido_pos_reembolso total_esperado,coalesce(sum(case when p.tipo_evento='COBRANCA' AND p.status='APROVADO' then p.valor when p.tipo_evento='ESTORNO' AND p.status='APROVADO' then -p.valor else 0 end),0)-m.total_pedido_pos_reembolso diferenca FROM vw_pedidos_metricas m LEFT JOIN pagamentos p USING(pedido_id) GROUP BY m.pedido_id,m.total_pedido_pos_reembolso;

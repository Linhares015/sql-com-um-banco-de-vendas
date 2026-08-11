#!/usr/bin/env python3
"""Gera, sem rede nem relógio, o conjunto Aurora v1.2.

Os valores são manipulados em centavos; os CSVs são deliberadamente ordenados
pela chave que receberão durante a carga (identities começam em 1 em banco novo).
"""
import csv
import hashlib
import json
import random
import shutil
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

SEED = 20260810
RNG = random.Random(SEED)
OUT = Path("build")

def cents(value): return f"{value // 100}.{value % 100:02d}"
def stamp(day, hour=15):
    return (datetime(day.year, day.month, day.day, hour, tzinfo=timezone.utc)
            .isoformat().replace("+00:00", "+00"))
def write(name, columns, rows):
    path = OUT / f"{name}.csv"
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(columns)
        writer.writerows(rows)

def item_total(items, pedido_id):
    return sum(q * (price - discount) for p, _n, _sku, q, price, discount, _cost in items if p == pedido_id)

def main():
    if OUT.exists(): shutil.rmtree(OUT)
    OUT.mkdir()
    write("categorias", ["nome", "descricao", "ativa"], [
        (name, f"Categoria sintética {name}", "true")
        for name in ("Cozinha", "Mesa", "Organização", "Limpeza", "Banho", "Lavanderia", "Jardim", "Utilidades")])

    products = []
    for i in range(1, 121):
        price = 3000 + ((i * 137) % 16000)
        cost = price * (35 + ((i * 3) % 38)) // 100
        products.append((f"AUR-{i:08d}", f"Produto Aurora {i:03d}", (i - 1) % 8 + 1,
                         cents(price), cents(cost), date(2018 + i % 5, 1 + i % 12, 1), "", "true"))
    write("produtos", ["sku", "nome", "categoria_id", "preco_lista_atual", "custo_padrao_atual", "data_lancamento", "data_descontinuacao", "ativo"], products)

    locations = [("AC", "Norte", "Rio Branco"), ("AL", "Nordeste", "Maceió"), ("BA", "Nordeste", "Salvador"), ("DF", "Centro-Oeste", "Brasília"), ("MG", "Sudeste", "Belo Horizonte"), ("PR", "Sul", "Curitiba"), ("RJ", "Sudeste", "Rio de Janeiro"), ("RS", "Sul", "Porto Alegre"), ("SP", "Sudeste", "São Paulo")]
    clients = []
    for i in range(1, 4001):
        uf, region, city = locations[(i - 1) % len(locations)]
        birth = "" if i <= 600 else date(1940 + i % 68, 1 + i % 12, 1 + i % 27)
        clients.append((f"CLI-{i:08d}", f"Cliente Sintético {i:04d}", f"cliente{i:04d}@aurora.example", birth, city, uf, region, stamp(date(2022, 7, 1) + timedelta(days=i % 180)), "true" if i % 2 else "false"))
    write("clientes", ["codigo_cliente", "nome", "email", "data_nascimento", "cidade", "uf", "regiao", "data_cadastro", "aceita_marketing"], clients)
    write("canais", ["codigo", "nome", "tipo", "data_inicio_operacao"], [
        ("SITE", "Site", "DIGITAL", date(2020, 1, 1)), ("MARKETPLACE", "Marketplace", "DIGITAL", date(2020, 1, 1)),
        ("LOJA_CURITIBA", "Loja Curitiba", "FISICO", date(2020, 1, 1)), ("LOJA_SAO_PAULO", "Loja São Paulo", "FISICO", date(2024, 4, 1)),
        ("TELEVENDAS", "Televendas", "ASSISTIDO", date(2020, 1, 1))])
    teams = ("Curitiba", "São Paulo", "Televendas")
    write("vendedores", ["matricula", "nome", "equipe", "data_admissao", "data_desligamento"], [
        (f"VND-{i:06d}", f"Vendedor Sintético {i:02d}", teams[(i - 1) % 3], date(2018 + i % 6, 1, 1), "") for i in range(1, 25)])

    yearly = {2023:(1400,1050,650,0,500), 2024:(1500,1050,600,400,450), 2025:(1750,1100,550,600,400)}
    month_cycle = [1,2,3,4,5,6,7,8,9,10,11,11,12]
    orders, oid = [], 0
    for year, counts in yearly.items():
        year_serial = 0
        for channel, count in enumerate(counts, 1):
            for serial in range(1, count + 1):
                oid += 1
                year_serial += 1
                month = month_cycle[(serial + channel * 3) % len(month_cycle)]
                if channel == 4 and year == 2024:
                    month = 4 + ((serial * 7) % 9)
                day = date(year, month, 1) + timedelta(days=(serial * 17 + channel * 5) % 28)
                status = "CANCELADO" if oid <= 840 else "FATURADO" if oid <= 900 else "ENVIADO" if oid <= 1000 else "ENTREGUE"
                guest = oid <= 1440
                city, uf = ("", "") if channel in (3, 4) else ("Curitiba", "PR")
                vendor = "" if channel < 3 else ({3: (1,4,7,10,13,16,19), 4: (2,5,8,11,14,17,20,23), 5: (3,6,9,12,15,18,21)}[channel][oid % (8 if channel == 4 else 7)])
                orders.append([f"PED-{year}-{year_serial:06d}", stamp(day), "" if guest else None, channel, vendor, status,
                               "NAO_APLICAVEL" if status == "CANCELADO" else "SEM_DEVOLUCAO", city, uf,
                               cents(0 if channel in (3,4) else 1290), "" if status == "CANCELADO" else stamp(day + timedelta(days=1)),
                               stamp(day + timedelta(days=4)) if status == "ENTREGUE" else "", "Cliente desistiu" if status == "CANCELADO" else ""])

    # Frequência exata dos 3.600 compradores nos 10.560 pedidos identificados não cancelados.
    buyer_slots = []
    buyer_slots += list(range(1, 1201))
    buyer_slots += [i for i in range(1201, 2101) for _ in range(2)]
    buyer_slots += [i for i in range(2101, 3601) for _ in range(3)]
    buyer_slots += [i for i in range(2101, 3601) for _ in range(2)] + list(range(2101, 2161))
    assert len(buyer_slots) == 10560
    RNG.shuffle(buyer_slots)
    it = iter(buyer_slots)
    for index, order in enumerate(orders, 1):
        if index > 1440: order[2] = next(it)
    write("pedidos", ["numero_pedido", "data_pedido", "cliente_id", "canal_id", "vendedor_id", "status_logistico", "status_devolucao", "cidade_entrega", "uf_entrega", "valor_frete_cotado", "data_faturamento", "data_entrega", "motivo_cancelamento"], orders)

    items = []
    for pedido_id in range(1, 12001):
        for number in range(1, 4 if pedido_id <= 3600 else 3):
            line = len(items) + 1
            product = ((pedido_id * 3 + number * 17) % 112) + 1
            price = 3000 + ((product * 137) % 16000)
            discount = 0 if line % 100 < 62 else price * (5 + (line % 5) * 5) // 100
            cost = price * (35 + (line * 3) % 38) // 100
            if line <= 60: cost = price - discount + 100
            items.append((pedido_id, number, product, 1 + line % 8, price, discount, cost))
    assert len(items) == 27600
    write("itens_pedido", ["pedido_id", "numero_item", "produto_id", "quantidade", "preco_unitario", "desconto_unitario", "custo_unitario"], [(p,n,sku,q,cents(price),cents(discount),cents(cost)) for p,n,sku,q,price,discount,cost in items])

    returns, return_items = [], []
    # Todos após o pedido 4.000: possuem duas linhas e estão entregues.
    for j, pedido_id in enumerate(range(4001, 4721)):
        status = "CONCLUIDA" if j < 600 else "RECUSADA" if j < 672 else "SOLICITADA"
        delivered = date.fromisoformat(orders[pedido_id - 1][11][:10])
        requested = delivered + timedelta(days=5)
        closed = "" if status == "SOLICITADA" else stamp(requested + timedelta(days=2))
        returns.append((pedido_id, f"DEV-{requested.year}-{j+1:06d}", stamp(requested), status, ("ARREPENDIMENTO","AVARIA","ITEM_INCORRETO","ATRASO","OUTRO")[j % 5], closed))
        lines = 2 if (status == "CONCLUIDA" and j >= 420) or (status == "RECUSADA" and j < 624) or (status == "SOLICITADA" and j < 684) else 1
        for num in range(1, lines + 1):
            item_id = 2 * pedido_id + 3599 + (num - 1)  # após 3.600 há duas linhas/pedido
            item = items[item_id - 1]
            quantity = item[3] if status == "CONCLUIDA" and j >= 420 else 1
            return_items.append((j + 1, item_id, quantity, quantity * (item[4] - item[5])))
    assert len(return_items) == 936
    for j in range(600): orders[4000 + j][6] = "PARCIAL" if j < 420 else "TOTAL"
    write("pedidos", ["numero_pedido", "data_pedido", "cliente_id", "canal_id", "vendedor_id", "status_logistico", "status_devolucao", "cidade_entrega", "uf_entrega", "valor_frete_cotado", "data_faturamento", "data_entrega", "motivo_cancelamento"], orders)
    write("devolucoes", ["pedido_id", "protocolo", "data_solicitacao", "status", "motivo", "data_encerramento"], returns)
    write("itens_devolucao", ["devolucao_id", "item_pedido_id", "quantidade_devolvida", "valor_reembolso"], [(d,i,q,cents(v)) for d,i,q,v in return_items])

    payments, approved = [], {}
    for pedido_id, order in enumerate(orders, 1):
        day = date.fromisoformat(order[1][:10]); total = item_total(items, pedido_id) + (0 if order[5] == "CANCELADO" else 1290 if order[3] not in (3,4) else 0)
        seq = 1
        if pedido_id <= 600:
            payments.append([pedido_id, seq, stamp(day + timedelta(days=1)), "PIX", "COBRANCA", "RECUSADO", total, 1, "", ""])
        elif pedido_id <= 840:
            payments.append([pedido_id, seq, stamp(day + timedelta(days=1)), "PIX", "COBRANCA", "APROVADO", total, 1, "", ""]); approved[pedido_id] = len(payments)
            payments.append([pedido_id, 2, stamp(day + timedelta(days=2)), "PIX", "ESTORNO", "APROVADO", total, 1, approved[pedido_id], ""])
        else:
            if pedido_id <= 1200:
                payments.append([pedido_id, seq, stamp(day), "BOLETO", "COBRANCA", "RECUSADO", total, 1, "", ""]); seq += 1
            if 2001 <= pedido_id <= 2480:
                first = total // 2
                payments.append([pedido_id, seq, stamp(day + timedelta(days=1)), "PIX", "COBRANCA", "APROVADO", first, 1, "", ""]); approved[pedido_id] = len(payments)
                payments.append([pedido_id, seq + 1, stamp(day + timedelta(days=2)), "CARTAO_CREDITO", "COBRANCA", "APROVADO", total - first, 2, "", ""])
            else:
                payments.append([pedido_id, seq, stamp(day + timedelta(days=1)), "PIX", "COBRANCA", "APROVADO", total, 1, "", ""]); approved[pedido_id] = len(payments)
    for dev_id in range(1, 601):
        pedido_id = 4000 + dev_id
        closing = date.fromisoformat(returns[dev_id - 1][5][:10])
        refund = sum(value for d, _item, _quantity, value in return_items if d == dev_id)
        base_seq = 2
        payments.append([pedido_id, base_seq, stamp(closing + timedelta(days=1)), "PIX", "ESTORNO", "APROVADO", refund, 1, approved[pedido_id], dev_id])
    assert len(payments) == 13680
    write("pagamentos", ["pedido_id", "sequencia", "data_pagamento", "meio_pagamento", "tipo_evento", "status", "valor", "parcelas", "pagamento_origem_id", "devolucao_id"], [(p,s,d,m,e,st,cents(v),n,o,dev) for p,s,d,m,e,st,v,n,o,dev in payments])
    manifest = {path.name: {"linhas": sum(1 for _ in path.open(encoding="utf-8")) - 1, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()} for path in sorted(OUT.glob("*.csv"))}
    (OUT / "manifest.json").write_text(json.dumps({"seed": SEED, "arquivos": manifest}, indent=2, sort_keys=True) + "\n", encoding="utf-8")

if __name__ == "__main__": main()

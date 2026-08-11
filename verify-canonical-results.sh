#!/usr/bin/env bash
set -euo pipefail

# A referência é deliberadamente somente-leitura neste fluxo.  A promoção de
# novos hashes exige mudar contracts/canonical-results-v1.2.json em commit
# explícito, nunca uma execução deste runner.
reference=contracts/canonical-results-v1.2.json
[[ -f "$reference" ]] || { echo "I38: referência canônica ausente: $reference" >&2; exit 1; }
tmp_dir=$(mktemp -d canonical-results.XXXXXX)
trap 'rm -rf "$tmp_dir"' EXIT

for n in $(seq -w 1 40); do
  timeout 60s docker compose exec -T db psql -q -X -v ON_ERROR_STOP=1 -U aurora -d aurora \
    --csv -P null=NULL -f "/workspace/answers/q${n}.sql" > "$tmp_dir/q${n}.csv"
done

python3 - "$reference" "$tmp_dir" <<'PY'
import csv
import hashlib
import json
import pathlib
import sys

reference = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))
actual_dir = pathlib.Path(sys.argv[2])
errors = []

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

for n in range(1, 41):
    name = f'q{n:02d}.csv'
    expected = reference['answers'].get(name)
    csv_path = actual_dir / name
    sql_path = pathlib.Path('answers') / f'q{n:02d}.sql'
    if expected is None:
        errors.append(f'{name}: ausente da referência')
        continue
    raw = csv_path.read_bytes()
    if raw.startswith(b'\xef\xbb\xbf') or b'\r' in raw or not raw.endswith(b'\n'):
        errors.append(f'{name}: formato CSV não é UTF-8/LF/newline final')
    try:
        text = raw.decode('utf-8')
        rows = list(csv.reader(text.splitlines()))
    except (UnicodeDecodeError, csv.Error) as exc:
        errors.append(f'{name}: CSV inválido ({exc})')
        continue
    if not rows or rows[0] != expected['columns']:
        errors.append(f'{name}: nomes/ordem de colunas divergentes')
    if len(rows) - 1 != expected['linhas']:
        errors.append(f'{name}: cardinalidade {len(rows)-1} != {expected["linhas"]}')
    if expected.get('format') != 'utf-8,lf,csv,null=NULL,header':
        errors.append(f'{name}: contrato de formato inválido na referência')
    if sha(sql_path) != expected['sql_sha256']:
        errors.append(f'{name}: hash SQL divergente')
    # Hash byte a byte inclui a ordenação prescrita: uma inversão de linhas
    # também falha, mesmo que cardinalidade e valores agregados coincidam.
    if sha(csv_path) != expected['sha256']:
        errors.append(f'{name}: hash CSV/ordenação divergente')

if set(reference['answers']) != {f'q{n:02d}.csv' for n in range(1, 41)}:
    errors.append('referência não contém exatamente Q01–Q40')
if errors:
    raise SystemExit('I38 falhou:\n- ' + '\n- '.join(errors))
print('I38 passou: Q01–Q40 conferem contra a referência canônica versionada.')
PY

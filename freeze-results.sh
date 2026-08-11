#!/usr/bin/env bash
set -euo pipefail

# Nunca promove CSV parcial: tudo é escrito fora de results/ e só então trocado.
tmp_dir=$(mktemp -d results.tmp.XXXXXX)
trap 'rm -rf "$tmp_dir"' EXIT
timeout 90s python3 answers/generate.py
for n in $(seq -w 1 40); do
  timeout 60s docker compose exec -T db psql -q -X -v ON_ERROR_STOP=1 -U aurora -d aurora \
    --csv -P null=NULL -f "/workspace/answers/q${n}.sql" > "$tmp_dir/q${n}.csv"
done
python3 - "$tmp_dir" <<'PY' > "$tmp_dir/manifest.json"
import hashlib, json, pathlib, sys
root = pathlib.Path(sys.argv[1])
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
answers = pathlib.Path('answers')
payload = {
  'proveniencia': {
    'dataset_design_v1_2_sha256': sha(pathlib.Path('DATASET-DESIGN-v1.2.md')),
    'schema_sha256': sha(pathlib.Path('schema.sql')),
    'build_manifest_sha256': sha(pathlib.Path('build/manifest.json')),
    'postgres_image': 'postgres@sha256:95206741a5b214807675e14165369d05b93a9cf692223b616d07cca227e74b0b',
  },
  'respostas': {}
}
for n in range(1, 41):
  stem = f'q{n:02d}'
  csv = root / f'{stem}.csv'
  sql = answers / f'{stem}.sql'
  payload['respostas'][csv.name] = {
    'linhas': len(csv.read_text(encoding='utf-8').splitlines()) - 1,
    'sha256': sha(csv),
    'sql_sha256': sha(sql),
  }
print(json.dumps(payload, indent=2, sort_keys=True))
PY
rm -rf results
mv "$tmp_dir" results
trap - EXIT

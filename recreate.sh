#!/usr/bin/env bash
set -euo pipefail
timeout 90s docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U aurora -d aurora -f /workspace/schema.sql
timeout 90s python3 generate.py
timeout 180s docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U aurora -d aurora -f /workspace/load.sql

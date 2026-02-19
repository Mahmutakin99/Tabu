#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CATALOG_PATH="${1:-$ROOT_DIR/Tabu/Files/Kelimeler.json}"
SOURCES_PATH="${2:-$ROOT_DIR/Tabu/Files/Kelimeler.sources.json}"

ruby "$ROOT_DIR/scripts/validate_catalog.rb" "$CATALOG_PATH"
ruby "$ROOT_DIR/scripts/verify_sources_alignment.rb" "$CATALOG_PATH" "$SOURCES_PATH"

echo "Catalog quality gate passed."

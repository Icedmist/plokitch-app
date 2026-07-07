#!/usr/bin/env bash
set -euo pipefail

# Exports full schema and data (compressed) using pg_dump and DATABASE_URL from .env
# Requires: pg_dump (Postgres client) installed and network access to the DB

if [ -z "${DATABASE_URL:-}" ]; then
  # try loading from .env if present
  if [ -f .env ]; then
    # Safely parse .env lines of the form KEY=VALUE, ignoring comments and empty lines.
    while IFS= read -r line; do
      # skip comments and empty lines
      [[ -z "$line" || ${line#\s} =~ ^# ]] && continue
      # extract key and value at the first '='
      if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        val="${BASH_REMATCH[2]}"
        # remove surrounding quotes if present
        if [[ "$val" =~ ^\"(.*)\"$ ]]; then
          val="${BASH_REMATCH[1]}"
        elif [[ "$val" =~ ^\'(.*)\'$ ]]; then
          val="${BASH_REMATCH[1]}"
        fi
        export "$key=$val"
      fi
    done < .env
  fi
fi

if [ -z "${DATABASE_URL:-}" ]; then
  echo "DATABASE_URL not set. Export aborted." >&2
  exit 1
fi

OUT_DIR="db_exports"
mkdir -p "$OUT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCHEMA_FILE="$OUT_DIR/db_schema_$TIMESTAMP.sql"
DATA_FILE="$OUT_DIR/db_data_$TIMESTAMP.sql"
FULL_FILE="$OUT_DIR/db_full_$TIMESTAMP.sql.gz"

# Dump schema only
pg_dump --schema-only "$DATABASE_URL" > "$SCHEMA_FILE"
# Dump data only (no schema)
pg_dump --data-only "$DATABASE_URL" > "$DATA_FILE"
# Full compressed dump
pg_dump "$DATABASE_URL" | gzip > "$FULL_FILE"

echo "Schema -> $SCHEMA_FILE"
echo "Data -> $DATA_FILE"
echo "Full (gz) -> $FULL_FILE"

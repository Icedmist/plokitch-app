DB export and inspection

Prerequisites:
- `pg_dump` from PostgreSQL client tools must be installed.
- Network access to the Supabase/Postgres instance.
- Your `.env` file should contain a `DATABASE_URL` environment variable.

Quick dump (schema + data):

```bash
# make script executable once
chmod +x scripts/dump_db.sh
# run
./scripts/dump_db.sh
```

This will create `db_exports/` with schema, data, and a gzipped full dump.

To inspect schema only without running the script:

```bash
# loads .env and runs pg_dump schema-only
export $(grep -v '^#' .env | xargs)
pg_dump --schema-only "$DATABASE_URL" > schema.sql
```

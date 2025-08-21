#!/bin/bash
set -euo pipefail

DB_USER="${DB_USER:-backup}"
DB_PASSWORD="${DB_PASSWORD:-password}"
DB_HOST="localhost"
DB_PORT="3306"

DB_PROD="ShopDB"
DB_RESERVE="ShopDBReserve"
DB_DEV="ShopDBDevelopment"

DUMP_SCHEMA_DATA="/tmp/${DB_PROD}_schema_data.sql"
DUMP_DATA_ONLY="/tmp/${DB_PROD}_data.sql"

echo "[INFO] Starting backup procedure for ShopDB at $(date)"

# Создаем полный дамп без --events
echo "[INFO] Creating full dump of $DB_PROD..."
mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" \
    --routines --triggers --databases "$DB_PROD" > "$DUMP_SCHEMA_DATA" 2>/dev/null || true

echo "[INFO] Restoring dump into $DB_RESERVE..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_RESERVE" < "$DUMP_SCHEMA_DATA" 2>/dev/null || true

# Создаем дамп только данных без схемы
echo "[INFO] Creating data-only dump of $DB_PROD..."
mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" \
    --no-create-info --skip-triggers --skip-add-drop-table "$DB_PROD" > "$DUMP_DATA_ONLY" 2>/dev/null || true

echo "[INFO] Restoring data into $DB_DEV..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_DEV" < "$DUMP_DATA_ONLY" 2>/dev/null || true

rm -f "$DUMP_SCHEMA_DATA" "$DUMP_DATA_ONLY"

echo "[INFO] Backup and restore finished successfully at $(date)"

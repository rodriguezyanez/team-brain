#!/usr/bin/env bash
# =============================================================
# backup.sh — Backup y restore de los volúmenes de Neo4j
# =============================================================

set -e

BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

backup() {
  mkdir -p "$BACKUP_DIR"
  echo "📦 Creando backup en ${BACKUP_DIR}/neo4j-backup-${TIMESTAMP}.tar.gz ..."

  docker run --rm \
    -v team-brain_neo4j_data:/data \
    -v "$(pwd)/${BACKUP_DIR}":/backup \
    alpine \
    tar czf "/backup/neo4j-backup-${TIMESTAMP}.tar.gz" /data

  echo "✅ Backup creado: ${BACKUP_DIR}/neo4j-backup-${TIMESTAMP}.tar.gz"
  echo "   Tamaño: $(du -sh ${BACKUP_DIR}/neo4j-backup-${TIMESTAMP}.tar.gz | cut -f1)"
}

restore() {
  FILE="$1"
  if [ -z "$FILE" ]; then
    echo "❌ Especifica el archivo: ./backup.sh restore backups/neo4j-backup-XXXX.tar.gz"
    exit 1
  fi

  echo "⚠️  Esto sobreescribirá los datos actuales. ¿Continuar? (s/N)"
  read -r CONFIRM
  if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo "Cancelado."
    exit 0
  fi

  echo "♻️  Restaurando desde $FILE ..."
  docker compose down

  docker run --rm \
    -v team-brain_neo4j_data:/data \
    -v "$(pwd)":/backup \
    alpine \
    sh -c "rm -rf /data/* && tar xzf /backup/${FILE} -C / --strip-components=0"

  docker compose up -d
  echo "✅ Restauración completa."
}

list() {
  echo "📋 Backups disponibles en ${BACKUP_DIR}/:"
  ls -lh "${BACKUP_DIR}"/neo4j-backup-*.tar.gz 2>/dev/null || echo "   (ninguno)"
}

case "${1:-backup}" in
  backup)  backup ;;
  restore) restore "$2" ;;
  list)    list ;;
  *)
    echo "Uso: $0 [backup|restore <archivo>|list]"
    ;;
esac

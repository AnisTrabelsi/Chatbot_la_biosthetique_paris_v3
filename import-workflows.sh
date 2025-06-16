#!/usr/bin/env bash
set -euo pipefail

# Nom du service n8n tel qu'il est défini dans docker-compose.yml
N8N_SERVICE="n8n"

echo "🔎 Vérification que le service '${N8N_SERVICE}' est en cours d'exécution…"
docker compose ps "${N8N_SERVICE}" | grep Up >/dev/null \
  || { echo "❌ Le service '${N8N_SERVICE}' n'est pas démarré. Lance d'abord 'docker compose up -d'."; exit 1; }

echo "📂 Import des workflows depuis './workflows/'"
for wf in workflows/*.json; do
  filename=$(basename "$wf")
  echo " • Import de '${filename}'…"
  docker compose exec -T "${N8N_SERVICE}" \
    n8n import:workflow-and-overwrite --input "/home/node/workflows/${filename}"
done

echo "✅ Tous les workflows ont été importés avec succès !"

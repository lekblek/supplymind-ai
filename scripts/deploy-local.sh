#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "======================================"
echo " SupplyMind AI - Local Deployment"
echo "======================================"

if [ ! -f "infra/docker/.env" ]; then
    echo "Missing infra/docker/.env file"
    exit 1
fi

echo "[1/4] Running local CI"
bash "$ROOT_DIR/scripts/ci-local.sh"

echo "[2/4] Validating Docker Compose"
just docker-config

echo "[3/4] Building and starting containers"
just docker-up

echo "[4/4] Checking application health"

for attempt in {1..30}; do
    response="$(
        curl --fail --silent \
          --max-time 3 \
         http://127.0.0.1:8080/api/v1/actuator/health \
          2>/dev/null || true
    )"

    if [[ "$response" == *'"status":"UP"'* ]]; then
        echo "Application health check passed"
        docker compose ps
        echo
        echo "LOCAL DEPLOYMENT PASSED"
        exit 0
    fi

    sleep 2
done

echo "Application did not become healthy"
docker compose logs --tail=100 backend
exit 1

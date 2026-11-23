#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/apps/supplymind-backend"

echo "======================================"
echo " SupplyMind AI - Local CI"
echo "======================================"

cd "$ROOT_DIR"

echo "[1/5] Checking Git changes"
git diff --check
git diff --cached --check

echo "[2/5] Checking Docker"
docker info >/dev/null

echo "[3/5] Checking Java"
java -version

echo "[4/5] Building and testing backend"
cd "$BACKEND_DIR"

./mvnw --batch-mode \
  --no-transfer-progress \
  clean verify

echo "[5/5] Checking packaged JAR"

shopt -s nullglob
jars=(target/*.jar)

if [ "${#jars[@]}" -ne 1 ]; then
    echo "Expected exactly one executable JAR."
    exit 1
fi

echo "Artifact: ${jars[0]}"
echo
echo "LOCAL CI PASSED"

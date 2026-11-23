# SupplyMind AI — command runner
# Shell: Git Bash (Windows), Bash (Linux/macOS)
# Usage: just / just --list

set minimum-version := '1.55.0'
set indentation := '  '
set shell := ['bash', '-eu', '-o', 'pipefail', '-c']
set quiet := true
set positional-arguments := true

backend := 'apps/supplymind-backend'
web := 'apps/supplymind-web'
mobile := 'apps/supplymind_mobile'
compose_file := 'infra/docker/compose.yml'
env_file := 'infra/docker/.env'
db_service := env('DB_SERVICE', 'postgres-app')
backend_base := env('BACKEND_BASE_URL', 'http://127.0.0.1:8080/api/v1')
web_base := env('WEB_BASE_URL', 'http://127.0.0.1:4200')

# --------------------------- Discovery / checks ---------------------------

# List all documented recipes.
default:
  @just --list

# Show recipes grouped by purpose.
[group('00 · Tools')]
help:
  @just --list

# Inspect local tool versions (optional tools are reported as missing).
[group('00 · Tools')]
doctor:
  @echo '== Toolchain =='
  @for c in just git java javac node npm flutter dart docker adb; do if command -v "$c" >/dev/null 2>&1; then echo "[OK] $c"; else echo "[--] $c not found"; fi; done
  @just --version
  @java -version
  @node --version
  @npm --version
  @flutter --version
  @docker compose version


# Confirm the expected monorepo paths exist.
[group('00 · Tools')]
paths:
    @for p in '{{backend}}/pom.xml' '{{compose_file}}'; do test -f "$p" && echo "[OK] $p" || { echo "[MISSING] $p"; exit 1; }; done

# Check that the private Docker env file exists without printing secrets.
[group('00 · Tools')]
env-check:
  @test -f '{{env_file}}' || { echo 'Missing {{env_file}}; create from the local example and add credentials.'; exit 1; }
  @echo '{{env_file}} exists (contents not displayed).'

# --

# --------------------------- Docker / services ----------------------------

# Validate Compose without printing resolved secrets.
[group('10 · Docker')]
docker-config: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' config --quiet

# List service names defined in infra/docker/compose.yml.
[group('10 · Docker')]
docker-services: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' config --services

# Start Compose services; wait for healthy services.
[group('10 · Docker')]
docker-up: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' up -d --wait

# Start or rebuild Compose services.
[group('10 · Docker')]
docker-build: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' up -d --build --wait

# Stop/remove containers and network but preserve database volumes.
[group('10 · Docker')]
docker-down: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' down

# Stop running containers without removing them.
[group('10 · Docker')]
docker-stop: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' stop

# Restart one Compose service or all services.
[group('10 · Docker')]
docker-restart service='': env-check
  @if [[ -n "$1" ]]; then docker compose --env-file '{{env_file}}' -f '{{compose_file}}' restart "$1"; else docker compose --env-file '{{env_file}}' -f '{{compose_file}}' restart; fi

# List Compose containers.
[group('10 · Docker')]
docker-ps: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' ps

# Follow logs for all services, or for one named service.
[group('10 · Docker')]
docker-logs service='': env-check
  @if [[ -n "$1" ]]; then docker compose --env-file '{{env_file}}' -f '{{compose_file}}' logs -f --tail=100 "$1"; else docker compose --env-file '{{env_file}}' -f '{{compose_file}}' logs -f --tail=100; fi

# Open an interactive shell in a Compose service (if it has sh).
[group('10 · Docker')]
docker-shell service: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' exec "$1" sh

# ----------------------------- PostgreSQL ---------------------------------

# Start only the PostgreSQL Compose service (default: postgres).
[group('20 · Database')]
db-up: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' up -d --wait '{{db_service}}'

# Check PostgreSQL readiness from inside its container.
[group('20 · Database')]
db-ping: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' exec -T '{{db_service}}' sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"'

# Open PostgreSQL psql using container-local credentials.
[group('20 · Database')]
db-shell: env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' exec '{{db_service}}' sh -c 'exec psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'

# Inspect Flyway history; change schema if you do not use app.
[group('20 · Database')]
db-history schema='app': env-check
  @docker compose --env-file '{{env_file}}' -f '{{compose_file}}' exec -T '{{db_service}}' sh -c 'exec psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT installed_rank, version, description, success FROM $1.flyway_schema_history ORDER BY installed_rank;"' sh "$1"

# Create a timestamped, untracked PostgreSQL custom-format backup.
[group('20 · Database')]
db-backup: env-check
  #!/usr/bin/env bash
  set -euo pipefail
  mkdir -p backups
  file="backups/supplymind-$(date +%Y%m%d-%H%M%S).dump"
  git check-ignore -q "$file" || { echo 'STOP: backups/ is not ignored by Git.' >&2; exit 1; }
  trap 'rm -f "$file"' ERR
  docker compose --env-file '{{env_file}}' -f '{{compose_file}}' exec -T '{{db_service}}' sh -c 'exec pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$file"
  test -s "$file" || { echo 'Backup is empty.' >&2; exit 1; }
  trap - ERR
  echo "Backup created: $file (treat as sensitive data)"


# ---------------------------- Spring Boot ---------------------------------

# Run the backend with the selected Spring profile (default local).
[group('30 · Backend')]
backend-run profile='local':
  @if [[ -f '{{env_file}}' ]]; then just --dotenv-path '{{env_file}}' _backend-run "$1"; else just _backend-run "$1"; fi

# Internal: only this child process receives database env variables.
[private]
_backend-run profile:
  @root="$(pwd -W 2>/dev/null || pwd -P)"; \
    secrets_dir="$root/infra/docker/secrets/postgres/"; \
    test -d "$secrets_dir" || { echo "Missing PostgreSQL secrets directory: $secrets_dir" >&2; exit 1; }; \
    SUPPLYMIND_ROOT="$root" SUPPLYMIND_SECRETS_DIR="$secrets_dir" bash -c 'cd apps/supplymind-backend && ./mvnw spring-boot:run "-Dspring-boot.run.profiles=$1"' _ "$1"

# Start PostgreSQL, then Spring Boot on the host.
[group('30 · Backend')]
dev-backend: db-up
  @just backend-run local

# Run the backend test suite.
[group('30 · Backend')]
backend-test:
  @if [[ -f '{{env_file}}' ]]; then just --dotenv-path '{{env_file}}' _backend-mvn test; else just _backend-mvn test; fi

# Clean, verify, and run Maven checks.
[group('30 · Backend')]
backend-verify:
  @if [[ -f '{{env_file}}' ]]; then just --dotenv-path '{{env_file}}' _backend-mvn clean verify; else just _backend-mvn clean verify; fi

# Verify backend with local environment variables loaded only for Maven.
[group('30 · Backend')]
backend-verify-local:
  @if [[ -f '{{env_file}}' ]]; then just --dotenv-path '{{env_file}}' _backend-verify-local; else just _backend-verify-local; fi

[private]
_backend-verify-local:
  @just _backend-mvn clean verify

# Internal: run Maven in the backend with the repository root exported for the secrets config tree.
[private]
_backend-mvn *goals:
  @SUPPLYMIND_ROOT="$(pwd -W 2>/dev/null || pwd -P)" bash -c 'cd apps/supplymind-backend && ./mvnw -B -ntp "$@"' _ {{goals}}

# Package the Spring Boot application without skipping tests.
[group('30 · Backend')]
backend-package:
  @cd '{{backend}}' && ./mvnw -B -ntp package

# Show the resolved Maven dependency tree.
[group('30 · Backend')]
backend-deps:
  @cd '{{backend}}' && ./mvnw -B -ntp dependency:tree

# Probe the backend Actuator endpoint.
[group('30 · Backend')]
backend-health:
  @curl --fail --silent --show-error '{{backend_base}}/actuator/health' && echo

# Probe the backend technical API endpoint, if implemented.
[group('30 · Backend')]
backend-api-health:
  @curl --fail --silent --show-error '{{backend_base}}/api/system/status' && echo


# Generate the versioned OpenAPI contract automatically.
[group('30 · Backend')]
openapi-update:
  @if [[ -f '{{env_file}}' ]]; then just --dotenv-path '{{env_file}}' _openapi-update; else just _openapi-update; fi

[private]
_openapi-update:
  @root_dir="$(pwd -W 2>/dev/null || pwd -P)"; \
    cd '{{backend}}' && \
    SupplyMind="$root_dir" ./mvnw -B -ntp -Popenapi-export -DskipTests verify

# Verify that the generated contract matches Git.
[group('30 · Backend')]
openapi-check:
  @just openapi-update
  @git diff --exit-code -- contracts/openapi/supplymind-api.json

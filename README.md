# SupplyMind AI

Intelligent Supply Chain & Procurement Copilot.

SupplyMind AI is an independent business application
for inventory monitoring, procurement workflows,
supplier analysis and AI-assisted decision-making.

## Product vision

Enable organizations to detect stock shortages,
compare procurement options and make informed,
traceable purchasing decisions.

Human approval remains mandatory for sensitive
business operations.

## Technology stack

- Java and Spring Boot
- Spring Modulith
- PostgreSQL and Flyway
- Angular and TypeScript
- Python and FastAPI (future AI service)
- Docker and GitHub Actions

## Architecture

The initial implementation uses a modular monolith.

Business modules:
- Inventory
- Orders
- Procurement (future)
- Budget (future)

AI capabilities will be introduced progressively
through an independently deployable service.

## Project independence

SupplyMind AI is part of the Kuamoja ecosystem,
but does not depend on Kuamoja ERP to run.

Future integrations must use explicit contracts.

## Current status

Phase 00 - Project foundation.

See docs/PROJECT_STATE.md for progress.

## License

No license has been selected yet.
All rights reserved.

## Local development

### Requirements

- Java 25
- Docker with Docker Compose
- Git Bash (Windows)
- Maven Wrapper included in the repository

### Configuration

Copy `.env.example` to `.env` and configure
the local PostgreSQL credentials.

### Run local CI

```bash
./scripts/ci-local.sh
```

### Build and deploy locally

```bash
./scripts/deploy-local.sh
```

### Check application

```bash
curl http://localhost:8081/actuator/health
```

### Inspect containers

```bash
docker compose ps
docker compose logs -f backend
```

### Stop local services

```bash
docker compose down
```

Do not use `docker compose down -v`
unless persistent database deletion is intentional.

## Development milestones

- Phase 00: Engineering foundation
- Phase 01: Inventory and Orders
- Phase 02: Procurement
- Phase 03: Approval workflow

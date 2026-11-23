# ADR-0001 - Architecture initiale de SupplyMind AI

Date: 2026-11-23
Status: Accepted for initial development

## Context

SupplyMind AI must be an independent, maintainable
and demonstrable business application.

An earlier design proposed a microservices architecture
with Kafka, Keycloak, an API Gateway and AI agents
from the beginning.

That architecture introduces substantial operational
complexity before the first business workflow exists.

## Decision

Start with a modular Spring Boot application using:

- Spring Boot
- Spring Modulith
- PostgreSQL
- Flyway
- REST APIs
- Automated tests

Separate business modules by responsibility.

Introduce a dedicated FastAPI application when
AI capabilities become necessary.

Do not require Kuamoja ERP for startup or operation.

## Initial business modules

1. Inventory
2. Orders

Procurement and budgeting will follow after the
first functional workflow is validated.

## Deferred technologies

- Kafka
- Microservice extraction
- API Gateway
- Keycloak
- LangGraph
- MCP
- RAG

These technologies remain candidates for later phases.
Their introduction requires a demonstrated need
or a clearly defined learning objective.

## Security boundaries

AI recommendations cannot authorize purchases.

Sensitive operations require server-side validation
and explicit human approval.

## Consequences

Advantages:
- Faster functional feedback
- Simpler local development
- Easier automated testing
- Reduced operational complexity
- Clearer progressive tutorials

Trade-offs:
- Less runtime isolation initially
- Future extraction may require refactoring
- Module boundaries must be enforced

## Re-evaluation

Review this decision when introducing external
events, AI workflows or independent service
deployment.

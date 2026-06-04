# ADR-001: Adopt Microservices as the Primary Architecture Style

**Status:** Accepted

## Context
YouScout is a greenfield video-centric social platform targeting millions of global users through phased geographic expansion. The five highest-priority architecture characteristics identified through domain analysis are: Scalability, Availability, Performance, Elasticity, and Fault Tolerance. An analysis of all eight candidate styles (M1–M3, D1–D4) against these characteristics conclusively shows that only the Microservices style achieves maximum ratings across all five. The project budget is unconstrained, which allows absorbing the higher operational complexity inherent to microservices. The team will be organized into cross-functional groups per business domain (Conway's Law), which naturally maps to per-service ownership.

## Decision
Adopt **Microservices Architecture (D4)** as the primary architectural style, complemented by **Event-Driven Architecture (D3)** patterns — specifically Apache Kafka — for asynchronous inter-service communication. Services communicate synchronously via REST/HTTP for operations requiring immediate responses, and asynchronously via Kafka for eventually-consistent operations (feed updates, notifications, analytics).

## Consequences
- ✅ Independent horizontal scaling per service
- ✅ Fault isolation — failures are contained to a single bounded context
- ✅ Technology freedom — each service selects its optimal stack
- ✅ Independent deployability — CI/CD pipeline per service
- ✅ Team autonomy — each team owns a complete, deployable service
- ❌ Distributed system complexity requires dedicated operational tooling (service discovery, distributed tracing, centralized config)
- ❌ No cross-service ACID transactions — requires Saga pattern (see ADR-013)
- ❌ Network latency between services — requires Circuit Breaker pattern (see ADR-006)

## Governance
- Every new service requires architectural review before creation
- No service may directly access another service's database
- All services must expose `/actuator/health` and `/actuator/metrics` endpoints
- All synchronous inter-service calls must implement a circuit breaker
- Architecture deviations must be captured in a new or superseding ADR

## Notes
References: Lewis & Fowler (2014), Chris Richardson *Microservices Patterns* (2018), Prof. ALLAKI ASEDS slides 2025/2026.

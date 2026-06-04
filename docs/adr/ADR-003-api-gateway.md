# ADR-003: API Gateway as Single Entry Point

**Status:** Accepted

## Context
The Flutter mobile app must communicate with 8 backend microservices. Direct Client-to-Microservice communication is the naive solution, but the course explicitly rejects it: *"it rarely makes sense for clients to talk directly to microservices."* Problems: (1) the mobile app must make N requests to render one screen, increasing latency on mobile connections; (2) the client is tightly coupled to the internal service topology; (3) cross-cutting concerns (authentication, rate limiting, logging) must be re-implemented in every service; (4) refactoring internal services requires mobile app updates.

## Decision
Deploy **Spring Cloud Gateway** as the single API Gateway. All external traffic — from the Flutter app and the admin back-office — passes through it. Responsibilities:
- JWT token validation (reject unauthorized requests before they reach services)
- Request routing based on URL path (`/api/users/** → user-service`, `/api/videos/** → video-service`, etc.)
- Rate limiting per IP and per user token (prevent abuse)
- SSL/TLS termination
- Global request/response logging with correlation ID injection
- Load balancing across multiple instances of each service (via Eureka integration)
- Protocol translation where needed

## Consequences
- ✅ Simplified client — one base URL, one auth mechanism
- ✅ Cross-cutting concerns centralized — changes to JWT validation apply instantly across all services
- ✅ Internal topology fully encapsulated — services can be refactored without client changes
- ✅ Enables Backend-For-Frontend (BFF) pattern if mobile and admin clients eventually need differentiated APIs
- ❌ The gateway becomes a potential Single Point of Failure — mitigated by deploying a minimum of 3 gateway instances behind a load balancer
- ❌ Can become a development bottleneck if every new endpoint requires a gateway routing rule update — mitigated by automated route registration via Eureka

## Governance
- No service is directly accessible from the internet — all traffic routes through the gateway
- The gateway contains zero business logic — routing, auth, and cross-cutting concerns only
- Gateway deployed in HA mode (≥3 instances) with health checks and automatic failover
- JWT validation failure returns 401 without hitting any downstream service

## Notes
Technology: Spring Cloud Gateway. References: API Gateway slides, Prof. ALLAKI. Pattern: Backend-For-Frontend (BFF) variant available for future admin portal isolation.

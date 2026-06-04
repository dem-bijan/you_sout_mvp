# ADR-006: Circuit Breaker Pattern for Partial Failure Handling

**Status:** Accepted

## Context
The course (*Handling Partial Failures in Microservices*) identifies the core risk of synchronous service communication: *"situations when an invoked service is either down or exhibiting high latency."* Without protection, a slow `social-service` would cause the API Gateway to hold open HTTP connections waiting for a response, eventually exhausting thread pools and cascading into a total platform outage. This is called **cascading failure**, and it is the primary operational risk of synchronous microservice communication.

The three solutions from the course are: (1) network timeouts, (2) limiting outstanding requests, (3) Circuit Breaker pattern.

## Decision
Implement **Resilience4j Circuit Breaker** on every synchronous inter-service HTTP call, combined with:
- **Network timeouts**: 3-second connection timeout, 5-second read timeout on all service clients
- **Retry with exponential backoff**: 3 attempts with 500ms initial delay and 2× multiplier
- **Fallback responses**: Every circuit-broken call returns a degraded but valid response (empty list, cached value, or graceful error message) rather than propagating an exception to the user

Circuit states: CLOSED (normal operation) → OPEN (failure threshold exceeded, all calls fail fast) → HALF-OPEN (test calls to check recovery) → CLOSED (if recovery confirmed).

Configuration: Open after 5 failures in 10 calls (50% failure rate), wait 30 seconds in OPEN state before HALF-OPEN.

## Consequences
- ✅ Cascading failure prevention — a failed downstream service never takes down upstream services
- ✅ Graceful degradation — users see partial functionality rather than a broken page
- ✅ Automatic recovery — circuit self-heals when the downstream service recovers
- ✅ Fast failure — open circuit fails immediately rather than waiting for timeout, improving perceived performance during outages
- ❌ Fallback handlers add development overhead — every circuit breaker needs a defined fallback
- ❌ False positives possible — a network blip could trip the circuit briefly; tuning of thresholds is required

## Governance
- All inter-service HTTP clients use `@CircuitBreaker` annotation or equivalent Resilience4j configuration
- Fallback handlers are mandatory — no circuit breaker without a fallback (enforced in code review)
- Circuit breaker state metrics are exposed via Micrometer → Prometheus and visible in Grafana dashboards
- Load testing validates circuit breaker behavior before each production deployment

## Notes
Technology: Resilience4j. References: Handling Partial Failures slides, Prof. ALLAKI.

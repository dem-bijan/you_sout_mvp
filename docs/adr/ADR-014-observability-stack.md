# ADR-014: Centralized Observability Stack

**Status:** Accepted

## Context
A distributed system with 8 microservices and a message broker is operationally opaque without explicit observability infrastructure. When a video upload fails, the operations team must determine whether the failure occurred in the API Gateway, video-service, MinIO, or Kafka — within minutes, not hours. Without distributed tracing, this requires manual log correlation across 8 different log streams.

## Decision
Three-pillar observability:
1. **Distributed Tracing — Zipkin**: Every request receives a `X-Trace-Id` correlation ID at the API Gateway (injected via Micrometer Tracing). This ID propagates through all service calls and Kafka messages. Zipkin UI shows the complete call tree for any request, including time spent in each service.
2. **Metrics — Prometheus + Grafana**: Spring Actuator exposes metrics at `/actuator/prometheus`. Prometheus scrapes all services every 15 seconds. Grafana dashboards show: request rates, error rates (HTTP 4xx/5xx), p50/p95/p99 latencies, JVM metrics, Kafka consumer lag.
3. **Structured Logging**: Each service produces JSON-formatted logs including trace ID, service name, timestamp, and log level. Logs aggregate to a central collector (Loki in production, file-based for MVP).

## Consequences
- ✅ Root cause analysis of failures reduced from hours to minutes
- ✅ Performance bottlenecks visible in Zipkin flame graphs
- ✅ Proactive alerting via Grafana AlertManager before users are impacted
- ❌ Observability infrastructure adds RAM and disk requirements (~2GB additional)

## Governance
- Every new service must add `spring-boot-starter-actuator` and `micrometer-tracing-bridge-brave` dependencies
- Critical user flows (login, video upload, feed load) must have Grafana alerting on p95 latency thresholds
- Trace sampling rate: 10% in production (100% in development)

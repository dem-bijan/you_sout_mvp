# ADR-008: Service Discovery via Netflix Eureka

**Status:** Accepted

## Context
In a containerized microservices environment, service instances come and go dynamically (scaling, rolling deployments, failures). The API Gateway and other services cannot use hardcoded IP addresses or hostnames — those change constantly. A service discovery mechanism is required so that services can locate each other dynamically.

## Decision
Deploy **Netflix Eureka Server** as the service registry. All microservices register themselves with Eureka on startup (providing their hostname, port, health check URL, and metadata). The API Gateway uses Eureka to resolve service locations for load balancing (Spring Cloud LoadBalancer). Health checks are performed every 10 seconds; unresponsive instances are evicted after 30 seconds.

## Consequences
- ✅ Dynamic service location — no hardcoded IPs or hostnames
- ✅ Automatic load balancing across multiple instances of the same service
- ✅ Failed instances are automatically removed from the registry
- ✅ Native integration with Spring Cloud Gateway and Spring Boot
- ❌ Eureka Server itself is a dependency — deployed in HA mode (2+ instances) to avoid SPOF
- ❌ Eureka has known limitations at very high scale (10,000+ instances) — acceptable for YouScout MVP

## Governance
- Eureka deployed as a pair of instances (peer-aware replication)
- All services must implement `/actuator/health` returning Spring Boot Actuator health status
- Service metadata includes version tag for blue-green deployment routing

# ADR-011: Docker + Docker Compose for Containerization and Local Development

**Status:** Accepted

## Context
With 8 microservices, 2 infrastructure services (Eureka, Config), and 7+ infrastructure dependencies (PostgreSQL instances, Redis, MongoDB, Kafka, Zookeeper, MinIO), setting up a local development environment manually would require hours and produce environment-specific bugs ("works on my machine"). Containerization ensures consistent environments across all developers and deployment targets.

## Decision
All services are packaged as **Docker images** using multi-stage Dockerfile builds (JDK build stage → JRE runtime stage) to minimize image sizes. **Docker Compose** orchestrates all services and infrastructure dependencies for local development and demonstration. Each service communicates via Docker's internal network (`youscout-network`) using service names as hostnames.

Production deployment uses **Kubernetes** (or AWS ECS/Railway.app for MVP demo). The Docker Compose file serves as the reference topology that the Kubernetes deployment mirrors.

## Consequences
- ✅ `docker-compose up` brings the entire platform online in under 3 minutes
- ✅ All developers work in identical environments — no "works on my machine" issues
- ✅ Environment parity between development, staging, and production
- ✅ Multi-stage builds produce small production images (JRE-only, ~150MB vs JDK 500MB)
- ❌ Docker required on developer machines
- ❌ Resource-intensive on local machines (RAM: ~8GB for full stack)

## Governance
- All Docker images are tagged with Git commit SHA for traceability
- Images are built on every push via CI/CD and stored in a container registry
- `HEALTHCHECK` directives defined in every Dockerfile

# YouScout MVP Architecture Plan

## Overview
The goal is to deliver a **microservices‑based MVP** for a football‑talent social network, adhering to the ALD course constraints and the premium UI guidelines.

## Service Landscape
| Service | Responsibility | Language / Framework | Database | Port |
|---|---|---|---|---|
| **API Gateway** | Entry point, routing, auth, rate‑limiting | Node.js Fastify | – | 8080 |
| **User Service** | Registration, login, profile CRUD, JWT issuance | Python FastAPI | PostgreSQL | 8001 |
| **Video Service** | Upload, storage metadata, video feed listing | Python FastAPI | MongoDB | 8002 |
| **Interaction Service** | Likes, skill ratings, comments | Python FastAPI | MongoDB | 8003 |
| **Auth Service** (optional, embedded in gateway) | JWT verification, key rotation | Node.js Fastify | – | 8080 |

## Inter‑service Communication
- **Synchronous REST** for query‑oriented calls (e.g., User → Video to fetch feed). 
- **Circuit Breaker** on the critical User → Video call using the `opossum` library in the gateway to prevent cascade failures.
- **Asynchronous events** (future) via RabbitMQ / Kafka for notifications, but not required for MVP.

## Data Management
- **Database‑per‑service** pattern ensures loose coupling.
- **PostgreSQL** schema for Users (id, email, hashed_password, profile data).
- **MongoDB** collections for Videos (id, user_id, url, metadata) and Interactions (video_id, user_id, like, rating).
- All DBs run in Docker containers with persistent volumes.

## Storage Layer
- **MinIO** (S3‑compatible) runs locally; the Video Service stores video blobs there and serves signed URLs.
- For the MVP we mount a host directory (`./data/videos`) into MinIO for easy inspection.

## Authentication & Authorization
- **JWT (RS256)** issued by the User Service, signed with a private key stored in the gateway.
- The gateway validates JWT on every request and injects `user_id` into downstream calls.

## Deployment
- **Docker Compose** orchestrates all services, networks, and volumes.
- Each service is built from its own Dockerfile (Node.js for gateway, Python for FastAPI services).
- The compose file defines a single overlay network `youScoutNet` for internal communication.

## CI / Testing
- Unit tests with **pytest** for Python services and **jest** for Node.js.
- Integration tests using **Postman/Newman** against the gateway.
- Linting with **flake8**, **black**, **eslint**.

## Next Steps (Phase 3)
1. Scaffold repository structure and Dockerfiles.
2. Implement the API Gateway with routing and JWT validation.
3. Develop the User Service (auth flows, PostgreSQL models).
4. Build the Video Service (MinIO integration, MongoDB models).
5. Add the Interaction Service.
6. Write integration tests and CI pipeline.

*All components are designed for future extension – e.g., swapping MinIO for real S3, adding a message broker, or scaling services horizontally.*

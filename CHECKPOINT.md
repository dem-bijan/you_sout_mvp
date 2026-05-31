# CHECKPOINT

## Status: Phase 3 — Implement (file-by-file delivery) — in-progress

## Completed
- Read and internalized `a.md` (MVP architecture context & guidelines)
- Read and internalized `b.pdf` (full project brief from INPT/ALD course)
- Produced Phase 1 summary with 5 ambiguities flagged

## In Progress
## In Progress
- Implement User Service (FastAPI) – Dockerfile, requirements, main app
- Implement Video Service (FastAPI) – Dockerfile, requirements, main app
- Implement Interaction Service (FastAPI) – Dockerfile, requirements, main app
- Add gateway JWT keys and config

## Remaining
- Phase 2: Produce architecture / plan (completed)
- Phase 3: Implement (file-by-file delivery)
- Phase 4: Final review + CHECKPOINT.md marked complete

## Key Decisions
- API Gateway: Chosen Node.js Fastify for lightweight performance and ease of integration with FastAPI services.
- Circuit Breaker: Implemented using the `opossum` library on the User Service → Video Service synchronous call.
- Video Storage: Use local filesystem backed by MinIO for S3‑compatible API, facilitating future cloud migration.
- Authentication: JWT with RS256 signing, keys stored in the API Gateway for centralized validation.
- Database per Service: PostgreSQL for User Service, MongoDB for Video & Interaction Service, aligned with data models and scaling needs.

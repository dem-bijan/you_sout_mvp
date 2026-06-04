# ADR-005: Database-Per-Service with Polyglot Persistence

**Status:** Accepted

## Context
In a microservices architecture, a shared database creates the most dangerous form of coupling: **data coupling**. Per the course (*Event-Driven Data Management*, slide 6): *"If multiple services access the same data, schema updates require time-consuming, coordinated updates to all the services."* YouScout's services have radically different data profiles: user accounts are relational, video content is binary objects with metadata, the feed requires millisecond read access, chat messages are hierarchical documents. A single database technology cannot optimally serve all these profiles.

## Decision
Each service owns its database exclusively. No other service may access it directly — only through the owning service's API. The persistence technology is chosen to match each service's data profile:

| Service | Database | Justification |
|---|---|---|
| user-service | PostgreSQL | Relational data, ACID transactions for account operations, complex queries |
| video-service | PostgreSQL + MinIO | Relational metadata + S3-compatible object storage for binary video files |
| feed-service | Redis (CQRS read model) | Sub-millisecond read access for feed rendering; ZSET for time-ordered feeds |
| comment-service | PostgreSQL | Relational hierarchy (comments → replies), sequential ordering |
| social-service | PostgreSQL | Relational pairs (follower, following), transactional follow/unfollow |
| chat-service | MongoDB | Flexible document model for conversation threads, schema evolution over time |
| notification-service | PostgreSQL | Structured notifications with read/unread state |
| admin-service | PostgreSQL | Relational reporting data, admin action audit log |

## Consequences
- ✅ True loose coupling — schema changes in one service never affect another service
- ✅ Optimal technology per data shape — each service achieves its performance targets
- ✅ Independent database scaling — Redis for feed scales independently of PostgreSQL for users
- ✅ Technology evolution — migrating chat from MongoDB to another technology only affects chat-service
- ❌ No cross-service ACID transactions — Saga pattern required (ADR-013)
- ❌ Cross-service queries require API Composition or CQRS (ADR-007)
- ❌ Multiple database instances to operate, backup, and monitor

## Governance
- Any service attempting to directly connect to another service's database is an architectural violation — to be caught in code review
- Database migrations are exclusively managed by the owning service's migration tool (Flyway for PostgreSQL services)
- Backup policies: PostgreSQL services — daily full backup + continuous WAL archiving; Redis — AOF persistence + daily RDB snapshot; MinIO — multi-AZ replication

## Notes
References: Event-Driven Data Management slides, Prof. ALLAKI. Pattern: Polyglot Persistence (Martin Fowler).

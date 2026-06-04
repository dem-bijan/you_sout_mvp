# ADR-013: Saga Pattern for Distributed Transactions

**Status:** Accepted

## Context
With the Database-per-Service pattern (ADR-005), classical ACID transactions spanning multiple services are impossible. The course (*Event-Driven Data Management*, slide 11) explicitly states: *"2PC is not an option for Microservices."* YouScout has operations that span multiple services: account deletion must remove videos, comments, chat messages, and notifications. Video deletion must update like counts and remove feed entries.

## Decision
Implement **Choreography-based Saga** for cross-service transactions. Each service listens to domain events and executes its local transaction, publishing its own event to trigger the next step. For account deletion:
1. `user-service` publishes `user.account.deleted`
2. `video-service` consumes → marks all user videos as inactive → publishes `user.videos.deleted`
3. `comment-service` consumes → marks all user comments as inactive
4. `feed-service` consumes → removes user's feed entries
5. `notification-service` consumes → deletes all notifications
6. `chat-service` consumes → archives all conversations

Compensation transactions (rollback equivalents) are defined for each step in case of failure. The `user-service` maintains a saga state machine to track progress.

## Consequences
- ✅ No distributed locks — each service operates independently
- ✅ Services remain loosely coupled — no orchestrator knows about all services
- ✅ Natural alignment with event-driven architecture (Kafka)
- ❌ Potential for complex compensating transaction chains
- ❌ Debugging a saga requires tracing events across multiple services — mitigated by distributed tracing (ADR-014)

## Governance
- Every saga step is logged with saga ID and step status
- Compensation transactions are unit-tested for every saga scenario
- Saga timeouts: if a step has not completed within 30 seconds, the saga coordinator triggers compensation

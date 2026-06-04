# ADR-004: Apache Kafka for Asynchronous Inter-Service Communication

**Status:** Accepted

## Context
Multiple YouScout operations are inherently asynchronous: publishing a video should not block the user while the feed updates for all their followers. Sending notifications to thousands of followers on each video upload cannot be done synchronously. Analytics event collection cannot add latency to user-facing operations. If these operations were implemented as synchronous REST call chains, a slow or failed notification-service would block video uploads — coupling services that should be independent. The course (*Event-Driven Data Management*) explicitly teaches async messaging as the solution to distributed data management challenges.

## Decision
Apache **Kafka** is the message broker for all asynchronous inter-service communication. Kafka topics and their producer/consumer mapping:

| Topic | Producer | Consumers |
|---|---|---|
| `youscout.video.published` | video-service | feed-service, notification-service, admin-service |
| `youscout.comment.created` | comment-service | notification-service, admin-service |
| `youscout.like.added` | social-service | notification-service, video-service (count update) |
| `youscout.user.followed` | social-service | feed-service, notification-service |
| `youscout.video.reported` | video-service | admin-service |
| `youscout.user.blocked` | social-service | feed-service, notification-service |

Synchronous REST is reserved for: authentication, resource creation with immediate ID return, user profile queries, and any operation where the user explicitly waits for a result.

## Consequences
- ✅ Temporal decoupling — producers never wait for consumers
- ✅ Fan-out pattern — one event triggers multiple downstream processes independently
- ✅ Message persistence — Kafka retains messages for 7 days, enabling replay on consumer restart
- ✅ Natural audit trail — every published event is a timestamped record of what happened
- ✅ Backpressure handling — consumers process at their own rate without blocking producers
- ❌ Eventual consistency — the feed may show a video 100-500ms after publication (acceptable)
- ❌ Consumer idempotency required — messages may be delivered more than once (at-least-once semantics)
- ❌ Kafka + Zookeeper add operational infrastructure to manage

## Governance
- All event schemas are versioned using JSON Schema Registry
- All consumers are implemented to be idempotent (duplicate message = same result)
- Dead Letter Topics (DLT) configured for each topic — failed messages go to `{topic}.DLT` for investigation
- Kafka retention: 7 days, partition count: 3 per topic minimum, replication factor: 3

## Notes
References: Event-Driven Data Management slides, Prof. ALLAKI. Technology: Apache Kafka with Spring Kafka.

# ADR-007: CQRS Pattern for Feed Service

**Status:** Accepted

## Context
The news feed is the most read endpoint in the entire YouScout platform — every session starts with the feed. It requires aggregating recent videos from all accounts a user follows, ordered by timestamp. A naive implementation would call `social-service` to get the user's following list, then call `video-service` for each followed user's latest videos — generating O(N) API calls per feed request where N is the number of accounts followed. This is exactly the API Composition anti-pattern identified in the course (*Event-Driven Data Management*, slide 20) as producing *"high-latency, inefficient joins"*.

## Decision
`feed-service` implements the **CQRS (Command Query Responsibility Segregation)** pattern with a Redis materialized view as the read side. The feed is pre-computed and stored in Redis as a sorted set (ZSET), keyed by user ID, scored by video publish timestamp. It is updated asynchronously by consuming Kafka events — specifically `youscout.video.published` and `youscout.user.followed`. Feed reads are served exclusively from Redis with no inter-service calls at read time, achieving sub-10ms response times.

Feed update logic:
1. `video.published` event arrives → fetch the video author's follower list (via user-service call, cached in Redis) → prepend video ID to each follower's feed ZSET
2. `user.followed` event arrives → fetch the newly-followed user's recent videos → prepend them to the follower's feed

## Consequences
- ✅ Sub-10ms feed reads regardless of how many accounts the user follows
- ✅ feed-service is fully independent at read time — read operations never call another service
- ✅ Feed remains available even if video-service or social-service is temporarily unavailable
- ✅ Feed can serve millions of concurrent reads from Redis cluster without database pressure
- ❌ Eventual consistency — the feed update may lag 100-500ms behind the actual video publication (accepted trade-off)
- ❌ Redis storage for feeds — mitigated by TTL policies and configurable feed depth (max 500 videos per user)

## Governance
- The Redis feed ZSET is updated ONLY via Kafka event consumers — never by direct API calls from other services
- Feed entries expire after 7 days (TTL) — the Explore tab serves older content via direct video-service queries
- Redis feed data is treated as a cache — video-service is the source of truth for video metadata

## Notes
References: CQRS section, Event-Driven Data Management slides, Prof. ALLAKI. Technology: Spring Data Redis, Apache Kafka.

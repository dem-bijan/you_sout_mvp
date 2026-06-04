# ADR-002: Decompose Services Using Domain-Driven Design Bounded Contexts

**Status:** Accepted

## Context
Defining the correct service boundaries is the most consequential decision in a microservices architecture. Boundaries that are too fine produce excessive inter-service chattiness, degrading performance and making the system hard to debug. Boundaries that are too coarse negate the benefits of microservices. The course presents two principled decomposition approaches: Business Capability and Sub-Domain (DDD). YouScout's domain is moderately complex with 5+ distinct business capabilities, making DDD the more rigorous choice. The risk of creating a "distributed monolith" — services that are separately deployed but tightly coupled — must be actively mitigated.

## Decision
Apply the **DDD Sub-Domain decomposition** approach following the 4-phase process from the course: (1) Domain Analysis via Event Storming, (2) Bounded Context definition, (3) Domain Model creation (Tactical DDD — Entities, Value Objects, Aggregates), (4) Microservice identification. Two decomposition guidelines from the course are applied:
- **SRP (Single Responsibility Principle)**: Each service has exactly one reason to change
- **CCP (Common Closure Principle)**: Components that change for the same business reason belong in the same service

The mapping of bounded contexts to services is: Identity & Access → `user-service`, Content Management → `video-service`, Feed & Discovery → `feed-service`, Comments → `comment-service`, Social Engagement → `social-service`, Messaging → `chat-service`, Notification → `notification-service`, Administration → `admin-service`.

## Consequences
- ✅ Architecturally stable — business sub-domains change far less frequently than technology choices
- ✅ Ubiquitous language alignment between code and domain experts
- ✅ High cohesion within services, low coupling between services
- ✅ Validated against the 6 correctness criteria from the course (no chatty calls, no lock-step deployment, no tight coupling, single responsibility, no data consistency problems, small team per service)
- ❌ Requires an Event Storming workshop before development begins
- ❌ Boundary decisions for edge cases (e.g., does a "Like" belong to video-service or social-service?) require explicit team consensus

## Governance
- Any new feature is analyzed against existing bounded contexts before a new service is considered
- The Context Map is maintained at `/docs/architecture/context-map.png` and updated with each sprint
- Domain model classes are never shared between services — each service defines its own model

## Notes
References: DDD to define microservices slides; Eric Evans (2003) *Domain-Driven Design*; Decomposition Strategies slides, Prof. ALLAKI.

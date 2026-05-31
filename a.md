# YouScout - MVP Architecture Context & Guidelines

## 1. Project Overview
YouScout is a mobile social network (TikTok-style) dedicated to football talents. 
**Goal for this MVP:** Implement the critical path using a simplified Microservices architecture to demonstrate distributed systems concepts (ALD course). The codebase must be engineered for immediate extensibility so that post-MVP features can be integrated without refactoring the core foundation.

## 2. Core Features (MVP Scope ONLY)
- **User Management:** Registration/Login (JWT), Create Profile (Player, Scout, Fan).
- **Video Content:** Upload short videos, store them, retrieve video feed (metadata + URL).
- **Interactions:** Like videos, simple skill rating.

## 3. Architecture Constraints (ALD Course Alignment)
- **Architecture Style:** Microservices (deployable via Docker Compose).
- **API Gateway:** Required. Mobile app must only communicate with the API Gateway.
- **Inter-service Communication:** - Synchronous (REST API) for queries.
  - Circuit Breaker must be implemented on at least one synchronous call.
- **Data Management:** `Database per service` pattern. No shared databases.
- **Infrastructure:** Containerized environment (Docker). Services must be stateless to allow for seamless transition to advanced container orchestration later.

## 4. Tech Stack Recommendations
- **Frontend:** Flutter (Mobile cross-platform). 
- **API Gateway:** Node.js (Express/Fastify) or Spring Cloud Gateway.
- **Microservices (Backend):** Python (FastAPI), Node.js (NestJS), or Java (Spring Boot) - choose the most efficient for rapid MVP generation while supporting rigorous object-oriented testing.
- **Databases:** PostgreSQL (for Users), MongoDB (for Videos/Interactions).
- **Storage:** Local filesystem simulating Object Storage (MinIO or local static folder mapping) for video blob storage.

## 5. UI/UX Strict Guidelines (The "Majestic" Standard)
The frontend must not look like a standard MVP. It must deliver a premium, 5-star iOS-level aesthetic and a high-impact visual design. Apply the following design constraints to the Flutter implementation:
- **Cinematic & Immersive:** The video feed must dominate the screen edge-to-edge. Use subtle gradient overlays at the top and bottom to ensure text readability without breaking the immersion.
- **Depth & Materiality:** Implement subtle 3D depth cues, glassmorphism (frosted glass effects) for overlays and modal sheets, and metallic or highly polished accent tones for interactive elements (like the skill rating or 'Like' buttons). 
- **Clean Subject Focus:** When displaying player profiles, utilize a clean, uncluttered layout that keeps the focus entirely on the athlete and their stats.
- **Micro-interactions:** Ensure every tap has a smooth, spring-based animation response. Route transitions must be seamless and fluid.
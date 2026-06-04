# 🏟️ YouScout — Football Talent Discovery Platform

> Une plateforme sociale de type TikTok dédiée à la découverte de talents footballistiques. Les joueurs publient des vidéos de leurs compétences, les recruteurs découvrent de nouveaux talents.

---

## 📐 Architecture

```
┌──────────┐     ┌───────────────┐     ┌───────────────────────────────────────┐
│  Flutter │────►│  API Gateway  │────►│  Microservices (Spring Boot 3.3.x)   │
│  Mobile  │     │  (port 8080)  │     │                                       │
└──────────┘     └───────┬───────┘     │  user-service      (8081)             │
                         │             │  video-service      (8082)             │
                         │             │  feed-service       (8083)             │
                    JWT (RS256)        │  comment-service    (8084)             │
                    vérification       │  social-service     (8085)             │
                                       │  notification-svc   (8086)             │
                                       │  admin-service      (8087)             │
                                       └───────────────────────────────────────┘
                                              │         │         │
                                         ┌────┴───┐ ┌───┴──┐ ┌───┴────┐
                                         │ Kafka  │ │Redis │ │ MinIO  │
                                         │  9092  │ │ 6379 │ │  9000  │
                                         └────────┘ └──────┘ └────────┘
                                              │
                                         ┌────┴───────┐
                                         │ PostgreSQL │
                                         │    5432    │
                                         └────────────┘
```

## 🛠️ Stack Technique

| Couche | Technologie |
|--------|------------|
| Backend | Java 21, Spring Boot 3.3.5, Spring Cloud 2023.0.3 |
| Base de données | PostgreSQL 16 (une DB par service), Redis 7 |
| Messaging | Apache Kafka 3.6 |
| Stockage vidéo | MinIO (compatible S3) |
| Découverte | Netflix Eureka |
| Migrations | Flyway |
| Frontend | Flutter 3.22.x, Dart 3.3, Riverpod, GoRouter, Dio |
| Conteneurisation | Docker, Docker Compose |

---

## 🚀 Lancer le projet

### Prérequis

- **Docker** ≥ 24.0 et **Docker Compose** ≥ 2.20
- **Java 21** (pour le développement backend local)
- **Maven** ≥ 3.9 (ou utiliser le `mvnw` inclus)
- **Flutter** ≥ 3.22.0 (pour le frontend mobile)

### 1. Cloner le dépôt

```bash
git clone https://github.com/<votre-org>/you_scout_mvp.git
cd you_scout_mvp
```

### 2. Générer les clés RSA

```bash
cd infrastructure
chmod +x generate-keys.sh
./generate-keys.sh
```

Cela crée `infrastructure/keys/private.pem` et `infrastructure/keys/public.pem` utilisées par le user-service (signature) et l'api-gateway (vérification).

### 3. Configurer les variables d'environnement

```bash
cp infrastructure/.env.example infrastructure/.env
```

Éditez `infrastructure/.env` si nécessaire (les valeurs par défaut fonctionnent pour le développement local).

### 4. Démarrer l'infrastructure et les services

```bash
cd infrastructure
docker-compose up -d
```

Cela démarre dans l'ordre :
1. **PostgreSQL** — bases `youscout_users`, `youscout_videos`, `youscout_comments`, `youscout_social`, `youscout_notifications`
2. **Redis** — cache du feed
3. **Kafka + Zookeeper** — messaging asynchrone
4. **MinIO** — stockage objet (vidéos)
5. **Eureka Server** — découverte de services
6. **API Gateway** — point d'entrée HTTP (port 8080)
7. **Tous les microservices** — user, video, feed, comment, social, notification, admin

### 5. Vérifier que tout fonctionne

```bash
# Eureka dashboard
open http://localhost:8761

# API Gateway health
curl http://localhost:8080/actuator/health

# MinIO console
open http://localhost:9001  # user: youscout_minio / pass: youscout_minio_secret
```

### 6. Lancer le frontend Flutter

```bash
cd frontend/youscout_app
flutter pub get
flutter run
```

> **Note** : Par défaut, l'app pointe vers `http://localhost:8080/api`. Pour tester sur un appareil physique, modifiez `baseUrl` dans `lib/core/network/api_client.dart` avec l'IP de votre machine.

---

## 📁 Structure du projet

```
you_sout_mvp/
├── docs/
│   └── adr/                          # Architecture Decision Records
│       ├── ADR-001-microservices-architecture.md
│       ├── ADR-002-ddd-bounded-contexts.md
│       ├── ADR-003-api-gateway.md
│       ├── ADR-004-kafka-async-communication.md
│       ├── ADR-005-polyglot-persistence.md
│       ├── ADR-006-circuit-breaker.md
│       ├── ADR-007-cqrs-feed.md
│       ├── ADR-008-service-discovery.md
│       ├── ADR-009-jwt-oauth2.md
│       ├── ADR-010-minio-storage.md
│       ├── ADR-011-docker-compose.md
│       ├── ADR-012-flutter-frontend.md
│       ├── ADR-013-saga-pattern.md
│       └── ADR-014-observability-stack.md
├── infrastructure/
│   ├── docker-compose.yml            # Orchestration complète
│   ├── generate-keys.sh              # Génération RSA
│   ├── kafka/topics-init.sh          # Création auto des topics Kafka
│   └── .env.example
├── services/
│   ├── eureka-server/                # Service discovery
│   ├── api-gateway/                  # Gateway + JWT filter
│   ├── user-service/                 # Auth, profils, tokens
│   ├── video-service/                # Upload, MinIO, métadonnées
│   ├── feed-service/                 # Feed Redis (fan-out)
│   ├── comment-service/              # CRUD commentaires
│   ├── social-service/               # Follow / unfollow
│   ├── notification-service/         # Notifications (Kafka consumer)
│   └── admin-service/                # Modération (stub)
└── frontend/
    └── youscout_app/                 # Application Flutter
        └── lib/
            ├── core/                 # Theme, Network, Router, Providers
            ├── features/             # Auth, Feed, Upload, Profile, Notifications, Discover
            └── shared/              # Widgets réutilisables
```

---

## 🔐 Authentification

1. Le client envoie `POST /api/users/login` avec email + mot de passe.
2. Le `user-service` retourne un **access token** (JWT RS256, 15 min) et un **refresh token** (7 jours).
3. Le client stocke les tokens dans `flutter_secure_storage`.
4. Chaque requête ultérieure inclut le header `Authorization: Bearer <token>`.
5. L'**API Gateway** vérifie le JWT avec la clé publique RSA et injecte les headers `X-User-Id` et `X-User-Email`.
6. Les services en aval font confiance à ces headers (réseau Docker privé).
7. À l'expiration, le client utilise le refresh token pour obtenir de nouveaux tokens (transparent via `AuthInterceptor`).

---

## 📨 Événements Kafka

| Topic | Producteur | Consommateur(s) |
|-------|-----------|-----------------|
| `youscout.video.published` | video-service | feed-service, notification-service, admin-service |
| `youscout.comment.created` | comment-service | notification-service, admin-service |
| `youscout.like.added` | social-service | notification-service, video-service |
| `youscout.user.followed` | social-service | feed-service, notification-service |
| `youscout.video.reported` | video-service | admin-service |
| `youscout.user.blocked` | social-service | feed-service, notification-service |

---

## 📝 Architecture Decision Records (ADRs)

Les décisions architecturales sont documentées dans [`docs/adr/`](docs/adr/) :

| ADR | Sujet |
|-----|-------|
| [ADR-001](docs/adr/ADR-001-microservices-architecture.md) | Adopt Microservices as the Primary Architecture Style |
| [ADR-002](docs/adr/ADR-002-ddd-bounded-contexts.md) | Decompose Services Using Domain-Driven Design Bounded Contexts |
| [ADR-003](docs/adr/ADR-003-api-gateway.md) | API Gateway as Single Entry Point |
| [ADR-004](docs/adr/ADR-004-kafka-async-communication.md) | Apache Kafka for Asynchronous Inter-Service Communication |
| [ADR-005](docs/adr/ADR-005-polyglot-persistence.md) | Database-Per-Service with Polyglot Persistence |
| [ADR-006](docs/adr/ADR-006-circuit-breaker.md) | Circuit Breaker Pattern for Partial Failure Handling |
| [ADR-007](docs/adr/ADR-007-cqrs-feed.md) | CQRS Pattern for Feed Service |
| [ADR-008](docs/adr/ADR-008-service-discovery.md) | Service Discovery via Netflix Eureka |
| [ADR-009](docs/adr/ADR-009-jwt-oauth2.md) | JWT + OAuth2 Authentication Strategy |
| [ADR-010](docs/adr/ADR-010-minio-storage.md) | MinIO for Video Object Storage |
| [ADR-011](docs/adr/ADR-011-docker-compose.md) | Docker + Docker Compose for Containerization |
| [ADR-012](docs/adr/ADR-012-flutter-frontend.md) | Flutter for Cross-Platform Mobile Frontend |
| [ADR-013](docs/adr/ADR-013-saga-pattern.md) | Saga Pattern for Distributed Transactions |
| [ADR-014](docs/adr/ADR-014-observability-stack.md) | Centralized Observability Stack |

---

## 🧪 Tests (à venir)

- **Backend** : JUnit 5 + Testcontainers (PostgreSQL, Kafka, Redis)
- **Frontend** : Widget tests + integration tests avec `flutter_test`
- **E2E** : Scénarios Postman / Newman via le gateway

---

## 📜 Licence

Projet universitaire — tous droits réservés.

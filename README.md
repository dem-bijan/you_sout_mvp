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
git clone https://github.com/<votre-org>/you_sout_mvp.git
cd you_sout_mvp
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
open http://localhost:9001  # user: minioadmin / pass: minioadmin
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
│       ├── ADR-002-kafka-async-communication.md
│       ├── ADR-003-jwt-gateway-auth.md
│       ├── ADR-004-redis-feed-fanout.md
│       └── ADR-005-flutter-riverpod.md
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
| `youscout.video.published` | video-service | feed-service |
| `youscout.video.liked` | video-service | notification-service |
| `youscout.comment.created` | comment-service | notification-service |
| `youscout.user.followed` | social-service | notification-service, feed-service |

---

## 📝 Architecture Decision Records (ADRs)

Les décisions architecturales sont documentées dans [`docs/adr/`](docs/adr/) :

| ADR | Sujet |
|-----|-------|
| [ADR-001](docs/adr/ADR-001-microservices-architecture.md) | Architecture microservices |
| [ADR-002](docs/adr/ADR-002-kafka-async-communication.md) | Communication asynchrone via Kafka |
| [ADR-003](docs/adr/ADR-003-jwt-gateway-auth.md) | Authentification JWT centralisée |
| [ADR-004](docs/adr/ADR-004-redis-feed-fanout.md) | Fan-out sur Redis pour le feed |
| [ADR-005](docs/adr/ADR-005-flutter-riverpod.md) | Flutter avec Riverpod |

---

## 🧪 Tests (à venir)

- **Backend** : JUnit 5 + Testcontainers (PostgreSQL, Kafka, Redis)
- **Frontend** : Widget tests + integration tests avec `flutter_test`
- **E2E** : Scénarios Postman / Newman via le gateway

---

## 📜 Licence

Projet universitaire — tous droits réservés.

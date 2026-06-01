# YouScout MVP — Complete Technical Specification for AI-Assisted Development

> **Purpose:** This document is the authoritative context for an AI coding agent tasked with building the YouScout MVP. Read every section before writing a single line of code. Every decision here is deliberate and architecturally grounded.

---

## 1. System Overview

**YouScout** is a football-talent discovery social network. Think TikTok, but exclusively for football skill videos. Users post vertical short-form football videos, other users discover them, likes/comments create engagement, and scouts can discover talent.

**MVP Scope — what MUST work end-to-end:**
1. Register and log in (email/password + Google OAuth stub)
2. Upload a video with description, skills, and hashtags
3. See a personalized vertical video feed
4. Like a video
5. Comment on a video
6. Follow / unfollow a user
7. View a user profile with their videos
8. View notifications (new follower, new like, new comment)

**Out of MVP scope (do not build):**
- Real-time chat (chat-service is scaffolded but empty)
- Admin back-office (stub only)
- Video transcoding (store raw upload)
- Discover/search by hashtag (scaffold the endpoint, no UI)

---

## 2. Architecture Summary

- **Style:** Microservices + Event-Driven (Kafka for async operations)
- **API Gateway:** Spring Cloud Gateway — single entry point for all mobile traffic
- **Service Discovery:** Netflix Eureka
- **Auth:** JWT (RS256) issued by user-service, validated at API Gateway
- **Async:** Apache Kafka topics for feed updates and notifications
- **CDN:** Cloudflare in front of MinIO (for video serving)
- **Observability:** Zipkin (distributed tracing) + Spring Actuator metrics

---

## 3. Technology Stack

| Layer | Technology | Version |
|---|---|---|
| Backend language | Java | 21 (LTS) |
| Backend framework | Spring Boot | 3.3.x |
| Build tool | Maven | 3.9.x |
| API Gateway | Spring Cloud Gateway | 2023.x |
| Service discovery | Netflix Eureka | Spring Cloud 2023.x |
| Message broker | Apache Kafka | 3.7.x |
| Relational DB | PostgreSQL | 16 |
| Cache / Feed store | Redis | 7.2 |
| Document DB | MongoDB | 7.0 |
| Object storage | MinIO | latest |
| Containerization | Docker + Docker Compose | Compose v2 |
| Mobile framework | Flutter | 3.22.x (stable) |
| State management | Riverpod | 2.5.x |
| HTTP client | Dio | 5.4.x |
| Mobile navigation | GoRouter | 13.x |

---

## 4. Repository Structure

```
youscout/
├── services/
│   ├── eureka-server/
│   ├── api-gateway/
│   ├── user-service/
│   ├── video-service/
│   ├── feed-service/
│   ├── comment-service/
│   ├── social-service/
│   ├── notification-service/
│   └── admin-service/          ← stub only for MVP
├── frontend/
│   └── youscout_app/           ← Flutter project
├── infrastructure/
│   ├── docker-compose.yml
│   ├── docker-compose.override.yml   ← dev overrides
│   └── kafka/
│       └── topics-init.sh
├── docs/
│   ├── adr/                    ← ADR-001 through ADR-014
│   └── architecture/
│       └── context-map.png
└── README.md
```

---

## 5. Service Specifications

### 5.1 Eureka Server

**Port:** 8761
**Dependencies:** `spring-cloud-starter-netflix-eureka-server`

```yaml
# application.yml
server:
  port: 8761
spring:
  application:
    name: eureka-server
eureka:
  client:
    register-with-eureka: false
    fetch-registry: false
  server:
    wait-time-in-ms-when-sync-empty: 0
```

```java
// EurekaServerApplication.java
@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
    }
}
```

---

### 5.2 API Gateway

**Port:** 8080
**Dependencies:** `spring-cloud-starter-gateway`, `spring-cloud-starter-netflix-eureka-client`, `jjwt-api`, `jjwt-impl`

**Routing rules:**
| Path | Routes to | Strip prefix |
|---|---|---|
| `/api/users/**` | `lb://user-service` | yes (1 segment) |
| `/api/videos/**` | `lb://video-service` | yes |
| `/api/feed/**` | `lb://feed-service` | yes |
| `/api/comments/**` | `lb://comment-service` | yes |
| `/api/social/**` | `lb://social-service` | yes |
| `/api/notifications/**` | `lb://notification-service` | yes |

**Public endpoints (no JWT required):**
- `POST /api/users/register`
- `POST /api/users/login`
- `GET /api/videos/{id}` (public viewing)
- `GET /api/feed/explore`

**JWT filter implementation:**
```java
@Component
public class JwtAuthFilter implements GlobalFilter, Ordered {
    private static final List<String> PUBLIC_PATHS = List.of(
        "/api/users/register", "/api/users/login",
        "/api/videos/", "/api/feed/explore"
    );

    @Value("${jwt.public-key}")
    private String publicKeyStr;

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getPath().value();
        boolean isPublic = PUBLIC_PATHS.stream().anyMatch(path::startsWith);
        if (isPublic) return chain.filter(exchange);

        String authHeader = exchange.getRequest().getHeaders().getFirst("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }

        try {
            String token = authHeader.substring(7);
            Claims claims = Jwts.parserBuilder()
                .setSigningKey(getPublicKey(publicKeyStr))
                .build()
                .parseClaimsJws(token)
                .getBody();

            ServerHttpRequest mutatedRequest = exchange.getRequest().mutate()
                .header("X-User-Id", claims.getSubject())
                .header("X-User-Email", claims.get("email", String.class))
                .header("X-User-Role", claims.get("role", String.class))
                .build();

            return chain.filter(exchange.mutate().request(mutatedRequest).build());
        } catch (Exception e) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
    }

    @Override
    public int getOrder() { return -1; }
}
```

---

### 5.3 user-service

**Port:** 8081
**Database:** PostgreSQL — `youscout_users`
**Dependencies:** `spring-boot-starter-web`, `spring-boot-starter-data-jpa`, `spring-boot-starter-security`, `postgresql`, `jjwt-api`, `jjwt-impl`, `jjwt-jackson`, `spring-cloud-starter-netflix-eureka-client`, `flyway-core`

#### Database Schema (Flyway migration V1)
```sql
-- V1__init_users.sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    display_name VARCHAR(100) NOT NULL,
    bio TEXT DEFAULT '',
    avatar_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    oauth_provider VARCHAR(20),         -- GOOGLE, FACEBOOK, LOCAL
    oauth_provider_id VARCHAR(255),
    follower_count INT DEFAULT 0,
    following_count INT DEFAULT 0,
    video_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
```

#### REST API Endpoints
```
POST   /register              → RegisterRequest → AuthResponse (jwt + refreshToken + UserDTO)
POST   /login                 → LoginRequest    → AuthResponse
POST   /refresh               → {refreshToken}  → AuthResponse
POST   /logout                → (auth required) → 200 OK

GET    /profile               → (auth) → UserDTO (own profile)
GET    /{id}                  → UserDTO (any profile, public)
PUT    /profile               → UpdateProfileRequest → UserDTO (auth required)
DELETE /account               → (auth) → 204 No Content (triggers saga)

GET    /{id}/stats            → { followerCount, followingCount, videoCount }
```

#### Key DTOs
```java
public record RegisterRequest(
    @NotBlank String username,
    @Email String email,
    @Size(min = 8) String password,
    @NotBlank String displayName
) {}

public record LoginRequest(
    @Email String email,
    @NotBlank String password
) {}

public record AuthResponse(
    String accessToken,
    String refreshToken,
    long expiresIn,
    UserDTO user
) {}

public record UserDTO(
    String id,
    String username,
    String displayName,
    String bio,
    String avatarUrl,
    int followerCount,
    int followingCount,
    int videoCount,
    boolean isFollowedByCurrentUser
) {}
```

#### JWT Configuration
```java
@Service
public class JwtService {
    // RS256 — asymmetric signing
    // Private key stays in user-service
    // Public key shared to API gateway via config server

    private final RSAPrivateKey privateKey;
    private final RSAPublicKey publicKey;

    public String generateAccessToken(User user) {
        return Jwts.builder()
            .subject(user.getId().toString())
            .claim("email", user.getEmail())
            .claim("role", "USER")
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + 3600_000)) // 1 hour
            .signWith(privateKey)
            .compact();
    }
}
```

---

### 5.4 video-service

**Port:** 8082
**Databases:** PostgreSQL (`youscout_videos`) + MinIO
**Dependencies:** spring-boot-starter-web, jpa, postgresql, spring-kafka, minio SDK, eureka-client, flyway

#### Database Schema
```sql
-- V1__init_videos.sql
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    user_username VARCHAR(50) NOT NULL,   -- denormalized for feed performance
    user_display_name VARCHAR(100) NOT NULL,
    user_avatar_url VARCHAR(500),
    title VARCHAR(255),
    description TEXT,
    minio_key VARCHAR(500) NOT NULL,       -- path in MinIO bucket
    video_url VARCHAR(1000) NOT NULL,      -- CDN URL
    thumbnail_url VARCHAR(1000),
    duration_seconds INTEGER,
    views_count BIGINT DEFAULT 0,
    likes_count BIGINT DEFAULT 0,
    comments_count BIGINT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    icon_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE video_skills (
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    skill_id UUID REFERENCES skills(id),
    PRIMARY KEY (video_id, skill_id)
);

CREATE TABLE hashtags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    video_count INT DEFAULT 0
);

CREATE TABLE video_hashtags (
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    hashtag_id UUID REFERENCES hashtags(id),
    PRIMARY KEY (video_id, hashtag_id)
);

CREATE TABLE video_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID REFERENCES videos(id),
    reporter_user_id UUID NOT NULL,
    reason VARCHAR(500) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed default skills
INSERT INTO skills (name, icon_name) VALUES
    ('Dribbling', 'sports_soccer'),
    ('Shooting', 'target'),
    ('Passing', 'swap_horiz'),
    ('Defending', 'shield'),
    ('Freestyle', 'star'),
    ('Speed', 'flash_on'),
    ('Heading', 'sports_soccer'),
    ('First Touch', 'touch_app');

CREATE INDEX idx_videos_user_id ON videos(user_id);
CREATE INDEX idx_videos_created_at ON videos(created_at DESC);
```

#### REST API Endpoints
```
POST   /                   multipart/form-data → VideoDTO   (auth)
  Fields: file (video), description, skillIds (JSON array), hashtags (comma-separated)

GET    /{id}               → VideoDTO (public)
GET    /user/{userId}      → Page<VideoDTO>    (public)
DELETE /{id}               → 204 No Content    (auth, must be owner)

POST   /{id}/like          → { likesCount: int } (auth)
DELETE /{id}/like          → { likesCount: int } (auth)
POST   /{id}/report        → { reason: string }  (auth)
POST   /{id}/view          → 200 OK             (anonymous)

GET    /skills             → List<SkillDTO>     (public, for upload screen)
GET    /trending           → Page<VideoDTO>     (public, sorted by views_count)
```

#### Kafka Events Published
```java
// video-service publishes when a video is successfully saved:
public record VideoPublishedEvent(
    String videoId,
    String userId,
    String username,
    String displayName,
    String avatarUrl,
    String videoUrl,
    String thumbnailUrl,
    String description,
    long timestamp
) {}

// Topic: youscout.video.published
// Partition key: userId (ensures ordering per user)
```

#### MinIO Upload Logic
```java
@Service
public class VideoStorageService {
    private final MinioClient minioClient;

    public String uploadVideo(MultipartFile file, String videoId) throws Exception {
        String key = "videos/" + videoId + "/original" + getExtension(file);
        minioClient.putObject(
            PutObjectArgs.builder()
                .bucket("youscout-videos")
                .object(key)
                .stream(file.getInputStream(), file.getSize(), -1)
                .contentType(file.getContentType())
                .build()
        );
        return "https://cdn.youscout.local/" + key; // CDN URL
    }
}
```

---

### 5.5 feed-service

**Port:** 8083
**Database:** Redis
**Dependencies:** spring-boot-starter-web, spring-boot-starter-data-redis, spring-kafka, eureka-client

#### Feed Architecture (CQRS Read Model)
- Redis ZSET key: `feed:{userId}` — members are videoIds, scores are Unix timestamps
- Redis HASH key: `video:meta:{videoId}` — cached video metadata (url, user, description)
- Max feed depth: 500 entries per user (trim on write)
- TTL: 7 days

#### Kafka Consumers
```java
@Component
public class FeedKafkaConsumer {

    @KafkaListener(topics = "youscout.video.published", groupId = "feed-service")
    public void onVideoPublished(VideoPublishedEvent event) {
        // 1. Get the author's follower list from user-service (cached in Redis)
        List<String> followerIds = getFollowerIds(event.getUserId());
        // 2. Add video to each follower's feed ZSET
        followerIds.forEach(followerId -> {
            redisTemplate.opsForZSet().add(
                "feed:" + followerId,
                event.getVideoId(),
                event.getTimestamp()
            );
            // Trim to max 500
            redisTemplate.opsForZSet().removeRange("feed:" + followerId, 0, -501);
        });
        // 3. Cache video metadata
        cacheVideoMeta(event);
    }

    @KafkaListener(topics = "youscout.user.followed", groupId = "feed-service")
    public void onUserFollowed(UserFollowedEvent event) {
        // Backfill: add the new following's last 20 videos to the follower's feed
        List<VideoSummary> recentVideos = getRecentVideos(event.getFollowingId(), 20);
        recentVideos.forEach(video ->
            redisTemplate.opsForZSet().add(
                "feed:" + event.getFollowerId(),
                video.getId(),
                video.getTimestamp()
            )
        );
    }
}
```

#### REST API
```
GET /                 → Page<VideoDTO>   (auth required)
  Params: page (default 0), size (default 10)
  Returns: paginated feed items, newest first

GET /explore          → Page<VideoDTO>   (public, no auth)
  Returns: trending videos for non-logged-in users
```

---

### 5.6 comment-service

**Port:** 8084
**Database:** PostgreSQL (`youscout_comments`)

#### Database Schema
```sql
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID NOT NULL,
    user_id UUID NOT NULL,
    user_username VARCHAR(50) NOT NULL,
    user_display_name VARCHAR(100) NOT NULL,
    user_avatar_url VARCHAR(500),
    content TEXT NOT NULL,
    parent_id UUID REFERENCES comments(id),   -- NULL = top-level, non-null = reply
    likes_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_comments_video_id ON comments(video_id, created_at DESC);
CREATE INDEX idx_comments_parent_id ON comments(parent_id);
```

#### REST API
```
POST   /                 → { videoId, content, parentId? } → CommentDTO   (auth)
GET    /video/{videoId}  → Page<CommentDTO>                               (public)
DELETE /{id}             → 204 No Content                                 (auth, owner)
POST   /{id}/report      → { reason }                                     (auth)
```

#### Kafka Events Published
```java
// Topic: youscout.comment.created
public record CommentCreatedEvent(
    String commentId,
    String videoId,
    String videoOwnerId,   // who to notify
    String commenterId,
    String commenterUsername,
    String commentPreview, // first 100 chars
    long timestamp
) {}
```

---

### 5.7 social-service

**Port:** 8085
**Database:** PostgreSQL (`youscout_social`)

#### Database Schema
```sql
CREATE TABLE follows (
    follower_id UUID NOT NULL,
    following_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id)
);

CREATE TABLE blocks (
    blocker_id UUID NOT NULL,
    blocked_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id)
);

CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);
```

#### REST API
```
POST   /follow/{targetUserId}    → { isFollowing: true }     (auth)
DELETE /follow/{targetUserId}    → { isFollowing: false }     (auth)
POST   /block/{targetUserId}     → 200 OK                     (auth)
DELETE /block/{targetUserId}     → 200 OK                     (auth)

GET    /{userId}/followers       → Page<UserDTO>              (public)
GET    /{userId}/following       → Page<UserDTO>              (public)
GET    /is-following/{targetId}  → { isFollowing: bool }      (auth)
GET    /followers/{userId}       → List<String> (IDs only)    (internal)
```

#### Kafka Events Published
```java
// Topic: youscout.user.followed
public record UserFollowedEvent(
    String followerId,
    String followingId,
    String followerUsername,
    long timestamp
) {}
```

After follow/unfollow, make a REST call to user-service to update follower/following counts.

---

### 5.8 notification-service

**Port:** 8086
**Database:** PostgreSQL (`youscout_notifications`)
**Role:** Kafka consumer only — no REST API called by other services

#### Database Schema
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL,   -- NEW_FOLLOWER, VIDEO_LIKED, NEW_COMMENT
    actor_id UUID NOT NULL,
    actor_username VARCHAR(50) NOT NULL,
    actor_avatar_url VARCHAR(500),
    reference_id UUID,            -- videoId or commentId
    reference_preview VARCHAR(200),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_id, created_at DESC);
```

#### REST API (for mobile to fetch notifications)
```
GET    /            → Page<NotificationDTO>   (auth)
POST   /mark-read   → { ids: [uuid] }         (auth)
POST   /mark-all-read                          (auth)
GET    /unread-count → { count: int }          (auth)
```

#### Kafka Consumers
```java
@KafkaListener(topics = "youscout.user.followed")
public void onUserFollowed(UserFollowedEvent e) {
    createNotification(e.getFollowingId(), "NEW_FOLLOWER", e.getFollowerId(), e.getFollowerUsername(), null, null);
}

@KafkaListener(topics = "youscout.video.liked")
public void onVideoLiked(VideoLikedEvent e) {
    createNotification(e.getVideoOwnerId(), "VIDEO_LIKED", e.getLikerId(), e.getLikerUsername(), e.getVideoId(), e.getVideoThumbnail());
}

@KafkaListener(topics = "youscout.comment.created")
public void onCommentCreated(CommentCreatedEvent e) {
    createNotification(e.getVideoOwnerId(), "NEW_COMMENT", e.getCommenterId(), e.getCommenterUsername(), e.getVideoId(), e.getCommentPreview());
}
```

---

## 6. Kafka Configuration

### Topics Definition
```bash
# infrastructure/kafka/topics-init.sh
kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.video.published --partitions 3 --replication-factor 1
kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.comment.created --partitions 3 --replication-factor 1
kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.video.liked     --partitions 3 --replication-factor 1
kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.user.followed   --partitions 3 --replication-factor 1
kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.video.reported  --partitions 1 --replication-factor 1

# Dead Letter Topics
kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.video.published.DLT --partitions 1 --replication-factor 1
kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.comment.created.DLT --partitions 1 --replication-factor 1
```

### Spring Kafka Producer Config (all services)
```yaml
spring:
  kafka:
    bootstrap-servers: kafka:9092
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      properties:
        spring.json.add.type.headers: false
    consumer:
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        spring.json.trusted.packages: "com.youscout.*"
```

---

## 7. Docker Compose

```yaml
# infrastructure/docker-compose.yml
version: '3.9'

networks:
  youscout-network:
    driver: bridge

volumes:
  postgres-users-data:
  postgres-videos-data:
  postgres-comments-data:
  postgres-social-data:
  postgres-notifications-data:
  redis-data:
  minio-data:
  mongodb-data:
  kafka-data:

services:

  # ─── INFRASTRUCTURE ───────────────────────────────────────

  postgres-users:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: youscout_users
      POSTGRES_USER: youscout
      POSTGRES_PASSWORD: youscout_secret
    volumes:
      - postgres-users-data:/var/lib/postgresql/data
    networks: [youscout-network]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U youscout -d youscout_users"]
      interval: 10s
      retries: 5

  postgres-videos:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: youscout_videos
      POSTGRES_USER: youscout
      POSTGRES_PASSWORD: youscout_secret
    volumes:
      - postgres-videos-data:/var/lib/postgresql/data
    networks: [youscout-network]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U youscout -d youscout_videos"]
      interval: 10s
      retries: 5

  postgres-comments:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: youscout_comments
      POSTGRES_USER: youscout
      POSTGRES_PASSWORD: youscout_secret
    volumes:
      - postgres-comments-data:/var/lib/postgresql/data
    networks: [youscout-network]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U youscout -d youscout_comments"]
      interval: 10s
      retries: 5

  postgres-social:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: youscout_social
      POSTGRES_USER: youscout
      POSTGRES_PASSWORD: youscout_secret
    volumes:
      - postgres-social-data:/var/lib/postgresql/data
    networks: [youscout-network]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U youscout -d youscout_social"]
      interval: 10s
      retries: 5

  postgres-notifications:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: youscout_notifications
      POSTGRES_USER: youscout
      POSTGRES_PASSWORD: youscout_secret
    volumes:
      - postgres-notifications-data:/var/lib/postgresql/data
    networks: [youscout-network]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U youscout -d youscout_notifications"]
      interval: 10s
      retries: 5

  redis:
    image: redis:7.2-alpine
    command: redis-server --appendonly yes --maxmemory 512mb --maxmemory-policy allkeys-lru
    volumes:
      - redis-data:/data
    networks: [youscout-network]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s

  mongodb:
    image: mongo:7.0
    environment:
      MONGO_INITDB_ROOT_USERNAME: youscout
      MONGO_INITDB_ROOT_PASSWORD: youscout_secret
      MONGO_INITDB_DATABASE: youscout_chat
    volumes:
      - mongodb-data:/data/db
    networks: [youscout-network]

  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: youscout_minio
      MINIO_ROOT_PASSWORD: youscout_minio_secret
    volumes:
      - minio-data:/data
    ports:
      - "9000:9000"
      - "9001:9001"
    networks: [youscout-network]
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 10s

  zookeeper:
    image: confluentinc/cp-zookeeper:7.6.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    networks: [youscout-network]

  kafka:
    image: confluentinc/cp-kafka:7.6.0
    depends_on: [zookeeper]
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "false"
    volumes:
      - kafka-data:/var/lib/kafka/data
    networks: [youscout-network]
    healthcheck:
      test: ["CMD", "kafka-topics.sh", "--bootstrap-server", "localhost:9092", "--list"]
      interval: 15s
      retries: 5

  kafka-init:
    image: confluentinc/cp-kafka:7.6.0
    depends_on:
      kafka:
        condition: service_healthy
    command: >
      bash -c "
      kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.video.published --partitions 3 --replication-factor 1 --if-not-exists &&
      kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.comment.created --partitions 3 --replication-factor 1 --if-not-exists &&
      kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.video.liked     --partitions 3 --replication-factor 1 --if-not-exists &&
      kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.user.followed   --partitions 3 --replication-factor 1 --if-not-exists &&
      kafka-topics.sh --create --bootstrap-server kafka:9092 --topic youscout.video.reported  --partitions 1 --replication-factor 1 --if-not-exists &&
      echo 'Topics created successfully'
      "
    networks: [youscout-network]

  zipkin:
    image: openzipkin/zipkin:latest
    ports:
      - "9411:9411"
    networks: [youscout-network]

  # ─── APPLICATION SERVICES ─────────────────────────────────

  eureka-server:
    build: ../services/eureka-server
    ports:
      - "8761:8761"
    networks: [youscout-network]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8761/actuator/health"]
      interval: 15s
      retries: 5

  api-gateway:
    build: ../services/api-gateway
    ports:
      - "8080:8080"
    environment:
      EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://eureka-server:8761/eureka
      JWT_PUBLIC_KEY: ${JWT_PUBLIC_KEY}
      MANAGEMENT_ZIPKIN_TRACING_ENDPOINT: http://zipkin:9411/api/v2/spans
    depends_on:
      eureka-server:
        condition: service_healthy
    networks: [youscout-network]

  user-service:
    build: ../services/user-service
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-users:5432/youscout_users
      SPRING_DATASOURCE_USERNAME: youscout
      SPRING_DATASOURCE_PASSWORD: youscout_secret
      EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://eureka-server:8761/eureka
      JWT_PRIVATE_KEY: ${JWT_PRIVATE_KEY}
      JWT_PUBLIC_KEY: ${JWT_PUBLIC_KEY}
      MANAGEMENT_ZIPKIN_TRACING_ENDPOINT: http://zipkin:9411/api/v2/spans
    depends_on:
      postgres-users:
        condition: service_healthy
      eureka-server:
        condition: service_healthy
    networks: [youscout-network]

  video-service:
    build: ../services/video-service
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-videos:5432/youscout_videos
      SPRING_DATASOURCE_USERNAME: youscout
      SPRING_DATASOURCE_PASSWORD: youscout_secret
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092
      MINIO_ENDPOINT: http://minio:9000
      MINIO_ACCESS_KEY: youscout_minio
      MINIO_SECRET_KEY: youscout_minio_secret
      MINIO_BUCKET: youscout-videos
      EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://eureka-server:8761/eureka
      MANAGEMENT_ZIPKIN_TRACING_ENDPOINT: http://zipkin:9411/api/v2/spans
    depends_on:
      postgres-videos:
        condition: service_healthy
      kafka:
        condition: service_healthy
      minio:
        condition: service_healthy
      eureka-server:
        condition: service_healthy
    networks: [youscout-network]

  feed-service:
    build: ../services/feed-service
    environment:
      SPRING_DATA_REDIS_HOST: redis
      SPRING_DATA_REDIS_PORT: 6379
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092
      USER_SERVICE_URL: http://user-service:8081
      VIDEO_SERVICE_URL: http://video-service:8082
      EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://eureka-server:8761/eureka
      MANAGEMENT_ZIPKIN_TRACING_ENDPOINT: http://zipkin:9411/api/v2/spans
    depends_on:
      redis:
        condition: service_healthy
      kafka:
        condition: service_healthy
      eureka-server:
        condition: service_healthy
    networks: [youscout-network]

  comment-service:
    build: ../services/comment-service
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-comments:5432/youscout_comments
      SPRING_DATASOURCE_USERNAME: youscout
      SPRING_DATASOURCE_PASSWORD: youscout_secret
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092
      EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://eureka-server:8761/eureka
      MANAGEMENT_ZIPKIN_TRACING_ENDPOINT: http://zipkin:9411/api/v2/spans
    depends_on:
      postgres-comments:
        condition: service_healthy
      kafka:
        condition: service_healthy
      eureka-server:
        condition: service_healthy
    networks: [youscout-network]

  social-service:
    build: ../services/social-service
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-social:5432/youscout_social
      SPRING_DATASOURCE_USERNAME: youscout
      SPRING_DATASOURCE_PASSWORD: youscout_secret
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092
      USER_SERVICE_URL: http://user-service:8081
      EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://eureka-server:8761/eureka
      MANAGEMENT_ZIPKIN_TRACING_ENDPOINT: http://zipkin:9411/api/v2/spans
    depends_on:
      postgres-social:
        condition: service_healthy
      kafka:
        condition: service_healthy
      eureka-server:
        condition: service_healthy
    networks: [youscout-network]

  notification-service:
    build: ../services/notification-service
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-notifications:5432/youscout_notifications
      SPRING_DATASOURCE_USERNAME: youscout
      SPRING_DATASOURCE_PASSWORD: youscout_secret
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092
      EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://eureka-server:8761/eureka
      MANAGEMENT_ZIPKIN_TRACING_ENDPOINT: http://zipkin:9411/api/v2/spans
    depends_on:
      postgres-notifications:
        condition: service_healthy
      kafka:
        condition: service_healthy
      eureka-server:
        condition: service_healthy
    networks: [youscout-network]
```

---

## 8. Flutter Application

### 8.1 Design System

**Design language:** Minimal, high-contrast dark theme — think Apple Fitness meets TikTok. Premium, functional, no clutter.

#### Color Palette
```dart
// lib/core/theme/app_colors.dart
class AppColors {
  // Backgrounds
  static const Color background       = Color(0xFF09090B);   // near-black
  static const Color surfaceCard      = Color(0xFF141416);   // dark card
  static const Color surfaceElevated  = Color(0xFF1C1C1F);   // elevated surface
  static const Color surfaceOverlay   = Color(0xFF232328);   // modal/sheet bg

  // Brand
  static const Color primary          = Color(0xFF00D4FF);   // electric cyan
  static const Color primaryGlow      = Color(0x3300D4FF);   // glow effect
  static const Color secondary        = Color(0xFF7B61FF);   // soft purple (skills)

  // Accent
  static const Color like             = Color(0xFFFF3B5C);   // Instagram-red
  static const Color gold             = Color(0xFFFFD60A);   // ratings, gold
  static const Color success          = Color(0xFF30D158);   // confirm green

  // Text
  static const Color textPrimary      = Color(0xFFF5F5F7);   // almost-white
  static const Color textSecondary    = Color(0xFF8E8E93);   // muted gray
  static const Color textTertiary     = Color(0xFF48484A);   // very muted

  // Borders
  static const Color borderSubtle     = Color(0xFF2C2C2E);
  static const Color borderDefault    = Color(0xFF3A3A3C);
}
```

#### Typography
```dart
// lib/core/theme/app_typography.dart
class AppTypography {
  static const String fontFamily = '.SF Pro Display'; // fallback: 'Inter'

  static const TextStyle displayLarge   = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1.0, color: AppColors.textPrimary);
  static const TextStyle displayMedium  = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: AppColors.textPrimary);
  static const TextStyle titleLarge     = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle titleMedium    = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle bodyLarge      = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const TextStyle bodyMedium     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const TextStyle labelLarge     = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static const TextStyle caption        = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textTertiary);
}
```

#### Theme Configuration
```dart
// lib/core/theme/app_theme.dart
ThemeData get darkTheme => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surfaceCard,
    background: AppColors.background,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surfaceCard,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textTertiary,
    type: BottomNavigationBarType.fixed,
  ),
);
```

---

### 8.2 Project Structure
```
lib/
├── main.dart
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_theme.dart
│   ├── network/
│   │   ├── api_client.dart           ← Dio instance with interceptors
│   │   ├── auth_interceptor.dart     ← Injects JWT, handles 401
│   │   └── api_endpoints.dart        ← All endpoint constants
│   ├── storage/
│   │   └── secure_storage.dart       ← flutter_secure_storage wrapper
│   ├── router/
│   │   └── app_router.dart           ← GoRouter definition
│   └── providers/
│       └── providers.dart            ← Global Riverpod providers
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── models/
│   │   │       ├── user_model.dart
│   │   │       └── auth_response.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── splash_screen.dart
│   │   │   │   ├── onboarding_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── providers/
│   │   │       └── auth_provider.dart
│   ├── feed/
│   │   ├── data/
│   │   │   ├── feed_repository.dart
│   │   │   └── models/
│   │   │       └── video_model.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── home_screen.dart        ← Main feed (vertical pager)
│   │   │   │   └── video_player_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── video_item.dart         ← Full-screen video card
│   │   │   │   ├── side_actions.dart       ← Like/comment/share buttons
│   │   │   │   ├── video_info_panel.dart   ← Username, description, hashtags
│   │   │   │   └── skill_chip.dart         ← Skill tag badge
│   │   │   └── providers/
│   │   │       └── feed_provider.dart
│   ├── upload/
│   │   ├── data/
│   │   │   └── upload_repository.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── upload_screen.dart
│   │   │   └── providers/
│   │   │       └── upload_provider.dart
│   ├── profile/
│   │   ├── data/
│   │   │   └── profile_repository.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── profile_screen.dart
│   │   │   └── providers/
│   │   │       └── profile_provider.dart
│   ├── notifications/
│   │   ├── data/
│   │   │   └── notification_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── notifications_screen.dart
│   │       └── providers/
│   │           └── notification_provider.dart
│   └── discover/
│       └── presentation/
│           └── screens/
│               └── discover_screen.dart    ← stub for MVP
└── shared/
    └── widgets/
        ├── ys_button.dart              ← YouScout primary button
        ├── ys_text_field.dart          ← Styled input field
        ├── ys_avatar.dart              ← User avatar with online indicator
        ├── ys_shimmer.dart             ← Loading skeleton
        └── bottom_nav_bar.dart         ← Custom bottom navigation
```

---

### 8.3 Navigation (GoRouter)
```dart
// lib/core/router/app_router.dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/splash';
      if (isSplash) return null;
      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: '/upload', builder: (_, __) => const UploadScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(
            path: '/profile/:userId',
            builder: (context, state) => ProfileScreen(userId: state.pathParameters['userId']!),
          ),
        ],
      ),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
    ],
  );
});
```

---

### 8.4 Screen Specifications

#### SplashScreen
- Full-screen dark background (#09090B)
- Centered YouScout logo (animated: fade in + scale up 0.8 → 1.0, 600ms)
- Below logo: thin electric cyan progress line animating horizontally
- On complete: check for stored JWT, redirect accordingly
- No back button possible

#### OnboardingScreen
- 3 pages, swipeable with PageView
- Each page: full-screen gradient background + large emoji icon + title + subtitle
- Page 1: "Show the world your game" — cyan gradient
- Page 2: "Get discovered by scouts" — purple gradient
- Page 3: "Join millions of football fans" — dark with star particles
- Bottom: dot indicators + "Get Started" button (full-width, cyan, rounded-full)

#### LoginScreen
```
Layout (full-screen, scrollable):
- Top 30%: gradient background with football pitch line motif (subtle)
- Logo + "YouScout" wordmark (white, 28px bold)
- White card (surfaceCard) from 40% down, with top-radius 32px
  - "Welcome back" (24px bold)
  - Email field (ys_text_field)
  - Password field (ys_text_field, obscure, show/hide toggle)
  - "Sign In" button (full-width, cyan gradient, 52px tall, rounded 12px)
  - OR divider
  - Google Sign In button (outline, white icon + text)
  - "Don't have an account? Register" (link at bottom)
```

#### RegisterScreen
- Same card structure as Login
- Fields: Display Name, Username, Email, Password, Confirm Password
- Real-time username availability check (debounced 500ms, calls user-service)
- Green checkmark when username is available
- "Create Account" button

#### HomeScreen (Feed — core feature)
```dart
// Full-screen vertical PageView of videos
// Each page is a full-screen VideoItem widget

class HomeScreen extends ConsumerStatefulWidget {
  // PageController with viewportFraction: 1.0
  // Feed items loaded from feed-service (paginated, load next page when 3 items from end)
  // Auto-play current video, pause adjacent videos
  // Preload next 2 videos for smooth scrolling

  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => VideoItem(video: videos[index]),
          ),
          // Top overlay: YouScout logo (left) + Explore | For You tabs (center)
          _TopBar(),
          // No bottom navigation here — the tab bar is handled by MainShell
        ],
      ),
    );
  }
}
```

#### VideoItem Widget (Full-Screen Video Card)
```
Layout: Stack
├── VideoPlayer (full screen, fit: cover, looping)
├── Gradient overlay (bottom 40%: transparent → black 70%)
├── VideoInfoPanel (bottom-left)
│   ├── @username (white, 16px bold, tappable → profile)
│   ├── Description (white, 14px, max 3 lines with "more")
│   ├── Horizontal scroll of SkillChips (cyan outline, 12px)
│   └── #hashtags (cyan, 14px)
├── SideActions (right side, 72px from right)
│   ├── AvatarWithFollow (44px circle + + button overlay)
│   ├── LikeButton (heart icon, count below, animated)
│   ├── CommentButton (bubble icon, count below)
│   └── ShareButton (arrow icon)
└── MusicBar (bottom, DJ icon + scrolling text — optional)
```

#### LikeButton Animation
```dart
class LikeButton extends StatefulWidget {
  // On tap:
  // 1. Immediate optimistic update (flip liked state, update count)
  // 2. Scale animation: 1.0 → 1.4 → 1.0 (150ms spring)
  // 3. Floating hearts animation (3 hearts float upward and fade)
  // 4. API call in background
  // 5. On error: revert optimistic update
}
```

#### Comments Bottom Sheet
```dart
// Opens as a draggable bottom sheet covering 75% of screen
// Top: "Comments" title + X close + comment count
// Body: ListView of CommentCard widgets
//   Each CommentCard: avatar + username + content + time + like count
//   Reply indentation (16px left padding) for replies
// Bottom: Sticky comment input bar
//   Avatar + TextField + Send button (cyan)
// Keyboard-aware: adjusts when keyboard opens
```

#### UploadScreen
```
Layout (full-screen, dark):
Step 1 — Pick Video:
  - Large dotted border area in center
  - Camera icon + "Tap to select video" 
  - OR "Record with camera" button below
  - Uses image_picker package

Step 2 — Preview + Details (after selection):
  - Thumbnail preview (left, 1/3 width)
  - Right 2/3:
    - Description TextField (multiline, hint: "Describe your skills...")
    - SkillPicker: horizontal scroll of skill chips, tap to toggle (cyan when selected)
    - HashtagField: chips input for hashtags
  - "Share" button (full-width cyan, bottom)
  - Upload progress bar (linear, cyan) when uploading

Step 3 — Success:
  - Checkmark animation (Lottie or custom)
  - "Your video is live!" 
  - "Go to feed" button
```

#### ProfileScreen
```
Layout:
Header (200px tall):
  - Gradient background (user's primary color based on first letter)
  - Avatar (80px circle, centered, elevated with shadow)
  - Display name (20px bold, white)
  - @username (14px, textSecondary)
  - Bio (14px, textSecondary, max 2 lines)
  - Stats row: Videos | Followers | Following (tappable)
  - Follow button (if not own profile): 
    - Not following: filled cyan "Follow"
    - Following: outline "Following"

Content:
  - GridView of video thumbnails (3 columns, 2px gap)
  - Each thumbnail: 16:9 aspect ratio image with play icon overlay
  - Tap → opens VideoPlayerScreen

Own profile:
  - Settings gear icon in header
  - Edit Profile button (outline, white)
```

#### NotificationsScreen
```
Layout:
- App bar: "Notifications" + "Mark all read" text button
- ListView of NotificationCard widgets grouped by "Today" / "This week" / "Earlier"

NotificationCard:
  - Avatar (36px) + notification text + timestamp
  - Right: thumbnail if video-related
  - Unread: subtle cyan left border (2px) + slightly lighter background
  - Types:
    - NEW_FOLLOWER: "[user] started following you"
    - VIDEO_LIKED: "[user] liked your video"
    - NEW_COMMENT: "[user] commented: [preview]"
```

---

### 8.5 API Client
```dart
// lib/core/network/api_client.dart
class ApiClient {
  static const String baseUrl = 'http://localhost:8080';  // API Gateway
  late final Dio _dio;

  ApiClient(Ref ref) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.addAll([
      AuthInterceptor(ref),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  Dio get dio => _dio;
}

// lib/core/network/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  final Ref _ref;
  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try refresh
      final refreshed = await _ref.read(authProvider.notifier).refreshToken();
      if (refreshed) {
        // Retry the original request
        final opts = err.requestOptions;
        final token = await SecureStorage.getAccessToken();
        opts.headers['Authorization'] = 'Bearer $token';
        final response = await _ref.read(apiClientProvider).dio.fetch(opts);
        handler.resolve(response);
        return;
      }
      // Refresh failed → logout
      _ref.read(authProvider.notifier).logout();
    }
    handler.next(err);
  }
}
```

---

### 8.6 Key Flutter Dependencies
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # State & Navigation
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^13.2.0

  # Network
  dio: ^5.4.3+1
  retrofit: ^4.1.0

  # Storage
  flutter_secure_storage: ^9.2.2

  # Video
  video_player: ^2.8.6
  chewie: ^1.8.1            # optional: adds controls UI on top of video_player

  # Media
  image_picker: ^1.1.2

  # UI
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  animations: ^2.0.11       # Material motion transitions
  lottie: ^3.1.0            # JSON animations for success states
  flutter_animate: ^4.5.0   # Easy widget animations

  # Utils
  timeago: ^3.6.1           # "2 minutes ago" timestamps
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  retrofit_generator: ^8.1.0
```

---

## 9. Common Spring Boot Service Template

Every service follows this structure:

```
service-name/
├── pom.xml
├── Dockerfile
└── src/main/
    ├── java/com/youscout/servicename/
    │   ├── ServiceNameApplication.java
    │   ├── config/
    │   │   ├── KafkaConfig.java        (if uses Kafka)
    │   │   ├── SecurityConfig.java     (no-op for non-user services)
    │   │   └── OpenApiConfig.java
    │   ├── controller/
    │   │   └── ServiceNameController.java
    │   ├── service/
    │   │   └── ServiceNameService.java
    │   ├── repository/
    │   │   └── ServiceNameRepository.java
    │   ├── domain/
    │   │   └── EntityName.java         (JPA @Entity)
    │   ├── dto/
    │   │   ├── RequestDTO.java
    │   │   └── ResponseDTO.java
    │   ├── event/
    │   │   ├── EventProducer.java
    │   │   ├── EventConsumer.java
    │   │   └── events/
    │   │       └── SomeEvent.java
    │   └── exception/
    │       ├── GlobalExceptionHandler.java
    │       └── NotFoundException.java
    └── resources/
        ├── application.yml
        └── db/migration/
            └── V1__init.sql
```

### Dockerfile (multi-stage)
```dockerfile
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN ./mvnw package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Base application.yml
```yaml
spring:
  application:
    name: ${SERVICE_NAME}
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate.dialect: org.hibernate.dialect.PostgreSQLDialect
  flyway:
    enabled: true
    locations: classpath:db/migration

eureka:
  client:
    service-url:
      defaultZone: ${EUREKA_CLIENT_SERVICEURL_DEFAULTZONE:http://localhost:8761/eureka}
  instance:
    prefer-ip-address: true
    lease-renewal-interval-in-seconds: 10
    lease-expiration-duration-in-seconds: 30

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  tracing:
    sampling:
      probability: 1.0       # 100% in dev, set to 0.1 in prod

resilience4j:
  circuitbreaker:
    instances:
      default:
        sliding-window-size: 10
        failure-rate-threshold: 50
        wait-duration-in-open-state: 30s
        permitted-number-of-calls-in-half-open-state: 5
  timelimiter:
    instances:
      default:
        timeout-duration: 5s
```

---

## 10. Setup & Run Guide

```bash
# 1. Clone and enter project
git clone https://github.com/yourteam/youscout
cd youscout

# 2. Generate RSA key pair for JWT
openssl genrsa -out private-key.pem 2048
openssl rsa -in private-key.pem -pubout -out public-key.pem
# Export as environment variables
export JWT_PRIVATE_KEY=$(cat private-key.pem | base64 -w 0)
export JWT_PUBLIC_KEY=$(cat public-key.pem | base64 -w 0)

# 3. Build all Spring Boot services
for service in eureka-server api-gateway user-service video-service feed-service comment-service social-service notification-service; do
  cd services/$service && ./mvnw clean package -DskipTests && cd ../..
done

# 4. Launch full stack
cd infrastructure
docker-compose up -d

# 5. Verify all services are healthy
docker-compose ps
curl http://localhost:8761  # Eureka dashboard
curl http://localhost:8080/actuator/health  # API Gateway health

# 6. Seed skills data (runs automatically via Flyway in video-service)

# 7. Run Flutter app
cd frontend/youscout_app
flutter pub get
flutter run  # or: flutter run --dart-define=API_URL=http://localhost:8080

# Useful ports:
# 8080  → API Gateway (all API calls go here)
# 8761  → Eureka Dashboard
# 9000  → MinIO API
# 9001  → MinIO Console (UI)
# 9411  → Zipkin Tracing UI
```

---

## 11. Critical Implementation Rules

1. **Every API response follows this envelope:**
```json
{
  "success": true,
  "data": { ... },
  "message": "OK",
  "timestamp": "2025-01-01T00:00:00Z"
}
```

2. **Every error response:**
```json
{
  "success": false,
  "error": "RESOURCE_NOT_FOUND",
  "message": "Video with id xyz not found",
  "timestamp": "2025-01-01T00:00:00Z"
}
```

3. **All user data propagated from JWT headers, never from request body.** The user ID for "who is doing this action" always comes from `X-User-Id` header (set by API Gateway after JWT validation), never from a field the client sends.

4. **Optimistic UI updates in Flutter.** Like, follow, comment counts update immediately in the UI. If the API call fails, revert. Never make the user wait for a server round-trip to see their action reflected.

5. **Video upload is chunked.** The Flutter client sends videos in 5MB chunks using Dio's FormData streaming. Do not load the entire video into memory.

6. **Feed pagination uses cursor-based pagination**, not offset. The cursor is the timestamp of the last item received. This avoids the "missing items on page boundary" problem caused by new items being inserted at the top.

7. **All images are served through CachedNetworkImage in Flutter.** Never use Image.network() directly. This ensures disk caching and prevents redundant network requests.

8. **The video player in the feed auto-plays when the video is visible and pauses when scrolled away.** Use a PageView visibility listener to track which video is active.

9. **Bottom sheets and dialogs use BackdropFilter blur.** Apply `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` to the background when showing modals for the premium glass-morphism effect.

10. **All text inputs have proper keyboard types.** Email fields use `TextInputType.emailAddress`, usernames use `TextInputType.text` with `textInputAction: TextInputAction.next`.

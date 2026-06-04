# ADR-009: JWT + OAuth2 Authentication Strategy

**Status:** Accepted

## Context
YouScout requires two authentication modes: native account creation with email/password, and social login via Google and Facebook (explicitly stated in the project brief). Authentication must be stateless at the service level — a centralized session store would be a scaling bottleneck at millions of users. Token validation must happen at the API Gateway level to avoid each service re-implementing auth logic.

## Decision
**JWT (JSON Web Token)** is the authentication mechanism. The flow:
1. User authenticates via email/password or OAuth2 provider (Google/Facebook) through `user-service`
2. `user-service` issues a signed JWT (RS256, 1-hour expiry) + Refresh Token (7-day expiry, stored in database)
3. The Flutter app stores the JWT in Flutter Secure Storage (Keychain on iOS, Keystore on Android)
4. Every request to the API Gateway includes `Authorization: Bearer {jwt}`
5. The API Gateway validates the JWT signature and expiry — no call to user-service required
6. Valid JWT payload is forwarded to downstream services in request headers (`X-User-Id`, `X-User-Role`)

OAuth2 integration uses the **Authorization Code Flow with PKCE** (mandatory for mobile apps per RFC 7636 to prevent authorization code interception attacks).

## Consequences
- ✅ Stateless auth at API Gateway — no central session store needed, scales infinitely
- ✅ Services receive verified user identity without auth database lookups on every request
- ✅ OAuth2 PKCE is the security standard for mobile apps
- ✅ Refresh token rotation prevents token theft exploitation
- ❌ JWT cannot be revoked before expiry — mitigated by short 1-hour expiry and token denylist for logout
- ❌ Token size adds ~200 bytes to every request — negligible

## Governance
- JWT signed with RS256 (asymmetric) — public key distributed to gateway, private key kept in user-service only
- Token denylist in Redis for logout and account suspension (checked by gateway on sensitive operations)
- Refresh tokens are single-use (rotation) — reuse of an old refresh token triggers account lockdown

# ADR-012: Flutter for Cross-Platform Mobile Frontend

**Status:** Accepted

## Context
YouScout targets both iOS and Android users. Native development (Swift for iOS + Kotlin for Android) would require double the mobile development effort and two separate teams. The project brief specifies a cross-platform approach. Candidates evaluated: Flutter (Dart), React Native (JavaScript), Ionic (Web).

## Decision
**Flutter** is selected as the mobile framework. Justification over alternatives:
- **vs. React Native**: Flutter compiles to native ARM code via the Dart compiler; React Native uses a JavaScript bridge (eliminated in New Architecture, but still less performant). Flutter achieves 60/120fps consistently. Critical for the full-screen video feed experience.
- **vs. Ionic**: Ionic renders a WebView — unacceptable for a video-first application where UI performance is paramount.
- **Flutter advantages**: Single codebase for iOS + Android, Skia/Impeller rendering engine (pixel-perfect on both platforms), excellent video player packages, and a large component ecosystem.

Key packages: `video_player`, `dio`, `flutter_secure_storage`, `riverpod`, `image_picker`, `cached_network_image`, `shimmer`, `animations`.

## Consequences
- ✅ Single codebase for iOS and Android
- ✅ Native performance — 60fps video feed scrolling
- ✅ Consistent UI across platforms
- ✅ Hot reload for rapid development
- ❌ Dart learning curve for developers unfamiliar with it
- ❌ Larger app binary size than purely native apps

## Governance
- State management: **Riverpod** (compile-safe, scalable, testable)
- Navigation: **GoRouter** (type-safe, supports deep linking)
- HTTP client: **Dio** with auth interceptor for automatic JWT injection
- All sensitive data stored in `flutter_secure_storage` — never in SharedPreferences

# ADR-005 : Flutter avec Riverpod pour le client mobile

**Date** : 2026-05-31  
**Statut** : Accepté  
**Décideurs** : Équipe YouScout

## Contexte

L'application mobile YouScout cible iOS et Android. Le choix du framework UI et de la solution de gestion d'état est critique pour la maintenabilité et la performance.

## Décision

- **Framework** : **Flutter 3.22.x** (Dart)
- **Gestion d'état** : **Riverpod** (v2, via `flutter_riverpod`)
- **Navigation** : **GoRouter** avec redirect guards pour l'authentification
- **Réseau** : **Dio** avec intercepteurs pour l'authentification automatique

## Justification

### Flutter
- **Multi-plateforme** : un seul codebase pour iOS et Android, réduisant l'effort de développement de ~40%.
- **Performance** : rendu natif via Skia/Impeller, crucial pour le feed vidéo vertical.
- **Écosystème** : `video_player`, `image_picker`, `flutter_secure_storage` sont matures et bien maintenus.

### Riverpod (vs Provider, BLoC, GetX)
- **Compile-safe** : les providers sont déclarés globalement et typés, éliminant les erreurs de `context` de Provider.
- **Testabilité** : chaque provider peut être overridden dans les tests sans widget tree.
- **Family providers** : permet de keyer un provider par paramètre (ex: `profileProvider(userId)`).
- **AsyncNotifier** : gestion native des états loading/error/data, idéal pour les appels API.

### GoRouter
- **Redirect declaratif** : les guards d'authentification sont déclarés une fois dans le routeur.
- **Deep links** : support natif pour le partage de profils et vidéos.
- **ShellRoute** : permet la barre de navigation persistante sans reconstruction.

## Architecture de l'application

```
lib/
├── core/           # Theme, Network, Storage, Router, Providers
├── features/       # Feature-first: auth, feed, upload, profile, notifications
│   └── <feature>/
│       ├── data/           # Models, Repository
│       └── presentation/   # Screens, Widgets, Providers
└── shared/         # Widgets réutilisables (bottom nav, etc.)
```

## Conséquences

- L'équipe doit connaître Dart et le paradigme réactif de Riverpod.
- Les packages natifs (caméra, stockage sécurisé) nécessitent une configuration platform-specific.
- Les tests widget/integration sont plus complexes qu'avec un monolithe natif.

## Alternatives rejetées

- **React Native** : performance inférieure pour le rendu vidéo temps réel, bridge JS coûteux.
- **Natif (Swift + Kotlin)** : double effort de développement, non justifié pour un MVP.
- **BLoC** : trop de boilerplate (Events + States + Bloc) pour un MVP rapide.

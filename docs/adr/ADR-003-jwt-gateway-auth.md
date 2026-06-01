# ADR-003 : Authentification JWT centralisée à l'API Gateway

**Date** : 2026-05-31  
**Statut** : Accepté  
**Décideurs** : Équipe YouScout

## Contexte

Chaque requête entrante doit être authentifiée. Deux options : vérifier le JWT dans chaque microservice, ou centraliser la vérification dans l'API Gateway.

## Décision

La vérification JWT (RS256) est effectuée **uniquement dans l'API Gateway** via un filtre Spring Cloud Gateway (`JwtAuthFilter`). Les services en aval reçoivent les headers suivants, injectés par le gateway après validation :

```
X-User-Id: <UUID>
X-User-Email: <email>
```

Les services en aval **font confiance** à ces headers sans re-valider le token.

## Justification

- **Simplification** : les services métier n'ont pas besoin de dépendance sur la bibliothèque JWT ni de configuration RSA.
- **Point unique de politique de sécurité** : les règles d'expiration, de blacklist, et de rotation de clés sont gérées en un seul endroit.
- **Performance** : le token n'est parsé/vérifié qu'une seule fois par requête.

## Schéma

```
Client → API Gateway (JWT verify) → X-User-Id header → user-service / video-service / ...
```

## Conséquences

- **Confiance implicite** : si un service est directement exposé (contournant le gateway), il n'a aucune vérification. Mitigation : réseau Docker privé, seul le gateway expose le port 8080.
- **Single point of failure** : si le gateway tombe, tout est indisponible. Mitigation : déploiement multi-instance derrière un load balancer en production.

## Clés RSA

- L'algorithme **RS256** est utilisé (clé privée pour signer dans user-service, clé publique pour vérifier dans api-gateway).
- Les clés sont générées via le script `infrastructure/generate-keys.sh` et montées via volume Docker.

## Alternatives rejetées

- **JWT vérifié dans chaque service** : duplique la configuration, complique la rotation de clés.
- **OAuth2 / Keycloak** : sur-dimensionné pour un MVP, ajouterait un service supplémentaire à maintenir.

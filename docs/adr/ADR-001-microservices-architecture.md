# ADR-001 : Architecture microservices

**Date** : 2026-05-31  
**Statut** : Accepté  
**Décideurs** : Équipe YouScout

## Contexte

YouScout est une plateforme sociale de type TikTok dédiée au football. Elle doit gérer des flux vidéo lourds, du temps réel (feed, notifications), et une croissance potentiellement rapide de la base d'utilisateurs.

## Décision

Adopter une **architecture microservices** avec les services suivants :

| Service | Responsabilité |
|---------|---------------|
| `user-service` | Authentification, profils, gestion des tokens |
| `video-service` | Upload, stockage (MinIO), métadonnées vidéo |
| `feed-service` | Agrégation du fil (fan-out sur Redis) |
| `comment-service` | CRUD des commentaires |
| `social-service` | Suivi (follow/unfollow) |
| `notification-service` | Notifications en réponse aux événements Kafka |
| `admin-service` | Modération (stub MVP) |
| `api-gateway` | Point d'entrée unique, vérification JWT centralisée |
| `eureka-server` | Découverte de services |

## Justification

- **Scalabilité indépendante** : le service vidéo pourra être scalé horizontalement sans impacter l'authentification.
- **Isolation des fautes** : un crash du service de commentaires ne fait pas tomber le feed.
- **Déploiement indépendant** : chaque équipe pourra déployer son service séparément.
- **Séparation des bases de données** : chaque service possède sa propre base PostgreSQL, éliminant les couplages au niveau données.

## Conséquences

- Complexité opérationnelle accrue (Docker Compose pour le dev, orchestrateur en production).
- Nécessité d'un mécanisme de communication inter-services (Kafka choisi, voir ADR-002).
- Traçabilité distribuée à mettre en place à terme (Spring Cloud Sleuth / Zipkin).

## Alternatives rejetées

- **Monolithe modulaire** : plus simple, mais ne permet pas le scaling indépendant du service vidéo.
- **Serverless (Cloud Functions)** : trop de cold-starts pour une expérience de feed temps réel.

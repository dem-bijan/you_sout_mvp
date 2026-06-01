# ADR-002 : Communication asynchrone via Apache Kafka

**Date** : 2026-05-31  
**Statut** : Accepté  
**Décideurs** : Équipe YouScout

## Contexte

Les microservices doivent communiquer pour propager les événements métier (vidéo publiée → mise à jour du feed, like → notification). Deux approches possibles : appels HTTP synchrones ou messagerie asynchrone.

## Décision

Utiliser **Apache Kafka** comme broker de messages pour toute la communication inter-services événementielle.

### Topics Kafka

| Topic | Producteur | Consommateurs |
|-------|-----------|--------------|
| `youscout.video.published` | video-service | feed-service |
| `youscout.video.liked` | video-service | notification-service |
| `youscout.comment.created` | comment-service | notification-service |
| `youscout.user.followed` | social-service | notification-service, feed-service |

### Partitionnement

Les messages sont partitionnés par `userId` pour garantir l'ordre strict des événements d'un même utilisateur.

## Justification

- **Découplage temporel** : les consommateurs ne bloquent pas les producteurs.
- **Résilience** : si le notification-service est indisponible, les messages sont conservés dans Kafka et consommés au retour.
- **Fan-out naturel** : un événement `video.published` est consommé simultanément par le feed-service et (à terme) l'analytics-service.
- **Replay** : possibilité de rejouer les événements en cas de bug ou de reconstruction d'état.

## Conséquences

- Complexité de déploiement : Kafka + Zookeeper à gérer.
- **Cohérence éventuelle** (eventual consistency) : le feed n'est pas mis à jour instantanément après un publish.
- Nécessité de gérer l'idempotence côté consommateur.

## Alternatives rejetées

- **REST synchrone** : crée un couplage fort et des cascades de pannes.
- **RabbitMQ** : plus simple mais ne supporte pas nativement le partitionnement par clé ni le replay.

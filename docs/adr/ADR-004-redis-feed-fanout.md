# ADR-004 : Fan-out sur Redis pour le feed

**Date** : 2026-05-31  
**Statut** : Accepté  
**Décideurs** : Équipe YouScout

## Contexte

Le fil d'actualité ("For You") doit afficher les vidéos des comptes suivis par l'utilisateur, triées par date de publication. Deux approches classiques : fan-out-on-write (pré-calculer le feed) ou fan-out-on-read (calculer à la volée).

## Décision

Adopter le modèle **fan-out-on-write** avec **Redis Sorted Sets** (ZSET).

### Fonctionnement

1. Un utilisateur publie une vidéo → événement `youscout.video.published` envoyé sur Kafka.
2. Le `feed-service` consomme cet événement.
3. Il récupère la liste des followers du publieur (via appel REST au `social-service`).
4. Pour chaque follower, il ajoute le `videoId` dans un ZSET Redis (`feed:{userId}`) avec le timestamp comme score.
5. Le feed est tronqué à 500 entrées maximum pour limiter l'usage mémoire.

### Clé Redis

```
feed:{userId}  →  ZSET { videoId1: timestamp1, videoId2: timestamp2, ... }
```

## Justification

- **Lecture ultra-rapide** : `ZREVRANGE` sur un ZSET est O(log N + M), bien plus rapide qu'un JOIN SQL.
- **Simplicité du client** : le frontend fait un seul appel GET pour récupérer le feed paginé.
- **Compatible avec la croissance** : Redis supporte des millions de clés, et peut être clusterisé.

## Conséquences

- **Coût en écriture** : pour un utilisateur avec 100K followers, chaque publication génère 100K insertions Redis. Mitigation : les célébrités utiliseront un fan-out hybride en V2.
- **Cohérence éventuelle** : le feed n'est pas instantanément à jour. Acceptable pour un réseau social.
- **Dépendance à Redis** : si Redis tombe, le feed est temporairement indisponible. Mitigation : fallback sur l'explore feed (trending).

## Alternatives rejetées

- **Fan-out-on-read (SQL)** : trop lent en lecture pour un flux temps réel.
- **Graph database** : sur-dimensionné et ajoute une technologie supplémentaire.

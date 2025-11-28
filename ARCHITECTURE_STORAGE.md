# 🏗️ Architecture de Stockage - Hive + Drift (SQLite)

## 📋 Vue d'ensemble

Cette application utilise une architecture de stockage hybride optimisée pour les performances et la persistance, inspirée des grandes applications comme Spotify, Apple Music et Netflix.

## 🏆 Hive - Stockage Session & Profil

### Pourquoi Hive ?
- ✅ **Ultra rapide** : Accès instantané aux données
- ✅ **100% hors-ligne** : Fonctionne sans Internet
- ✅ **Persistance garantie** : Les données ne disparaissent JAMAIS
- ✅ **Simple à utiliser** : API intuitive
- ✅ **Parfait pour JSON** : Stockage de structures complexes

### Ce qui est stocké dans Hive

#### 1. Session Utilisateur (`UserSession`)
```dart
- userId: ID Supabase
- email: Email de l'utilisateur
- accessToken: Token d'authentification
- refreshToken: Token de rafraîchissement
- tokenExpiresAt: Date d'expiration
- fullName: Nom complet
- role: admin ou user
- photoUrl: Photo de profil
- choraleName: Nom de la chorale
- pupitre: soprano, alto, tenor, basse
- createdAt: Date de création
- lastLoginAt: Dernière connexion
```

#### 2. Paramètres Application (`AppSettings`)
```dart
- theme: light, dark, system
- defaultPupitre: Pupitre par défaut
- volume: Volume par défaut (0.0 à 1.0)
- offlineMode: Mode hors-ligne activé
- autoDownloadFavorites: Téléchargement auto des favoris
- audioQuality: low, medium, high
- notificationsEnabled: Notifications activées
- language: Langue de l'application
```

### Service Hive
```dart
HiveSessionService
├── saveSession()        // Sauvegarder la session
├── getSession()         // Récupérer la session
├── hasSession()         // Vérifier si session existe
├── isSessionValid()     // Vérifier si token valide
├── updateToken()        // Mettre à jour le token
├── updateProfile()      // Mettre à jour le profil
├── clearSession()       // Déconnexion
├── saveSettings()       // Sauvegarder les paramètres
├── getSettings()        // Récupérer les paramètres
└── updateSetting()      // Mettre à jour un paramètre
```

## 🥈 Drift (SQLite) - Stockage Massif

### Pourquoi Drift ?
- ✅ **Gros volumes** : Stockage de milliers de chants
- ✅ **Requêtes complexes** : Tri, recherche, filtres
- ✅ **Super stable** : Utilisé par Spotify, Apple Music
- ✅ **Type-safe** : Sécurité du typage Dart
- ✅ **Migrations faciles** : Évolution du schéma

### Tables de la base de données

#### 1. `chants_table`
Stocke tous les chants disponibles
```sql
- id: UUID du chant
- titre: Titre du chant
- categorie: Catégorie (Louange, Adoration, etc.)
- auteur: Auteur du chant
- urlAudio: URL du fichier audio
- duree: Durée en secondes
- createdAt: Date de création
- type: normal ou pupitre
- lyrics: Paroles (optionnel)
- partitionUrl: URL de la partition (optionnel)
- isCached: Chant en cache local
- lastSyncedAt: Dernière synchronisation
```

#### 2. `favorites_table`
Stocke les favoris de chaque utilisateur
```sql
- id: UUID du favori
- userId: ID de l'utilisateur
- chantId: ID du chant
- createdAt: Date d'ajout
- isSynced: Synchronisé avec Supabase
```

#### 3. `playlists_table`
Stocke les playlists créées par les utilisateurs
```sql
- id: UUID de la playlist
- userId: ID de l'utilisateur
- name: Nom de la playlist
- description: Description (optionnel)
- createdAt: Date de création
- updatedAt: Dernière modification
- isSynced: Synchronisé avec Supabase
```

#### 4. `playlist_chants_table`
Stocke les chants dans les playlists
```sql
- id: UUID
- playlistId: ID de la playlist
- chantId: ID du chant
- position: Position dans la playlist
- addedAt: Date d'ajout
```

#### 5. `listening_history_table`
Stocke l'historique d'écoute
```sql
- id: UUID
- userId: ID de l'utilisateur
- chantId: ID du chant
- listenedAt: Date d'écoute
- duration: Durée écoutée en secondes
- completed: Écoute complète ou non
- isSynced: Synchronisé avec Supabase
```

#### 6. `downloaded_chants_table`
Stocke les chants téléchargés pour le mode hors-ligne
```sql
- id: UUID
- chantId: ID du chant
- localPath: Chemin local du fichier
- fileSize: Taille du fichier en octets
- downloadedAt: Date de téléchargement
- status: completed, pending, failed
```

### Service Drift
```dart
DriftChantsService
├── syncChantsFromSupabase()      // Synchroniser depuis Supabase
├── getAllChants()                 // Récupérer tous les chants
├── getChantById()                 // Récupérer un chant par ID
├── searchChants()                 // Rechercher des chants
├── getChantsByCategory()          // Filtrer par catégorie
├── getChantsByType()              // Filtrer par type
├── getUserFavoriteIds()           // Récupérer les IDs des favoris
├── getUserFavoriteChants()        // Récupérer les chants favoris
├── addFavorite()                  // Ajouter un favori
├── removeFavorite()               // Retirer un favori
├── isFavorite()                   // Vérifier si favori
├── syncFavoritesFromSupabase()    // Synchroniser les favoris
├── addToHistory()                 // Ajouter à l'historique
├── getUserHistory()               // Récupérer l'historique
├── markAsDownloaded()             // Marquer comme téléchargé
├── isDownloaded()                 // Vérifier si téléchargé
└── getAllDownloads()              // Récupérer tous les téléchargements
```

## 🔄 Flux de Synchronisation

### 1. Au démarrage de l'application
```
1. Initialiser Hive
2. Initialiser Drift
3. Vérifier si session existe dans Hive
4. Si session valide:
   - Charger le profil depuis Hive
   - Charger les chants depuis Drift (mode hors-ligne)
   - Synchroniser avec Supabase en arrière-plan
5. Si pas de session:
   - Afficher l'écran de connexion
```

### 2. Lors de la connexion
```
1. Authentifier avec Supabase
2. Récupérer le profil utilisateur
3. Sauvegarder la session dans Hive
4. Récupérer les chants depuis Supabase
5. Sauvegarder les chants dans Drift
6. Récupérer les favoris depuis Supabase
7. Sauvegarder les favoris dans Drift
```

### 3. Lors de l'ajout d'un favori
```
1. Ajouter immédiatement dans Drift (mise à jour optimiste)
2. Mettre à jour l'UI instantanément
3. Synchroniser avec Supabase en arrière-plan
4. Marquer comme synchronisé dans Drift
```

### 4. Lors de la déconnexion
```
1. Supprimer la session de Hive
2. Vider les données utilisateur de Drift
3. Garder les chants en cache pour le prochain utilisateur
```

## 📊 Comparaison avec l'ancienne architecture

| Fonctionnalité | Avant (SharedPreferences) | Après (Hive + Drift) |
|----------------|---------------------------|----------------------|
| **Session persistante** | ❌ Non fiable | ✅ 100% garantie |
| **Vitesse de lecture** | 🐌 Lent | ⚡ Ultra rapide |
| **Stockage massif** | ❌ Limité | ✅ Illimité |
| **Requêtes complexes** | ❌ Impossible | ✅ SQL complet |
| **Mode hors-ligne** | ⚠️ Partiel | ✅ Complet |
| **Type-safe** | ❌ Non | ✅ Oui |
| **Migrations** | ❌ Difficile | ✅ Facile |

## 🎯 Avantages pour le SaaS Multi-Tenant

Cette architecture est parfaitement adaptée pour évoluer vers un SaaS multi-tenant :

1. **Isolation des données** : Chaque utilisateur a ses propres favoris, playlists, historique
2. **Synchronisation cloud** : Les données locales peuvent être synchronisées avec Supabase
3. **Mode hors-ligne complet** : L'application fonctionne même sans Internet
4. **Scalabilité** : Peut gérer des milliers de chants et d'utilisateurs
5. **Performance** : Chargement instantané, même avec beaucoup de données

## 🚀 Prochaines étapes

1. ✅ Implémenter Hive pour la session
2. ✅ Implémenter Drift pour les chants
3. ⏳ Migrer l'authentification vers Hive
4. ⏳ Migrer le cache des chants vers Drift
5. ⏳ Implémenter la synchronisation bidirectionnelle
6. ⏳ Ajouter les playlists collaboratives
7. ⏳ Implémenter le mode hors-ligne complet

## 📚 Ressources

- [Documentation Hive](https://docs.hivedb.dev/)
- [Documentation Drift](https://drift.simonbinder.eu/)
- [Architecture Spotify](https://engineering.atspotify.com/)
- [Best Practices Flutter](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)

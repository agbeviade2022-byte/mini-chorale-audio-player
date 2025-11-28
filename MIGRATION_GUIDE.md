# 📋 Guide de Migration - Hive + Drift

## 🎯 Objectif

Migrer progressivement de **SharedPreferences** vers **Hive + Drift** pour améliorer les performances et la fiabilité.

## ✅ Ce qui a été fait

### 1. Installation des dépendances
- ✅ Hive et hive_flutter ajoutés
- ✅ Drift et sqlite3_flutter_libs ajoutés
- ✅ build_runner configuré
- ✅ Fichiers générés avec `flutter pub run build_runner build`

### 2. Modèles Hive créés
- ✅ `UserSession` - Session utilisateur avec token et profil
- ✅ `AppSettings` - Paramètres de l'application

### 3. Base de données Drift créée
- ✅ `AppDatabase` avec 6 tables:
  - `chants_table` - Tous les chants
  - `favorites_table` - Favoris par utilisateur
  - `playlists_table` - Playlists créées
  - `playlist_chants_table` - Chants dans les playlists
  - `listening_history_table` - Historique d'écoute
  - `downloaded_chants_table` - Chants téléchargés

### 4. Services créés
- ✅ `HiveSessionService` - Gestion de la session avec Hive
- ✅ `DriftChantsService` - Gestion des chants avec Drift
- ✅ `EnhancedAuthService` - Service d'authentification amélioré

### 5. Providers Riverpod
- ✅ `storage_providers.dart` - Providers pour Hive et Drift

### 6. Initialisation
- ✅ Hive initialisé dans `main.dart`
- ✅ Provider Hive ajouté au ProviderScope

## 🔄 Prochaines étapes de migration

### Phase 1: Migration de l'authentification (PRIORITAIRE)

#### Étape 1.1: Remplacer SupabaseAuthService
```dart
// Dans lib/providers/auth_provider.dart

// AVANT
final authServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

// APRÈS
final authServiceProvider = Provider<EnhancedAuthService>((ref) {
  final hiveSession = ref.watch(hiveSessionServiceProvider);
  return EnhancedAuthService(hiveSession);
});
```

#### Étape 1.2: Ajouter la restauration de session au démarrage
```dart
// Dans lib/screens/splash/splash_screen.dart

@override
void initState() {
  super.initState();
  _initializeApp();
}

Future<void> _initializeApp() async {
  final authService = ref.read(authServiceProvider);
  
  // Essayer de restaurer la session depuis Hive
  final hasSession = await authService.restoreSession();
  
  if (hasSession) {
    // Rediriger vers l'écran principal
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  } else {
    // Rediriger vers l'écran de connexion
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}
```

#### Étape 1.3: Tester la persistance de session
1. Se connecter à l'application
2. Fermer complètement l'application
3. Rouvrir l'application
4. ✅ L'utilisateur doit rester connecté

### Phase 2: Migration du cache des chants

#### Étape 2.1: Remplacer ChantsCacheService
```dart
// Dans lib/providers/chants_provider.dart

// Ajouter le provider Drift
final driftChantsProvider = FutureProvider<List<Chant>>((ref) async {
  final driftService = ref.watch(driftChantsServiceProvider);
  return await driftService.getAllChants();
});

// Modifier le provider principal pour utiliser Drift en fallback
final chantsProvider = FutureProvider<List<Chant>>((ref) async {
  try {
    // 1. Essayer de charger depuis Drift (mode hors-ligne)
    final driftService = ref.watch(driftChantsServiceProvider);
    final cachedChants = await driftService.getAllChants();
    
    if (cachedChants.isNotEmpty) {
      print('📦 ${cachedChants.length} chants chargés depuis Drift');
      
      // 2. Synchroniser avec Supabase en arrière-plan
      _syncChantsInBackground(ref);
      
      return cachedChants;
    }
    
    // 3. Si pas de cache, charger depuis Supabase
    final supabaseService = ref.watch(supabaseChantsServiceProvider);
    final chants = await supabaseService.getAllChants();
    
    // 4. Sauvegarder dans Drift
    await driftService.syncChantsFromSupabase(chants);
    
    return chants;
  } catch (e) {
    print('❌ Erreur: $e');
    rethrow;
  }
});

Future<void> _syncChantsInBackground(Ref ref) async {
  try {
    final supabaseService = ref.read(supabaseChantsServiceProvider);
    final driftService = ref.read(driftChantsServiceProvider);
    
    final chants = await supabaseService.getAllChants();
    await driftService.syncChantsFromSupabase(chants);
    
    print('🔄 Chants synchronisés avec Supabase');
  } catch (e) {
    print('⚠️ Erreur de synchronisation: $e');
  }
}
```

#### Étape 2.2: Tester le mode hors-ligne
1. Se connecter et charger les chants
2. Activer le mode avion
3. Redémarrer l'application
4. ✅ Les chants doivent être disponibles

### Phase 3: Migration des favoris

#### Étape 3.1: Remplacer FavoritesCacheService
```dart
// Dans lib/providers/favorites_provider.dart

final favoritesProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final driftService = ref.watch(driftChantsServiceProvider);
  
  try {
    // 1. Charger depuis Drift
    final favoriteIds = await driftService.getUserFavoriteIds(userId);
    
    // 2. Synchroniser avec Supabase en arrière-plan
    _syncFavoritesInBackground(ref, userId);
    
    return favoriteIds;
  } catch (e) {
    print('❌ Erreur: $e');
    return [];
  }
});

// Notifier pour ajouter/retirer des favoris
class FavoritesNotifier extends StateNotifier<AsyncValue<void>> {
  final DriftChantsService _driftService;
  final SupabaseFavoritesService _supabaseService;
  
  FavoritesNotifier(this._driftService, this._supabaseService)
      : super(const AsyncValue.data(null));
  
  Future<void> toggleFavorite(String userId, String chantId) async {
    state = const AsyncValue.loading();
    
    try {
      final isFav = await _driftService.isFavorite(userId, chantId);
      
      if (isFav) {
        // Retirer le favori
        await _driftService.removeFavorite(userId, chantId);
        await _supabaseService.removeFavorite(userId, chantId);
      } else {
        // Ajouter le favori
        await _driftService.addFavorite(userId, chantId);
        await _supabaseService.addFavorite(userId, chantId);
      }
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
```

### Phase 4: Migration de l'historique d'écoute

#### Étape 4.1: Utiliser Drift pour l'historique
```dart
// Dans lib/services/audio_player_service.dart

// Ajouter à la fin de la lecture d'un chant
Future<void> _onChantCompleted(String chantId, int duration) async {
  final userId = _authService.currentUser?.id;
  if (userId == null) return;
  
  // Sauvegarder dans Drift
  await _driftService.addToHistory(
    userId: userId,
    chantId: chantId,
    duration: duration,
    completed: true,
  );
  
  // Synchroniser avec Supabase en arrière-plan
  _syncHistoryToSupabase(userId, chantId, duration);
}
```

### Phase 5: Supprimer les anciens services

Une fois que tout fonctionne avec Hive et Drift:

1. ❌ Supprimer `ChantsCacheService`
2. ❌ Supprimer `FavoritesCacheService`
3. ❌ Remplacer `SupabaseAuthService` par `EnhancedAuthService`
4. ✅ Garder `shared_preferences` uniquement pour les petites données temporaires

## 🧪 Tests à effectuer

### Test 1: Persistance de session
- [ ] Se connecter
- [ ] Fermer l'app complètement
- [ ] Rouvrir l'app
- [ ] ✅ Utilisateur toujours connecté

### Test 2: Mode hors-ligne complet
- [ ] Se connecter et charger les chants
- [ ] Activer le mode avion
- [ ] Redémarrer l'app
- [ ] ✅ Chants disponibles
- [ ] ✅ Favoris disponibles
- [ ] ✅ Lecture audio fonctionne

### Test 3: Synchronisation
- [ ] Ajouter un favori hors-ligne
- [ ] Réactiver Internet
- [ ] ✅ Favori synchronisé avec Supabase

### Test 4: Multi-utilisateurs
- [ ] Se connecter avec utilisateur A
- [ ] Ajouter des favoris
- [ ] Se déconnecter
- [ ] Se connecter avec utilisateur B
- [ ] ✅ Pas de favoris de A visibles
- [ ] ✅ Session de B correcte

## 📊 Avantages attendus

| Métrique | Avant | Après |
|----------|-------|-------|
| Temps de chargement session | ~500ms | ~50ms |
| Temps de chargement chants | ~2s | ~100ms |
| Fiabilité session | 90% | 99.9% |
| Mode hors-ligne | Partiel | Complet |
| Taille max données | 10 MB | Illimité |

## 🚨 Points d'attention

1. **Migration progressive** : Ne pas tout migrer d'un coup
2. **Tests réguliers** : Tester après chaque phase
3. **Backup** : Garder les anciens services pendant la migration
4. **Logs** : Ajouter des logs pour débugger
5. **Performance** : Surveiller les performances

## 📞 Support

Si vous rencontrez des problèmes:
1. Vérifier les logs dans la console
2. Vérifier que build_runner a bien généré les fichiers `.g.dart`
3. Nettoyer et rebuild: `flutter clean && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs`

## 🎉 Résultat final

Une fois la migration terminée, vous aurez:
- ✅ Session utilisateur ultra-fiable avec Hive
- ✅ Stockage massif de chants avec Drift
- ✅ Mode hors-ligne complet
- ✅ Synchronisation bidirectionnelle avec Supabase
- ✅ Performances optimales
- ✅ Base solide pour le SaaS multi-tenant

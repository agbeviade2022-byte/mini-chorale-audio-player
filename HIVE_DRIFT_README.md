# 🏆 Hive + Drift - Guide d'utilisation

## 📚 Table des matières
1. [Introduction](#introduction)
2. [Hive - Session & Profil](#hive---session--profil)
3. [Drift - Base de données](#drift---base-de-données)
4. [Exemples d'utilisation](#exemples-dutilisation)
5. [Commandes utiles](#commandes-utiles)

## Introduction

Cette application utilise maintenant **Hive** pour la session utilisateur et **Drift (SQLite)** pour le stockage massif de données.

### Pourquoi cette architecture ?

| Besoin | Solution | Raison |
|--------|----------|--------|
| Session utilisateur | Hive | Ultra rapide, 100% fiable |
| Token & profil | Hive | Accès instantané |
| Paramètres app | Hive | Simple et efficace |
| Chants (milliers) | Drift | Requêtes SQL puissantes |
| Favoris | Drift | Relations entre tables |
| Playlists | Drift | Gestion complexe |
| Historique | Drift | Tri et filtres avancés |

## Hive - Session & Profil

### 🔧 Initialisation

Hive est initialisé automatiquement dans `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Hive
  final hiveService = HiveSessionService();
  await hiveService.initialize();
  
  runApp(MyApp());
}
```

### 📝 Sauvegarder une session

```dart
// Après connexion réussie
final session = UserSession(
  userId: user.id,
  email: user.email,
  accessToken: token,
  refreshToken: refreshToken,
  fullName: 'Jean Dupont',
  role: 'user',
  createdAt: DateTime.now(),
  lastLoginAt: DateTime.now(),
);

await hiveService.saveSession(session);
```

### 🔍 Récupérer la session

```dart
// Au démarrage de l'app
final session = hiveService.getSession();

if (session != null && session.isValid) {
  print('Utilisateur connecté: ${session.email}');
  print('Token valide: ${session.isValid}');
} else {
  print('Pas de session valide');
}
```

### 🔄 Mettre à jour le profil

```dart
await hiveService.updateProfile(
  fullName: 'Jean Dupont',
  photoUrl: 'https://example.com/photo.jpg',
  choraleName: 'Chorale Saint-Michel',
  pupitre: 'tenor',
);
```

### 🗑️ Déconnexion

```dart
await hiveService.clearSession();
```

### ⚙️ Paramètres de l'application

```dart
// Récupérer les paramètres
final settings = hiveService.getSettings();
print('Thème: ${settings.theme}');
print('Volume: ${settings.volume}');

// Mettre à jour un paramètre
await hiveService.updateSetting(
  theme: 'dark',
  volume: 0.8,
  offlineMode: true,
);
```

## Drift - Base de données

### 🔧 Initialisation

Drift est initialisé automatiquement via les providers:

```dart
// Dans votre widget
final driftService = ref.watch(driftChantsServiceProvider);
```

### 📝 Synchroniser les chants depuis Supabase

```dart
// Récupérer les chants depuis Supabase
final supabaseChants = await supabaseService.getAllChants();

// Sauvegarder dans Drift
await driftService.syncChantsFromSupabase(supabaseChants);

print('✅ ${supabaseChants.length} chants synchronisés');
```

### 🔍 Récupérer les chants

```dart
// Tous les chants
final allChants = await driftService.getAllChants();

// Un chant par ID
final chant = await driftService.getChantById('chant-id');

// Recherche
final results = await driftService.searchChants('alléluia');

// Filtrer par catégorie
final louanges = await driftService.getChantsByCategory('Louange');

// Filtrer par type
final pupitres = await driftService.getChantsByType('pupitre');
```

### ⭐ Gérer les favoris

```dart
// Ajouter un favori
await driftService.addFavorite(userId, chantId);

// Retirer un favori
await driftService.removeFavorite(userId, chantId);

// Vérifier si favori
final isFav = await driftService.isFavorite(userId, chantId);

// Récupérer tous les favoris
final favoriteIds = await driftService.getUserFavoriteIds(userId);
final favoriteChants = await driftService.getUserFavoriteChants(userId);

// Synchroniser depuis Supabase
await driftService.syncFavoritesFromSupabase(userId, favoriteIds);
```

### 📊 Historique d'écoute

```dart
// Ajouter une écoute
await driftService.addToHistory(
  userId: userId,
  chantId: chantId,
  duration: 180, // secondes
  completed: true,
);

// Récupérer l'historique
final history = await driftService.getUserHistory(userId, limit: 50);

for (final entry in history) {
  print('Écouté le: ${entry['listenedAt']}');
  print('Durée: ${entry['duration']}s');
}
```

### 📥 Téléchargements

```dart
// Marquer comme téléchargé
await driftService.markAsDownloaded(
  chantId: chantId,
  localPath: '/path/to/file.mp3',
  fileSize: 5242880, // octets
);

// Vérifier si téléchargé
final isDownloaded = await driftService.isDownloaded(chantId);

// Récupérer tous les téléchargements
final downloads = await driftService.getAllDownloads();
```

## Exemples d'utilisation

### Exemple 1: Connexion avec persistance

```dart
class LoginScreen extends ConsumerWidget {
  Future<void> _login(WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    
    try {
      // Connexion
      final response = await authService.signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      
      // La session est automatiquement sauvegardée dans Hive
      print('✅ Connecté et session sauvegardée');
      
      // Rediriger vers l'écran principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainLayout()),
      );
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }
}
```

### Exemple 2: Chargement des chants avec cache

```dart
class ChantsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chantsAsync = ref.watch(chantsProvider);
    
    return chantsAsync.when(
      data: (chants) {
        // Chants chargés depuis Drift (rapide) ou Supabase
        return ListView.builder(
          itemCount: chants.length,
          itemBuilder: (context, index) {
            return ChantTile(chant: chants[index]);
          },
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Erreur: $error'),
    );
  }
}

// Provider avec cache Drift
final chantsProvider = FutureProvider<List<Chant>>((ref) async {
  final driftService = ref.watch(driftChantsServiceProvider);
  final supabaseService = ref.watch(supabaseChantsServiceProvider);
  
  // 1. Essayer de charger depuis Drift (mode hors-ligne)
  final cachedChants = await driftService.getAllChants();
  
  if (cachedChants.isNotEmpty) {
    print('📦 Chants chargés depuis le cache');
    
    // 2. Synchroniser en arrière-plan
    _syncInBackground(ref);
    
    return cachedChants;
  }
  
  // 3. Charger depuis Supabase
  final chants = await supabaseService.getAllChants();
  
  // 4. Sauvegarder dans Drift
  await driftService.syncChantsFromSupabase(chants);
  
  return chants;
});
```

### Exemple 3: Toggle favori avec mise à jour optimiste

```dart
class ChantTile extends ConsumerWidget {
  final Chant chant;
  
  Future<void> _toggleFavorite(WidgetRef ref) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    
    final driftService = ref.read(driftChantsServiceProvider);
    final supabaseService = ref.read(supabaseFavoritesServiceProvider);
    
    try {
      final isFav = await driftService.isFavorite(userId, chant.id);
      
      if (isFav) {
        // Retirer immédiatement de Drift (UI instantanée)
        await driftService.removeFavorite(userId, chant.id);
        
        // Synchroniser avec Supabase en arrière-plan
        supabaseService.removeFavorite(userId, chant.id).catchError((e) {
          print('⚠️ Erreur sync: $e');
        });
      } else {
        // Ajouter immédiatement dans Drift (UI instantanée)
        await driftService.addFavorite(userId, chant.id);
        
        // Synchroniser avec Supabase en arrière-plan
        supabaseService.addFavorite(userId, chant.id).catchError((e) {
          print('⚠️ Erreur sync: $e');
        });
      }
      
      // Rafraîchir l'UI
      ref.invalidate(favoritesProvider);
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }
}
```

### Exemple 4: Restauration de session au démarrage

```dart
class SplashScreen extends ConsumerStatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }
  
  Future<void> _checkSession() async {
    final authService = ref.read(authServiceProvider);
    
    // Attendre 2 secondes pour le splash
    await Future.delayed(Duration(seconds: 2));
    
    // Essayer de restaurer la session depuis Hive
    final hasSession = await authService.restoreSession();
    
    if (hasSession) {
      // Session valide, aller à l'écran principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainLayout()),
      );
    } else {
      // Pas de session, aller à la connexion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }
}
```

## Commandes utiles

### Générer les fichiers Hive et Drift

```bash
# Générer tous les fichiers .g.dart
flutter pub run build_runner build --delete-conflicting-outputs

# Générer en mode watch (auto-génération)
flutter pub run build_runner watch --delete-conflicting-outputs

# Nettoyer et régénérer
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Débugger Hive

```dart
// Afficher les stats
final stats = hiveService.getStorageStats();
print('Stats: $stats');

// Vérifier si session existe
print('Session existe: ${hiveService.hasSession()}');
print('Session valide: ${hiveService.isSessionValid()}');

// Afficher la session
final session = hiveService.getSession();
print('Session: ${session?.toMap()}');
```

### Débugger Drift

```dart
// Compter les chants
final chants = await driftService.getAllChants();
print('Nombre de chants: ${chants.length}');

// Compter les favoris
final favorites = await driftService.getUserFavoriteIds(userId);
print('Nombre de favoris: ${favorites.length}');

// Vérifier un chant
final chant = await driftService.getChantById(chantId);
print('Chant trouvé: ${chant != null}');
```

### Nettoyer les données

```dart
// Nettoyer Hive
await hiveService.clearAllData();

// Nettoyer Drift
await driftService.clearAllData();

// Nettoyer les données d'un utilisateur
await driftService.clearUserData(userId);
```

## 🚨 Erreurs courantes

### Erreur: "Type 'UserSession' is not a subtype of type 'HiveObject'"

**Solution**: Régénérer les fichiers avec build_runner
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Erreur: "Box is already open"

**Solution**: Ne pas appeler `initialize()` plusieurs fois
```dart
// ❌ Mauvais
await hiveService.initialize();
await hiveService.initialize(); // Erreur

// ✅ Bon
await hiveService.initialize(); // Une seule fois
```

### Erreur: "Database is locked"

**Solution**: Fermer la base de données avant de la rouvrir
```dart
await database.close();
```

## 📚 Ressources

- [Documentation Hive](https://docs.hivedb.dev/)
- [Documentation Drift](https://drift.simonbinder.eu/)
- [Architecture Storage](./ARCHITECTURE_STORAGE.md)
- [Guide de Migration](./MIGRATION_GUIDE.md)

## 🎉 Conclusion

Avec Hive + Drift, votre application a maintenant:
- ✅ Session ultra-fiable qui ne se perd jamais
- ✅ Chargement instantané des données
- ✅ Mode hors-ligne complet
- ✅ Synchronisation bidirectionnelle avec Supabase
- ✅ Base solide pour le SaaS multi-tenant

Profitez de ces performances dignes de Spotify ! 🚀

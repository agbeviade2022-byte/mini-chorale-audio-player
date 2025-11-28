# ✅ Checklist : Stabilité sur Mobile

## 🔴 **URGENT - Permissions Android manquantes**

### **AndroidManifest.xml** - Ajoutez ces permissions

Ouvrez `android/app/src/main/AndroidManifest.xml` et ajoutez **AVANT** `<application>` :

```xml
<!-- ⚠️ PERMISSIONS MANQUANTES CRITIQUES -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32" />
```

**État actuel** : ❌ INTERNET manque → **L'app ne peut pas télécharger les chants !**

---

## 🍎 **iOS - Permissions manquantes**

### **Info.plist** - Vérifiez ces clés

Ouvrez `ios/Runner/Info.plist` et ajoutez :

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
<key>NSAppleMusicUsageDescription</key>
<string>Cette application a besoin d'accéder à vos fichiers audio</string>
```

---

## 🔧 **1. Gestion du Lifecycle de l'App**

### **Problème** : L'audio peut s'arrêter quand l'app passe en arrière-plan

### **Solution** : Ajouter un gestionnaire de lifecycle

Créez `lib/services/app_lifecycle_observer.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/providers/audio_provider.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref ref;

  AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App en arrière-plan - le son continue de jouer
        print('App en arrière-plan');
        break;
      case AppLifecycleState.resumed:
        // App revient au premier plan
        print('App au premier plan');
        break;
      case AppLifecycleState.inactive:
        // Transition
        break;
      case AppLifecycleState.detached:
        // App fermée - sauvegarder l'état
        final audioService = ref.read(audioServiceProvider);
        audioService.dispose();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
```

Modifiez `main.dart` :

```dart
class _AppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }
}
```

---

## 🌐 **2. Gestion des Erreurs Réseau**

### **Problème** : Plantage si pas de connexion internet

### **Solution** : Ajouter une vérification de connexion

Créez `lib/services/connectivity_service.dart` :

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }

  Future<bool> hasConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

Ajoutez dans `pubspec.yaml` :

```yaml
dependencies:
  connectivity_plus: ^5.0.0
```

Utilisez dans `audio_provider.dart` :

```dart
Future<void> playChant(Chant chant, {List<Chant>? playlist}) async {
  // Vérifier la connexion
  final hasConnection = await ConnectivityService().hasConnection();
  
  if (!hasConnection) {
    // Vérifier si le chant est téléchargé
    final isDownloaded = await _ref.read(
      isChantDownloadedProvider(chant.id).future
    );
    
    if (!isDownloaded) {
      throw Exception('Pas de connexion internet et chant non téléchargé');
    }
  }
  
  // Continuer la lecture...
}
```

---

## 💾 **3. Gestion de la Mémoire**

### **Problème** : Fuite de mémoire avec les streams

### **Solution** : S'assurer que tous les streams sont fermés

Dans `audio_player_service.dart`, vérifiez la méthode `dispose()` :

```dart
@override
void dispose() {
  // ✅ Fermer TOUS les StreamControllers
  _playingController.close();
  _positionController.close();
  _durationController.close();
  _playerStateController.close();
  _currentChantController.close();
  
  // ✅ Arrêter le player
  _player.stop();
  _player.dispose();
  
  // ✅ Annuler les subscriptions
  _playerSubscription?.cancel();
  _positionSubscription?.cancel();
  _durationSubscription?.cancel();
}
```

---

## ⚡ **4. Optimisations de Performance**

### **A. Chargement paresseux des images**

Dans les cartes de chants, utilisez `CachedNetworkImage` :

```yaml
dependencies:
  cached_network_image: ^3.3.0
```

```dart
// Au lieu de Image.network
CachedNetworkImage(
  imageUrl: chant.imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### **B. Pagination de la liste de chants**

Au lieu de charger tous les chants :

```dart
// Dans chants_provider.dart
final chantsPageProvider = FutureProvider.family<List<Chant>, int>((ref, page) async {
  final limit = 20;
  final offset = page * limit;
  
  return await supabase
    .from('chants')
    .select()
    .range(offset, offset + limit - 1)
    .order('created_at', ascending: false);
});
```

### **C. Debounce sur la recherche**

```dart
// Dans home_screen.dart
Timer? _debounce;

void _onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    // Effectuer la recherche
    setState(() {
      _searchQuery = query;
    });
  });
}
```

---

## 🐛 **5. Gestion Globale des Erreurs**

### **Ajouter dans main.dart** :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Capturer les erreurs Flutter
  FlutterError.onError = (details) {
    print('Flutter Error: ${details.exception}');
    // TODO: Envoyer à un service de tracking (Sentry, Firebase Crashlytics)
  };

  // ✅ Capturer les erreurs Dart
  runZonedGuarded(
    () async {
      await Supabase.initialize(...);
      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      print('Dart Error: $error');
      // TODO: Envoyer à un service de tracking
    },
  );
}
```

---

## 📱 **6. Tests sur Appareil Physique**

### **Checklist de test** :

- [ ] **Connexion lente** : Tester avec 3G/4G
- [ ] **Pas de connexion** : Mode avion
- [ ] **Batterie faible** : < 20%
- [ ] **Mémoire limitée** : Tester sur appareil ancien
- [ ] **Interruptions** : Appel téléphonique pendant la lecture
- [ ] **Bluetooth** : Écouteurs connectés/déconnectés
- [ ] **Multi-tâches** : Passer entre apps
- [ ] **Rotation écran** : Portrait/Paysage

---

## 🔋 **7. Optimisation Batterie**

### **Dans audio_player_service.dart** :

```dart
// Réduire la fréquence de mise à jour de la position
_player.positionStream
  .distinct((prev, next) => prev.inSeconds == next.inSeconds) // ✅ Seulement si changement de seconde
  .listen((position) {
    _positionController.add(position);
  });
```

---

## 📦 **8. Taille de l'APK**

### **Optimiser build.gradle** :

`android/app/build.gradle` :

```gradle
android {
    buildTypes {
        release {
            // ✅ Activer ProGuard pour réduire la taille
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
    
    // ✅ Générer des APK par architecture
    splits {
        abi {
            enable true
            reset()
            include 'armeabi-v7a', 'arm64-v8a', 'x86_64'
            universalApk false
        }
    }
}
```

---

## 🎯 **Priorités d'Implémentation**

### **🔴 CRITIQUE (À faire maintenant)**
1. ✅ Ajouter permission `INTERNET` dans AndroidManifest.xml
2. ✅ Vérifier `dispose()` dans AudioPlayerService
3. ✅ Gestion des erreurs réseau

### **🟡 IMPORTANT (Cette semaine)**
4. ⚠️ Lifecycle observer
5. ⚠️ Tests sur appareil physique
6. ⚠️ Gestion globale des erreurs

### **🟢 AMÉLIORATIONS (Optionnel)**
7. 💡 Optimisation batterie
8. 💡 Cache des images
9. 💡 Pagination

---

## 📝 **Commandes de Test**

```bash
# Tester sur Android
flutter run --release

# Vérifier les fuites de mémoire
flutter run --profile
# Ouvrir DevTools > Memory

# Analyser la taille de l'app
flutter build apk --analyze-size

# Build optimisé pour production
flutter build apk --split-per-abi --obfuscate --split-debug-info=./debug-info
```

---

## ✅ **Checklist Finale**

- [ ] Permissions Android ajoutées
- [ ] Permissions iOS ajoutées
- [ ] Lifecycle observer implémenté
- [ ] Gestion des erreurs réseau
- [ ] Streams tous fermés dans dispose()
- [ ] Erreurs globales capturées
- [ ] Testé sur appareil physique
- [ ] Testé sans connexion internet
- [ ] Testé avec interruptions (appels)
- [ ] Build release optimisé

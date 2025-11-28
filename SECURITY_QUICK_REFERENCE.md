# 🔐 SÉCURITÉ - GUIDE DE RÉFÉRENCE RAPIDE

## 🚀 INSTALLATION RAPIDE (45 min)

### 1. Installer les dépendances
```bash
flutter pub get
```

### 2. Exécuter la migration SQL
```sql
-- Dans Supabase SQL Editor
-- Copier/coller: migration_security_tracking.sql
```

### 3. Modifier main.dart
```dart
import 'package:mini_chorale_audio_player/services/encrypted_hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(...);
  
  // ✅ AJOUTER CES LIGNES
  final encryptedHive = EncryptedHiveService();
  await encryptedHive.initialize();
  await encryptedHive.migrateFromUnencryptedHive();
  
  runApp(ProviderScope(child: MyApp()));
}
```

### 4. Modifier enhanced_auth_service.dart
```dart
import 'package:mini_chorale_audio_player/services/encrypted_hive_service.dart';
import 'package:mini_chorale_audio_player/services/session_tracking_service.dart';

class EnhancedAuthService {
  final EncryptedHiveService _encryptedHive;
  final SessionTrackingService _sessionTracking;

  EnhancedAuthService(this._encryptedHive, this._sessionTracking);
  
  // Modifier signIn() et signOut()
}
```

---

## 📚 UTILISATION DES SERVICES

### **SecureStorageService** (Tokens)

```dart
final secureStorage = SecureStorageService();

// Sauvegarder
await secureStorage.saveAccessToken(token);
await secureStorage.saveRefreshToken(refreshToken);

// Récupérer
final token = await secureStorage.getAccessToken();
final isExpired = await secureStorage.isTokenExpired();

// Nettoyer
await secureStorage.clearTokens();
await secureStorage.clearAll();
```

### **EncryptedHiveService** (Données)

```dart
final encryptedHive = EncryptedHiveService();

// Initialiser
await encryptedHive.initialize();

// Sauvegarder session (tokens automatiquement dans Secure Storage)
await encryptedHive.saveSession(userSession);

// Récupérer session (tokens récupérés depuis Secure Storage)
final session = await encryptedHive.getSession();

// Vérifier
final hasSession = encryptedHive.hasSession();
final isValid = await encryptedHive.isSessionValid();

// Nettoyer
await encryptedHive.clearSession();
await encryptedHive.clearAll();
```

### **SessionTrackingService** (Sécurité)

```dart
final sessionTracking = SessionTrackingService();

// Tracker connexion
await sessionTracking.trackLogin(userId: userId);

// Tracker déconnexion
await sessionTracking.trackLogout(userId: userId);

// Obtenir sessions actives
final sessions = await sessionTracking.getActiveSessions(userId);

// Détecter activité suspecte
final check = await sessionTracking.checkSuspiciousActivity(userId);
if (check['is_suspicious']) {
  // Alerter l'utilisateur
}

// Déconnecter une session
await sessionTracking.disconnectSession(
  userId: userId,
  sessionId: sessionId,
);

// Déconnecter toutes les autres sessions
await sessionTracking.disconnectAllOtherSessions(userId);

// Statistiques
final stats = await sessionTracking.getConnectionStats(userId);
```

---

## 🔒 FONCTIONS SQL DISPONIBLES

### **Rate Limiting**

```dart
// Vérifier si bloqué
final isBlocked = await supabase.rpc('is_login_blocked', params: {
  'p_identifier': email,
  'p_identifier_type': 'email',
});

// Enregistrer tentative échouée
final result = await supabase.rpc('record_failed_login', params: {
  'p_email': email,
  'p_error_message': error.toString(),
});

// Réinitialiser après succès
await supabase.rpc('reset_login_attempts', params: {
  'p_email': email,
});
```

### **Sessions**

```dart
// Obtenir sessions actives
final sessions = await supabase.rpc('get_active_sessions', params: {
  'p_user_id': userId,
});

// Détecter activité suspecte
final suspicious = await supabase.rpc('detect_suspicious_activity', params: {
  'p_user_id': userId,
});
```

---

## 🎯 EXEMPLE COMPLET: CONNEXION SÉCURISÉE

```dart
Future<void> secureSignIn(String email, String password) async {
  try {
    // 1. Vérifier si bloqué
    final isBlocked = await _supabase.rpc('is_login_blocked', params: {
      'p_identifier': email,
      'p_identifier_type': 'email',
    });

    if (isBlocked == true) {
      throw Exception('Compte bloqué. Trop de tentatives.');
    }

    // 2. Authentifier
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // 3. Réinitialiser compteur
    await _supabase.rpc('reset_login_attempts', params: {
      'p_email': email,
    });

    // 4. Sauvegarder session chiffrée
    final userSession = UserSession(
      userId: response.user!.id,
      email: email,
      accessToken: response.session?.accessToken,
      refreshToken: response.session?.refreshToken,
      // ... autres champs
    );
    
    await _encryptedHive.saveSession(userSession);

    // 5. Tracker connexion
    await _sessionTracking.trackLogin(userId: response.user!.id);

    // 6. Vérifier activité suspecte
    final check = await _sessionTracking.checkSuspiciousActivity(
      response.user!.id,
    );

    if (check['is_suspicious'] == true) {
      // Alerter l'utilisateur
      _showSecurityAlert(check['reasons']);
    }

    print('✅ Connexion sécurisée réussie');
  } catch (e) {
    // Enregistrer tentative échouée
    await _supabase.rpc('record_failed_login', params: {
      'p_email': email,
      'p_error_message': e.toString(),
    });
    
    rethrow;
  }
}
```

---

## 🎯 EXEMPLE COMPLET: DÉCONNEXION SÉCURISÉE

```dart
Future<void> secureSignOut() async {
  try {
    final userId = _supabase.auth.currentUser?.id;

    // 1. Tracker déconnexion
    if (userId != null) {
      await _sessionTracking.trackLogout(userId: userId);
    }

    // 2. Nettoyer données locales
    await _encryptedHive.clearAll();
    await _secureStorage.clearAll();

    // 3. Déconnecter de Supabase
    await _supabase.auth.signOut();

    print('✅ Déconnexion sécurisée réussie');
  } catch (e) {
    print('❌ Erreur déconnexion: $e');
    rethrow;
  }
}
```

---

## 🔍 DÉBOGAGE

### **Vérifier le stockage sécurisé**

```dart
// Vérifier si des données existent
final hasData = await secureStorage.hasSecureData();
print('Données sécurisées: $hasData');

// Obtenir toutes les clés (DEBUG ONLY)
final keys = await secureStorage.getAllKeys();
print('Clés: $keys');
```

### **Vérifier Hive chiffré**

```dart
// Statistiques
final stats = encryptedHive.getStorageStats();
print('Hive stats: $stats');

// Vérifier session
final hasSession = encryptedHive.hasSession();
final isValid = await encryptedHive.isSessionValid();
print('Session: $hasSession, Valide: $isValid');
```

### **Vérifier tracking**

```dart
// Obtenir statistiques
final stats = await sessionTracking.getConnectionStats(userId);
print('Total connexions: ${stats['total_logins']}');
print('Sessions actives: ${stats['active_sessions']}');
print('Appareils uniques: ${stats['unique_devices']}');
```

---

## ⚠️ ERREURS COURANTES

### **Erreur: "EncryptedHiveService not initialized"**

```dart
// Solution: Initialiser avant utilisation
final encryptedHive = EncryptedHiveService();
await encryptedHive.initialize();
```

### **Erreur: "Box already open"**

```dart
// Solution: Vérifier si déjà ouvert
if (!Hive.isBoxOpen('user_session_encrypted')) {
  await encryptedHive.initialize();
}
```

### **Erreur: "PlatformException: read"**

```dart
// Solution: Permissions manquantes (Android)
// Ajouter dans AndroidManifest.xml:
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

---

## 📊 TABLES SQL CRÉÉES

1. **user_sessions_log** - Historique connexions
2. **security_alerts** - Alertes de sécurité
3. **failed_login_attempts** - Tentatives échouées
4. **login_blocks** - Blocages temporaires

---

## 🔧 CONFIGURATION

### **Android (android/app/build.gradle)**

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21 // Minimum pour Secure Storage
    }
}
```

### **iOS (ios/Podfile)**

```ruby
platform :ios, '12.0' # Minimum pour Secure Storage
```

---

## ✅ CHECKLIST RAPIDE

- [ ] `flutter pub get` exécuté
- [ ] Migration SQL exécutée sur Supabase
- [ ] `EncryptedHiveService` initialisé dans `main.dart`
- [ ] `EnhancedAuthService` modifié
- [ ] Tests de connexion OK
- [ ] Tests de déconnexion OK
- [ ] Rate limiting testé (5 tentatives)
- [ ] Sessions actives visibles

---

## 🆘 COMMANDES UTILES

```bash
# Nettoyer et rebuild
flutter clean
flutter pub get
flutter run

# Générer les fichiers Hive
flutter packages pub run build_runner build --delete-conflicting-outputs

# Logs détaillés
flutter run --verbose

# Tests
flutter test
```

---

## 📞 SUPPORT

**Documentation complète:**
- `SECURITY_AUDIT_SPOTIFY_LEVEL.md` - Audit
- `IMPLEMENTATION_GUIDE_SECURITY.md` - Guide détaillé
- `SECURITY_IMPLEMENTATION_SUMMARY.md` - Résumé

**Fichiers créés:**
- `lib/services/secure_storage_service.dart`
- `lib/services/encrypted_hive_service.dart`
- `lib/services/session_tracking_service.dart`
- `migration_security_tracking.sql`

---

**🔐 Votre app est maintenant sécurisée au niveau Spotify ! ✅**

# ⚡ COMMANDES RAPIDES - SÉCURITÉ

## 🚀 LANCEMENT RAPIDE

### **1. Nettoyer et installer**
```bash
cd "D:\Projet Flutter\mini_chorale_audio_player"
flutter clean
flutter pub get
```

### **2. Lancer l'application**
```bash
flutter run
```

### **3. Rebuild complet**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 🔍 VÉRIFICATIONS

### **Vérifier les dépendances**
```bash
flutter pub outdated
```

### **Vérifier les erreurs**
```bash
flutter analyze
```

### **Logs détaillés**
```bash
flutter run --verbose
```

---

## 🗄️ SUPABASE SQL

### **Exécuter la migration de sécurité**

1. Ouvrir: https://supabase.com/dashboard
2. Aller dans: SQL Editor
3. Copier/coller: `migration_security_tracking.sql`
4. Cliquer: Run

### **Vérifier les tables créées**
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
  AND table_name IN (
    'user_sessions_log',
    'security_alerts',
    'failed_login_attempts',
    'login_blocks'
  );
```

### **Vérifier les fonctions créées**
```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'is_login_blocked',
    'record_failed_login',
    'reset_login_attempts',
    'get_active_sessions',
    'detect_suspicious_activity'
  );
```

---

## 🧪 TESTS

### **Test 1: Connexion normale**
1. Lancer l'app
2. Se connecter avec un compte valide
3. Vérifier les logs:
```
✅ Connexion réussie et session sauvegardée de manière sécurisée
📊 Connexion trackée
🔐 Session sauvegardée dans EncryptedHive (AES-256)
```

### **Test 2: Rate limiting**
1. Essayer de se connecter 5 fois avec un mauvais mot de passe
2. À la 6ème tentative, vérifier le message:
```
Compte temporairement bloqué. Trop de tentatives de connexion. 
Réessayez dans 15 minutes.
```

### **Test 3: Déconnexion**
1. Se connecter
2. Se déconnecter
3. Vérifier les logs:
```
📊 Déconnexion trackée
🧹 Nettoyage complet des données locales...
✅ EncryptedHive nettoyé
✅ SecureStorage nettoyé
✅ Déconnexion réussie et données nettoyées de manière sécurisée
```

### **Test 4: Migration automatique**
1. Première connexion après mise à jour
2. Vérifier les logs:
```
🔐 Initialisation du système de sécurité...
✅ EncryptedHiveService initialisé avec chiffrement AES-256
✅ Migration des anciennes données terminée
```

---

## 🐛 DÉBOGAGE

### **Problème: Erreur de compilation**
```bash
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub get
flutter run
```

### **Problème: Hive déjà ouvert**
```bash
# Supprimer les fichiers Hive
# Android
adb shell run-as com.chorale.audio_player rm -rf /data/data/com.chorale.audio_player/app_flutter/

# iOS - Réinstaller l'app
flutter run --uninstall-first
```

### **Problème: Migration SQL échoue**
```sql
-- Vérifier si les tables existent déjà
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Supprimer les tables si nécessaire
DROP TABLE IF EXISTS user_sessions_log CASCADE;
DROP TABLE IF EXISTS security_alerts CASCADE;
DROP TABLE IF EXISTS failed_login_attempts CASCADE;
DROP TABLE IF EXISTS login_blocks CASCADE;

-- Puis réexécuter migration_security_tracking.sql
```

---

## 📊 MONITORING

### **Voir les sessions actives**
```sql
SELECT 
  usl.id,
  usl.user_id,
  usl.device_info->>'model' as device,
  usl.platform,
  usl.connected_at,
  usl.disconnected_at
FROM user_sessions_log usl
WHERE usl.disconnected_at IS NULL
ORDER BY usl.connected_at DESC;
```

### **Voir les tentatives échouées**
```sql
SELECT 
  email,
  COUNT(*) as attempts,
  MAX(attempted_at) as last_attempt
FROM failed_login_attempts
WHERE attempted_at > NOW() - INTERVAL '1 hour'
GROUP BY email
ORDER BY attempts DESC;
```

### **Voir les alertes de sécurité**
```sql
SELECT 
  sa.id,
  sa.user_id,
  sa.alert_type,
  sa.severity,
  sa.details,
  sa.created_at
FROM security_alerts sa
WHERE sa.resolved = FALSE
ORDER BY sa.created_at DESC
LIMIT 20;
```

---

## 🔧 MAINTENANCE

### **Nettoyer les anciennes données**
```sql
-- Exécuter manuellement
SELECT cleanup_old_security_data();
```

### **Réinitialiser un compte bloqué**
```sql
-- Débloquer un utilisateur
DELETE FROM login_blocks 
WHERE identifier = 'email@example.com';
```

### **Voir les statistiques**
```sql
SELECT 
  COUNT(DISTINCT user_id) as total_users,
  COUNT(*) as total_sessions,
  COUNT(*) FILTER (WHERE disconnected_at IS NULL) as active_sessions,
  COUNT(*) FILTER (WHERE connected_at > NOW() - INTERVAL '24 hours') as sessions_24h
FROM user_sessions_log;
```

---

## 📱 COMMANDES ANDROID

### **Voir les logs Android**
```bash
adb logcat | grep -i "flutter"
```

### **Nettoyer les données de l'app**
```bash
adb shell pm clear com.chorale.audio_player
```

### **Réinstaller l'app**
```bash
flutter run --uninstall-first
```

---

## 🍎 COMMANDES iOS

### **Voir les logs iOS**
```bash
flutter logs
```

### **Nettoyer les données de l'app**
```bash
# Supprimer l'app du simulateur
xcrun simctl uninstall booted com.chorale.audioPlayer

# Réinstaller
flutter run
```

---

## ⚡ RACCOURCIS UTILES

### **Rebuild rapide**
```bash
flutter run --hot-reload
```

### **Rebuild complet**
```bash
flutter run --no-fast-start
```

### **Mode release**
```bash
flutter run --release
```

### **Profiler les performances**
```bash
flutter run --profile
```

---

## 📝 NOTES

### **Ports utilisés**
- Supabase: 443 (HTTPS)
- Flutter DevTools: 9100
- Flutter Hot Reload: Random

### **Fichiers importants**
- `lib/main.dart` - Point d'entrée
- `lib/services/enhanced_auth_service.dart` - Authentification
- `lib/providers/auth_provider.dart` - Providers
- `migration_security_tracking.sql` - Migration SQL

### **Logs à surveiller**
```
🔐 Système de sécurité niveau Spotify activé ✅
✅ Connexion réussie et session sauvegardée de manière sécurisée
📊 Connexion trackée
⚠️ Activité suspecte détectée
```

---

## 🆘 AIDE RAPIDE

### **Erreur: "Function does not exist"**
→ Exécuter `migration_security_tracking.sql` sur Supabase

### **Erreur: "Box already open"**
→ `flutter clean && flutter run`

### **Erreur: "Permission denied"**
→ Vérifier les permissions Android/iOS

### **App ne démarre pas**
→ `flutter clean && flutter pub get && flutter run`

---

**💡 Astuce: Gardez ce fichier ouvert pendant le développement !**

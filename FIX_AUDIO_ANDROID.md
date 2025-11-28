# 🔧 Correction du Bug Audio sur Android

## ❌ Problème
L'audio ne joue pas sur l'APK Android mais fonctionne sur le web.

## ✅ Corrections Appliquées

### 1. **Configuration build.gradle**
- ✅ `minSdk` défini à 21 (Android 5.0+)
- ✅ `minifyEnabled = false` pour éviter l'obfuscation
- ✅ `shrinkResources = false` pour préserver les ressources audio

### 2. **Permissions AndroidManifest.xml**
- ✅ `INTERNET` - Streaming audio
- ✅ `ACCESS_NETWORK_STATE` - Vérifier la connexion
- ✅ `WAKE_LOCK` - Lecture en arrière-plan
- ✅ `FOREGROUND_SERVICE` - Service audio
- ✅ `FOREGROUND_SERVICE_MEDIA_PLAYBACK` - Lecture média
- ✅ `READ_MEDIA_AUDIO` - Accès aux fichiers audio (Android 13+)
- ✅ `usesCleartextTraffic="true"` - Support HTTP si nécessaire

### 3. **Règles ProGuard**
Fichier `android/app/proguard-rules.pro` créé pour protéger :
- Classes `just_audio`
- Classes `audio_service`
- Classes `ExoPlayer`
- Méthodes natives

### 4. **Amélioration du code**
- ✅ Meilleur logging dans `audio_handler.dart`
- ✅ Support fichiers locaux ET URLs réseau
- ✅ Gestion d'erreurs améliorée avec stack traces

---

## 🚀 Étapes pour Tester

### 1. Nettoyer le projet
```bash
flutter clean
flutter pub get
```

### 2. Rebuild l'APK
```bash
flutter build apk --release
```

### 3. Installer sur Android
```bash
flutter install
```

### 4. Tester avec logs
```bash
# Dans un terminal séparé
adb logcat | findstr "🎵\|❌\|✅"
```

---

## 🔍 Debug en Temps Réel

### Voir les logs Flutter
```bash
flutter logs
```

### Voir les logs Android natifs
```bash
adb logcat -s flutter
```

### Filtrer les logs audio
```bash
adb logcat | findstr "AudioHandler\|just_audio\|ExoPlayer"
```

---

## 📋 Checklist de Vérification

Avant de tester, vérifiez :

- [ ] **Connexion Internet** active sur le téléphone
- [ ] **Permissions accordées** dans Paramètres > Apps > Mini Chorale
- [ ] **URLs Supabase** correctes dans le code
- [ ] **Fichiers audio** accessibles publiquement sur Supabase
- [ ] **Version Android** >= 5.0 (API 21)

---

## 🐛 Si le Problème Persiste

### Vérifier les URLs Supabase

1. Ouvrir un chant dans l'app
2. Regarder les logs pour voir l'URL
3. Copier l'URL et la tester dans un navigateur
4. Si l'URL ne fonctionne pas dans le navigateur → Problème Supabase

### Tester avec un fichier local

Modifier temporairement `audio_handler.dart` :
```dart
// Test avec un fichier audio de test
await _player.setUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
```

Si ça fonctionne → Problème avec les URLs Supabase
Si ça ne fonctionne pas → Problème de configuration Android

### Vérifier les politiques Supabase Storage

Dans Supabase Dashboard :
1. Storage > audio_files
2. Policies > Vérifier que "Anyone can view audio files" existe
3. Tester l'URL publique d'un fichier

---

## 🎯 Causes Communes

| Problème | Solution |
|----------|----------|
| URLs HTTPS bloquées | ✅ Déjà corrigé avec `usesCleartextTraffic` |
| Permissions manquantes | ✅ Toutes ajoutées dans AndroidManifest |
| minSdk trop bas | ✅ Défini à 21 |
| ProGuard obfuscation | ✅ Désactivé + règles ajoutées |
| Fichiers Supabase privés | ⚠️ À vérifier dans Dashboard |
| URLs expirées | ⚠️ Vérifier si URLs signées |

---

## 📱 Test Rapide

### Commande tout-en-un
```bash
flutter clean && flutter pub get && flutter build apk --release && flutter install && flutter logs
```

### Vérifier l'installation
```bash
adb shell pm list packages | findstr chorale
```

### Désinstaller l'ancienne version
```bash
adb uninstall com.example.mini_chorale_audio_player
```

---

## ✅ Validation

Après les corrections, l'audio devrait :
- ✅ Se charger correctement
- ✅ Jouer sans erreur
- ✅ Afficher les contrôles
- ✅ Fonctionner en arrière-plan
- ✅ Afficher les notifications

---

## 📞 Support Supplémentaire

Si le problème persiste après toutes ces corrections :

1. **Partager les logs** : `flutter logs > logs.txt`
2. **Vérifier la version Android** du téléphone
3. **Tester sur un autre appareil** Android
4. **Vérifier les URLs Supabase** dans un navigateur

---

**Date** : 17 novembre 2025  
**Status** : ✅ Corrections appliquées - Prêt pour test

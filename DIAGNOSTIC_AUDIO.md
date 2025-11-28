# 🔍 Diagnostic Audio - Pourquoi ça ne fonctionne toujours pas ?

## ✅ APKs Générés

Vous avez maintenant **3 APKs** optimisés par architecture :

| Fichier | Taille | Architecture | Utilisation |
|---------|--------|--------------|-------------|
| `app-arm64-v8a-release.apk` | 23.8 MB | ARM 64-bit | **La plupart des téléphones modernes** |
| `app-armeabi-v7a-release.apk` | 21.7 MB | ARM 32-bit | Téléphones plus anciens |
| `app-x86_64-release.apk` | 25.2 MB | x86 64-bit | Émulateurs/Tablettes Intel |

**👉 Utilisez `app-arm64-v8a-release.apk` pour votre téléphone**

---

## 🚨 Problème : "Ça ne passe toujours pas"

### Qu'est-ce qui ne fonctionne pas exactement ?

Cochez ce qui s'applique :

- [ ] **L'APK ne s'installe pas** → Problème d'installation
- [ ] **L'app s'ouvre mais crash immédiatement** → Erreur au démarrage
- [ ] **L'app s'ouvre mais les chants ne s'affichent pas** → Problème de connexion Supabase
- [ ] **Les chants s'affichent mais ne jouent pas** → Problème audio
- [ ] **Les détails des chants sont vides** → Problème d'affichage
- [ ] **Autre** → Précisez

---

## 🔧 Tests de Diagnostic

### Test 1: Vérifier l'installation

```bash
# Désinstaller l'ancienne version
adb uninstall com.example.mini_chorale_audio_player

# Installer la nouvelle
adb install "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```

**Résultat attendu :**
```
Success
```

---

### Test 2: Voir les logs en temps réel

```bash
# Terminal 1 : Lancer l'app
adb shell am start -n com.example.mini_chorale_audio_player/.MainActivity

# Terminal 2 : Voir les logs
adb logcat | findstr "flutter\|AudioHandler\|just_audio\|ERROR"
```

**Ce qu'on cherche :**
- ✅ `🎵 Chargement audio: https://...`
- ✅ `✅ Audio chargé avec succès`
- ✅ `▶️ Démarrage lecture`
- ❌ `❌ Erreur lors du chargement de l'audio`

---

### Test 3: Vérifier les URLs Supabase

**Dans les logs, cherchez une ligne comme :**
```
🎵 Chargement audio: https://xxxxx.supabase.co/storage/v1/object/public/audio_files/...
```

**Copiez cette URL et testez-la dans un navigateur :**
- ✅ Si le fichier audio se télécharge → URLs OK
- ❌ Si erreur 404 → Fichiers supprimés ou privés
- ❌ Si erreur 403 → Permissions Supabase incorrectes

---

### Test 4: Tester avec un fichier audio de test

Pour isoler le problème, modifiez temporairement le code :

**Fichier : `lib/services/audio_handler.dart` ligne 68**

**AVANT :**
```dart
await _player.setUrl(url);
```

**APRÈS (temporaire pour test) :**
```dart
// Test avec un fichier audio public
await _player.setUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
```

**Rebuild et testez :**
```bash
flutter build apk --release --split-per-abi
adb install -r "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```

**Résultat :**
- ✅ Si ça joue → Problème avec vos URLs Supabase
- ❌ Si ça ne joue pas → Problème de configuration Android

---

## 🔍 Causes Possibles

### Cause 1: URLs Supabase expirées ou privées

**Symptôme :** Les chants s'affichent mais ne jouent pas

**Solution :**
1. Aller dans Supabase Dashboard
2. Storage > audio_files
3. Vérifier que les fichiers existent
4. Vérifier les policies RLS :
   ```sql
   -- Cette policy doit exister
   CREATE POLICY "Anyone can view audio files"
   ON storage.objects FOR SELECT
   USING (bucket_id = 'audio_files');
   ```

---

### Cause 2: Permissions Android non accordées

**Symptôme :** L'app crash ou l'audio ne joue pas

**Solution :**
1. Paramètres > Applications > Mini Chorale Audio Player
2. Permissions > Vérifier que toutes sont accordées :
   - ✅ Stockage
   - ✅ Réseau (devrait être automatique)

---

### Cause 3: Ancienne version en cache

**Symptôme :** Les modifications ne sont pas prises en compte

**Solution :**
```bash
# Désinstaller complètement
adb uninstall com.example.mini_chorale_audio_player

# Nettoyer les données
adb shell pm clear com.example.mini_chorale_audio_player

# Réinstaller
adb install "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```

---

### Cause 4: Problème de connexion réseau

**Symptôme :** Erreur "Pas de connexion"

**Solution :**
1. Vérifier que le téléphone a Internet (WiFi ou 4G)
2. Tester dans un navigateur mobile : https://supabase.com
3. Vérifier les paramètres réseau de l'app

---

### Cause 5: Fichiers audio corrompus ou format incompatible

**Symptôme :** Certains chants jouent, d'autres non

**Solution :**
- just_audio supporte : MP3, AAC, WAV, FLAC, OGG
- Vérifier le format des fichiers dans Supabase
- Tester avec un fichier MP3 simple

---

## 📊 Commandes de Debug Complètes

### Voir TOUS les logs Flutter
```bash
adb logcat -s flutter
```

### Voir les erreurs uniquement
```bash
adb logcat *:E
```

### Sauvegarder les logs dans un fichier
```bash
adb logcat > logs_audio.txt
```

### Vérifier si l'app est installée
```bash
adb shell pm list packages | findstr chorale
```

### Voir la version installée
```bash
adb shell dumpsys package com.example.mini_chorale_audio_player | findstr versionName
```

---

## 🆘 Checklist de Dépannage

Cochez au fur et à mesure :

### Installation
- [ ] Ancienne version désinstallée
- [ ] Nouvelle APK installée (app-arm64-v8a-release.apk)
- [ ] App s'ouvre sans crash

### Connexion
- [ ] Téléphone connecté à Internet
- [ ] Supabase accessible dans un navigateur
- [ ] Les chants s'affichent dans la liste

### Audio
- [ ] Clic sur un chant ne crash pas
- [ ] Le mini-player apparaît en bas
- [ ] Les contrôles (play/pause) répondent
- [ ] Le son sort des haut-parleurs

### Logs
- [ ] Logs Flutter visibles avec `adb logcat -s flutter`
- [ ] Pas d'erreurs rouges dans les logs
- [ ] URLs audio visibles dans les logs

---

## 📝 Informations à Fournir

Si le problème persiste, fournissez :

1. **Quel est le symptôme exact ?**
   - L'app crash ?
   - Pas de son ?
   - Écran blanc ?

2. **Que disent les logs ?**
   ```bash
   adb logcat -s flutter > logs.txt
   # Partagez le fichier logs.txt
   ```

3. **Test avec fichier audio public**
   - Avez-vous testé avec l'URL de test ?
   - Résultat ?

4. **Version Android**
   ```bash
   adb shell getprop ro.build.version.release
   ```

5. **Modèle de téléphone**
   ```bash
   adb shell getprop ro.product.model
   ```

---

## ✅ Si Tout Fonctionne

Si l'audio fonctionne maintenant :
- ✅ Gardez `app-arm64-v8a-release.apk` pour les futures installations
- ✅ Les corrections sont permanentes
- ✅ Vous pouvez supprimer les fichiers de debug (.md, .bat, .ps1)

---

**Date :** 17 novembre 2025  
**Status :** En diagnostic  
**APK :** app-arm64-v8a-release.apk (23.8 MB)

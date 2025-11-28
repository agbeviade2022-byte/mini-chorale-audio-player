# 📦 Gestion des Versions APK

## 🎯 Problème Actuel

Vous avez probablement une **ancienne version** de l'APK installée sur votre téléphone, et Android refuse d'installer la nouvelle version si elle a le **même numéro de version**.

---

## ✅ Solution : Incrémenter la Version

### Version Actuelle
```yaml
version: 1.0.0+1
         ↑     ↑
         |     └─ versionCode (nombre entier pour Android)
         └─ versionName (version lisible pour les humains)
```

### Nouvelle Version Recommandée
```yaml
version: 1.0.1+2
```

---

## 🔧 Comment Changer la Version

### Méthode 1 : Modifier pubspec.yaml (RECOMMANDÉ)

**Fichier : `pubspec.yaml` ligne 4**

**AVANT :**
```yaml
version: 1.0.0+1
```

**APRÈS :**
```yaml
version: 1.0.1+2
```

**Puis rebuild :**
```bash
flutter clean
flutter build apk --release --split-per-abi
```

---

### Méthode 2 : Spécifier lors du build

```bash
flutter build apk --release --split-per-abi --build-name=1.0.1 --build-number=2
```

---

## 📋 Règles de Versioning

### versionCode (le nombre après +)
- **DOIT être incrémenté** à chaque nouvelle compilation
- Nombre entier uniquement : 1, 2, 3, 4...
- Android utilise ce nombre pour déterminer quelle version est plus récente
- **Critique** : Si versionCode est identique ou inférieur, l'installation échoue

### versionName (avant le +)
- Version lisible pour les utilisateurs : 1.0.0, 1.0.1, 1.1.0, 2.0.0...
- Format recommandé : MAJEUR.MINEUR.PATCH
- Pas obligatoire pour l'installation, mais bonne pratique

---

## 🎯 Historique des Versions

| Version | versionCode | Date | Changements |
|---------|-------------|------|-------------|
| 1.0.0 | 1 | Initiale | Version originale avec notifications |
| 1.0.1 | 2 | 17 nov 2025 | Fix minSdk + withValues → withOpacity |

---

## 🚀 Processus Complet de Mise à Jour

### Étape 1 : Incrémenter la version
```yaml
# Dans pubspec.yaml
version: 1.0.1+2
```

### Étape 2 : Nettoyer
```bash
flutter clean
```

### Étape 3 : Rebuild
```bash
flutter build apk --release --split-per-abi
```

### Étape 4 : Désinstaller l'ancienne version
```bash
adb uninstall com.example.mini_chorale_audio_player
```

### Étape 5 : Installer la nouvelle
```bash
adb install "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```

---

## ⚠️ Erreurs Courantes

### Erreur : "INSTALL_FAILED_VERSION_DOWNGRADE"
**Cause :** Le versionCode de la nouvelle APK est inférieur ou égal à l'ancienne

**Solution :**
```yaml
# Augmentez le versionCode
version: 1.0.1+2  # ou +3, +4, etc.
```

### Erreur : "INSTALL_FAILED_UPDATE_INCOMPATIBLE"
**Cause :** Signature différente ou conflit de version

**Solution :**
```bash
# Désinstaller complètement l'ancienne version
adb uninstall com.example.mini_chorale_audio_player

# Puis réinstaller
adb install "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```

### Erreur : "App not installed"
**Cause :** Espace insuffisant ou APK corrompu

**Solution :**
1. Vérifier l'espace disponible sur le téléphone
2. Rebuild l'APK
3. Réessayer l'installation

---

## 🔍 Vérifier la Version Installée

### Sur le téléphone
```bash
adb shell dumpsys package com.example.mini_chorale_audio_player | findstr versionName
adb shell dumpsys package com.example.mini_chorale_audio_player | findstr versionCode
```

### Dans l'app (si vous ajoutez un écran "À propos")
```dart
import 'package:package_info_plus/package_info_plus.dart';

final packageInfo = await PackageInfo.fromPlatform();
print('Version: ${packageInfo.version}');
print('Build: ${packageInfo.buildNumber}');
```

---

## 📊 Stratégie de Versioning Recommandée

### Pour le Développement
```yaml
version: 1.0.0+1  # Première version
version: 1.0.0+2  # Fix bug
version: 1.0.0+3  # Autre fix
version: 1.0.1+4  # Petite amélioration
```

### Pour la Production
```yaml
version: 1.0.0+1   # Release initiale
version: 1.0.1+2   # Patch (bug fixes)
version: 1.1.0+3   # Minor (nouvelles fonctionnalités)
version: 2.0.0+4   # Major (changements importants)
```

---

## ✅ Checklist Avant Installation

- [ ] Version incrémentée dans `pubspec.yaml`
- [ ] `flutter clean` exécuté
- [ ] APK rebuild avec `--split-per-abi`
- [ ] Ancienne version désinstallée du téléphone
- [ ] Nouvelle APK installée
- [ ] App testée sur le téléphone

---

## 🎯 Commande Tout-en-Un

Voici une commande qui fait tout d'un coup :

```bash
# Nettoyer, builder, désinstaller, installer
flutter clean && flutter build apk --release --split-per-abi && adb uninstall com.example.mini_chorale_audio_player && adb install "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```

---

## 📝 Notes Importantes

1. **Toujours incrémenter versionCode** avant chaque nouvelle compilation
2. **Désinstaller l'ancienne version** si vous avez des problèmes d'installation
3. **Garder un historique** des versions et changements
4. **Tester sur plusieurs appareils** si possible

---

**Version actuelle :** 1.0.0+1  
**Version recommandée :** 1.0.1+2  
**Date :** 17 novembre 2025

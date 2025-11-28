# 🧪 Test avec Émulateur Android Studio

## 🎯 Objectif

Tester l'application sur l'émulateur Android Studio pour identifier les fonctionnalités qui ne sont pas compilées correctement.

---

## 📋 Fonctionnalités à Vérifier

### ✅ Checklist Complète

#### Authentification
- [ ] Écran de connexion s'affiche
- [ ] Connexion avec email/mot de passe fonctionne
- [ ] Inscription fonctionne
- [ ] Déconnexion fonctionne

#### Liste des Chants
- [ ] Les chants s'affichent dans la liste
- [ ] La recherche fonctionne
- [ ] Les filtres par catégorie fonctionnent
- [ ] Les favoris s'affichent (icône cœur)
- [ ] Les chants téléchargés ont l'icône offline

#### Lecteur Audio
- [ ] Clic sur un chant lance la lecture
- [ ] Le mini-player apparaît en bas
- [ ] Play/Pause fonctionne
- [ ] Boutons Suivant/Précédent fonctionnent
- [ ] Le full-player s'ouvre en swipe up
- [ ] La barre de progression fonctionne
- [ ] Le temps s'affiche correctement

#### Détails des Chants
- [ ] Écran de détails s'affiche
- [ ] Titre, auteur, catégorie visibles
- [ ] Durée affichée
- [ ] Date d'ajout visible
- [ ] Bouton "Écouter" fonctionne

#### Fonctionnalités Avancées
- [ ] Téléchargement de chants fonctionne
- [ ] Lecture hors ligne fonctionne
- [ ] Historique d'écoute enregistré
- [ ] Chants récemment écoutés affichés
- [ ] Mode shuffle fonctionne
- [ ] Mode repeat fonctionne

#### Admin (si compte admin)
- [ ] Bouton + flottant visible
- [ ] Ajout de chant normal fonctionne
- [ ] Ajout de chant pupitre fonctionne
- [ ] Modification de chant fonctionne
- [ ] Suppression de chant fonctionne

---

## 🚀 Commandes pour Émulateur

### 1. Lister les émulateurs disponibles
```bash
emulator -list-avds
```

### 2. Lancer un émulateur spécifique
```bash
emulator -avd <nom_emulateur>
```

### 3. Lancer l'app sur l'émulateur
```bash
flutter run --release
```

### 4. Voir les logs en temps réel
```bash
flutter logs
```

---

## 🔍 Problèmes Potentiels Identifiés

### Problème 1: Warnings de Compilation

**Warnings observés :**
```
Warning: Flutter support for your project's Kotlin version (2.0.0) will soon be dropped
warning: [options] source value 8 is obsolete
warning: [options] target value 8 is obsolete
```

**Impact :** Peut causer des problèmes de compatibilité

---

### Problème 2: Dépendances Obsolètes

**Packages avec versions plus récentes disponibles :**
- audio_session 0.1.25 → 0.2.2
- just_audio 0.9.46 → 0.10.5
- flutter_riverpod 2.6.1 → 3.0.3
- file_picker 8.3.7 → 10.3.6

**Impact :** Fonctionnalités manquantes ou bugs

---

### Problème 3: Configuration Java

**Source/Target Java 8 obsolète**

**Impact :** Certaines fonctionnalités modernes ne compilent pas

---

## ✅ Corrections à Appliquer

### Correction 1: Mettre à jour Kotlin

**Fichier : `android/build.gradle` ou `android/settings.gradle`**

Chercher et remplacer :
```gradle
// AVANT
ext.kotlin_version = '2.0.0'

// APRÈS
ext.kotlin_version = '2.1.0'
```

---

### Correction 2: Mettre à jour Java Version

**Fichier : `android/app/build.gradle`**

```gradle
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlinOptions {
    jvmTarget = '17'
}
```

---

### Correction 3: Mettre à jour les dépendances critiques

**Fichier : `pubspec.yaml`**

```yaml
dependencies:
  # Audio Player - Versions mises à jour
  just_audio: ^0.10.5
  audio_service: ^0.18.12
  
  # State Management
  flutter_riverpod: ^3.0.3
  
  # File Picker
  file_picker: ^10.3.6
```

---

## 📊 Script de Test Complet

```bash
# 1. Lister les émulateurs
emulator -list-avds

# 2. Lancer l'émulateur (remplacer <nom> par votre émulateur)
start emulator -avd <nom>

# 3. Attendre que l'émulateur démarre (30-60 secondes)

# 4. Vérifier que l'émulateur est détecté
flutter devices

# 5. Lancer l'app en mode release
flutter run --release

# 6. Dans un autre terminal, voir les logs
flutter logs
```

---

## 🆘 Si l'Émulateur ne Démarre Pas

### Vérifier Android Studio
```bash
# Ouvrir Android Studio
# Tools > AVD Manager
# Créer un nouvel émulateur si nécessaire
```

### Créer un Émulateur Recommandé
- **Device:** Pixel 6
- **System Image:** Android 13 (API 33) ou Android 14 (API 34)
- **RAM:** 2048 MB minimum
- **Storage:** 2 GB minimum

---

## 📝 Rapport de Test

Après avoir testé sur l'émulateur, notez :

### Fonctionnalités qui FONCTIONNENT
- [ ] ...
- [ ] ...

### Fonctionnalités qui NE FONCTIONNENT PAS
- [ ] ...
- [ ] ...

### Erreurs dans les Logs
```
[Coller les erreurs ici]
```

---

**Date :** 17 novembre 2025  
**Version :** 1.0.1+2  
**Objectif :** Identifier les fonctionnalités manquantes

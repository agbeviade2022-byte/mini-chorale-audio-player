# 🔧 Guide de Remplacement Automatique dans VS Code

## 📋 Étapes à suivre (2 minutes)

### Étape 1: Ouvrir la fonction Rechercher/Remplacer

**Méthode 1 (Raccourci clavier):**
- Appuyez sur `Ctrl + Shift + H`

**Méthode 2 (Menu):**
- Cliquez sur l'icône 🔍 dans la barre latérale gauche
- Ou Menu → Édition → Rechercher dans les fichiers

---

### Étape 2: Configurer la recherche

Dans la fenêtre qui s'ouvre, vous verrez 2 champs:

**Champ 1 - "Rechercher":**
```
.withValues(alpha: 
```

**Champ 2 - "Remplacer":**
```
.withOpacity(
```

---

### Étape 3: Filtrer les fichiers

Dans le champ **"Fichiers à inclure"**, entrez:
```
lib/**/*.dart
```

Cela limitera la recherche aux fichiers Dart dans le dossier `lib`.

---

### Étape 4: Vérifier les résultats

VS Code affichera:
- ✅ **58 résultats** dans 11 fichiers
- La liste des fichiers concernés
- Un aperçu de chaque occurrence

**Fichiers qui seront modifiés:**
- `lib/screens/home/home_screen.dart` (13)
- `lib/screens/chants/chants_pupitre_list.dart` (13)
- `lib/screens/player/full_player.dart` (11)
- `lib/screens/chants/chants_list.dart` (7)
- `lib/screens/auth/login.dart` (3)
- `lib/widgets/champ_recherche.dart` (3)
- `lib/config/theme.dart` (2)
- `lib/screens/auth/register.dart` (2)
- `lib/widgets/chants_filter.dart` (2)
- `lib/screens/player/mini_player.dart` (1)
- `lib/screens/splash/splash_screen.dart` (1)

---

### Étape 5: Remplacer tout

**Option 1 (Recommandé):**
- Cliquez sur l'icône **"Remplacer tout"** (icône avec 2 flèches)
- Ou appuyez sur `Ctrl + Alt + Enter`

**Option 2 (Prudent):**
- Cliquez sur **"Remplacer"** une par une pour vérifier
- Utilisez les flèches pour naviguer entre les résultats

---

### Étape 6: Confirmer

VS Code demandera:
> **"Voulez-vous remplacer 58 occurrences dans 11 fichiers ?"**

Cliquez sur **"Remplacer"** ou **"Oui"**

---

## ✅ Vérification

Après le remplacement, VS Code affichera:
```
✅ 58 occurrences remplacées dans 11 fichiers
```

---

## 🚀 Étapes suivantes

Une fois le remplacement terminé:

### 1. Sauvegarder tous les fichiers
```
Ctrl + K, S
```
Ou Menu → Fichier → Enregistrer tout

### 2. Nettoyer le projet
Ouvrir le terminal dans VS Code (`Ctrl + ù`) et exécuter:
```bash
flutter clean
```

### 3. Récupérer les dépendances
```bash
flutter pub get
```

### 4. Rebuild l'APK
```bash
flutter build apk --release
```

### 5. Installer sur Android
```bash
flutter install
```

---

## 🔍 Exemple visuel

**AVANT le remplacement:**
```dart
color: AppTheme.darkGrey.withValues(alpha: 0.7)
color: Colors.white.withValues(alpha: 0.5)
color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3)
```

**APRÈS le remplacement:**
```dart
color: AppTheme.darkGrey.withOpacity(0.7)
color: Colors.white.withOpacity(0.5)
color: Theme.of(context).colorScheme.surface.withOpacity(0.3)
```

---

## ⚠️ Si vous ne voyez pas 58 résultats

### Vérifiez:
1. **Le point avant withValues** → `.withValues(alpha: ` (avec le point)
2. **L'espace après "alpha:"** → `alpha: ` (avec espace)
3. **Le filtre de fichiers** → `lib/**/*.dart`

### Réessayez avec une recherche plus large:
- Rechercher: `withValues(alpha:`
- Remplacer: `withOpacity(`

---

## 🆘 En cas de problème

### Problème 1: "Aucun résultat trouvé"
**Solution:** Vérifiez que vous êtes dans le bon dossier
- Le dossier ouvert doit être: `d:\Projet Flutter\mini_chorale_audio_player`

### Problème 2: "Fichiers en lecture seule"
**Solution:** Fermez tous les fichiers ouverts
- `Ctrl + K, W` (Fermer tout)
- Puis refaites le remplacement

### Problème 3: "Erreur de remplacement"
**Solution:** Faites-le manuellement fichier par fichier
- Ouvrez chaque fichier listé ci-dessus
- `Ctrl + H` pour rechercher/remplacer dans le fichier actuel
- Rechercher: `.withValues(alpha: `
- Remplacer: `.withOpacity(`
- Cliquez sur "Remplacer tout"

---

## 📊 Résumé

| Étape | Action | Raccourci |
|-------|--------|-----------|
| 1 | Ouvrir Rechercher/Remplacer | `Ctrl + Shift + H` |
| 2 | Entrer recherche | `.withValues(alpha: ` |
| 3 | Entrer remplacement | `.withOpacity(` |
| 4 | Filtrer fichiers | `lib/**/*.dart` |
| 5 | Remplacer tout | `Ctrl + Alt + Enter` |
| 6 | Sauvegarder tout | `Ctrl + K, S` |

---

**Temps estimé:** 2 minutes  
**Difficulté:** ⭐ Facile  
**Impact:** 🔴 Critique - Corrige l'affichage

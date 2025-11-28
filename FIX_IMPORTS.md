# 🔧 Guide de Correction des Imports

Après avoir organisé les fichiers dans la structure `lib/`, vous devez corriger les imports dans tous les fichiers.

## 🚨 Problème

Les fichiers ont été créés avec des imports relatifs comme :
```dart
import '../config_theme.dart';
import '../model_chant.dart';
```

Mais maintenant que les fichiers sont organisés dans `lib/`, les imports doivent utiliser le package name.

## ✅ Solution

### Option 1 : Remplacement automatique (Recommandé)

Utilisez la fonction "Find and Replace" de votre IDE :

#### Dans VS Code :
1. Ouvrir "Find and Replace" (`Ctrl+Shift+H`)
2. Effectuer les remplacements suivants (un par un) :

```
# Config
Chercher : import '../config_theme.dart';
Remplacer : import 'package:mini_chorale_audio_player/config/theme.dart';

Chercher : import '../../config_theme.dart';
Remplacer : import 'package:mini_chorale_audio_player/config/theme.dart';

# Models
Chercher : import '../model_chant.dart';
Remplacer : import 'package:mini_chorale_audio_player/models/chant.dart';

Chercher : import '../../model_chant.dart';
Remplacer : import 'package:mini_chorale_audio_player/models/chant.dart';

Chercher : import '../model_user.dart';
Remplacer : import 'package:mini_chorale_audio_player/models/user.dart';

Chercher : import '../../model_user.dart';
Remplacer : import 'package:mini_chorale_audio_player/models/user.dart';

Chercher : import '../model_category.dart';
Remplacer : import 'package:mini_chorale_audio_player/models/category.dart';

Chercher : import '../../model_category.dart';
Remplacer : import 'package:mini_chorale_audio_player/models/category.dart';

# Services
Chercher : import '../service_auth.dart';
Remplacer : import 'package:mini_chorale_audio_player/services/supabase_auth_service.dart';

Chercher : import '../../service_auth.dart';
Remplacer : import 'package:mini_chorale_audio_player/services/supabase_auth_service.dart';

Chercher : import '../service_chants.dart';
Remplacer : import 'package:mini_chorale_audio_player/services/supabase_chants_service.dart';

Chercher : import '../../service_chants.dart';
Remplacer : import 'package:mini_chorale_audio_player/services/supabase_chants_service.dart';

Chercher : import '../service_storage.dart';
Remplacer : import 'package:mini_chorale_audio_player/services/supabase_storage_service.dart';

Chercher : import '../../service_storage.dart';
Remplacer : import 'package:mini_chorale_audio_player/services/supabase_storage_service.dart';

Chercher : import '../service_audio_player.dart';
Remplacer : import 'package:mini_chorale_audio_player/services/audio_player_service.dart';

Chercher : import '../../service_audio_player.dart';
Remplacer : import 'package:mini_chorale_audio_player/services/audio_player_service.dart';

# Providers
Chercher : import '../provider_auth.dart';
Remplacer : import 'package:mini_chorale_audio_player/providers/auth_provider.dart';

Chercher : import '../../provider_auth.dart';
Remplacer : import 'package:mini_chorale_audio_player/providers/auth_provider.dart';

Chercher : import '../provider_chants.dart';
Remplacer : import 'package:mini_chorale_audio_player/providers/chants_provider.dart';

Chercher : import '../../provider_chants.dart';
Remplacer : import 'package:mini_chorale_audio_player/providers/chants_provider.dart';

Chercher : import '../provider_audio.dart';
Remplacer : import 'package:mini_chorale_audio_player/providers/audio_provider.dart';

Chercher : import '../../provider_audio.dart';
Remplacer : import 'package:mini_chorale_audio_player/providers/audio_provider.dart';

# Widgets
Chercher : import '../widget_custom_button.dart';
Remplacer : import 'package:mini_chorale_audio_player/widgets/custom_button.dart';

Chercher : import '../../widget_custom_button.dart';
Remplacer : import 'package:mini_chorale_audio_player/widgets/custom_button.dart';

Chercher : import '../widget_champ_recherche.dart';
Remplacer : import 'package:mini_chorale_audio_player/widgets/champ_recherche.dart';

Chercher : import '../../widget_champ_recherche.dart';
Remplacer : import 'package:mini_chorale_audio_player/widgets/champ_recherche.dart';

Chercher : import '../widget_audio_wave.dart';
Remplacer : import 'package:mini_chorale_audio_player/widgets/audio_wave.dart';

Chercher : import '../../widget_audio_wave.dart';
Remplacer : import 'package:mini_chorale_audio_player/widgets/audio_wave.dart';

# Screens
Chercher : import '../onboarding/onboarding_screen.dart';
Remplacer : import 'package:mini_chorale_audio_player/screens/onboarding/onboarding_screen.dart';

Chercher : import '../home/home_screen.dart';
Remplacer : import 'package:mini_chorale_audio_player/screens/home/home_screen.dart';

Chercher : import '../auth/login.dart';
Remplacer : import 'package:mini_chorale_audio_player/screens/auth/login.dart';

Chercher : import 'register.dart';
Remplacer : import 'package:mini_chorale_audio_player/screens/auth/register.dart';

Chercher : import '../chants/chants_list.dart';
Remplacer : import 'package:mini_chorale_audio_player/screens/chants/chants_list.dart';

Chercher : import 'chant_details.dart';
Remplacer : import 'package:mini_chorale_audio_player/screens/chants/chant_details.dart';

Chercher : import '../player/mini_player.dart';
Remplacer : import 'package:mini_chorale_audio_player/screens/player/mini_player.dart';

Chercher : import 'full_player.dart';
Remplacer : import 'package:mini_chorale_audio_player/screens/player/full_player.dart';

Chercher : import '../admin/add_chant.dart';
Remplacer : import 'package:mini_chorale_audio_player/screens/admin/add_chant.dart';

Chercher : import 'config_theme.dart';
Remplacer : import 'package:mini_chorale_audio_player/config/theme.dart';

Chercher : import 'screen_splash.dart';
Remplacer : import 'package:mini_chorale_audio_player/screens/splash/splash_screen.dart';
```

### Option 2 : Correction manuelle

Ouvrir chaque fichier et corriger les imports selon ce schéma :

#### Fichier : lib/main.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/screens/splash/splash_screen.dart';
```

#### Fichier : lib/screens/splash/splash_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';
import 'package:mini_chorale_audio_player/screens/onboarding/onboarding_screen.dart';
import 'package:mini_chorale_audio_player/screens/home/home_screen.dart';
```

#### Fichier : lib/screens/auth/login.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/widgets/custom_button.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';
import 'package:mini_chorale_audio_player/screens/home/home_screen.dart';
import 'package:mini_chorale_audio_player/screens/auth/register.dart';
```

Et ainsi de suite pour tous les fichiers...

## 📝 Liste complète des fichiers à corriger

### 1. lib/main.dart
- [x] Importer config/theme.dart
- [x] Importer screens/splash/splash_screen.dart

### 2. lib/services/ (4 fichiers)
- [x] supabase_auth_service.dart : Aucun import local
- [x] supabase_chants_service.dart : Importer models/chant.dart
- [x] supabase_storage_service.dart : Aucun import local
- [x] audio_player_service.dart : Importer models/chant.dart

### 3. lib/providers/ (3 fichiers)
- [x] auth_provider.dart : Importer services et models
- [x] chants_provider.dart : Importer services et models
- [x] audio_provider.dart : Importer services et models

### 4. lib/widgets/ (3 fichiers)
- [x] custom_button.dart : Importer config/theme.dart
- [x] champ_recherche.dart : Importer config/theme.dart
- [x] audio_wave.dart : Importer config/theme.dart

### 5. lib/screens/ (11 fichiers)
Tous doivent importer config, providers, widgets selon leurs besoins

## 🧪 Vérification

Après correction, exécutez :

```bash
flutter pub get
flutter analyze
```

S'il n'y a pas d'erreurs, vous êtes prêt !

```bash
flutter run
```

## 💡 Astuce

Utilisez l'auto-import de votre IDE :
- VS Code : `Ctrl+.` sur une classe non importée
- Android Studio : `Alt+Enter` sur une classe non importée

L'IDE proposera automatiquement le bon import package.

## 🐛 Erreurs courantes

### "Target of URI doesn't exist"
➡️ Vérifiez que le fichier existe au bon emplacement dans lib/

### "Undefined name"
➡️ L'import est incorrect ou manquant

### "The imported libraries ... must not have a part"
➡️ Vous avez peut-être un import circulaire

---

**Bon courage avec les corrections ! 🚀**

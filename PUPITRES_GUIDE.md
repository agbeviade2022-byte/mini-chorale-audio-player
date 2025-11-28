# Guide d'implémentation - Chants par Pupitre

## Étapes d'installation

### 1. Exécuter la migration SQL

Ouvrez Supabase Dashboard → SQL Editor et exécutez le fichier :
```
add_chant_type_migration.sql
```

Cela ajoutera la colonne `type` à votre table `chants`.

### 2. Installer les dépendances

Exécutez dans le terminal :
```bash
flutter pub get
```

Cela installera :
- `record` : Pour l'enregistrement audio
- `permission_handler` : Pour gérer les permissions microphone
- `path_provider` : Pour le stockage temporaire

### 3. Permissions Android

Ajoutez dans `android/app/src/main/AndroidManifest.xml` (avant `</manifest>`) :
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 4. Permissions iOS

Ajoutez dans `ios/Runner/Info.plist` :
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Cette application a besoin d'accéder au microphone pour enregistrer des chants</string>
```

### 5. Permissions Web

Pour le web, les permissions sont gérées automatiquement par le navigateur.

## Nouveaux fichiers créés

### Modèles
- `lib/models/pupitre.dart` : Gestion des pupitres avec couleurs et icônes

### Services
- `lib/services/audio_recorder_service.dart` : Service d'enregistrement audio

### Screens
- `lib/screens/admin/add_chant_pupitre.dart` : Ajout de chant par pupitre
- `lib/screens/chants/chants_pupitre_list.dart` : Liste des chants par pupitre

## Utilisation

### Ajouter un chant par pupitre (Admin)

1. Accédez à l'écran `AddChantPupitreScreen`
2. Entrez le titre du chant
3. Sélectionnez le pupitre (Ténor, Basse, Soprano, Alto)
4. Choisissez le mode :
   - **Uploader** : Sélectionner un fichier audio existant
   - **Enregistrer** : Enregistrer directement depuis le microphone
5. Cliquez sur "Ajouter le chant"

### Voir les chants par pupitre

Naviguez vers `ChantsPupitreListScreen` pour voir :
- Tous les chants par pupitre
- Filtrage par pupitre spécifique
- Vue groupée par pupitre
- Lecture directe des chants

## Navigation recommandée

### Option 1 : Depuis le menu principal

Ajoutez un bouton dans votre home screen :
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChantsPupitreListScreen(),
      ),
    );
  },
  child: const Text('Chants par Pupitre'),
),
```

### Option 2 : Depuis le menu admin

Pour ajouter des chants par pupitre :
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddChantPupitreScreen(),
      ),
    );
  },
  child: const Text('Ajouter Chant Pupitre'),
),
```

## Différences entre types de chants

### Chants Normaux (type: 'normal')
- Catégories : Répétition, Messe, Adoration, Noël, Pâques
- Upload uniquement
- Liste via `ChantsListScreen`

### Chants par Pupitre (type: 'pupitre')
- Catégories : Ténor, Basse, Soprano, Alto
- Upload OU Enregistrement
- Liste via `ChantsPupitreListScreen`
- Couleurs distinctives par pupitre

## Providers disponibles

```dart
// Tous les chants par pupitre
ref.watch(chantsPupitreProvider)

// Chants d'un pupitre spécifique
ref.watch(chantsByPupitreProvider('Ténor'))

// Tous les chants normaux
ref.watch(chantsNormalsProvider)

// Tous les chants (normaux + pupitres)
ref.watch(chantsProvider)
```

## Personnalisation

### Modifier les couleurs des pupitres

Dans `lib/models/pupitre.dart`, modifiez la méthode `getColorForPupitre()` :
```dart
case tenor:
  return 0xFFFF9800; // Votre couleur en hexadécimal
```

### Ajouter d'autres pupitres

Dans `lib/models/pupitre.dart`, ajoutez dans la liste `all` :
```dart
static const List<String> all = [
  tenor,
  basse,
  soprano,
  alto,
  'Nouveau Pupitre', // Ajoutez ici
];
```

## Dépannage

### L'enregistrement ne fonctionne pas
- Vérifiez les permissions dans les fichiers AndroidManifest.xml et Info.plist
- Sur web, autorisez l'accès au microphone dans le navigateur
- Testez `await _recorderService.hasPermission()` pour déboguer

### Les chants ne s'affichent pas
- Vérifiez que la migration SQL a été exécutée
- Vérifiez que les chants ont le bon `type` dans la base de données :
  ```sql
  SELECT id, titre, type FROM chants;
  ```

### Erreur 400 lors de l'upload
- Assurez-vous que le bucket `audio_files` existe
- Vérifiez que votre utilisateur a le rôle `admin`
- Consultez `STORAGE_SETUP.md` pour la configuration complète

# 🚀 Guide de Démarrage Rapide - Mini-Chorale Audio Player

## ⚡ Installation en 5 minutes

### 1️⃣ Prérequis (2 min)

```bash
# Vérifier Flutter
flutter --version

# Doit afficher : Flutter 3.0.0 ou supérieur
```

Si Flutter n'est pas installé : https://docs.flutter.dev/get-started/install

### 2️⃣ Configurer Supabase (3 min)

#### A. Créer un compte Supabase (gratuit)

1. Aller sur https://app.supabase.com
2. Cliquer sur "New Project"
3. Remplir :
   - Nom du projet : `mini-chorale`
   - Mot de passe base de données : (notez-le bien !)
   - Région : Europe West
4. Cliquer sur "Create new project" (attend 1-2 min)

#### B. Configurer la base de données

1. Dans le menu gauche, cliquer sur "SQL Editor"
2. Cliquer sur "New Query"
3. Copier TOUT le contenu du fichier `supabase_setup.sql`
4. Coller dans l'éditeur
5. Cliquer sur "Run" (en bas à droite)
6. Vérifier : "Success. No rows returned" ✅

#### C. Récupérer les clés API

1. Cliquer sur l'icône ⚙️ Settings (en bas à gauche)
2. Cliquer sur "API" dans le menu
3. Copier :
   - `Project URL` (commence par https://xxx.supabase.co)
   - `anon public` key (longue chaîne de caractères)

### 3️⃣ Configurer l'application Flutter

1. Ouvrir `main.dart`
2. Ligne 11-12, remplacer :

```dart
await Supabase.initialize(
  url: 'COLLER_VOTRE_PROJECT_URL_ICI',
  anonKey: 'COLLER_VOTRE_ANON_KEY_ICI',
);
```

3. Sauvegarder

### 4️⃣ Installer les dépendances

```bash
flutter pub get
```

### 5️⃣ Lancer l'application

```bash
# Sur émulateur/simulateur
flutter run

# Ou sur appareil physique connecté
flutter run -d <device_id>
```

## 🎉 Premier lancement

### Créer un compte utilisateur

1. L'app s'ouvre sur le Splash Screen
2. Suivre l'onboarding (3 slides)
3. Sur l'écran Login, cliquer "S'inscrire"
4. Remplir le formulaire :
   - Nom complet : `Votre Nom`
   - Email : `votre@email.com`
   - Mot de passe : `minimum 6 caractères`
5. Cliquer "S'inscrire"

### Devenir administrateur

Par défaut, vous êtes un utilisateur simple. Pour devenir admin :

1. Aller sur https://app.supabase.com
2. Votre projet > Table Editor > `profiles`
3. Trouver votre ligne (avec votre email)
4. Double-cliquer sur la colonne `role`
5. Changer `user` en `admin`
6. Appuyer sur Entrée pour sauvegarder
7. Redémarrer l'app

### Ajouter votre premier chant

1. Sur l'écran Home, cliquer sur le bouton `+` (doré, en bas à droite)
2. Remplir le formulaire :
   - Titre : `Ave Maria`
   - Auteur/Voix : `Soprano`
   - Catégorie : `Messe`
3. Cliquer "Choisir un fichier audio"
4. Sélectionner un fichier MP3 (< 50MB)
5. Cliquer "Ajouter le chant"
6. Le chant apparaît dans la liste !

## 🎵 Utiliser l'application

### Écouter un chant

- Dans la liste, cliquer sur ▶️ pour lancer
- Le mini-player apparaît en bas
- Cliquer sur le mini-player pour ouvrir le lecteur complet

### Contrôles du lecteur

- ▶️ / ⏸️ : Play / Pause
- ⏮️ / ⏭️ : Chant précédent / suivant
- 🔀 : Mode aléatoire
- 🔁 : Répétition (Off / Une fois / Toutes)
- Slider : Avancer/reculer dans le chant

### Rechercher un chant

- Utiliser la barre de recherche en haut de l'écran Home
- Taper le titre ou l'auteur
- Les résultats s'affichent en temps réel

### Filtrer par catégorie

- Cliquer sur une catégorie (les chips en haut)
- Seuls les chants de cette catégorie s'affichent

## ❓ Problèmes courants

### "Failed to connect to Supabase"

➡️ Vérifier que :
- L'URL et l'anon key sont corrects dans `main.dart`
- Votre connexion internet fonctionne
- Le projet Supabase est actif (pas en pause)

### "Permission denied" lors de l'upload

➡️ Vérifier que :
- Vous êtes bien admin dans la table `profiles`
- Le bucket `audio_files` existe dans Storage
- Les politiques RLS sont bien appliquées

### L'audio ne se lance pas

➡️ Vérifier que :
- Le fichier audio est un format supporté (MP3, M4A, WAV)
- Le fichier fait moins de 50MB
- Le bucket `audio_files` est public

### L'app ne compile pas

➡️ Vérifier que :
- Tous les fichiers sont bien dans `d:\Projet Flutter\App Music Flutter\`
- Les imports dans les fichiers sont corrects
- `flutter pub get` a été exécuté

## 📞 Besoin d'aide ?

1. Lire le `README.md` complet
2. Vérifier le fichier `supabase_setup.sql`
3. Consulter la documentation Supabase : https://supabase.com/docs
4. Consulter la documentation Flutter : https://docs.flutter.dev

## 🎨 Personnalisation rapide

### Changer les couleurs

Ouvrir `config_theme.dart` et modifier :

```dart
static const Color primaryBlue = Color(0xFF1E3A5F); // Votre couleur
static const Color gold = Color(0xFFD4AF37); // Votre couleur
```

### Ajouter des catégories

Deux méthodes :

1. **Via l'app** (si vous êtes admin) :
   - TODO: Écran à ajouter

2. **Via Supabase** :
   - Table Editor > `categories`
   - Cliquer "Insert row"
   - Remplir `nom` avec votre catégorie
   - Cliquer "Save"

## 🚀 Prochaines étapes

1. ✅ Ajouter tous vos chants
2. ✅ Inviter les membres de la chorale
3. ✅ Organiser par catégories
4. 🔜 Planifier les répétitions
5. 🔜 Partager des playlists

## 💡 Conseils

- Utilisez des noms de fichiers clairs : `Ave_Maria_Soprano.mp3`
- Organisez bien vos catégories dès le début
- Testez avec quelques chants avant d'uploader toute votre bibliothèque
- Faites des sauvegardes régulières de votre base Supabase

---

**Bonne utilisation ! 🎵**

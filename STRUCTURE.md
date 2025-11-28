# 📁 Structure du Projet - Mini-Chorale Audio Player

## 📂 Organisation des fichiers

```
App Music Flutter/
│
├── 📄 pubspec.yaml                    # Dépendances et configuration
├── 📄 README.md                       # Documentation complète
├── 📄 QUICK_START.md                  # Guide de démarrage rapide
├── 📄 STRUCTURE.md                    # Ce fichier
├── 📄 .gitignore                      # Fichiers à ignorer par Git
├── 📄 supabase_setup.sql              # Script SQL de configuration
├── 📄 main.dart                       # Point d'entrée principal
│
├── 📁 config/
│   └── 📄 theme.dart                  # Thème et couleurs de l'app
│
├── 📁 models/                         # Modèles de données
│   ├── 📄 chant.dart                  # Modèle Chant
│   ├── 📄 user.dart                   # Modèle AppUser
│   ├── 📄 category.dart               # Modèle Category
│   └── 📄 subscription.dart           # Modèle Subscription (futur)
│
├── 📁 services/                       # Services métier
│   ├── 📄 supabase_auth_service.dart  # Gestion authentification
│   ├── 📄 supabase_chants_service.dart # Gestion des chants
│   ├── 📄 supabase_storage_service.dart # Upload/Download fichiers
│   └── 📄 audio_player_service.dart   # Lecteur audio
│
├── 📁 providers/                      # State management (Riverpod)
│   ├── 📄 auth_provider.dart          # Provider authentification
│   ├── 📄 chants_provider.dart        # Provider chants
│   └── 📄 audio_provider.dart         # Provider lecteur audio
│
├── 📁 screens/                        # Écrans de l'application
│   │
│   ├── 📁 splash/
│   │   └── 📄 splash_screen.dart      # Écran de démarrage
│   │
│   ├── 📁 onboarding/
│   │   └── 📄 onboarding_screen.dart  # Écrans d'introduction
│   │
│   ├── 📁 auth/
│   │   ├── 📄 login.dart              # Écran de connexion
│   │   └── 📄 register.dart           # Écran d'inscription
│   │
│   ├── 📁 home/
│   │   └── 📄 home_screen.dart        # Écran principal
│   │
│   ├── 📁 chants/
│   │   ├── 📄 chants_list.dart        # Liste des chants
│   │   └── 📄 chant_details.dart      # Détails d'un chant
│   │
│   ├── 📁 player/
│   │   ├── 📄 mini_player.dart        # Mini-lecteur en bas
│   │   └── 📄 full_player.dart        # Lecteur plein écran
│   │
│   └── 📁 admin/
│       ├── 📄 add_chant.dart          # Ajouter un chant
│       └── 📄 add_category.dart       # Ajouter une catégorie
│
├── 📁 widgets/                        # Widgets réutilisables
│   ├── 📄 custom_button.dart          # Bouton personnalisé
│   ├── 📄 champ_recherche.dart        # Barre de recherche
│   └── 📄 audio_wave.dart             # Animation onde audio
│
└── 📁 assets/                         # Ressources (images, icônes)
    ├── 📁 images/
    └── 📁 icons/
```

## 🎯 Rôle de chaque fichier

### Configuration

- **pubspec.yaml** : Liste toutes les dépendances Flutter
- **main.dart** : Point d'entrée, initialise Supabase et l'app
- **config/theme.dart** : Définit les couleurs, styles, thème global

### Modèles (Models)

Les modèles représentent les données de l'application :

- **chant.dart** : Structure d'un chant (id, titre, catégorie, etc.)
- **user.dart** : Structure d'un utilisateur (id, nom, rôle)
- **category.dart** : Structure d'une catégorie
- **subscription.dart** : Pour le futur module d'abonnement

### Services

Les services gèrent la communication avec Supabase :

- **supabase_auth_service.dart** : Connexion, inscription, déconnexion
- **supabase_chants_service.dart** : CRUD chants, recherche, filtres
- **supabase_storage_service.dart** : Upload/suppression fichiers audio
- **audio_player_service.dart** : Contrôle du lecteur audio (play, pause, etc.)

### Providers (State Management)

Les providers gèrent l'état global de l'app avec Riverpod :

- **auth_provider.dart** : État d'authentification
- **chants_provider.dart** : Liste des chants, recherche
- **audio_provider.dart** : État du lecteur (chant actuel, lecture/pause)

### Écrans (Screens)

Chaque dossier contient les écrans d'une fonctionnalité :

#### Splash & Onboarding
- **splash_screen.dart** : Logo + chargement au démarrage
- **onboarding_screen.dart** : 3 slides de présentation

#### Authentification
- **login.dart** : Formulaire de connexion
- **register.dart** : Formulaire d'inscription

#### Home
- **home_screen.dart** : Écran principal avec liste et catégories

#### Chants
- **chants_list.dart** : Affiche tous les chants en liste
- **chant_details.dart** : Détails d'un chant spécifique

#### Lecteur Audio
- **mini_player.dart** : Barre de lecture en bas (toujours visible)
- **full_player.dart** : Lecteur plein écran avec tous les contrôles

#### Administration
- **add_chant.dart** : Formulaire pour ajouter un chant (admins)
- **add_category.dart** : Formulaire pour ajouter une catégorie (admins)

### Widgets

Composants réutilisables dans toute l'app :

- **custom_button.dart** : Bouton avec style personnalisé
- **champ_recherche.dart** : Barre de recherche stylisée
- **audio_wave.dart** : Animation visuelle pendant la lecture

## 🔄 Flux de données

```
User Action
    ↓
Screen/Widget
    ↓
Provider (Riverpod)
    ↓
Service
    ↓
Supabase (API/Database)
    ↓
Service
    ↓
Provider
    ↓
Screen/Widget (rebuild)
```

## 📊 Base de données Supabase

### Tables

1. **profiles**
   - Stocke les infos utilisateurs
   - Lié à auth.users de Supabase
   - Contient le rôle (user/admin)

2. **categories**
   - Liste des catégories de chants
   - Par défaut : Répétition, Messe, Adoration, Noël, Pâques

3. **chants**
   - Tous les chants
   - Référence la catégorie
   - Contient l'URL du fichier audio

4. **subscriptions** (futur)
   - Pour le module d'abonnement multi-chorales

### Storage

- **audio_files** : Bucket pour stocker les fichiers audio (MP3, WAV, etc.)

## 🎨 Architecture de l'UI

### Style Guide

- **Couleur primaire** : Bleu marine (#1E3A5F)
- **Couleur secondaire** : Doré (#D4AF37)
- **Background** : Blanc (#FFFFFF)
- **Coins arrondis** : 16px
- **Élévation** : 2px (shadows légères)
- **Police** : System default

### Composants

- Boutons avec coins arrondis
- Cards avec ombre légère
- Dégradés sur les backgrounds
- Animations fluides
- Icônes Material Design

## 🔐 Sécurité

- **RLS (Row Level Security)** : Activé sur toutes les tables
- **Policies** : Contrôlent qui peut lire/écrire
- **Rôles** : User (lecture seule) vs Admin (lecture/écriture)
- **Storage** : Public en lecture, admin en écriture

## 🚀 Modules futurs

Structure préparée pour :

- Module d'abonnement
- Gestion multi-chorales
- Statistiques d'écoute
- Playlists personnalisées
- Mode hors ligne
- Paroles et partitions

## 📝 Conventions de code

### Nommage

- **Fichiers** : snake_case (ex: `audio_player_service.dart`)
- **Classes** : PascalCase (ex: `AudioPlayerService`)
- **Variables/Fonctions** : camelCase (ex: `playChant`)
- **Constantes** : SCREAMING_SNAKE_CASE (ex: `MAX_FILE_SIZE`)

### Organisation

- Imports Flutter en premier
- Imports packages tiers ensuite
- Imports locaux en dernier
- Séparés par des lignes vides

### Commentaires

- Commentaires sur les fonctions complexes
- Documentation des classes publiques
- Explication des algorithmes non évidents

## 🛠️ Développement

### Commandes utiles

```bash
# Installer les dépendances
flutter pub get

# Lancer l'app
flutter run

# Générer le code (si besoin)
flutter pub run build_runner build

# Nettoyer le cache
flutter clean

# Analyser le code
flutter analyze

# Formater le code
flutter format .
```

### Tests

Structure prête pour :
- Tests unitaires (models, services)
- Tests d'intégration (providers)
- Tests de widgets (UI)

## 📚 Ressources

- [Documentation Flutter](https://docs.flutter.dev)
- [Documentation Supabase](https://supabase.com/docs)
- [Riverpod](https://riverpod.dev)
- [Just Audio](https://pub.dev/packages/just_audio)

---

**Dernière mise à jour** : 2025-01-14

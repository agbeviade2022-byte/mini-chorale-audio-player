# Mini-Chorale Audio Player

Application Flutter pour la gestion et l'écoute de chants de chorale avec lecteur audio moderne.

## 🎯 Fonctionnalités

- ✅ Authentification utilisateur (Supabase Auth)
- ✅ Gestion des chants par catégories
- ✅ Lecteur audio moderne avec contrôles complets
- ✅ Recherche en temps réel
- ✅ Interface admin pour ajouter des chants
- ✅ Upload de fichiers audio vers Supabase Storage
- ✅ Design moderne type Apple Music / Spotify
- ✅ Support des rôles utilisateurs (admin/user)

## 📋 Prérequis

- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Un compte Supabase (gratuit)

## 🚀 Installation

### 1. Cloner le projet

```bash
cd "App Music Flutter"
flutter pub get
```

### 2. Configuration Supabase

#### A. Créer un projet Supabase

1. Allez sur https://app.supabase.com
2. Créez un nouveau projet
3. Notez votre `URL` et `anon key`

#### B. Créer les tables SQL

Exécutez ces commandes SQL dans l'éditeur SQL de Supabase :

```sql
-- Table profiles
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table categories
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table chants
CREATE TABLE chants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titre TEXT NOT NULL,
  categorie TEXT NOT NULL,
  auteur TEXT NOT NULL,
  url_audio TEXT NOT NULL,
  duree INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table subscriptions (pour futur module)
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chorale_name TEXT NOT NULL,
  admin_id UUID REFERENCES auth.users(id),
  plan TEXT NOT NULL,
  active_until TIMESTAMP NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insérer les catégories par défaut
INSERT INTO categories (nom) VALUES
  ('Répétition'),
  ('Messe'),
  ('Adoration'),
  ('Noël'),
  ('Pâques');

-- Politique RLS pour profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- Politique RLS pour chants
ALTER TABLE chants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view chants"
  ON chants FOR SELECT
  USING (true);

CREATE POLICY "Only admins can insert chants"
  ON chants FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Only admins can update chants"
  ON chants FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Only admins can delete chants"
  ON chants FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Politique RLS pour categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view categories"
  ON categories FOR SELECT
  USING (true);

CREATE POLICY "Only admins can manage categories"
  ON categories FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
```

#### C. Configurer Storage

1. Dans Supabase Dashboard, allez dans `Storage`
2. Créez un bucket nommé `audio_files`
3. Rendez-le public
4. Définissez la taille max à 50MB

Ou exécutez ce SQL :

```sql
-- Créer le bucket storage
INSERT INTO storage.buckets (id, name, public)
VALUES ('audio_files', 'audio_files', true);

-- Politique storage
CREATE POLICY "Anyone can view audio files"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'audio_files');

CREATE POLICY "Admins can upload audio files"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'audio_files' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
```

### 3. Configuration de l'application

Ouvrez `main.dart` et remplacez :

```dart
await Supabase.initialize(
  url: 'VOTRE_SUPABASE_URL',
  anonKey: 'VOTRE_SUPABASE_ANON_KEY',
);
```

### 4. Lancer l'application

```bash
flutter run
```

## 📱 Structure du projet

```
lib/
├── main.dart                      # Point d'entrée
├── config/
│   └── theme.dart                 # Thème de l'app
├── models/
│   ├── chant.dart                 # Modèle Chant
│   ├── user.dart                  # Modèle User
│   ├── category.dart              # Modèle Category
│   └── subscription.dart          # Modèle Subscription (futur)
├── services/
│   ├── supabase_auth_service.dart # Service auth
│   ├── supabase_chants_service.dart # Service chants
│   ├── supabase_storage_service.dart # Service storage
│   └── audio_player_service.dart  # Service audio
├── providers/
│   ├── auth_provider.dart         # Provider auth
│   ├── chants_provider.dart       # Provider chants
│   └── audio_provider.dart        # Provider audio
├── screens/
│   ├── splash/
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── chants/
│   ├── player/
│   └── admin/
└── widgets/
    ├── custom_button.dart
    ├── champ_recherche.dart
    └── audio_wave.dart
```

## 🎨 Design

- Couleurs : Bleu marine (#1E3A5F) + Doré (#D4AF37) + Blanc
- Style : Moderne, inspiré d'Apple Music / Spotify
- Coins arrondis, dégradés, animations fluides

## 👤 Créer un admin

Par défaut, tous les nouveaux utilisateurs ont le rôle `user`. Pour créer un admin :

1. Inscrivez un utilisateur via l'app
2. Dans Supabase, allez dans `Table Editor` > `profiles`
3. Trouvez l'utilisateur et changez `role` de `user` à `admin`

## 📦 Packages utilisés

- `flutter_riverpod` : State management
- `supabase_flutter` : Backend & Auth
- `just_audio` : Lecteur audio
- `audio_service` : Service audio en arrière-plan
- `file_picker` : Sélection de fichiers
- `cached_network_image` : Cache d'images
- `intl` : Formatage

## 🔮 Fonctionnalités futures

- [ ] Module d'abonnement pour autres chorales
- [ ] Paroles des chants
- [ ] Partitions PDF
- [ ] Playlists personnalisées
- [ ] Favoris
- [ ] Statistiques d'écoute
- [ ] Mode hors ligne

## 📄 Licence

Ce projet est sous licence MIT.

## 👨‍💻 Auteur

Développé pour votre chorale avec ❤️

## 🆘 Support

Pour toute question ou problème :
1. Vérifiez que Supabase est bien configuré
2. Vérifiez les clés API dans `main.dart`
3. Vérifiez les politiques RLS dans Supabase
4. Consultez les logs Flutter pour les erreurs

## 🔧 Dépannage

### Erreur de connexion Supabase
- Vérifiez que l'URL et l'anon key sont correctes
- Vérifiez votre connexion internet

### Erreur d'upload audio
- Vérifiez que le bucket `audio_files` existe
- Vérifiez que l'utilisateur a le rôle admin
- Vérifiez que le fichier fait moins de 50MB

### Erreur de lecture audio
- Vérifiez que l'URL du fichier est accessible
- Vérifiez les permissions du bucket Storage

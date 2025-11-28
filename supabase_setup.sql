-- =====================================================
-- CONFIGURATION SUPABASE - Mini-Chorale Audio Player
-- =====================================================
-- Exécutez ces commandes dans l'éditeur SQL de Supabase
-- =====================================================

-- 1. CRÉATION DES TABLES
-- =====================================================

-- Table profiles (informations utilisateurs)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  full_name TEXT NOT NULL,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table categories
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table chants
CREATE TABLE IF NOT EXISTS chants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titre TEXT NOT NULL,
  categorie TEXT NOT NULL,
  auteur TEXT NOT NULL,
  url_audio TEXT NOT NULL,
  duree INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table subscriptions (pour module futur)
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chorale_name TEXT NOT NULL,
  admin_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL CHECK (plan IN ('basic', 'premium', 'enterprise')),
  active_until TIMESTAMP NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'cancelled')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- 2. INSERTION DES DONNÉES PAR DÉFAUT
-- =====================================================

-- Insérer les catégories par défaut
INSERT INTO categories (nom) VALUES
  ('Répétition'),
  ('Messe'),
  ('Adoration'),
  ('Noël'),
  ('Pâques')
ON CONFLICT (nom) DO NOTHING;

-- 3. CONFIGURATION ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Activer RLS sur toutes les tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE chants ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- 4. POLITIQUES RLS POUR PROFILES
-- =====================================================

-- Tout le monde peut voir les profils
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
CREATE POLICY "Users can view all profiles"
  ON profiles FOR SELECT
  USING (true);

-- Les utilisateurs peuvent créer leur propre profil
DROP POLICY IF EXISTS "Users can create own profile" ON profiles;
CREATE POLICY "Users can create own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Les utilisateurs peuvent mettre à jour leur propre profil
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- 5. POLITIQUES RLS POUR CATEGORIES
-- =====================================================

-- Tout le monde peut voir les catégories
DROP POLICY IF EXISTS "Anyone can view categories" ON categories;
CREATE POLICY "Anyone can view categories"
  ON categories FOR SELECT
  USING (true);

-- Seuls les admins peuvent ajouter des catégories
DROP POLICY IF EXISTS "Admins can insert categories" ON categories;
CREATE POLICY "Admins can insert categories"
  ON categories FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Seuls les admins peuvent modifier des catégories
DROP POLICY IF EXISTS "Admins can update categories" ON categories;
CREATE POLICY "Admins can update categories"
  ON categories FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Seuls les admins peuvent supprimer des catégories
DROP POLICY IF EXISTS "Admins can delete categories" ON categories;
CREATE POLICY "Admins can delete categories"
  ON categories FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 6. POLITIQUES RLS POUR CHANTS
-- =====================================================

-- Tout le monde peut voir les chants
DROP POLICY IF EXISTS "Anyone can view chants" ON chants;
CREATE POLICY "Anyone can view chants"
  ON chants FOR SELECT
  USING (true);

-- Seuls les admins peuvent ajouter des chants
DROP POLICY IF EXISTS "Admins can insert chants" ON chants;
CREATE POLICY "Admins can insert chants"
  ON chants FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Seuls les admins peuvent modifier des chants
DROP POLICY IF EXISTS "Admins can update chants" ON chants;
CREATE POLICY "Admins can update chants"
  ON chants FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Seuls les admins peuvent supprimer des chants
DROP POLICY IF EXISTS "Admins can delete chants" ON chants;
CREATE POLICY "Admins can delete chants"
  ON chants FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 7. POLITIQUES RLS POUR SUBSCRIPTIONS
-- =====================================================

-- Les admins peuvent voir leurs abonnements
DROP POLICY IF EXISTS "Admins can view own subscriptions" ON subscriptions;
CREATE POLICY "Admins can view own subscriptions"
  ON subscriptions FOR SELECT
  USING (auth.uid() = admin_id);

-- Les admins peuvent créer des abonnements
DROP POLICY IF EXISTS "Admins can create subscriptions" ON subscriptions;
CREATE POLICY "Admins can create subscriptions"
  ON subscriptions FOR INSERT
  WITH CHECK (auth.uid() = admin_id);

-- 8. FONCTIONS ET TRIGGERS
-- =====================================================

-- Fonction pour créer automatiquement un profil lors de l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour appeler la fonction lors de l'inscription
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 9. INDEX POUR PERFORMANCES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_chants_categorie ON chants(categorie);
CREATE INDEX IF NOT EXISTS idx_chants_created_at ON chants(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_subscriptions_admin_id ON subscriptions(admin_id);

-- 10. CONFIGURATION STORAGE (à faire via l'interface ou API)
-- =====================================================

-- IMPORTANT: Allez dans Storage dans le dashboard Supabase et :
-- 1. Créez un bucket nommé "audio_files"
-- 2. Rendez-le public
-- 3. Définissez la taille max à 52428800 (50MB)

-- Ou utilisez le SQL suivant (peut nécessiter des permissions spéciales) :

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'audio_files',
  'audio_files',
  true,
  52428800,
  ARRAY['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/m4a']
)
ON CONFLICT (id) DO NOTHING;

-- Politiques Storage pour audio_files

DROP POLICY IF EXISTS "Anyone can view audio files" ON storage.objects;
CREATE POLICY "Anyone can view audio files"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'audio_files');

DROP POLICY IF EXISTS "Admins can upload audio files" ON storage.objects;
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

DROP POLICY IF EXISTS "Admins can delete audio files" ON storage.objects;
CREATE POLICY "Admins can delete audio files"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'audio_files' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- =====================================================
-- FIN DE LA CONFIGURATION
-- =====================================================

-- VÉRIFICATION : Exécutez cette requête pour vérifier que tout est bien créé
SELECT 
  'Tables' as type,
  COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('profiles', 'categories', 'chants', 'subscriptions')

UNION ALL

SELECT 
  'Categories' as type,
  COUNT(*) as count
FROM categories;

-- Pour créer votre premier admin, après inscription :
-- UPDATE profiles SET role = 'admin' WHERE user_id = 'VOTRE_USER_ID';

-- =====================================================
-- RESET: Supprimer et recréer les tables multi-tenant
-- =====================================================
-- Ce script supprime les tables du système multi-tenant
-- et les recrée proprement (garde chants et profiles)

-- =====================================================
-- 1. SUPPRIMER LES TABLES DU MULTI-TENANT
-- =====================================================

-- Supprimer dans l'ordre (à cause des foreign keys)
DROP TABLE IF EXISTS ecoutes CASCADE;
DROP TABLE IF EXISTS playlist_chants CASCADE;
DROP TABLE IF EXISTS playlists CASCADE;
DROP TABLE IF EXISTS favoris CASCADE;
DROP TABLE IF EXISTS membres CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS chorales CASCADE;
DROP TABLE IF EXISTS plans CASCADE;

-- ⚠️ NE PAS SUPPRIMER: chants, profiles (contiennent vos données)

-- =====================================================
-- 2. RECRÉER LES TABLES PROPREMENT
-- =====================================================

-- Table des plans
CREATE TABLE plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(50) NOT NULL UNIQUE,
    prix_mensuel DECIMAL(10,2) NOT NULL,
    max_membres INTEGER NOT NULL,
    max_chants INTEGER NOT NULL,
    max_stockage_mb INTEGER NOT NULL,
    features JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des chorales
CREATE TABLE chorales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    plan_id UUID,
    statut VARCHAR(20) DEFAULT 'actif',
    total_membres INTEGER DEFAULT 0,
    total_chants INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des membres
CREATE TABLE membres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chorale_id UUID,
    user_id UUID NOT NULL,
    role VARCHAR(20) DEFAULT 'membre',
    pupitre VARCHAR(50),
    statut VARCHAR(20) DEFAULT 'actif',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(chorale_id, user_id)
);

-- Table des subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chorale_id UUID,
    plan_id UUID,
    statut VARCHAR(20) DEFAULT 'actif',
    date_debut TIMESTAMPTZ DEFAULT NOW(),
    date_fin TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des favoris
CREATE TABLE favoris (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    chant_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, chant_id)
);

-- Table des playlists
CREATE TABLE playlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    nom VARCHAR(100) NOT NULL,
    description TEXT,
    publique BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table playlist_chants
CREATE TABLE playlist_chants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    playlist_id UUID NOT NULL,
    chant_id UUID NOT NULL,
    ordre INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(playlist_id, chant_id)
);

-- Table des écoutes
CREATE TABLE ecoutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    chant_id UUID NOT NULL,
    chorale_id UUID,
    duree_ecoute INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 3. CRÉER LES INDEXES
-- =====================================================

CREATE INDEX idx_membres_chorale ON membres(chorale_id);
CREATE INDEX idx_membres_user ON membres(user_id);
CREATE INDEX idx_favoris_user ON favoris(user_id);
CREATE INDEX idx_favoris_chant ON favoris(chant_id);
CREATE INDEX idx_playlists_user ON playlists(user_id);
CREATE INDEX idx_playlist_chants_playlist ON playlist_chants(playlist_id);
CREATE INDEX idx_playlist_chants_chant ON playlist_chants(chant_id);
CREATE INDEX idx_ecoutes_user ON ecoutes(user_id);
CREATE INDEX idx_ecoutes_chant ON ecoutes(chant_id);

-- =====================================================
-- 4. DÉSACTIVER RLS SUR TOUTES LES TABLES
-- =====================================================

ALTER TABLE plans DISABLE ROW LEVEL SECURITY;
ALTER TABLE chorales DISABLE ROW LEVEL SECURITY;
ALTER TABLE membres DISABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions DISABLE ROW LEVEL SECURITY;
ALTER TABLE favoris DISABLE ROW LEVEL SECURITY;
ALTER TABLE playlists DISABLE ROW LEVEL SECURITY;
ALTER TABLE playlist_chants DISABLE ROW LEVEL SECURITY;
ALTER TABLE ecoutes DISABLE ROW LEVEL SECURITY;

-- Désactiver aussi sur les tables existantes
ALTER TABLE IF EXISTS chants DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS profiles DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. SUPPRIMER TOUTES LES POLICIES RLS
-- =====================================================

-- Policies sur chants
DROP POLICY IF EXISTS "chants_select_policy" ON chants;
DROP POLICY IF EXISTS "chants_insert_policy" ON chants;
DROP POLICY IF EXISTS "chants_update_policy" ON chants;
DROP POLICY IF EXISTS "chants_delete_policy" ON chants;

-- Policies sur profiles
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;

-- =====================================================
-- 6. INSÉRER LES DONNÉES PAR DÉFAUT
-- =====================================================

-- Plans
INSERT INTO plans (nom, prix_mensuel, max_membres, max_chants, max_stockage_mb, features)
VALUES 
    ('Gratuit', 0, 10, 50, 100, '["Lecteur audio basique", "10 membres max", "50 chants max"]'::jsonb),
    ('Standard', 9.99, 50, 500, 1000, '["Lecteur audio avancé", "50 membres", "500 chants", "Playlists illimitées"]'::jsonb),
    ('Premium', 29.99, 200, 2000, 5000, '["Tout Standard", "200 membres", "2000 chants", "Support prioritaire"]'::jsonb),
    ('Entreprise', 99.99, 999999, 999999, 999999, '["Tout Premium", "Membres illimités", "Chants illimités", "Support dédié"]'::jsonb);

-- Chorale par défaut
INSERT INTO chorales (nom, slug, description, plan_id)
SELECT 
    'Ma Chorale',
    'ma-chorale',
    'Chorale par défaut',
    id
FROM plans
WHERE nom = 'Gratuit'
LIMIT 1;

-- =====================================================
-- 7. VÉRIFICATION FINALE
-- =====================================================

-- Lister les tables
SELECT tablename, rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Compter les plans
SELECT 'PLANS' as table_name, COUNT(*) as nombre FROM plans;

-- Compter les chorales
SELECT 'CHORALES' as table_name, COUNT(*) as nombre FROM chorales;

-- Compter les chants (vos données sont préservées)
SELECT 'CHANTS' as table_name, COUNT(*) as nombre FROM chants;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Tables multi-tenant recréées proprement
-- ✅ RLS désactivé partout
-- ✅ Aucune policy RLS
-- ✅ 4 plans créés
-- ✅ 1 chorale créée
-- ✅ Vos chants et profiles sont préservés

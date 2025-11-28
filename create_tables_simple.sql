-- =====================================================
-- CRÉATION SIMPLE DES TABLES (SANS FOREIGN KEYS COMPLEXES)
-- =====================================================
-- Version simplifiée qui évite les erreurs de foreign keys

-- =====================================================
-- 1. CRÉER LES TABLES DE BASE
-- =====================================================

-- Table des plans
CREATE TABLE IF NOT EXISTS plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(50) NOT NULL UNIQUE,
    prix_mensuel DECIMAL(10,2) NOT NULL,
    prix_annuel DECIMAL(10,2),
    max_membres INTEGER NOT NULL,
    max_chants INTEGER NOT NULL,
    max_stockage_mb INTEGER NOT NULL,
    features JSONB DEFAULT '[]'::jsonb,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des chorales
CREATE TABLE IF NOT EXISTS chorales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    logo_url TEXT,
    plan_id UUID,
    statut VARCHAR(20) DEFAULT 'actif',
    total_membres INTEGER DEFAULT 0,
    total_chants INTEGER DEFAULT 0,
    total_ecoutes INTEGER DEFAULT 0,
    stockage_utilise_mb DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des membres (sans foreign key vers auth.users)
CREATE TABLE IF NOT EXISTS membres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chorale_id UUID,
    user_id UUID NOT NULL,
    role VARCHAR(20) DEFAULT 'membre',
    pupitre VARCHAR(50),
    statut VARCHAR(20) DEFAULT 'actif',
    date_adhesion TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(chorale_id, user_id)
);

-- Table des subscriptions
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chorale_id UUID,
    plan_id UUID,
    statut VARCHAR(20) DEFAULT 'actif',
    date_debut TIMESTAMPTZ DEFAULT NOW(),
    date_fin TIMESTAMPTZ,
    auto_renouvellement BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des favoris (sans foreign key vers auth.users)
CREATE TABLE IF NOT EXISTS favoris (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    chant_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, chant_id)
);

-- Table des playlists (sans foreign key vers auth.users)
CREATE TABLE IF NOT EXISTS playlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    nom VARCHAR(100) NOT NULL,
    description TEXT,
    publique BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table de liaison playlist-chants
CREATE TABLE IF NOT EXISTS playlist_chants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    playlist_id UUID NOT NULL,
    chant_id UUID NOT NULL,
    ordre INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(playlist_id, chant_id)
);

-- Table des écoutes (sans foreign key vers auth.users)
CREATE TABLE IF NOT EXISTS ecoutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    chant_id UUID NOT NULL,
    chorale_id UUID,
    duree_ecoute INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 2. AJOUTER chorale_id À LA TABLE chants SI ELLE EXISTE
-- =====================================================

DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chants') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'chants' AND column_name = 'chorale_id'
        ) THEN
            ALTER TABLE chants ADD COLUMN chorale_id UUID;
        END IF;
    END IF;
END $$;

-- =====================================================
-- 3. CRÉER LES INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_membres_chorale ON membres(chorale_id);
CREATE INDEX IF NOT EXISTS idx_membres_user ON membres(user_id);
CREATE INDEX IF NOT EXISTS idx_favoris_user ON favoris(user_id);
CREATE INDEX IF NOT EXISTS idx_favoris_chant ON favoris(chant_id);
CREATE INDEX IF NOT EXISTS idx_playlists_user ON playlists(user_id);
CREATE INDEX IF NOT EXISTS idx_playlist_chants_playlist ON playlist_chants(playlist_id);
CREATE INDEX IF NOT EXISTS idx_playlist_chants_chant ON playlist_chants(chant_id);
CREATE INDEX IF NOT EXISTS idx_ecoutes_user ON ecoutes(user_id);
CREATE INDEX IF NOT EXISTS idx_ecoutes_chant ON ecoutes(chant_id);
CREATE INDEX IF NOT EXISTS idx_ecoutes_chorale ON ecoutes(chorale_id);

-- =====================================================
-- 4. INSÉRER LES PLANS PAR DÉFAUT
-- =====================================================

INSERT INTO plans (nom, prix_mensuel, prix_annuel, max_membres, max_chants, max_stockage_mb, features)
VALUES 
    ('Gratuit', 0, 0, 10, 50, 100, '["Lecteur audio basique", "10 membres max", "50 chants max"]'::jsonb),
    ('Standard', 9.99, 99.99, 50, 500, 1000, '["Lecteur audio avancé", "50 membres", "500 chants"]'::jsonb),
    ('Premium', 29.99, 299.99, 200, 2000, 5000, '["Tout Standard", "200 membres", "2000 chants"]'::jsonb),
    ('Entreprise', 99.99, 999.99, 999999, 999999, 999999, '["Tout Premium", "Membres illimités"]'::jsonb)
ON CONFLICT (nom) DO NOTHING;

-- =====================================================
-- 5. CRÉER UNE CHORALE PAR DÉFAUT
-- =====================================================

INSERT INTO chorales (nom, slug, description, plan_id)
SELECT 
    'Ma Chorale',
    'ma-chorale',
    'Chorale par défaut',
    id
FROM plans
WHERE nom = 'Gratuit'
LIMIT 1
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- 6. DÉSACTIVER RLS SUR TOUTES LES TABLES
-- =====================================================

ALTER TABLE IF EXISTS plans DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS chorales DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS membres DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS subscriptions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS chants DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS favoris DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS playlists DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS playlist_chants DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ecoutes DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 7. SUPPRIMER TOUTES LES POLICIES RLS
-- =====================================================

-- Membres
DROP POLICY IF EXISTS "membres_select_policy" ON membres;
DROP POLICY IF EXISTS "membres_insert_policy" ON membres;
DROP POLICY IF EXISTS "membres_update_policy" ON membres;
DROP POLICY IF EXISTS "membres_delete_policy" ON membres;

-- Chorales
DROP POLICY IF EXISTS "chorales_select_policy" ON chorales;
DROP POLICY IF EXISTS "chorales_insert_policy" ON chorales;
DROP POLICY IF EXISTS "chorales_update_policy" ON chorales;
DROP POLICY IF EXISTS "chorales_delete_policy" ON chorales;

-- Chants
DROP POLICY IF EXISTS "chants_select_policy" ON chants;
DROP POLICY IF EXISTS "chants_insert_policy" ON chants;
DROP POLICY IF EXISTS "chants_update_policy" ON chants;
DROP POLICY IF EXISTS "chants_delete_policy" ON chants;

-- Favoris
DROP POLICY IF EXISTS "favoris_select_policy" ON favoris;
DROP POLICY IF EXISTS "favoris_insert_policy" ON favoris;
DROP POLICY IF EXISTS "favoris_delete_policy" ON favoris;

-- Playlists
DROP POLICY IF EXISTS "playlists_select_policy" ON playlists;
DROP POLICY IF EXISTS "playlists_insert_policy" ON playlists;
DROP POLICY IF EXISTS "playlists_update_policy" ON playlists;
DROP POLICY IF EXISTS "playlists_delete_policy" ON playlists;

-- =====================================================
-- 8. VÉRIFICATION FINALE
-- =====================================================

-- Lister toutes les tables
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Vérifier les plans
SELECT nom, prix_mensuel, max_membres, max_chants FROM plans ORDER BY prix_mensuel;

-- Vérifier les chorales
SELECT nom, slug, statut FROM chorales;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Toutes les tables créées
-- ✅ RLS désactivé partout
-- ✅ 4 plans créés
-- ✅ 1 chorale "Ma Chorale" créée
-- ✅ Pas d'erreur de foreign key

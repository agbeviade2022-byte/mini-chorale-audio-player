-- =====================================================
-- CRÉATION CONDITIONNELLE DES TABLES MANQUANTES
-- =====================================================
-- Ce script crée uniquement les tables qui n'existent pas encore

-- =====================================================
-- 1. CRÉER LES TABLES SI ELLES N'EXISTENT PAS
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
    plan_id UUID REFERENCES plans(id),
    statut VARCHAR(20) DEFAULT 'actif' CHECK (statut IN ('actif', 'suspendu', 'archive')),
    total_membres INTEGER DEFAULT 0,
    total_chants INTEGER DEFAULT 0,
    total_ecoutes INTEGER DEFAULT 0,
    stockage_utilise_mb DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des membres
CREATE TABLE IF NOT EXISTS membres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chorale_id UUID REFERENCES chorales(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    role VARCHAR(20) DEFAULT 'membre' CHECK (role IN ('membre', 'chef_pupitre', 'admin', 'super_admin')),
    pupitre VARCHAR(50),
    statut VARCHAR(20) DEFAULT 'actif' CHECK (statut IN ('actif', 'inactif', 'suspendu')),
    date_adhesion TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(chorale_id, user_id)
);

-- Table des subscriptions
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chorale_id UUID REFERENCES chorales(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES plans(id),
    statut VARCHAR(20) DEFAULT 'actif' CHECK (statut IN ('actif', 'annule', 'expire', 'suspendu')),
    date_debut TIMESTAMPTZ DEFAULT NOW(),
    date_fin TIMESTAMPTZ,
    auto_renouvellement BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des favoris
CREATE TABLE IF NOT EXISTS favoris (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    chant_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, chant_id)
);

-- Table des playlists
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
    playlist_id UUID REFERENCES playlists(id) ON DELETE CASCADE,
    chant_id UUID,
    ordre INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(playlist_id, chant_id)
);

-- Table des écoutes
CREATE TABLE IF NOT EXISTS ecoutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    chant_id UUID,
    chorale_id UUID REFERENCES chorales(id) ON DELETE CASCADE,
    duree_ecoute INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 2. AJOUTER LA COLONNE chorale_id À chants SI MANQUANTE
-- =====================================================

DO $$ 
BEGIN
    -- Vérifier si la table chants existe
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chants') THEN
        -- Ajouter la colonne chorale_id si elle n'existe pas
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'chants' AND column_name = 'chorale_id'
        ) THEN
            ALTER TABLE chants ADD COLUMN chorale_id UUID REFERENCES chorales(id) ON DELETE CASCADE;
            RAISE NOTICE 'Colonne chorale_id ajoutée à la table chants';
        ELSE
            RAISE NOTICE 'Colonne chorale_id existe déjà dans chants';
        END IF;
    ELSE
        RAISE NOTICE 'Table chants n''existe pas encore';
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
CREATE INDEX IF NOT EXISTS idx_ecoutes_user ON ecoutes(user_id);
CREATE INDEX IF NOT EXISTS idx_ecoutes_chant ON ecoutes(chant_id);
CREATE INDEX IF NOT EXISTS idx_ecoutes_chorale ON ecoutes(chorale_id);

-- =====================================================
-- 4. INSÉRER LES PLANS PAR DÉFAUT
-- =====================================================

INSERT INTO plans (nom, prix_mensuel, prix_annuel, max_membres, max_chants, max_stockage_mb, features)
VALUES 
    ('Gratuit', 0, 0, 10, 50, 100, '["Lecteur audio basique", "10 membres max", "50 chants max"]'::jsonb),
    ('Standard', 9.99, 99.99, 50, 500, 1000, '["Lecteur audio avancé", "50 membres", "500 chants", "Playlists illimitées"]'::jsonb),
    ('Premium', 29.99, 299.99, 200, 2000, 5000, '["Tout Standard", "200 membres", "2000 chants", "Support prioritaire"]'::jsonb),
    ('Entreprise', 99.99, 999.99, 999999, 999999, 999999, '["Tout Premium", "Membres illimités", "Support dédié"]'::jsonb)
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
-- 7. SUPPRIMER LES POLICIES RLS PROBLÉMATIQUES
-- =====================================================

DROP POLICY IF EXISTS "membres_select_policy" ON membres;
DROP POLICY IF EXISTS "membres_insert_policy" ON membres;
DROP POLICY IF EXISTS "membres_update_policy" ON membres;
DROP POLICY IF EXISTS "membres_delete_policy" ON membres;
DROP POLICY IF EXISTS "check_plan_limits_policy" ON membres;

DROP POLICY IF EXISTS "chorales_select_policy" ON chorales;
DROP POLICY IF EXISTS "chorales_insert_policy" ON chorales;
DROP POLICY IF EXISTS "chorales_update_policy" ON chorales;
DROP POLICY IF EXISTS "chorales_delete_policy" ON chorales;

DROP POLICY IF EXISTS "chants_select_policy" ON chants;
DROP POLICY IF EXISTS "chants_insert_policy" ON chants;
DROP POLICY IF EXISTS "chants_update_policy" ON chants;
DROP POLICY IF EXISTS "chants_delete_policy" ON chants;

DROP POLICY IF EXISTS "favoris_select_policy" ON favoris;
DROP POLICY IF EXISTS "favoris_insert_policy" ON favoris;
DROP POLICY IF EXISTS "favoris_delete_policy" ON favoris;

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
SELECT nom, prix_mensuel, max_membres FROM plans ORDER BY prix_mensuel;

-- Vérifier les chorales
SELECT nom, slug, statut FROM chorales;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Toutes les tables créées ou déjà existantes
-- ✅ RLS désactivé partout (rls_enabled = false)
-- ✅ 4 plans créés
-- ✅ 1 chorale "Ma Chorale" créée
-- ✅ Pas de policies RLS problématiques

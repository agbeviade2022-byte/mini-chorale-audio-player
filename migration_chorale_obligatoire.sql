-- =====================================================
-- MIGRATION : CHORALE OBLIGATOIRE POUR TOUS LES UTILISATEURS
-- =====================================================
-- Ce script ajoute la contrainte d'appartenance obligatoire à une chorale
-- pour tous les utilisateurs (admin et membres)
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : CRÉER LA TABLE CHORALES SI ELLE N'EXISTE PAS
-- =====================================================

CREATE TABLE IF NOT EXISTS chorales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(255) NOT NULL UNIQUE,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    logo_url TEXT,
    couleur_theme VARCHAR(7) DEFAULT '#6366F1',
    email_contact VARCHAR(255),
    telephone VARCHAR(50),
    adresse TEXT,
    ville VARCHAR(100),
    pays VARCHAR(100) DEFAULT 'France',
    site_web TEXT,
    nombre_membres INTEGER DEFAULT 0,
    statut VARCHAR(20) DEFAULT 'actif' CHECK (statut IN ('actif', 'inactif', 'suspendu')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_chorales_slug ON chorales(slug);
CREATE INDEX IF NOT EXISTS idx_chorales_statut ON chorales(statut);

-- =====================================================
-- ÉTAPE 2 : CRÉER UNE CHORALE PAR DÉFAUT
-- =====================================================

INSERT INTO chorales (nom, slug, description, statut)
VALUES (
    'Chorale Principale',
    'chorale-principale',
    'Chorale par défaut pour tous les nouveaux membres',
    'actif'
)
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- ÉTAPE 3 : AJOUTER LA COLONNE chorale_id À profiles
-- =====================================================

-- Ajouter la colonne si elle n'existe pas
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS chorale_id UUID REFERENCES chorales(id) ON DELETE SET NULL;

-- Mettre à jour les profils existants avec la chorale par défaut
UPDATE profiles 
SET chorale_id = (SELECT id FROM chorales WHERE slug = 'chorale-principale' LIMIT 1)
WHERE chorale_id IS NULL;

-- Rendre la colonne obligatoire APRÈS avoir mis à jour les données existantes
ALTER TABLE profiles ALTER COLUMN chorale_id SET NOT NULL;

-- Ajouter des colonnes supplémentaires utiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pupitre VARCHAR(50);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS telephone VARCHAR(50);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS date_adhesion TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS statut_membre VARCHAR(20) DEFAULT 'actif' CHECK (statut_membre IN ('actif', 'inactif', 'suspendu'));

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_profiles_chorale ON profiles(chorale_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_statut ON profiles(statut_membre);

-- =====================================================
-- ÉTAPE 4 : CRÉER LA TABLE INVITATIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chorale_id UUID NOT NULL REFERENCES chorales(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin')),
    pupitre VARCHAR(50),
    token VARCHAR(255) NOT NULL UNIQUE,
    invite_par UUID REFERENCES profiles(id) ON DELETE SET NULL,
    statut VARCHAR(20) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'acceptee', 'expiree', 'annulee')),
    expire_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(chorale_id, email)
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_invitations_chorale ON invitations(chorale_id);
CREATE INDEX IF NOT EXISTS idx_invitations_email ON invitations(email);
CREATE INDEX IF NOT EXISTS idx_invitations_token ON invitations(token);
CREATE INDEX IF NOT EXISTS idx_invitations_statut ON invitations(statut, expire_at);

-- =====================================================
-- ÉTAPE 5 : METTRE À JOUR LES RLS POLICIES
-- =====================================================

-- Supprimer les anciennes policies si elles existent
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leur profil" ON profiles;
DROP POLICY IF EXISTS "Utilisateurs peuvent modifier leur profil" ON profiles;
DROP POLICY IF EXISTS "Admins peuvent voir tous les profils" ON profiles;

-- Activer RLS sur profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy : Les utilisateurs peuvent voir leur propre profil
CREATE POLICY "Utilisateurs peuvent voir leur profil"
ON profiles FOR SELECT
USING (auth.uid() = user_id);

-- Policy : Les utilisateurs peuvent voir les profils de leur chorale
CREATE POLICY "Utilisateurs voient profils de leur chorale"
ON profiles FOR SELECT
USING (
    chorale_id IN (
        SELECT chorale_id FROM profiles WHERE user_id = auth.uid()
    )
);

-- Policy : Les utilisateurs peuvent modifier leur propre profil
CREATE POLICY "Utilisateurs peuvent modifier leur profil"
ON profiles FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy : Les admins peuvent voir tous les profils de leur chorale
CREATE POLICY "Admins voient tous profils de leur chorale"
ON profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid()
        AND p.chorale_id = profiles.chorale_id
        AND p.role IN ('admin', 'super_admin')
    )
);

-- Policy : Les admins peuvent modifier les profils de leur chorale
CREATE POLICY "Admins modifient profils de leur chorale"
ON profiles FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid()
        AND p.chorale_id = profiles.chorale_id
        AND p.role IN ('admin', 'super_admin')
    )
);

-- RLS pour chorales
ALTER TABLE chorales ENABLE ROW LEVEL SECURITY;

-- Policy : Les utilisateurs peuvent voir leur chorale
CREATE POLICY "Utilisateurs voient leur chorale"
ON chorales FOR SELECT
USING (
    id IN (
        SELECT chorale_id FROM profiles WHERE user_id = auth.uid()
    )
);

-- Policy : Les admins peuvent modifier leur chorale
CREATE POLICY "Admins modifient leur chorale"
ON chorales FOR UPDATE
USING (
    id IN (
        SELECT chorale_id FROM profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

-- RLS pour invitations
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- Policy : Les admins peuvent créer des invitations pour leur chorale
CREATE POLICY "Admins créent invitations"
ON invitations FOR INSERT
WITH CHECK (
    chorale_id IN (
        SELECT chorale_id FROM profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

-- Policy : Les admins peuvent voir les invitations de leur chorale
CREATE POLICY "Admins voient invitations de leur chorale"
ON invitations FOR SELECT
USING (
    chorale_id IN (
        SELECT chorale_id FROM profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

-- Policy : Les invités peuvent voir leur invitation par token
CREATE POLICY "Invités voient leur invitation"
ON invitations FOR SELECT
USING (true); -- Accessible publiquement par token (vérification dans l'app)

-- =====================================================
-- ÉTAPE 6 : CRÉER DES FONCTIONS UTILES
-- =====================================================

-- Fonction pour générer un token d'invitation unique
CREATE OR REPLACE FUNCTION generate_invitation_token()
RETURNS TEXT AS $$
BEGIN
    RETURN encode(gen_random_bytes(32), 'hex');
END;
$$ LANGUAGE plpgsql;

-- Fonction pour mettre à jour le nombre de membres d'une chorale
CREATE OR REPLACE FUNCTION update_chorale_membres_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE chorales 
        SET nombre_membres = nombre_membres + 1,
            updated_at = NOW()
        WHERE id = NEW.chorale_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE chorales 
        SET nombre_membres = GREATEST(nombre_membres - 1, 0),
            updated_at = NOW()
        WHERE id = OLD.chorale_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.chorale_id != NEW.chorale_id THEN
        UPDATE chorales 
        SET nombre_membres = GREATEST(nombre_membres - 1, 0),
            updated_at = NOW()
        WHERE id = OLD.chorale_id;
        
        UPDATE chorales 
        SET nombre_membres = nombre_membres + 1,
            updated_at = NOW()
        WHERE id = NEW.chorale_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour automatiquement le nombre de membres
DROP TRIGGER IF EXISTS trigger_update_chorale_membres ON profiles;
CREATE TRIGGER trigger_update_chorale_membres
AFTER INSERT OR UPDATE OR DELETE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_chorale_membres_count();

-- Fonction pour expirer automatiquement les invitations
CREATE OR REPLACE FUNCTION expire_old_invitations()
RETURNS void AS $$
BEGIN
    UPDATE invitations
    SET statut = 'expiree'
    WHERE statut = 'en_attente'
    AND expire_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ÉTAPE 7 : METTRE À JOUR LE TRIGGER DE CRÉATION DE PROFIL
-- =====================================================

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Créer une nouvelle fonction qui attend une invitation ou une chorale par défaut
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_chorale_id UUID;
    invitation_record RECORD;
BEGIN
    -- Chercher une invitation valide pour cet email
    SELECT * INTO invitation_record
    FROM invitations
    WHERE email = NEW.email
    AND statut = 'en_attente'
    AND expire_at > NOW()
    LIMIT 1;

    -- Si une invitation existe, utiliser ses informations
    IF FOUND THEN
        INSERT INTO public.profiles (user_id, full_name, role, chorale_id, pupitre, statut_membre)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
            invitation_record.role,
            invitation_record.chorale_id,
            invitation_record.pupitre,
            'actif'
        );
        
        -- Marquer l'invitation comme acceptée
        UPDATE invitations
        SET statut = 'acceptee'
        WHERE id = invitation_record.id;
    ELSE
        -- Sinon, utiliser la chorale par défaut
        SELECT id INTO default_chorale_id
        FROM chorales
        WHERE slug = 'chorale-principale'
        LIMIT 1;

        INSERT INTO public.profiles (user_id, full_name, role, chorale_id, statut_membre)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
            'user',
            default_chorale_id,
            'actif'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ÉTAPE 8 : VÉRIFICATIONS FINALES
-- =====================================================

-- Vérifier que tous les profils ont une chorale
DO $$
DECLARE
    profiles_sans_chorale INTEGER;
BEGIN
    SELECT COUNT(*) INTO profiles_sans_chorale
    FROM profiles
    WHERE chorale_id IS NULL;
    
    IF profiles_sans_chorale > 0 THEN
        RAISE NOTICE '⚠️ ATTENTION : % profils sans chorale trouvés !', profiles_sans_chorale;
    ELSE
        RAISE NOTICE '✅ Tous les profils ont une chorale assignée';
    END IF;
END $$;

-- Afficher un résumé
SELECT 
    '✅ MIGRATION TERMINÉE' as statut,
    (SELECT COUNT(*) FROM chorales) as nombre_chorales,
    (SELECT COUNT(*) FROM profiles) as nombre_profils,
    (SELECT COUNT(*) FROM invitations) as nombre_invitations;

-- =====================================================
-- FIN DE LA MIGRATION
-- =====================================================

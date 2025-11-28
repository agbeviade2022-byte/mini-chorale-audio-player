-- =====================================================
-- MIGRATION : Système de validation des membres par admin
-- VERSION EXÉCUTABLE (sans exemples)
-- =====================================================
-- Exécutez ce script dans Supabase SQL Editor
-- =====================================================

-- ÉTAPE 1 : Ajouter le champ statut_validation
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS statut_validation VARCHAR(20) DEFAULT 'en_attente';

-- Mettre à jour les utilisateurs existants comme validés
UPDATE profiles 
SET statut_validation = 'valide' 
WHERE statut_validation IS NULL OR statut_validation = 'en_attente';

-- ÉTAPE 2 : Rendre chorale_id NULLABLE
ALTER TABLE profiles 
ALTER COLUMN chorale_id DROP NOT NULL;

-- ÉTAPE 3 : Créer la table validations_membres
CREATE TABLE IF NOT EXISTS validations_membres (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    validateur_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    chorale_id UUID REFERENCES chorales(id) ON DELETE SET NULL,
    ancien_statut VARCHAR(20),
    nouveau_statut VARCHAR(20) NOT NULL,
    commentaire TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_validations_user_id ON validations_membres(user_id);
CREATE INDEX IF NOT EXISTS idx_validations_validateur_id ON validations_membres(validateur_id);
CREATE INDEX IF NOT EXISTS idx_validations_created_at ON validations_membres(created_at DESC);

-- ÉTAPE 4 : RLS pour validations_membres
ALTER TABLE validations_membres ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins voient toutes les validations" ON validations_membres;
CREATE POLICY "Admins voient toutes les validations"
ON validations_membres FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

DROP POLICY IF EXISTS "Admins créent des validations" ON validations_membres;
CREATE POLICY "Admins créent des validations"
ON validations_membres FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

-- ÉTAPE 5 : Fonction valider_membre
CREATE OR REPLACE FUNCTION valider_membre(
    p_user_id UUID,
    p_chorale_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_ancien_statut VARCHAR(20);
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = p_validateur_id 
        AND role IN ('admin', 'super_admin')
    ) THEN
        RAISE EXCEPTION 'Seuls les admins peuvent valider des membres';
    END IF;

    SELECT statut_validation INTO v_ancien_statut
    FROM profiles
    WHERE user_id = p_user_id;

    UPDATE profiles
    SET 
        chorale_id = p_chorale_id,
        statut_validation = 'valide',
        statut_membre = 'actif',
        updated_at = NOW()
    WHERE user_id = p_user_id;

    INSERT INTO validations_membres (
        user_id,
        validateur_id,
        chorale_id,
        ancien_statut,
        nouveau_statut,
        commentaire
    ) VALUES (
        p_user_id,
        p_validateur_id,
        p_chorale_id,
        v_ancien_statut,
        'valide',
        p_commentaire
    );

    RETURN TRUE;
END;
$$;

-- ÉTAPE 6 : Fonction refuser_membre
CREATE OR REPLACE FUNCTION refuser_membre(
    p_user_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_ancien_statut VARCHAR(20);
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = p_validateur_id 
        AND role IN ('admin', 'super_admin')
    ) THEN
        RAISE EXCEPTION 'Seuls les admins peuvent refuser des membres';
    END IF;

    SELECT statut_validation INTO v_ancien_statut
    FROM profiles
    WHERE user_id = p_user_id;

    UPDATE profiles
    SET 
        statut_validation = 'refuse',
        statut_membre = 'inactif',
        updated_at = NOW()
    WHERE user_id = p_user_id;

    INSERT INTO validations_membres (
        user_id,
        validateur_id,
        chorale_id,
        ancien_statut,
        nouveau_statut,
        commentaire
    ) VALUES (
        p_user_id,
        p_validateur_id,
        NULL,
        v_ancien_statut,
        'refuse',
        p_commentaire
    );

    RETURN TRUE;
END;
$$;

-- ÉTAPE 7 : RLS POLICIES pour chants
DROP POLICY IF EXISTS "Utilisateurs voient chants de leur chorale" ON chants;
DROP POLICY IF EXISTS "Enable read access for all users" ON chants;
DROP POLICY IF EXISTS "Public peut voir les chants" ON chants;
DROP POLICY IF EXISTS "Membres validés voient chants de leur chorale" ON chants;
DROP POLICY IF EXISTS "Admins voient tous les chants" ON chants;

CREATE POLICY "Membres validés voient chants de leur chorale"
ON chants FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = auth.uid() 
        AND chorale_id = chants.chorale_id
        AND statut_validation = 'valide'
        AND statut_membre = 'actif'
    )
);

CREATE POLICY "Admins voient tous les chants"
ON chants FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

-- ÉTAPE 8 : RLS POLICIES pour profiles
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leur profil" ON profiles;
DROP POLICY IF EXISTS "Utilisateurs voient profils de leur chorale" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Utilisateurs voient leur profil" ON profiles;
DROP POLICY IF EXISTS "Admins voient tous les profils" ON profiles;
DROP POLICY IF EXISTS "Utilisateurs modifient leur profil" ON profiles;
DROP POLICY IF EXISTS "Admins modifient tous les profils" ON profiles;

CREATE POLICY "Utilisateurs voient leur profil"
ON profiles FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Admins voient tous les profils"
ON profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role IN ('admin', 'super_admin')
    )
);

CREATE POLICY "Utilisateurs modifient leur profil"
ON profiles FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (
    user_id = auth.uid() 
    AND chorale_id = (SELECT chorale_id FROM profiles WHERE user_id = auth.uid())
    AND statut_validation = (SELECT statut_validation FROM profiles WHERE user_id = auth.uid())
);

CREATE POLICY "Admins modifient tous les profils"
ON profiles FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role IN ('admin', 'super_admin')
    )
);

-- ÉTAPE 9 : Trigger pour créer un profil en attente
CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO profiles (
        user_id,
        full_name,
        role,
        statut_validation,
        statut_membre,
        chorale_id
    ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
        'membre',
        'en_attente',
        'inactif',
        NULL
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_on_signup();

-- ÉTAPE 10 : Vue membres_en_attente
CREATE OR REPLACE VIEW membres_en_attente AS
SELECT 
    p.user_id,
    au.email,
    p.full_name,
    p.telephone,
    p.statut_validation,
    p.created_at,
    EXTRACT(DAY FROM NOW() - p.created_at) as jours_attente
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
ORDER BY p.created_at ASC;

-- ÉTAPE 11 : Vue stats_validations
CREATE OR REPLACE VIEW stats_validations AS
SELECT 
    COUNT(*) FILTER (WHERE statut_validation = 'en_attente') as en_attente,
    COUNT(*) FILTER (WHERE statut_validation = 'valide') as valides,
    COUNT(*) FILTER (WHERE statut_validation = 'refuse') as refuses,
    COUNT(*) as total
FROM profiles
WHERE role = 'membre';

-- ÉTAPE 12 : Permissions sur les vues
GRANT SELECT ON membres_en_attente TO authenticated;
GRANT SELECT ON stats_validations TO authenticated;

-- ÉTAPE 13 : Fonction pour le dashboard admin (récupérer users avec emails)
DROP FUNCTION IF EXISTS get_all_users_with_emails();

CREATE OR REPLACE FUNCTION get_all_users_with_emails()
RETURNS TABLE (
    id UUID,
    user_id UUID,
    full_name TEXT,
    role VARCHAR(20),
    email TEXT,
    telephone VARCHAR(20),
    chorale_id UUID,
    statut_validation VARCHAR(20),
    statut_membre VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.user_id = auth.uid() 
        AND profiles.role IN ('admin', 'super_admin')
    ) THEN
        RAISE EXCEPTION 'Accès refusé: seuls les admins peuvent voir tous les utilisateurs';
    END IF;

    RETURN QUERY
    SELECT 
        p.user_id as id,
        p.user_id,
        p.full_name,
        p.role,
        au.email,
        p.telephone,
        p.chorale_id,
        p.statut_validation,
        p.statut_membre,
        p.created_at,
        p.updated_at
    FROM profiles p
    LEFT JOIN auth.users au ON p.user_id = au.id
    ORDER BY p.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_all_users_with_emails() TO authenticated;

-- =====================================================
-- VÉRIFICATIONS
-- =====================================================

SELECT 'Migration terminée avec succès !' as status;

-- Voir les membres en attente
SELECT * FROM membres_en_attente;

-- Voir les statistiques
SELECT * FROM stats_validations;

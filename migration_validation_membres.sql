-- =====================================================
-- MIGRATION : Système de validation des membres par admin
-- =====================================================
-- Ce script met en place un système où :
-- 1. Les nouveaux utilisateurs s'inscrivent SANS choisir de chorale
-- 2. Leur email est confirmé automatiquement par Supabase
-- 3. Ils n'ont PAS accès aux chants tant qu'un admin ne les valide pas
-- 4. Seuls les admins/super_admins peuvent attribuer une chorale et valider
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : Ajouter le champ statut_validation
-- =====================================================

-- Ajouter la colonne statut_validation si elle n'existe pas
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS statut_validation VARCHAR(20) DEFAULT 'en_attente';

-- Valeurs possibles : 'en_attente', 'valide', 'refuse'

-- Mettre à jour les utilisateurs existants comme validés
UPDATE profiles 
SET statut_validation = 'valide' 
WHERE statut_validation IS NULL OR statut_validation = 'en_attente';

-- =====================================================
-- ÉTAPE 2 : Modifier la contrainte chorale_id (OPTIONNEL)
-- =====================================================

-- Rendre chorale_id NULLABLE pour permettre l'inscription sans chorale
ALTER TABLE profiles 
ALTER COLUMN chorale_id DROP NOT NULL;

-- =====================================================
-- ÉTAPE 3 : Créer une table pour l'historique des validations
-- =====================================================

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

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_validations_user_id ON validations_membres(user_id);
CREATE INDEX IF NOT EXISTS idx_validations_validateur_id ON validations_membres(validateur_id);
CREATE INDEX IF NOT EXISTS idx_validations_created_at ON validations_membres(created_at DESC);

-- =====================================================
-- ÉTAPE 4 : RLS pour la table validations_membres
-- =====================================================

ALTER TABLE validations_membres ENABLE ROW LEVEL SECURITY;

-- Les admins et super_admins peuvent voir toutes les validations
CREATE POLICY "Admins voient toutes les validations"
ON validations_membres FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

-- Seuls les admins et super_admins peuvent créer des validations
CREATE POLICY "Admins créent des validations"
ON validations_membres FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

-- =====================================================
-- ÉTAPE 5 : Fonction pour valider un membre
-- =====================================================

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
    -- Vérifier que le validateur est admin ou super_admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = p_validateur_id 
        AND role IN ('admin', 'super_admin')
    ) THEN
        RAISE EXCEPTION 'Seuls les admins peuvent valider des membres';
    END IF;

    -- Récupérer l'ancien statut
    SELECT statut_validation INTO v_ancien_statut
    FROM profiles
    WHERE user_id = p_user_id;

    -- Mettre à jour le profil
    UPDATE profiles
    SET 
        chorale_id = p_chorale_id,
        statut_validation = 'valide',
        statut_membre = 'actif',
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Enregistrer dans l'historique
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

-- =====================================================
-- ÉTAPE 6 : Fonction pour refuser un membre
-- =====================================================

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
    -- Vérifier que le validateur est admin ou super_admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = p_validateur_id 
        AND role IN ('admin', 'super_admin')
    ) THEN
        RAISE EXCEPTION 'Seuls les admins peuvent refuser des membres';
    END IF;

    -- Récupérer l'ancien statut
    SELECT statut_validation INTO v_ancien_statut
    FROM profiles
    WHERE user_id = p_user_id;

    -- Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'refuse',
        statut_membre = 'inactif',
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Enregistrer dans l'historique
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

-- =====================================================
-- ÉTAPE 7 : RLS POLICIES STRICTES pour les chants
-- =====================================================

-- Supprimer les anciennes policies sur chants
DROP POLICY IF EXISTS "Utilisateurs voient chants de leur chorale" ON chants;
DROP POLICY IF EXISTS "Enable read access for all users" ON chants;
DROP POLICY IF EXISTS "Public peut voir les chants" ON chants;

-- NOUVELLE POLICY : Seuls les membres VALIDÉS peuvent voir les chants
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

-- Les admins et super_admins voient tous les chants
CREATE POLICY "Admins voient tous les chants"
ON chants FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

-- =====================================================
-- ÉTAPE 8 : RLS POLICIES pour les profiles
-- =====================================================

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leur profil" ON profiles;
DROP POLICY IF EXISTS "Utilisateurs voient profils de leur chorale" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;

-- Les utilisateurs peuvent voir leur propre profil
CREATE POLICY "Utilisateurs voient leur profil"
ON profiles FOR SELECT
USING (user_id = auth.uid());

-- Les admins voient tous les profils
CREATE POLICY "Admins voient tous les profils"
ON profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role IN ('admin', 'super_admin')
    )
);

-- Les utilisateurs peuvent modifier leur propre profil (sauf chorale_id et statut_validation)
CREATE POLICY "Utilisateurs modifient leur profil"
ON profiles FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (
    user_id = auth.uid() 
    AND chorale_id = (SELECT chorale_id FROM profiles WHERE user_id = auth.uid())
    AND statut_validation = (SELECT statut_validation FROM profiles WHERE user_id = auth.uid())
);

-- Les admins peuvent modifier tous les profils
CREATE POLICY "Admins modifient tous les profils"
ON profiles FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role IN ('admin', 'super_admin')
    )
);

-- =====================================================
-- ÉTAPE 9 : Trigger pour créer un profil en attente
-- =====================================================

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
        'en_attente',  -- Par défaut en attente
        'inactif',     -- Inactif tant que non validé
        NULL           -- Pas de chorale assignée
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$;

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Créer le nouveau trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_on_signup();

-- =====================================================
-- ÉTAPE 10 : Vue pour les membres en attente
-- =====================================================

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

-- =====================================================
-- ÉTAPE 11 : Statistiques pour les admins
-- =====================================================

CREATE OR REPLACE VIEW stats_validations AS
SELECT 
    COUNT(*) FILTER (WHERE statut_validation = 'en_attente') as en_attente,
    COUNT(*) FILTER (WHERE statut_validation = 'valide') as valides,
    COUNT(*) FILTER (WHERE statut_validation = 'refuse') as refuses,
    COUNT(*) as total
FROM profiles
WHERE role = 'membre';

-- =====================================================
-- ÉTAPE 12 : Configurer Supabase pour confirmer les emails automatiquement
-- =====================================================

/*
IMPORTANT : Dans le dashboard Supabase, allez dans :
Authentication > Settings > Email Auth

Et configurez :
1. Enable email confirmations : ON (pour la sécurité)
2. Confirm email : ON
3. Secure email change : ON

Mais dans votre application Flutter, après l'inscription :
- L'utilisateur reçoit un email de confirmation
- Il clique sur le lien
- Son email est confirmé par Supabase
- MAIS il n'a toujours pas accès aux chants (statut_validation = 'en_attente')
- Il voit un écran d'attente jusqu'à validation par admin
*/

-- =====================================================
-- VÉRIFICATIONS
-- =====================================================

-- Vérifier les colonnes de profiles
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
AND column_name IN ('chorale_id', 'statut_validation', 'statut_membre')
ORDER BY ordinal_position;

-- Vérifier les policies sur chants
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename = 'chants'
ORDER BY policyname;

-- Vérifier les policies sur profiles
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Voir les membres en attente
SELECT * FROM membres_en_attente;

-- Voir les statistiques
SELECT * FROM stats_validations;

-- =====================================================
-- EXEMPLES D'UTILISATION (NE PAS EXÉCUTER - JUSTE POUR RÉFÉRENCE)
-- =====================================================

/*
-- Exemple 1 : Valider un membre et l'assigner à une chorale
SELECT valider_membre(
    'user-id-ici'::UUID,           -- ID de l'utilisateur à valider
    'chorale-id-ici'::UUID,        -- ID de la chorale à assigner
    auth.uid(),                     -- ID du validateur (vous)
    'Membre validé après vérification des documents'  -- Commentaire
);

-- Exemple 2 : Refuser un membre
SELECT refuser_membre(
    'user-id-ici'::UUID,           -- ID de l'utilisateur à refuser
    auth.uid(),                     -- ID du validateur (vous)
    'Documents incomplets'          -- Raison du refus
);

-- Exemple 3 : Voir l'historique des validations d'un utilisateur
SELECT 
    v.*,
    p_validateur.full_name as validateur_nom,
    c.nom as chorale_nom
FROM validations_membres v
LEFT JOIN profiles p_validateur ON v.validateur_id = p_validateur.user_id
LEFT JOIN chorales c ON v.chorale_id = c.id
WHERE v.user_id = 'user-id-ici'::UUID
ORDER BY v.created_at DESC;
*/

-- =====================================================
-- FIN DU SCRIPT
-- =====================================================

/*
RÉSUMÉ DES CHANGEMENTS :

✅ Nouveau flux d'inscription :
1. Utilisateur s'inscrit (email + mot de passe + nom)
2. Email confirmé automatiquement par Supabase
3. Profil créé avec statut_validation = 'en_attente'
4. Utilisateur voit un écran d'attente
5. Admin/Super_admin valide et assigne une chorale
6. Utilisateur peut maintenant accéder aux chants

✅ Sécurité renforcée :
- Pas d'accès aux chants sans validation admin
- Pas de choix de chorale par l'utilisateur
- Historique complet des validations
- RLS policies strictes

✅ Tables créées :
- validations_membres (historique)

✅ Fonctions créées :
- valider_membre()
- refuser_membre()
- create_profile_on_signup() (modifiée)

✅ Vues créées :
- membres_en_attente
- stats_validations
*/

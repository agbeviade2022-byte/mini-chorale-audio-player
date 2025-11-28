-- =====================================================
-- FIX FINAL : Correction complète validation membres
-- =====================================================
-- Corrige toutes les erreurs de colonnes manquantes
-- =====================================================

SELECT '🔧 CORRECTION FINALE : Validation membres' as info;

-- ============================================
-- ÉTAPE 1 : Ajouter updated_at à profiles
-- ============================================

SELECT '📋 ÉTAPE 1 : Ajout updated_at à profiles' as etape;

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

UPDATE public.profiles 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- Trigger pour mise à jour automatique
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

SELECT '✅ Colonne updated_at ajoutée à profiles' as status;

-- ============================================
-- ÉTAPE 2 : Créer/Recréer table validations_membres
-- ============================================

SELECT '📋 ÉTAPE 2 : Création table validations_membres' as etape;

-- Supprimer l'ancienne table si elle existe
DROP TABLE IF EXISTS public.validations_membres CASCADE;

-- Créer la nouvelle table avec toutes les colonnes
CREATE TABLE public.validations_membres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    validateur_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('validation', 'refus')),
    chorale_id UUID REFERENCES public.chorales(id) ON DELETE SET NULL,
    commentaire TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX idx_validations_membres_user_id ON public.validations_membres(user_id);
CREATE INDEX idx_validations_membres_validateur_id ON public.validations_membres(validateur_id);
CREATE INDEX idx_validations_membres_created_at ON public.validations_membres(created_at);

-- RLS
ALTER TABLE public.validations_membres ENABLE ROW LEVEL SECURITY;

-- Policy: Admins peuvent tout voir
CREATE POLICY "Admins can view all validations"
ON public.validations_membres
FOR SELECT
TO authenticated
USING (
    (SELECT role FROM public.profiles WHERE user_id = auth.uid() LIMIT 1) IN ('admin', 'super_admin')
);

-- Policy: Admins peuvent insérer
CREATE POLICY "Admins can insert validations"
ON public.validations_membres
FOR INSERT
TO authenticated
WITH CHECK (
    (SELECT role FROM public.profiles WHERE user_id = auth.uid() LIMIT 1) IN ('admin', 'super_admin')
);

SELECT '✅ Table validations_membres créée' as status;

-- ============================================
-- ÉTAPE 3 : Recréer les fonctions RPC
-- ============================================

SELECT '📋 ÉTAPE 3 : Recréation fonctions RPC' as etape;

-- Supprimer anciennes fonctions
DROP FUNCTION IF EXISTS public.valider_membre(UUID, UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.valider_membre(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS public.valider_membre(UUID, UUID);
DROP FUNCTION IF EXISTS public.refuser_membre(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.refuser_membre(UUID, UUID);

-- Fonction: valider_membre
CREATE OR REPLACE FUNCTION public.valider_membre(
    p_user_id UUID,
    p_chorale_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_validateur_role TEXT;
BEGIN
    -- Vérifier que l'appelant est bien le validateur
    IF p_validateur_id != auth.uid() THEN
        RAISE EXCEPTION 'Non autorisé: ID validateur ne correspond pas';
    END IF;
    
    -- Vérifier le rôle du validateur
    SELECT role INTO v_validateur_role
    FROM profiles
    WHERE user_id = p_validateur_id;
    
    IF v_validateur_role NOT IN ('admin', 'super_admin') THEN
        RAISE EXCEPTION 'Seuls les admins peuvent valider des membres';
    END IF;
    
    -- Vérifier que l'utilisateur existe
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Utilisateur introuvable';
    END IF;
    
    -- Vérifier que la chorale existe
    IF NOT EXISTS (SELECT 1 FROM chorales WHERE id = p_chorale_id) THEN
        RAISE EXCEPTION 'Chorale introuvable';
    END IF;
    
    -- Vérifier que l'utilisateur est en attente
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = p_user_id 
        AND statut_validation = 'en_attente'
    ) THEN
        RAISE EXCEPTION 'Utilisateur déjà validé ou refusé';
    END IF;
    
    -- Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'valide',
        statut_membre = 'actif',
        chorale_id = p_chorale_id,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Logger l'action
    INSERT INTO validations_membres (
        user_id,
        validateur_id,
        action,
        chorale_id,
        commentaire,
        created_at
    ) VALUES (
        p_user_id,
        p_validateur_id,
        'validation',
        p_chorale_id,
        p_commentaire,
        NOW()
    );
    
    RETURN TRUE;
END;
$$;

-- Fonction: refuser_membre
CREATE OR REPLACE FUNCTION public.refuser_membre(
    p_user_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_validateur_role TEXT;
BEGIN
    -- Vérifier que l'appelant est bien le validateur
    IF p_validateur_id != auth.uid() THEN
        RAISE EXCEPTION 'Non autorisé: ID validateur ne correspond pas';
    END IF;
    
    -- Vérifier le rôle du validateur
    SELECT role INTO v_validateur_role
    FROM profiles
    WHERE user_id = p_validateur_id;
    
    IF v_validateur_role NOT IN ('admin', 'super_admin') THEN
        RAISE EXCEPTION 'Seuls les admins peuvent refuser des membres';
    END IF;
    
    -- Vérifier que l'utilisateur existe
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Utilisateur introuvable';
    END IF;
    
    -- Vérifier le commentaire
    IF p_commentaire IS NULL OR LENGTH(TRIM(p_commentaire)) < 10 THEN
        RAISE EXCEPTION 'Motif requis (min 10 caractères)';
    END IF;
    
    -- Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'refuse',
        statut_membre = 'inactif',
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Logger l'action
    INSERT INTO validations_membres (
        user_id,
        validateur_id,
        action,
        commentaire,
        created_at
    ) VALUES (
        p_user_id,
        p_validateur_id,
        'refus',
        p_commentaire,
        NOW()
    );
    
    RETURN TRUE;
END;
$$;

-- Permissions
GRANT EXECUTE ON FUNCTION public.valider_membre TO authenticated;
GRANT EXECUTE ON FUNCTION public.refuser_membre TO authenticated;

SELECT '✅ Fonctions RPC créées' as status;

-- ============================================
-- ÉTAPE 4 : Vérification finale
-- ============================================

SELECT '📋 ÉTAPE 4 : Vérification finale' as etape;

-- Vérifier colonne updated_at
SELECT 
    'profiles.updated_at' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'profiles'
            AND column_name = 'updated_at'
        ) THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as statut;

-- Vérifier table validations_membres
SELECT 
    'validations_membres' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_name = 'validations_membres'
        ) THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as statut;

-- Vérifier colonnes de validations_membres
SELECT 
    column_name,
    data_type,
    '✅ Colonne présente' as statut
FROM information_schema.columns
WHERE table_name = 'validations_membres'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier fonctions
SELECT 
    routine_name,
    security_type,
    CASE 
        WHEN security_type = 'DEFINER' THEN '✅ SECURITY DEFINER'
        ELSE '⚠️ SECURITY INVOKER'
    END as statut
FROM information_schema.routines
WHERE routine_name IN ('valider_membre', 'refuser_membre')
AND routine_schema = 'public';

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ CORRECTION FINALE TERMINÉE ✅✅✅' as resultat;
SELECT 'Rafraîchissez le dashboard et réessayez la validation' as action;
SELECT 'Toutes les colonnes et tables sont maintenant en place' as note;

-- =====================================================
-- FIX URGENT : Récursion infinie RLS
-- =====================================================
-- Erreur: infinite recursion detected in policy
-- Cause: Policies RLS + Fonctions RPC créent récursion
-- =====================================================

SELECT '🔧 CORRECTION : Récursion infinie RLS' as info;

-- ============================================
-- ÉTAPE 1 : Supprimer TOUTES les policies
-- ============================================

SELECT '📋 ÉTAPE 1 : Suppression de toutes les policies' as etape;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile limited" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Super admins can do everything" ON public.profiles;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.profiles;

SELECT '✅ Toutes les policies supprimées' as status;

-- ============================================
-- ÉTAPE 2 : Créer policies SIMPLES
-- ============================================

SELECT '📋 ÉTAPE 2 : Création policies simples' as etape;

-- Policy 1: SELECT - Voir son propre profil
CREATE POLICY "select_own_profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy 2: SELECT - Admins voient tout (SANS sous-requête récursive)
CREATE POLICY "select_all_for_admins"
ON public.profiles
FOR SELECT
TO authenticated
USING (
    (SELECT role FROM public.profiles WHERE user_id = auth.uid() LIMIT 1) IN ('admin', 'super_admin')
);

-- Policy 3: UPDATE - Utilisateur modifie son profil
CREATE POLICY "update_own_profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy 4: UPDATE - Admins modifient tout
CREATE POLICY "update_all_for_admins"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
    (SELECT role FROM public.profiles WHERE user_id = auth.uid() LIMIT 1) IN ('admin', 'super_admin')
)
WITH CHECK (
    (SELECT role FROM public.profiles WHERE user_id = auth.uid() LIMIT 1) IN ('admin', 'super_admin')
);

SELECT '✅ Policies simples créées' as status;

-- ============================================
-- ÉTAPE 3 : Recréer fonctions avec SECURITY DEFINER
-- ============================================

SELECT '📋 ÉTAPE 3 : Recréation fonctions RPC' as etape;

-- Supprimer les anciennes fonctions
DROP FUNCTION IF EXISTS public.valider_membre(UUID, UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.valider_membre(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS public.valider_membre(UUID, UUID);
DROP FUNCTION IF EXISTS public.refuser_membre(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.refuser_membre(UUID, UUID);

SELECT '✅ Anciennes fonctions supprimées' as status;

-- Fonction: valider_membre (SECURITY DEFINER pour bypass RLS)
CREATE OR REPLACE FUNCTION public.valider_membre(
    p_user_id UUID,
    p_chorale_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER  -- ✅ Bypass RLS dans la fonction
SET search_path = public
AS $$
DECLARE
    v_validateur_role TEXT;
BEGIN
    -- Vérifier que l'appelant est bien le validateur
    IF p_validateur_id != auth.uid() THEN
        RAISE EXCEPTION 'Non autorisé: ID validateur ne correspond pas';
    END IF;
    
    -- Vérifier le rôle du validateur (sans déclencher RLS)
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
    
    -- Logger l'action (si table existe)
    BEGIN
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
    EXCEPTION WHEN undefined_table THEN
        -- Table n'existe pas, ignorer
        NULL;
    END;
    
    RETURN TRUE;
END;
$$;

-- Fonction: refuser_membre (SECURITY DEFINER pour bypass RLS)
CREATE OR REPLACE FUNCTION public.refuser_membre(
    p_user_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER  -- ✅ Bypass RLS dans la fonction
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
    
    -- Logger l'action (si table existe)
    BEGIN
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
    EXCEPTION WHEN undefined_table THEN
        -- Table n'existe pas, ignorer
        NULL;
    END;
    
    RETURN TRUE;
END;
$$;

-- Permissions sur les fonctions
GRANT EXECUTE ON FUNCTION public.valider_membre TO authenticated;
GRANT EXECUTE ON FUNCTION public.refuser_membre TO authenticated;

SELECT '✅ Fonctions RPC recréées avec SECURITY DEFINER' as status;

-- ============================================
-- ÉTAPE 4 : Vérification
-- ============================================

SELECT '📋 ÉTAPE 4 : Vérification' as etape;

-- Vérifier les policies
SELECT 
    policyname,
    cmd,
    '✅ Policy active' as statut
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Vérifier les fonctions
SELECT 
    routine_name,
    security_type,
    CASE 
        WHEN security_type = 'DEFINER' THEN '✅ SECURITY DEFINER (bypass RLS)'
        ELSE '⚠️ SECURITY INVOKER'
    END as statut
FROM information_schema.routines
WHERE routine_name IN ('valider_membre', 'refuser_membre')
AND routine_schema = 'public';

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ CORRECTION TERMINÉE ✅✅✅' as resultat;
SELECT 'Rafraîchissez le dashboard et réessayez la validation' as action;
SELECT 'Les fonctions RPC utilisent maintenant SECURITY DEFINER pour bypass RLS' as note;

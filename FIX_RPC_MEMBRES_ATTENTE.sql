-- =====================================================
-- FIX : RPC améliorée pour récupérer les membres en attente
-- =====================================================

SELECT '🔧 CRÉATION RPC AMÉLIORÉE' as info;

-- ============================================
-- ÉTAPE 1 : Supprimer l'ancienne fonction si elle existe
-- ============================================

DROP FUNCTION IF EXISTS get_membres_en_attente();

-- ============================================
-- ÉTAPE 2 : Créer la nouvelle fonction RPC
-- ============================================

CREATE OR REPLACE FUNCTION get_membres_en_attente()
RETURNS TABLE (
    user_id uuid,
    email text,
    full_name text,
    telephone text,
    created_at timestamptz,
    statut_validation text,
    jours_attente integer
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.user_id,
        au.email::text,
        p.full_name::text,
        p.telephone::text,
        p.created_at::timestamptz,
        p.statut_validation::text,
        EXTRACT(DAY FROM (NOW() - p.created_at))::integer as jours_attente
    FROM profiles p
    INNER JOIN auth.users au ON p.user_id = au.id
    WHERE 
        p.statut_validation = 'en_attente'
        AND p.user_id IS NOT NULL
        AND au.email_confirmed_at IS NOT NULL
        AND au.deleted_at IS NULL
    ORDER BY p.created_at DESC;
END;
$$;

-- ============================================
-- ÉTAPE 3 : Donner les permissions
-- ============================================

GRANT EXECUTE ON FUNCTION get_membres_en_attente() TO authenticated;

-- ============================================
-- ÉTAPE 4 : Vérification
-- ============================================

SELECT '📋 TEST : Membres en attente' as etape;

SELECT * FROM get_membres_en_attente();

-- ============================================
-- ÉTAPE 5 : Vérifier les doublons (emails déjà validés)
-- ============================================

SELECT '📋 VÉRIFICATION : Doublons potentiels' as etape;

SELECT 
    au.email,
    COUNT(*) as nombre_profils,
    STRING_AGG(p.statut_validation, ', ') as statuts,
    CASE 
        WHEN COUNT(*) > 1 THEN '⚠️ Doublon détecté'
        ELSE '✅ OK'
    END as statut
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
WHERE p.user_id IS NOT NULL
GROUP BY au.email
HAVING COUNT(*) > 1;

-- ============================================
-- ÉTAPE 6 : Nettoyer les profils sans user_id
-- ============================================

SELECT '📋 NETTOYAGE : Profils invalides' as etape;

SELECT 
    COUNT(*) as nombre_profils_invalides,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun profil invalide'
        ELSE '⚠️ Profils à supprimer'
    END as statut
FROM profiles
WHERE user_id IS NULL;

-- Supprimer les profils sans user_id
DELETE FROM profiles
WHERE user_id IS NULL;

SELECT '✅ Profils invalides supprimés' as resultat;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ RPC AMÉLIORÉE CRÉÉE ✅✅✅' as resultat;
SELECT 'Utilisez get_membres_en_attente() dans le dashboard' as note;

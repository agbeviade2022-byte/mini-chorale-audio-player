-- =====================================================
-- FIX : Supprimer les profils avec user_id null
-- =====================================================

SELECT '🔧 NETTOYAGE : Profils invalides' as info;

-- ============================================
-- ÉTAPE 1 : Voir les profils à supprimer
-- ============================================

SELECT '📋 ÉTAPE 1 : Profils avec user_id null' as etape;

SELECT 
    id,
    full_name,
    user_id,
    role,
    created_at,
    '❌ Sera supprimé' as action
FROM profiles
WHERE user_id IS NULL;

-- ============================================
-- ÉTAPE 2 : Supprimer les profils invalides
-- ============================================

SELECT '📋 ÉTAPE 2 : Suppression' as etape;

DELETE FROM profiles
WHERE user_id IS NULL;

SELECT '✅ Profils invalides supprimés' as status;

-- ============================================
-- ÉTAPE 3 : Vérification
-- ============================================

SELECT '📋 ÉTAPE 3 : Vérification' as etape;

-- Vérifier qu'il ne reste aucun profil avec user_id null
SELECT 
    COUNT(*) as nombre_profils_invalides,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun profil invalide'
        ELSE '❌ Il reste des profils invalides'
    END as statut
FROM profiles
WHERE user_id IS NULL;

-- Compter les profils valides
SELECT 
    COUNT(*) as nombre_profils_valides,
    '✅ Profils valides' as statut
FROM profiles
WHERE user_id IS NOT NULL;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ NETTOYAGE TERMINÉ ✅✅✅' as resultat;
SELECT 'Rafraîchissez la page dashboard/permissions' as action;

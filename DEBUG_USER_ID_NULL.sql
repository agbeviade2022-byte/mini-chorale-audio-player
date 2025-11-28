-- =====================================================
-- DEBUG : Utilisateurs avec user_id null
-- =====================================================

SELECT '🔍 DEBUG : user_id null' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier la fonction RPC
-- ============================================

SELECT '📋 ÉTAPE 1 : Fonction get_all_users_with_emails_debug' as etape;

-- Vérifier si la fonction existe
SELECT 
    routine_name,
    routine_type,
    '✅ Fonction existe' as statut
FROM information_schema.routines
WHERE routine_name = 'get_all_users_with_emails_debug'
AND routine_schema = 'public';

-- ============================================
-- ÉTAPE 2 : Tester la fonction
-- ============================================

SELECT '📋 ÉTAPE 2 : Test de la fonction' as etape;

-- Appeler la fonction
SELECT * FROM get_all_users_with_emails_debug();

-- ============================================
-- ÉTAPE 3 : Vérifier les profils sans user_id
-- ============================================

SELECT '📋 ÉTAPE 3 : Profils avec user_id null' as etape;

SELECT 
    id,
    full_name,
    user_id,
    created_at,
    '❌ user_id est NULL' as probleme
FROM profiles
WHERE user_id IS NULL;

-- Compter
SELECT 
    COUNT(*) as nombre,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun profil sans user_id'
        ELSE '❌ Profils sans user_id détectés'
    END as statut
FROM profiles
WHERE user_id IS NULL;

-- ============================================
-- ÉTAPE 4 : Vérifier les comptes sans profil
-- ============================================

SELECT '📋 ÉTAPE 4 : Comptes auth.users sans profil' as etape;

SELECT 
    au.id,
    au.email,
    au.created_at,
    '❌ Pas de profil' as probleme
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL;

-- Compter
SELECT 
    COUNT(*) as nombre,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Tous les comptes ont un profil'
        ELSE '❌ Comptes sans profil détectés'
    END as statut
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL;

-- ============================================
-- RÉSUMÉ
-- ============================================

SELECT '📊 RÉSUMÉ' as info;

SELECT 
    'Profils avec user_id null' as element,
    COUNT(*) as nombre
FROM profiles
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Comptes sans profil' as element,
    COUNT(*) as nombre
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL
UNION ALL
SELECT 
    'Profils valides' as element,
    COUNT(*) as nombre
FROM profiles
WHERE user_id IS NOT NULL;

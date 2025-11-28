-- =====================================================
-- DEBUG : Page Permissions - Membres ne s'affichent pas
-- =====================================================

SELECT '🔍 DEBUG : Vérification fonction RPC' as titre;

-- ============================================
-- 1. Vérifier si la fonction existe
-- ============================================

SELECT '📋 1. Fonctions RPC disponibles' as section;

SELECT 
    routine_name as fonction,
    routine_type as type,
    CASE 
        WHEN routine_name LIKE '%user%' OR routine_name LIKE '%email%' THEN '✅ Pertinent'
        ELSE '⚪ Autre'
    END as pertinence
FROM information_schema.routines
WHERE routine_schema = 'public'
AND (routine_name LIKE '%user%' OR routine_name LIKE '%email%' OR routine_name LIKE '%member%')
ORDER BY routine_name;

-- ============================================
-- 2. Vérifier les utilisateurs dans profiles
-- ============================================

SELECT '📋 2. Utilisateurs dans profiles' as section;

SELECT 
    p.id,
    p.user_id,
    p.full_name,
    p.role,
    au.email,
    CASE 
        WHEN p.user_id IS NULL THEN '❌ Pas de user_id'
        WHEN p.role = 'membre' THEN '⚪ Membre (filtré)'
        WHEN p.role IN ('admin', 'super_admin') THEN '✅ Admin'
        ELSE '⚠️ Rôle inconnu'
    END as statut
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.role DESC, p.full_name;

-- ============================================
-- 3. Tester la fonction get_all_users_with_emails_debug
-- ============================================

SELECT '📋 3. Test fonction get_all_users_with_emails_debug' as section;

-- Vérifier si la fonction existe
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'get_all_users_with_emails_debug'
    ) THEN
        RAISE NOTICE '✅ Fonction get_all_users_with_emails_debug existe';
    ELSE
        RAISE NOTICE '❌ Fonction get_all_users_with_emails_debug N''EXISTE PAS';
    END IF;
END $$;

-- Essayer de l'appeler (commenté si elle n'existe pas)
-- SELECT * FROM get_all_users_with_emails_debug();

-- ============================================
-- 4. Vérifier la fonction get_all_users_with_emails
-- ============================================

SELECT '📋 4. Test fonction get_all_users_with_emails' as section;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'get_all_users_with_emails'
    ) THEN
        RAISE NOTICE '✅ Fonction get_all_users_with_emails existe';
    ELSE
        RAISE NOTICE '❌ Fonction get_all_users_with_emails N''EXISTE PAS';
    END IF;
END $$;

-- Essayer de l'appeler
SELECT * FROM get_all_users_with_emails();

-- ============================================
-- 5. Statistiques
-- ============================================

SELECT '📋 5. Statistiques' as section;

SELECT 
    'Total utilisateurs' as element,
    COUNT(*)::text as valeur
FROM profiles

UNION ALL

SELECT 
    'Avec user_id' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE user_id IS NOT NULL

UNION ALL

SELECT 
    'Sans user_id' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE user_id IS NULL

UNION ALL

SELECT 
    'Membres' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE role = 'membre'

UNION ALL

SELECT 
    'Admins' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE role = 'admin'

UNION ALL

SELECT 
    'Super Admins' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE role = 'super_admin';

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅ DIAGNOSTIC TERMINÉ' as resultat;
SELECT 'Vérifiez les alertes ci-dessus' as note;

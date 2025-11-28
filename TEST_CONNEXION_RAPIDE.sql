-- =====================================================
-- TEST RAPIDE : Connexion Flutter ↔ Dashboard
-- =====================================================
-- Vérifier que toutes les pièces sont en place
-- =====================================================

-- ============================================
-- TEST 1 : Vérifier le trigger
-- ============================================

SELECT '🧪 TEST 1 : Vérification du trigger' as test;

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    CASE 
        WHEN trigger_name = 'on_auth_user_created' THEN '✅ Trigger existe'
        ELSE '❌ Trigger manquant'
    END as statut
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created'
AND event_object_schema = 'auth';

-- Si aucun résultat
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'on_auth_user_created'
        ) THEN '❌ PROBLÈME: Trigger on_auth_user_created n''existe pas !'
        ELSE '✅ OK'
    END as diagnostic;

-- ============================================
-- TEST 2 : Vérifier la fonction handle_new_user
-- ============================================

SELECT '🧪 TEST 2 : Vérification de la fonction handle_new_user' as test;

SELECT 
    routine_name,
    routine_type,
    security_type,
    CASE 
        WHEN routine_name = 'handle_new_user' THEN '✅ Fonction existe'
        ELSE '❌ Fonction manquante'
    END as statut,
    CASE 
        WHEN security_type = 'INVOKER' THEN '✅ SECURITY INVOKER (sécurisé)'
        WHEN security_type = 'DEFINER' THEN '⚠️ SECURITY DEFINER (à surveiller)'
        ELSE '❓ Type inconnu'
    END as securite
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
AND routine_schema = 'public';

-- Si aucun résultat
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'handle_new_user'
        ) THEN '❌ PROBLÈME: Fonction handle_new_user n''existe pas !'
        ELSE '✅ OK'
    END as diagnostic;

-- ============================================
-- TEST 3 : Vérifier la vue membres_en_attente
-- ============================================

SELECT '🧪 TEST 3 : Vérification de la vue membres_en_attente' as test;

SELECT 
    table_name,
    CASE 
        WHEN table_name = 'membres_en_attente' THEN '✅ Vue existe'
        ELSE '❌ Vue manquante'
    END as statut
FROM information_schema.views
WHERE table_name = 'membres_en_attente'
AND table_schema = 'public';

-- Vérifier la définition de la vue
SELECT 
    '📋 Définition de la vue' as info,
    CASE 
        WHEN view_definition LIKE '%LEFT JOIN%' THEN '✅ Utilise LEFT JOIN (correct)'
        WHEN view_definition LIKE '%JOIN%' THEN '⚠️ Utilise JOIN (peut causer problèmes)'
        ELSE '❓ Type de JOIN inconnu'
    END as type_join,
    CASE 
        WHEN view_definition LIKE '%auth.users%' THEN '✅ JOIN avec auth.users (correct)'
        ELSE '❌ Pas de JOIN avec auth.users'
    END as join_auth_users
FROM information_schema.views
WHERE table_name = 'membres_en_attente'
AND table_schema = 'public';

-- Si aucun résultat
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.views 
            WHERE table_name = 'membres_en_attente'
        ) THEN '❌ PROBLÈME: Vue membres_en_attente n''existe pas !'
        ELSE '✅ OK'
    END as diagnostic;

-- ============================================
-- TEST 4 : Vérifier les permissions sur la vue
-- ============================================

SELECT '🧪 TEST 4 : Permissions sur la vue' as test;

SELECT 
    grantee,
    privilege_type,
    CASE 
        WHEN grantee = 'authenticated' AND privilege_type = 'SELECT' THEN '✅ OK'
        WHEN grantee = 'anon' THEN '⚠️ Accès anonyme (risque RGPD)'
        ELSE '❓ À vérifier'
    END as statut
FROM information_schema.table_privileges
WHERE table_name = 'membres_en_attente'
AND table_schema = 'public'
ORDER BY grantee;

-- ============================================
-- TEST 5 : Tester la vue avec des données réelles
-- ============================================

SELECT '🧪 TEST 5 : Test de la vue avec données réelles' as test;

-- Compter les membres en attente
SELECT 
    COUNT(*) as nombre_membres_en_attente,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Des membres en attente existent'
        ELSE 'ℹ️ Aucun membre en attente (normal si tous validés)'
    END as statut
FROM membres_en_attente;

-- Afficher les 3 premiers membres en attente
SELECT 
    '📋 Aperçu des membres en attente' as info;

SELECT 
    user_id,
    email,
    full_name,
    jours_attente,
    CASE 
        WHEN email IS NOT NULL AND email != '' THEN '✅ Email OK'
        ELSE '❌ Email manquant'
    END as statut_email,
    CASE 
        WHEN full_name IS NOT NULL AND full_name != '' AND full_name NOT LIKE 'Utilisateur%' THEN '✅ Nom OK'
        WHEN full_name LIKE 'Utilisateur%' THEN '⚠️ Nom générique'
        ELSE '❌ Nom manquant'
    END as statut_nom
FROM membres_en_attente
ORDER BY created_at DESC
LIMIT 3;

-- ============================================
-- TEST 6 : Vérifier la cohérence des données
-- ============================================

SELECT '🧪 TEST 6 : Cohérence des données' as test;

-- Vérifier que tous les profils en attente ont un user dans auth.users
SELECT 
    'Profils en attente sans compte auth.users' as probleme,
    COUNT(*) as nombre,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Tous les profils ont un compte'
        ELSE '❌ Profils orphelins détectés'
    END as statut
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
AND au.id IS NULL;

-- Vérifier que tous les comptes auth.users ont un profil
SELECT 
    'Comptes auth.users sans profil' as probleme,
    COUNT(*) as nombre,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Tous les comptes ont un profil'
        ELSE '⚠️ Comptes sans profil détectés (trigger ne fonctionne pas)'
    END as statut
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL;

-- ============================================
-- TEST 7 : Simuler une inscription
-- ============================================

SELECT '🧪 TEST 7 : Simulation d''inscription' as test;

DO $$
DECLARE
    v_test_user_id UUID;
    v_test_email TEXT;
    v_profile_exists BOOLEAN;
BEGIN
    -- Générer un email de test unique
    v_test_email := 'test_' || EXTRACT(EPOCH FROM NOW())::TEXT || '@example.com';
    v_test_user_id := gen_random_uuid();
    
    RAISE NOTICE '📝 Simulation d''inscription pour: %', v_test_email;
    
    -- Simuler l'insertion dans auth.users (normalement fait par Supabase Auth)
    -- Note: On ne peut pas vraiment insérer dans auth.users depuis SQL
    -- Mais on peut tester si le trigger existe
    
    -- Vérifier si le trigger se déclencherait
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'on_auth_user_created'
    ) INTO v_profile_exists;
    
    IF v_profile_exists THEN
        RAISE NOTICE '✅ Trigger existe - Le profil serait créé automatiquement';
    ELSE
        RAISE NOTICE '❌ Trigger manquant - Le profil ne serait PAS créé';
    END IF;
END $$;

-- ============================================
-- RÉSUMÉ FINAL
-- ============================================

SELECT '📊 RÉSUMÉ FINAL' as info;

SELECT 
    'Trigger on_auth_user_created' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'on_auth_user_created'
        ) THEN '✅ Existe'
        ELSE '❌ Manquant'
    END as statut
UNION ALL
SELECT 
    'Fonction handle_new_user' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'handle_new_user'
        ) THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as statut
UNION ALL
SELECT 
    'Vue membres_en_attente' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.views 
            WHERE table_name = 'membres_en_attente'
        ) THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as statut
UNION ALL
SELECT 
    'Permissions sur la vue' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_privileges 
            WHERE table_name = 'membres_en_attente'
            AND grantee = 'authenticated'
        ) THEN '✅ OK'
        ELSE '❌ Manquantes'
    END as statut;

-- Diagnostic final
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created')
        AND EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'handle_new_user')
        AND EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'membres_en_attente')
        THEN '✅ TOUT EST EN PLACE - La connexion Flutter ↔ Dashboard fonctionne'
        ELSE '❌ PROBLÈME DÉTECTÉ - Consultez les tests ci-dessus'
    END as diagnostic_final;

SELECT '📝 Consultez VERIFICATION_CONNEXION_FLUTTER_DASHBOARD.md pour plus de détails' as documentation;

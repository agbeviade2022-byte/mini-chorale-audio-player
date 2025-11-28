-- =====================================================
-- TESTS DE SÉCURITÉ RAPIDES
-- =====================================================
-- Exécuter APRÈS avoir appliqué FIX_SECURITE_URGENT.sql
-- =====================================================

-- ============================================
-- TEST 1 : Escalade de privilèges
-- ============================================

SELECT '🧪 TEST 1 : Escalade de privilèges' as test;
SELECT 'Créer un utilisateur de test et essayer de le promouvoir' as description;

-- Créer un utilisateur de test
DO $$
DECLARE
    v_test_user_id UUID;
BEGIN
    -- Générer un UUID de test
    v_test_user_id := gen_random_uuid();
    
    -- Créer le profil de test
    INSERT INTO profiles (user_id, full_name, role, statut_validation)
    VALUES (v_test_user_id, 'Test User', 'membre', 'valide')
    ON CONFLICT (user_id) DO NOTHING;
    
    RAISE NOTICE 'Utilisateur de test créé: %', v_test_user_id;
    
    -- Essayer de le promouvoir (DOIT ÉCHOUER si RLS est correct)
    -- Note: Ce test ne peut pas vraiment simuler auth.uid()
    -- Il faut le faire manuellement via l'interface
    
END $$;

SELECT 
    '⚠️ Pour tester l''escalade de privilèges:' as info,
    '1. Connectez-vous avec un compte membre' as etape1,
    '2. Ouvrez la console du dashboard (F12)' as etape2,
    '3. Exécutez: await supabase.from("profiles").update({role:"super_admin"}).eq("user_id",myUserId)' as etape3,
    '4. Résultat attendu: Erreur RLS' as resultat_attendu;

-- ============================================
-- TEST 2 : Vérifier les RLS Policies
-- ============================================

SELECT '🧪 TEST 2 : Vérification des RLS Policies' as test;

-- Compter les policies sur profiles
SELECT 
    'Policies sur profiles' as table_name,
    COUNT(*) as nombre_policies,
    CASE 
        WHEN COUNT(*) >= 2 THEN '✅ OK'
        ELSE '❌ Insuffisant'
    END as statut
FROM pg_policies
WHERE tablename = 'profiles';

-- Compter les policies sur user_permissions
SELECT 
    'Policies sur user_permissions' as table_name,
    COUNT(*) as nombre_policies,
    CASE 
        WHEN COUNT(*) >= 4 THEN '✅ OK'
        ELSE '❌ Insuffisant'
    END as statut
FROM pg_policies
WHERE tablename = 'user_permissions';

-- Lister toutes les policies
SELECT 
    '📋 Liste des policies' as info;

SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN roles::text LIKE '%authenticated%' THEN '✅ authenticated'
        WHEN roles::text LIKE '%anon%' THEN '⚠️ anon'
        ELSE roles::text
    END as roles
FROM pg_policies
WHERE tablename IN ('profiles', 'user_permissions', 'modules_permissions')
ORDER BY tablename, policyname;

-- ============================================
-- TEST 3 : Vérifier SECURITY INVOKER
-- ============================================

SELECT '🧪 TEST 3 : Vérification SECURITY INVOKER' as test;

SELECT 
    routine_name,
    security_type,
    CASE 
        WHEN security_type = 'INVOKER' THEN '✅ SÉCURISÉ'
        WHEN security_type = 'DEFINER' THEN '❌ DANGEREUX'
        ELSE '❓ Inconnu'
    END as statut
FROM information_schema.routines
WHERE routine_name IN ('valider_membre', 'refuser_membre')
AND routine_schema = 'public';

-- ============================================
-- TEST 4 : Vérifier les permissions sur les vues
-- ============================================

SELECT '🧪 TEST 4 : Permissions sur les vues' as test;

SELECT 
    table_name,
    grantee,
    privilege_type,
    CASE 
        WHEN grantee = 'anon' AND table_name = 'membres_en_attente' THEN '❌ DANGEREUX'
        WHEN grantee = 'authenticated' THEN '✅ OK'
        ELSE '⚠️ À vérifier'
    END as statut
FROM information_schema.table_privileges
WHERE table_name IN ('membres_en_attente', 'stats_validations')
ORDER BY table_name, grantee;

-- ============================================
-- TEST 5 : Tester la fonction valider_membre
-- ============================================

SELECT '🧪 TEST 5 : Test de la fonction valider_membre' as test;

-- Créer un utilisateur en attente pour le test
DO $$
DECLARE
    v_test_user_id UUID;
    v_test_chorale_id UUID;
BEGIN
    v_test_user_id := gen_random_uuid();
    
    -- Créer un profil en attente
    INSERT INTO profiles (user_id, full_name, role, statut_validation)
    VALUES (v_test_user_id, 'Test Pending User', 'membre', 'en_attente')
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Récupérer une chorale existante
    SELECT id INTO v_test_chorale_id FROM chorales LIMIT 1;
    
    IF v_test_chorale_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucune chorale trouvée, créez-en une pour tester';
    ELSE
        RAISE NOTICE 'Test user créé: %', v_test_user_id;
        RAISE NOTICE 'Chorale: %', v_test_chorale_id;
        RAISE NOTICE 'Pour tester, connectez-vous en tant qu''admin et exécutez:';
        RAISE NOTICE 'SELECT valider_membre(''%''::UUID, ''%''::UUID, auth.uid(), ''Test'');', v_test_user_id, v_test_chorale_id;
    END IF;
END $$;

-- ============================================
-- TEST 6 : Vérifier RLS activé
-- ============================================

SELECT '🧪 TEST 6 : RLS activé sur les tables critiques' as test;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity = true THEN '✅ RLS activé'
        ELSE '❌ RLS désactivé (DANGEREUX)'
    END as statut
FROM pg_tables
WHERE tablename IN ('profiles', 'user_permissions', 'modules_permissions', 'validations_membres')
AND schemaname = 'public'
ORDER BY tablename;

-- ============================================
-- TEST 7 : Vérifier les super admins
-- ============================================

SELECT '🧪 TEST 7 : Liste des Super Admins' as test;

SELECT 
    p.user_id,
    au.email,
    p.full_name,
    p.role,
    p.statut_validation,
    CASE 
        WHEN p.role = 'super_admin' AND p.statut_validation = 'valide' THEN '✅ OK'
        WHEN p.role = 'super_admin' AND p.statut_validation != 'valide' THEN '⚠️ Non validé'
        ELSE '❓'
    END as statut
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin'
ORDER BY p.created_at;

-- ============================================
-- TEST 8 : Vérifier les contraintes FK
-- ============================================

SELECT '🧪 TEST 8 : Contraintes de clés étrangères' as test;

SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    '✅ OK' as statut
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name IN ('user_permissions', 'validations_membres')
ORDER BY tc.table_name;

-- ============================================
-- RÉSUMÉ DES TESTS
-- ============================================

SELECT '📊 RÉSUMÉ DES TESTS' as info;

SELECT 
    'RLS Policies' as categorie,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename IN ('profiles', 'user_permissions')) as nombre,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename IN ('profiles', 'user_permissions')) >= 6 
        THEN '✅ OK'
        ELSE '❌ Insuffisant'
    END as statut
UNION ALL
SELECT 
    'SECURITY INVOKER' as categorie,
    (SELECT COUNT(*) FROM information_schema.routines 
     WHERE routine_name IN ('valider_membre', 'refuser_membre') 
     AND security_type = 'INVOKER') as nombre,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.routines 
              WHERE routine_name IN ('valider_membre', 'refuser_membre') 
              AND security_type = 'INVOKER') = 2 
        THEN '✅ OK'
        ELSE '❌ DANGEREUX'
    END as statut
UNION ALL
SELECT 
    'RLS activé' as categorie,
    (SELECT COUNT(*) FROM pg_tables 
     WHERE tablename IN ('profiles', 'user_permissions') 
     AND rowsecurity = true) as nombre,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_tables 
              WHERE tablename IN ('profiles', 'user_permissions') 
              AND rowsecurity = true) = 2 
        THEN '✅ OK'
        ELSE '❌ DANGEREUX'
    END as statut
UNION ALL
SELECT 
    'Super Admins validés' as categorie,
    (SELECT COUNT(*) FROM profiles 
     WHERE role = 'super_admin' 
     AND statut_validation = 'valide') as nombre,
    CASE 
        WHEN (SELECT COUNT(*) FROM profiles 
              WHERE role = 'super_admin' 
              AND statut_validation = 'valide') >= 1 
        THEN '✅ OK'
        ELSE '⚠️ Aucun admin'
    END as statut;

-- ============================================
-- INSTRUCTIONS FINALES
-- ============================================

SELECT '✅ Tests SQL terminés' as status;
SELECT '📝 Consultez GUIDE_TESTS_SECURITE.md pour les tests manuels' as next_step;
SELECT '🌐 Testez maintenant le dashboard web' as action1;
SELECT '📱 Testez ensuite l''application Flutter' as action2;

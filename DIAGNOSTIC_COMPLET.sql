-- =====================================================
-- DIAGNOSTIC COMPLET DE L'INSCRIPTION
-- =====================================================
-- Exécutez ce script pour voir EXACTEMENT ce qui ne va pas
-- =====================================================

-- =====================================================
-- 1. VÉRIFIER LA STRUCTURE DE LA TABLE PROFILES
-- =====================================================

SELECT 
    '=== STRUCTURE DE LA TABLE PROFILES ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- =====================================================
-- 2. VÉRIFIER LE TRIGGER
-- =====================================================

SELECT 
    '=== TRIGGER ===' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users'
  AND trigger_schema = 'auth';

-- =====================================================
-- 3. VÉRIFIER LA FONCTION DU TRIGGER
-- =====================================================

SELECT 
    '=== FONCTION DU TRIGGER ===' as info;

SELECT 
    proname as function_name,
    prosrc as source_code
FROM pg_proc
WHERE proname IN ('create_profile_on_signup', 'handle_new_user');

-- =====================================================
-- 4. VÉRIFIER LES POLICIES RLS
-- =====================================================

SELECT 
    '=== POLICIES RLS ===' as info;

SELECT
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'INSERT' THEN '⚠️ POLICY INSERT TROUVÉE'
        ELSE '✅ OK'
    END as status,
    qual as using_clause,
    with_check
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;

-- =====================================================
-- 5. VÉRIFIER RLS
-- =====================================================

SELECT 
    '=== RLS STATUS ===' as info;

SELECT 
    tablename,
    rowsecurity,
    CASE 
        WHEN rowsecurity = true THEN '✅ RLS activé'
        ELSE '⚠️ RLS désactivé'
    END as status
FROM pg_tables
WHERE tablename = 'profiles';

-- =====================================================
-- 6. TESTER L'INSERTION MANUELLE
-- =====================================================

SELECT 
    '=== TEST INSERTION MANUELLE ===' as info;

DO $$
DECLARE
    test_user_id uuid := gen_random_uuid();
BEGIN
    -- Essayer d'insérer un profil de test
    INSERT INTO public.profiles (
        user_id,
        full_name,
        role,
        statut_validation,
        statut_membre,
        chorale_id
    )
    VALUES (
        test_user_id,
        'Test User',
        'membre',
        'en_attente',
        'inactif',
        NULL
    );
    
    RAISE NOTICE '✅ Test insertion réussi ! user_id: %', test_user_id;
    
    -- Nettoyer
    DELETE FROM public.profiles WHERE user_id = test_user_id;
    RAISE NOTICE '✅ Nettoyage effectué';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur insertion: %', SQLERRM;
        RAISE NOTICE '❌ SQLSTATE: %', SQLSTATE;
        RAISE NOTICE '❌ Detail: %', SQLERRM;
END $$;

-- =====================================================
-- 7. VÉRIFIER LES COMPTES ORPHELINS
-- =====================================================

SELECT 
    '=== COMPTES ORPHELINS ===' as info;

SELECT 
    COUNT(*) as nombre_comptes_orphelins,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun compte orphelin'
        ELSE '⚠️ ' || COUNT(*) || ' compte(s) sans profil'
    END as status
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL;

-- Détail des comptes orphelins
SELECT 
    au.id,
    au.email,
    au.created_at,
    au.raw_user_meta_data->>'full_name' as full_name
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL
ORDER BY au.created_at DESC
LIMIT 5;

-- =====================================================
-- 8. VÉRIFIER LES CONTRAINTES
-- =====================================================

SELECT 
    '=== CONTRAINTES ===' as info;

SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    CASE 
        WHEN tc.constraint_type = 'FOREIGN KEY' THEN ccu.table_name || '(' || ccu.column_name || ')'
        ELSE NULL
    END as references
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'profiles'
ORDER BY tc.constraint_type, tc.constraint_name;

-- =====================================================
-- 9. VÉRIFIER LES COLONNES NOT NULL
-- =====================================================

SELECT 
    '=== COLONNES NOT NULL SANS DÉFAUT ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    '⚠️ Colonne NOT NULL sans défaut' as warning
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND is_nullable = 'NO'
  AND column_default IS NULL
  AND column_name NOT IN ('user_id', 'id');

-- =====================================================
-- 10. RÉSUMÉ DU DIAGNOSTIC
-- =====================================================

SELECT 
    '=== RÉSUMÉ ===' as info;

SELECT 
    'Trigger existe' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name IN ('on_auth_user_created')
        ) THEN '✅ OUI'
        ELSE '❌ NON'
    END as status
UNION ALL
SELECT 
    'Fonction existe' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname IN ('create_profile_on_signup', 'handle_new_user')
        ) THEN '✅ OUI'
        ELSE '❌ NON'
    END as status
UNION ALL
SELECT 
    'Policy INSERT existe' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'profiles' AND cmd = 'INSERT'
        ) THEN '⚠️ OUI (PROBLÈME)'
        ELSE '✅ NON (OK)'
    END as status
UNION ALL
SELECT 
    'RLS activé' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE tablename = 'profiles' AND rowsecurity = true
        ) THEN '✅ OUI'
        ELSE '⚠️ NON'
    END as status
UNION ALL
SELECT 
    'Comptes orphelins' as check_item,
    CASE 
        WHEN (SELECT COUNT(*) FROM auth.users au LEFT JOIN public.profiles p ON au.id = p.user_id WHERE p.user_id IS NULL) = 0 
        THEN '✅ AUCUN'
        ELSE '⚠️ ' || (SELECT COUNT(*) FROM auth.users au LEFT JOIN public.profiles p ON au.id = p.user_id WHERE p.user_id IS NULL)::text
    END as status;

-- =====================================================
-- INSTRUCTIONS
-- =====================================================

/*
📋 INTERPRÉTATION DES RÉSULTATS :

✅ Trigger existe: OUI → Bon
✅ Fonction existe: OUI → Bon
✅ Policy INSERT existe: NON → Bon (pas de policy INSERT)
⚠️ Policy INSERT existe: OUI → PROBLÈME (supprimez-la)
✅ RLS activé: OUI → Bon
✅ Comptes orphelins: AUCUN → Bon

Si vous voyez "⚠️ Policy INSERT existe: OUI", c'est le problème !
Exécutez RESTAURER_INSCRIPTION.sql pour le corriger.

Si le test d'insertion manuelle échoue, regardez le message d'erreur.
*/

-- =====================================================
-- AUDIT : Sécurité des accès par chorale
-- =====================================================

SELECT '🔍 AUDIT : Vérification de la sécurité' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier les relations actuelles
-- ============================================

SELECT '📋 ÉTAPE 1 : Relations entre tables' as etape;

-- Vérifier la structure de profiles
SELECT 
    'profiles' as table_name,
    column_name,
    data_type,
    CASE 
        WHEN column_name = 'chorale_id' THEN '✅ Lien vers chorale'
        WHEN column_name = 'user_id' THEN '✅ Lien vers auth.users'
        ELSE '⚪ Autre'
    END as importance
FROM information_schema.columns
WHERE table_name = 'profiles'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier la structure de chants
SELECT 
    'chants' as table_name,
    column_name,
    data_type,
    CASE 
        WHEN column_name = 'chorale_id' THEN '✅ Lien vers chorale'
        WHEN column_name = 'id' THEN '✅ Clé primaire'
        ELSE '⚪ Autre'
    END as importance
FROM information_schema.columns
WHERE table_name = 'chants'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================
-- ÉTAPE 2 : Vérifier les RLS policies actuelles
-- ============================================

SELECT '📋 ÉTAPE 2 : Politiques RLS existantes' as etape;

-- Politiques sur profiles
SELECT 
    'profiles' as table_name,
    policyname as policy_name,
    cmd as command,
    qual as using_expression,
    CASE 
        WHEN qual LIKE '%chorale_id%' THEN '✅ Filtre par chorale'
        ELSE '⚠️ Pas de filtre chorale'
    END as securite
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Politiques sur chants
SELECT 
    'chants' as table_name,
    policyname as policy_name,
    cmd as command,
    qual as using_expression,
    CASE 
        WHEN qual LIKE '%chorale_id%' THEN '✅ Filtre par chorale'
        ELSE '⚠️ Pas de filtre chorale'
    END as securite
FROM pg_policies
WHERE tablename = 'chants'
ORDER BY policyname;

-- ============================================
-- ÉTAPE 3 : Tester les accès
-- ============================================

SELECT '📋 ÉTAPE 3 : Test des accès' as etape;

-- Membres avec leur chorale
SELECT 
    p.full_name,
    p.role,
    c.nom as chorale,
    COUNT(ch.id) as nb_chants_accessibles,
    CASE 
        WHEN p.chorale_id IS NULL THEN '❌ Pas de chorale'
        WHEN COUNT(ch.id) = 0 THEN '⚠️ Aucun chant'
        ELSE '✅ OK'
    END as statut
FROM profiles p
LEFT JOIN chorales c ON p.chorale_id = c.id
LEFT JOIN chants ch ON ch.chorale_id = p.chorale_id
WHERE p.role = 'membre'
GROUP BY p.full_name, p.role, c.nom, p.chorale_id;

-- ============================================
-- ÉTAPE 4 : Identifier les failles
-- ============================================

SELECT '📋 ÉTAPE 4 : Failles de sécurité potentielles' as etape;

-- Membres sans chorale
SELECT 
    '❌ FAILLE 1' as type,
    'Membres sans chorale' as probleme,
    COUNT(*) as nombre
FROM profiles
WHERE role = 'membre' AND chorale_id IS NULL;

-- Chants sans chorale
SELECT 
    '❌ FAILLE 2' as type,
    'Chants sans chorale' as probleme,
    COUNT(*) as nombre
FROM chants
WHERE chorale_id IS NULL;

-- Politiques RLS manquantes
SELECT 
    '⚠️ FAILLE 3' as type,
    'Vérifier les politiques RLS' as probleme,
    'Voir résultats ÉTAPE 2' as details;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅ AUDIT TERMINÉ' as resultat;
SELECT 'Analysez les résultats ci-dessus pour identifier les problèmes' as note;

-- =====================================================
-- VÉRIFICATION : Accès des membres validés
-- =====================================================
-- Vérifie si les membres validés ont accès à l'interface
-- =====================================================

SELECT '🔍 VÉRIFICATION ACCÈS MEMBRES VALIDÉS' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier les membres validés
-- ============================================

SELECT '📋 ÉTAPE 1 : Liste des membres validés' as etape;

SELECT 
    p.user_id,
    au.email,
    p.full_name,
    p.statut_validation,
    p.statut_membre,
    c.nom as chorale,
    p.role,
    CASE 
        WHEN p.statut_validation = 'valide' AND p.statut_membre = 'actif' THEN '✅ Devrait avoir accès'
        WHEN p.statut_validation = 'en_attente' THEN '⏳ En attente - Pas d''accès'
        WHEN p.statut_validation = 'refuse' THEN '❌ Refusé - Pas d''accès'
        WHEN p.statut_membre = 'inactif' THEN '⚠️ Inactif - Accès limité'
        ELSE '⚠️ Statut inconnu'
    END as acces_attendu
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
LEFT JOIN chorales c ON p.chorale_id = c.id
ORDER BY p.statut_validation, p.created_at DESC;

-- ============================================
-- ÉTAPE 2 : Vérifier les RLS policies sur chants
-- ============================================

SELECT '📋 ÉTAPE 2 : Policies RLS sur table chants' as etape;

SELECT 
    policyname,
    cmd,
    qual::text as using_clause,
    with_check::text as with_check_clause,
    '✅ Policy active' as statut
FROM pg_policies
WHERE tablename = 'chants'
ORDER BY policyname;

-- Compter les policies
SELECT 
    COUNT(*) as nombre_policies,
    CASE 
        WHEN COUNT(*) = 0 THEN '⚠️ Aucune policy - Accès libre'
        WHEN COUNT(*) > 0 THEN '✅ Policies actives'
    END as statut
FROM pg_policies
WHERE tablename = 'chants';

-- ============================================
-- ÉTAPE 3 : Vérifier si RLS est activé sur chants
-- ============================================

SELECT '📋 ÉTAPE 3 : Statut RLS sur table chants' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS activé'
        ELSE '⚠️ RLS désactivé - Tous peuvent accéder'
    END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'chants';

-- ============================================
-- ÉTAPE 4 : Vérifier les policies qui bloquent les non-validés
-- ============================================

SELECT '📋 ÉTAPE 4 : Policies bloquant les non-validés' as etape;

SELECT 
    policyname,
    cmd,
    qual::text as condition,
    CASE 
        WHEN qual::text LIKE '%statut_validation%' THEN '✅ Vérifie statut_validation'
        WHEN qual::text LIKE '%valide%' THEN '✅ Vérifie validation'
        ELSE '⚠️ Ne vérifie pas la validation'
    END as verification_validation
FROM pg_policies
WHERE tablename = 'chants'
ORDER BY policyname;

-- ============================================
-- ÉTAPE 5 : Test d'accès pour un membre validé
-- ============================================

SELECT '📋 ÉTAPE 5 : Simulation accès membre validé' as etape;

-- Simuler l'accès d'un membre validé
SELECT 
    'Membre validé peut voir les chants de sa chorale' as test,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'chants' 
            AND qual::text LIKE '%statut_validation%'
        ) THEN '✅ Policy vérifie le statut'
        ELSE '⚠️ Aucune vérification du statut'
    END as resultat;

-- ============================================
-- ÉTAPE 6 : Vérifier les chants accessibles
-- ============================================

SELECT '📋 ÉTAPE 6 : Chants dans la base' as etape;

SELECT 
    COUNT(*) as total_chants,
    COUNT(DISTINCT chorale_id) as chorales_avec_chants,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Chants disponibles'
        ELSE '⚠️ Aucun chant dans la base'
    END as statut
FROM chants;

-- Liste des chorales avec nombre de chants
SELECT 
    c.nom as chorale,
    COUNT(ch.id) as nombre_chants,
    '✅ Chants disponibles' as statut
FROM chorales c
LEFT JOIN chants ch ON c.id = ch.chorale_id
GROUP BY c.id, c.nom
ORDER BY nombre_chants DESC;

-- ============================================
-- ÉTAPE 7 : Vérifier le flux de validation
-- ============================================

SELECT '📋 ÉTAPE 7 : Flux de validation' as etape;

-- Vérifier que la validation change bien le statut
SELECT 
    'Flux de validation' as test,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'valider_membre'
        ) THEN '✅ Fonction valider_membre existe'
        ELSE '❌ Fonction valider_membre manquante'
    END as fonction_validation,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'refuser_membre'
        ) THEN '✅ Fonction refuser_membre existe'
        ELSE '❌ Fonction refuser_membre manquante'
    END as fonction_refus;

-- ============================================
-- RÉSUMÉ
-- ============================================

SELECT '📊 RÉSUMÉ' as info;

SELECT 
    'Membres validés' as element,
    COUNT(*) as nombre
FROM profiles
WHERE statut_validation = 'valide'
UNION ALL
SELECT 
    'Membres en attente' as element,
    COUNT(*) as nombre
FROM profiles
WHERE statut_validation = 'en_attente'
UNION ALL
SELECT 
    'Membres refusés' as element,
    COUNT(*) as nombre
FROM profiles
WHERE statut_validation = 'refuse'
UNION ALL
SELECT 
    'Chants disponibles' as element,
    COUNT(*) as nombre
FROM chants;

-- ============================================
-- RECOMMANDATIONS
-- ============================================

SELECT '💡 RECOMMANDATIONS' as info;

-- Vérifier si les policies sont correctes
SELECT 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chants') 
        THEN '⚠️ PROBLÈME: Aucune policy sur table chants - Créer des policies RLS'
        
        WHEN NOT EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'chants' 
            AND qual::text LIKE '%statut_validation%'
        ) 
        THEN '⚠️ ATTENTION: Les policies ne vérifient pas statut_validation - Les non-validés peuvent accéder'
        
        ELSE '✅ OK: Policies correctes'
    END as recommandation;

-- Vérifier si des membres validés existent
SELECT 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM profiles WHERE statut_validation = 'valide')
        THEN '⚠️ Aucun membre validé - Valider au moins un membre pour tester'
        ELSE '✅ Membres validés présents'
    END as recommandation;

-- Vérifier si des chants existent
SELECT 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM chants)
        THEN '⚠️ Aucun chant dans la base - Ajouter des chants pour tester'
        ELSE '✅ Chants disponibles'
    END as recommandation;

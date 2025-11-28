-- =====================================================
-- VÉRIFICATION : Page Chants Dashboard
-- =====================================================

SELECT '🔍 VÉRIFICATION PAGE CHANTS' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier la table chants
-- ============================================

SELECT '📋 ÉTAPE 1 : Structure table chants' as etape;

-- Vérifier les colonnes
SELECT 
    column_name,
    data_type,
    is_nullable,
    '✅ Colonne présente' as statut
FROM information_schema.columns
WHERE table_name = 'chants'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================
-- ÉTAPE 2 : Vérifier RLS sur chants
-- ============================================

SELECT '📋 ÉTAPE 2 : RLS sur table chants' as etape;

-- Statut RLS
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS activé'
        ELSE '⚠️ RLS désactivé'
    END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'chants';

-- Policies actives
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
        WHEN COUNT(*) = 0 THEN '⚠️ Aucune policy - Accès libre ou bloqué'
        WHEN COUNT(*) > 0 THEN '✅ Policies actives'
    END as statut
FROM pg_policies
WHERE tablename = 'chants';

-- ============================================
-- ÉTAPE 3 : Vérifier les chants dans la base
-- ============================================

SELECT '📋 ÉTAPE 3 : Chants disponibles' as etape;

-- Compter les chants
SELECT 
    COUNT(*) as total_chants,
    COUNT(DISTINCT chorale_id) as chorales_avec_chants,
    COUNT(DISTINCT pupitre) as pupitres_differents,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Chants disponibles'
        ELSE '⚠️ Aucun chant dans la base'
    END as statut
FROM chants;

-- Répartition par pupitre
SELECT 
    pupitre,
    COUNT(*) as nombre,
    '✅ Chants présents' as statut
FROM chants
GROUP BY pupitre
ORDER BY nombre DESC;

-- Répartition par chorale
SELECT 
    c.nom as chorale,
    COUNT(ch.id) as nombre_chants,
    '✅ Chants présents' as statut
FROM chorales c
LEFT JOIN chants ch ON c.id = ch.chorale_id
GROUP BY c.id, c.nom
ORDER BY nombre_chants DESC;

-- ============================================
-- ÉTAPE 4 : Vérifier les permissions dashboard
-- ============================================

SELECT '📋 ÉTAPE 4 : Permissions dashboard' as etape;

-- Vérifier que les admins peuvent voir les chants
SELECT 
    'Accès admin aux chants' as test,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chants')
        THEN '✅ Pas de RLS - Tous les authentifiés peuvent voir'
        
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'chants' 
            AND cmd = 'SELECT'
            AND qual::text = 'true'
        )
        THEN '✅ Policy SELECT permissive - Tous peuvent voir'
        
        ELSE '⚠️ Vérifier les policies - Accès peut être restreint'
    END as resultat;

-- ============================================
-- ÉTAPE 5 : Vérifier la table chorales
-- ============================================

SELECT '📋 ÉTAPE 5 : Table chorales' as etape;

-- Vérifier que la table chorales existe
SELECT 
    tablename,
    '✅ Table existe' as statut
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'chorales';

-- Compter les chorales
SELECT 
    COUNT(*) as nombre_chorales,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Chorales disponibles'
        ELSE '⚠️ Aucune chorale'
    END as statut
FROM chorales;

-- Liste des chorales
SELECT 
    id,
    nom,
    created_at,
    '✅ Chorale présente' as statut
FROM chorales
ORDER BY nom;

-- ============================================
-- ÉTAPE 6 : Test de requête dashboard
-- ============================================

SELECT '📋 ÉTAPE 6 : Simulation requête dashboard' as etape;

-- Simuler la requête du dashboard
SELECT 
    ch.id,
    ch.titre,
    ch.compositeur,
    ch.pupitre,
    ch.duree,
    ch.langue,
    ch.categorie,
    ch.chorale_id,
    c.nom as chorale_nom,
    '✅ Chant accessible' as statut
FROM chants ch
LEFT JOIN chorales c ON ch.chorale_id = c.id
ORDER BY ch.created_at DESC
LIMIT 5;

-- ============================================
-- RÉSUMÉ
-- ============================================

SELECT '📊 RÉSUMÉ' as info;

SELECT 
    'Total chants' as element,
    COUNT(*)::text as valeur
FROM chants
UNION ALL
SELECT 
    'Chorales avec chants' as element,
    COUNT(DISTINCT chorale_id)::text as valeur
FROM chants
UNION ALL
SELECT 
    'Policies RLS' as element,
    COUNT(*)::text as valeur
FROM pg_policies
WHERE tablename = 'chants'
UNION ALL
SELECT 
    'Total chorales' as element,
    COUNT(*)::text as valeur
FROM chorales;

-- ============================================
-- RECOMMANDATIONS
-- ============================================

SELECT '💡 RECOMMANDATIONS' as info;

-- Vérifier si des chants existent
SELECT 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM chants)
        THEN '⚠️ Aucun chant - Ajouter des chants via l''app Flutter pour tester'
        ELSE '✅ Chants présents - Page devrait afficher les données'
    END as recommandation;

-- Vérifier si RLS bloque l'accès
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'chants' 
            AND qual::text LIKE '%statut_validation%'
        )
        THEN '⚠️ RLS vérifie statut_validation - Seuls les membres validés peuvent voir'
        
        WHEN NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chants')
        THEN '✅ Pas de RLS - Tous les authentifiés peuvent voir'
        
        ELSE '✅ RLS permissif - Accès autorisé'
    END as recommandation;

-- Vérifier si les chorales existent
SELECT 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM chorales)
        THEN '⚠️ Aucune chorale - Créer des chorales d''abord'
        ELSE '✅ Chorales présentes'
    END as recommandation;

-- =====================================================
-- TEST SIMPLE : Vérifications critiques uniquement
-- =====================================================

SELECT '🔍 TEST SIMPLE - Vérifications critiques' as titre;

-- ============================================
-- 1. Type d'ID des chorales
-- ============================================

SELECT '📋 1. Type d''ID chorales' as section;

SELECT 
    'chorales.id' as colonne,
    pg_typeof((SELECT id FROM chorales LIMIT 1))::text as type_reel,
    CASE 
        WHEN pg_typeof((SELECT id FROM chorales LIMIT 1))::text = 'uuid' THEN '✅ UUID'
        WHEN pg_typeof((SELECT id FROM chorales LIMIT 1))::text = 'integer' THEN '🔢 INTEGER'
        ELSE '⚠️ Autre: ' || pg_typeof((SELECT id FROM chorales LIMIT 1))::text
    END as type_label;

-- ============================================
-- 2. Profils sans user_id
-- ============================================

SELECT '📋 2. Profils sans user_id' as section;

SELECT 
    COUNT(*) as nombre_profils_orphelins,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun profil orphelin'
        ELSE '❌ ' || COUNT(*)::text || ' profil(s) à supprimer'
    END as statut
FROM profiles
WHERE user_id IS NULL;

-- Liste des profils orphelins
SELECT 
    id,
    full_name,
    role,
    statut_validation,
    created_at
FROM profiles
WHERE user_id IS NULL
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 3. Doublons user_id
-- ============================================

SELECT '📋 3. Doublons user_id' as section;

SELECT 
    COUNT(*) as nombre_doublons,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun doublon'
        ELSE '❌ ' || COUNT(*)::text || ' user_id en double'
    END as statut
FROM (
    SELECT user_id
    FROM profiles
    WHERE user_id IS NOT NULL
    GROUP BY user_id
    HAVING COUNT(*) > 1
) doublons;

-- Liste des doublons
SELECT 
    user_id,
    COUNT(*) as nombre_profils,
    STRING_AGG(id::text, ', ') as profile_ids,
    STRING_AGG(full_name, ', ') as noms
FROM profiles
WHERE user_id IS NOT NULL
GROUP BY user_id
HAVING COUNT(*) > 1;

-- ============================================
-- 4. Relations invalides profiles → chorales
-- ============================================

SELECT '📋 4. Relations invalides profiles → chorales' as section;

SELECT 
    COUNT(*) as nombre_relations_invalides,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Toutes les relations valides'
        ELSE '❌ ' || COUNT(*)::text || ' relation(s) invalide(s)'
    END as statut
FROM profiles p
LEFT JOIN chorales c ON p.chorale_id = c.id
WHERE p.chorale_id IS NOT NULL AND c.id IS NULL;

-- ============================================
-- 5. Statistiques générales
-- ============================================

SELECT '📋 5. Statistiques' as section;

SELECT 
    'Total users (auth.users)' as element,
    COUNT(*)::text as valeur
FROM auth.users
UNION ALL
SELECT 
    'Total profiles' as element,
    COUNT(*)::text as valeur
FROM profiles
UNION ALL
SELECT 
    'Profiles avec user_id' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE user_id IS NOT NULL
UNION ALL
SELECT 
    'Profiles sans user_id' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Total chorales' as element,
    COUNT(*)::text as valeur
FROM chorales
UNION ALL
SELECT 
    'Chorales actives' as element,
    COUNT(*)::text as valeur
FROM chorales
WHERE statut = 'actif';

-- ============================================
-- RÉSULTAT FINAL
-- ============================================

SELECT '✅ TEST TERMINÉ' as resultat;
SELECT 'Vérifiez les sections ci-dessus pour les problèmes' as note;

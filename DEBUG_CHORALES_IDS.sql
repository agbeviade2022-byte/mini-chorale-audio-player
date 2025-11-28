-- =====================================================
-- DEBUG : Vérification des IDs de chorales
-- =====================================================

SELECT '🔍 DEBUG : IDs des chorales' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier la structure de la table chorales
-- ============================================

SELECT '📋 ÉTAPE 1 : Structure table chorales' as etape;

SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'id' THEN '🔑 Clé primaire'
        WHEN column_name = 'nom' THEN '📝 Nom'
        WHEN column_name = 'slug' THEN '🔗 Slug'
        ELSE '📄 Autre'
    END as description
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'chorales'
ORDER BY ordinal_position;

-- ============================================
-- ÉTAPE 2 : Lister toutes les chorales avec leurs IDs
-- ============================================

SELECT '📋 ÉTAPE 2 : Liste des chorales' as etape;

SELECT 
    id,
    nom,
    slug,
    ville,
    pays,
    statut,
    created_at,
    (SELECT COUNT(*) FROM profiles WHERE chorale_id = chorales.id) as nb_membres,
    CASE 
        WHEN statut = 'actif' THEN '✅ Active'
        ELSE '❌ Inactive'
    END as statut_label
FROM chorales
ORDER BY created_at DESC;

-- ============================================
-- ÉTAPE 3 : Vérifier le type de l'ID
-- ============================================

SELECT '📋 ÉTAPE 3 : Type de l''ID' as etape;

SELECT 
    pg_typeof(id) as type_id,
    id,
    nom,
    CASE 
        WHEN pg_typeof(id)::text = 'uuid' THEN '✅ UUID'
        WHEN pg_typeof(id)::text = 'integer' THEN '🔢 Integer'
        WHEN pg_typeof(id)::text = 'bigint' THEN '🔢 BigInt'
        WHEN pg_typeof(id)::text LIKE 'character%' THEN '📝 String'
        ELSE '⚠️ Autre: ' || pg_typeof(id)::text
    END as type_label
FROM chorales
LIMIT 5;

-- ============================================
-- ÉTAPE 4 : Vérifier les profils liés aux chorales
-- ============================================

SELECT '📋 ÉTAPE 4 : Profils par chorale' as etape;

SELECT 
    c.id as chorale_id,
    c.nom as chorale_nom,
    COUNT(p.id) as nombre_membres,
    STRING_AGG(p.full_name, ', ') as membres
FROM chorales c
LEFT JOIN profiles p ON p.chorale_id = c.id
GROUP BY c.id, c.nom
ORDER BY nombre_membres DESC;

-- ============================================
-- ÉTAPE 5 : Vérifier les chants par chorale
-- ============================================

SELECT '📋 ÉTAPE 5 : Chants par chorale' as etape;

SELECT 
    c.id as chorale_id,
    c.nom as chorale_nom,
    COUNT(ch.id) as nombre_chants,
    STRING_AGG(ch.titre, ', ' ORDER BY ch.titre) as chants
FROM chorales c
LEFT JOIN chants ch ON ch.chorale_id = c.id
GROUP BY c.id, c.nom
ORDER BY nombre_chants DESC;

-- ============================================
-- ÉTAPE 6 : Vérifier s'il y a des IDs orphelins
-- ============================================

SELECT '📋 ÉTAPE 6 : Vérification IDs orphelins' as etape;

-- Profils avec chorale_id invalide
SELECT 
    'Profils avec chorale_id invalide' as type,
    COUNT(*) as nombre,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun'
        ELSE '⚠️ ' || COUNT(*) || ' profil(s)'
    END as statut
FROM profiles p
LEFT JOIN chorales c ON p.chorale_id = c.id
WHERE p.chorale_id IS NOT NULL
AND c.id IS NULL

UNION ALL

-- Chants avec chorale_id invalide
SELECT 
    'Chants avec chorale_id invalide' as type,
    COUNT(*) as nombre,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun'
        ELSE '⚠️ ' || COUNT(*) || ' chant(s)'
    END as statut
FROM chants ch
LEFT JOIN chorales c ON ch.chorale_id = c.id
WHERE ch.chorale_id IS NOT NULL
AND c.id IS NULL;

-- ============================================
-- ÉTAPE 7 : Comparer les IDs entre Flutter et Dashboard
-- ============================================

SELECT '📋 ÉTAPE 7 : Format des IDs' as etape;

SELECT 
    id,
    nom,
    LENGTH(id::text) as longueur_id,
    CASE 
        WHEN id::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN '✅ Format UUID valide'
        WHEN id::text ~ '^[0-9]+$' 
        THEN '🔢 Format numérique'
        ELSE '⚠️ Format non standard'
    END as format_id
FROM chorales
ORDER BY created_at DESC;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '📊 RÉSUMÉ' as info;

SELECT 
    'Nombre total de chorales' as element,
    COUNT(*)::text as valeur
FROM chorales

UNION ALL

SELECT 
    'Chorales actives' as element,
    COUNT(*)::text as valeur
FROM chorales
WHERE statut = 'actif'

UNION ALL

SELECT 
    'Type d''ID utilisé' as element,
    pg_typeof(id)::text as valeur
FROM chorales
LIMIT 1;

SELECT '✅✅✅ DIAGNOSTIC TERMINÉ ✅✅✅' as resultat;

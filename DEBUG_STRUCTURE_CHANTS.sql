-- =====================================================
-- DEBUG : Structure complète table chants
-- =====================================================

SELECT '🔍 DEBUG : Structure table chants' as info;

-- ============================================
-- ÉTAPE 1 : Toutes les colonnes
-- ============================================

SELECT '📋 ÉTAPE 1 : Liste complète des colonnes' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length,
    '✅ Colonne présente' as statut
FROM information_schema.columns
WHERE table_name = 'chants'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================
-- ÉTAPE 2 : Vérifier colonnes spécifiques
-- ============================================

SELECT '📋 ÉTAPE 2 : Colonnes audio' as etape;

SELECT 
    column_name,
    data_type,
    CASE 
        WHEN column_name LIKE '%audio%' THEN '✅ Colonne audio trouvée'
        WHEN column_name LIKE '%url%' THEN '✅ Colonne URL trouvée'
        WHEN column_name LIKE '%fichier%' THEN '✅ Colonne fichier trouvée'
        ELSE '⚠️ Autre colonne'
    END as type
FROM information_schema.columns
WHERE table_name = 'chants'
AND table_schema = 'public'
AND (
    column_name LIKE '%audio%' 
    OR column_name LIKE '%url%'
    OR column_name LIKE '%fichier%'
)
ORDER BY column_name;

-- ============================================
-- ÉTAPE 3 : Compter les colonnes
-- ============================================

SELECT '📋 ÉTAPE 3 : Nombre de colonnes' as etape;

SELECT 
    COUNT(*) as nombre_colonnes,
    '✅ Colonnes dans la table' as statut
FROM information_schema.columns
WHERE table_name = 'chants'
AND table_schema = 'public';

-- ============================================
-- RÉSUMÉ
-- ============================================

SELECT '📊 RÉSUMÉ' as info;

SELECT 
    'Colonne audio_url existe' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'chants' AND column_name = 'audio_url'
        )
        THEN '✅ Oui'
        ELSE '❌ Non'
    END as statut
UNION ALL
SELECT 
    'Colonnes audio alternatives' as element,
    COALESCE(
        (SELECT string_agg(column_name, ', ')
         FROM information_schema.columns
         WHERE table_name = 'chants'
         AND (column_name LIKE '%audio%' OR column_name LIKE '%url%')),
        'Aucune'
    ) as statut;

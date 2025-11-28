-- =====================================================
-- DEBUG : Foreign key chants → chorales
-- =====================================================

SELECT '🔍 DEBUG : Foreign key chants' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier la structure de la table chants
-- ============================================

SELECT '📋 ÉTAPE 1 : Structure table chants' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'chants'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================
-- ÉTAPE 2 : Vérifier les foreign keys
-- ============================================

SELECT '📋 ÉTAPE 2 : Foreign keys sur table chants' as etape;

SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    '✅ Foreign key existe' as statut
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'chants'
AND tc.table_schema = 'public';

-- Compter
SELECT 
    COUNT(*) as nombre_foreign_keys,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ Aucune foreign key'
        ELSE '✅ Foreign keys présentes'
    END as statut
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
AND table_name = 'chants'
AND table_schema = 'public';

-- ============================================
-- ÉTAPE 3 : Vérifier la colonne chorale_id
-- ============================================

SELECT '📋 ÉTAPE 3 : Colonne chorale_id' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name = 'chorale_id' THEN '✅ Colonne existe'
        ELSE '⚠️ Autre colonne'
    END as statut
FROM information_schema.columns
WHERE table_name = 'chants'
AND column_name = 'chorale_id'
AND table_schema = 'public';

-- ============================================
-- ÉTAPE 4 : Vérifier la table chorales
-- ============================================

SELECT '📋 ÉTAPE 4 : Table chorales' as etape;

SELECT 
    tablename,
    '✅ Table existe' as statut
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'chorales';

-- ============================================
-- RÉSUMÉ
-- ============================================

SELECT '📊 RÉSUMÉ' as info;

SELECT 
    'Table chants existe' as element,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chants')
        THEN '✅ Oui'
        ELSE '❌ Non'
    END as statut
UNION ALL
SELECT 
    'Table chorales existe' as element,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chorales')
        THEN '✅ Oui'
        ELSE '❌ Non'
    END as statut
UNION ALL
SELECT 
    'Colonne chorale_id existe' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'chants' AND column_name = 'chorale_id'
        )
        THEN '✅ Oui'
        ELSE '❌ Non'
    END as statut
UNION ALL
SELECT 
    'Foreign key existe' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_constraints
            WHERE constraint_type = 'FOREIGN KEY'
            AND table_name = 'chants'
        )
        THEN '✅ Oui'
        ELSE '❌ Non'
    END as statut;

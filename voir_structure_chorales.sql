-- =====================================================
-- VOIR LA STRUCTURE EXACTE DE LA TABLE CHORALES
-- =====================================================

SELECT
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'chorales'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- AFFICHER AUSSI UN EXEMPLE DE DONNÉES
-- =====================================================

SELECT * FROM chorales LIMIT 1;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- Vous verrez toutes les colonnes disponibles dans chorales
-- Par exemple:
-- column_name | data_type | is_nullable
-- ------------|-----------|------------
-- id          | uuid      | NO
-- nom         | text      | YES
-- description | text      | YES
-- created_at  | timestamp | YES
-- etc...
-- =====================================================

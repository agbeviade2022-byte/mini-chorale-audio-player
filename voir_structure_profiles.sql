-- =====================================================
-- VOIR LA STRUCTURE EXACTE DE LA TABLE PROFILES
-- =====================================================

SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- Vous verrez toutes les colonnes disponibles dans profiles
-- Par exemple:
-- column_name | data_type | is_nullable
-- ------------|-----------|------------
-- id          | uuid      | NO
-- full_name   | varchar   | YES
-- role        | varchar   | YES
-- created_at  | timestamp | YES
-- etc...

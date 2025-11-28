-- =====================================================
-- TEST ÉTAPE PAR ÉTAPE
-- Exécutez chaque section séparément
-- =====================================================

-- ============================================
-- ÉTAPE 1 : Type d'ID chorales
-- ============================================

SELECT 
    'chorales.id' as colonne,
    pg_typeof((SELECT id FROM chorales LIMIT 1))::text as type_reel;

-- =====================================================
-- VÉRIFICATION SIMPLE - NE PEUT PAS ÉCHOUER
-- =====================================================
-- Version ultra-simplifiée sans colonnes optionnelles

-- =====================================================
-- 1. LISTER LES TABLES
-- =====================================================

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '⚠️ RLS Activé'
        ELSE '✅ RLS Désactivé'
    END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- =====================================================
-- 2. COMPTER LES PLANS
-- =====================================================

SELECT 'PLANS' as table_name, COUNT(*) as nombre FROM plans;

-- =====================================================
-- 3. COMPTER LES CHORALES
-- =====================================================

SELECT 'CHORALES' as table_name, COUNT(*) as nombre FROM chorales;

-- =====================================================
-- 4. COMPTER LES CHANTS
-- =====================================================

SELECT 'CHANTS' as table_name, COUNT(*) as nombre FROM chants;

-- =====================================================
-- 5. COMPTER LES FAVORIS
-- =====================================================

SELECT 'FAVORIS' as table_name, COUNT(*) as nombre FROM favoris;

-- =====================================================
-- 6. COMPTER LES PLAYLISTS
-- =====================================================

SELECT 'PLAYLISTS' as table_name, COUNT(*) as nombre FROM playlists;

-- =====================================================
-- 7. VÉRIFIER LES POLICIES RLS
-- =====================================================

SELECT 
    tablename,
    policyname
FROM pg_policies
WHERE schemaname = 'public';

-- =====================================================
-- INTERPRÉTATION
-- =====================================================

/*
✅ TOUT EST BON SI:
- Toutes les tables ont "✅ RLS Désactivé"
- PLANS: 4
- CHORALES: au moins 1
- Aucune policy RLS (requête 7 vide)

⚠️ À CORRIGER SI:
- Des tables ont "⚠️ RLS Activé" → Exécuter fix_all_rls.sql
- PLANS: moins de 4 → Exécuter create_tables_minimal.sql
- CHORALES: 0 → Exécuter create_tables_minimal.sql
- Des policies existent → Exécuter fix_all_rls.sql

🚀 SI TOUT EST BON:
Relancez votre app Flutter:
flutter run
*/

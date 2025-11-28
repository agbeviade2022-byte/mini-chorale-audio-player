-- =====================================================
-- SOLUTION TEMPORAIRE: Désactiver RLS pour tester
-- =====================================================
-- ⚠️ ATTENTION: Utilisez ceci UNIQUEMENT pour tester en développement
-- Ne jamais faire ça en production !

-- Désactiver RLS sur la table membres
ALTER TABLE membres DISABLE ROW LEVEL SECURITY;

-- Vérifier que RLS est désactivé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'membres';

-- =====================================================
-- Pour réactiver RLS plus tard (après avoir corrigé les policies):
-- =====================================================
-- ALTER TABLE membres ENABLE ROW LEVEL SECURITY;

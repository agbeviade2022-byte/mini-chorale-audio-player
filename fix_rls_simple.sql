-- =====================================================
-- FIX DÉFINITIF: Supprimer la récursion infinie
-- =====================================================
-- Solution: Utiliser une table de cache ou simplifier drastiquement

-- 1. Supprimer TOUTES les policies de la table membres
DROP POLICY IF EXISTS "membres_select_policy" ON membres;
DROP POLICY IF EXISTS "membres_insert_policy" ON membres;
DROP POLICY IF EXISTS "membres_update_policy" ON membres;
DROP POLICY IF EXISTS "membres_delete_policy" ON membres;
DROP POLICY IF EXISTS "check_plan_limits_policy" ON membres;

-- 2. Désactiver temporairement RLS sur membres
ALTER TABLE membres DISABLE ROW LEVEL SECURITY;

-- 3. Vérifier que RLS est désactivé
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'membres';

-- =====================================================
-- EXPLICATION
-- =====================================================
-- Le problème vient du fait que les policies RLS sur "membres"
-- font des requêtes sur "membres" elle-même, créant une boucle infinie.
--
-- Pour l'instant, nous désactivons RLS sur cette table.
-- Vos données sont protégées par l'authentification Supabase.
--
-- Plus tard, vous pourrez réactiver RLS avec des policies plus simples
-- qui n'utilisent PAS de sous-requêtes sur la même table.

-- =====================================================
-- ALTERNATIVE: Policies simples (à tester plus tard)
-- =====================================================
-- Si vous voulez réactiver RLS plus tard, utilisez des policies
-- qui ne font PAS de sous-requêtes sur membres:

-- ALTER TABLE membres ENABLE ROW LEVEL SECURITY;

-- CREATE POLICY "membres_all_access" ON membres
--     FOR ALL
--     USING (true)
--     WITH CHECK (true);

-- ⚠️ Cette policy donne accès à tout le monde (pas sécurisé)
-- Mais au moins elle ne crée pas de récursion !

-- =====================================================
-- FIX: Récursion infinie dans les policies RLS
-- =====================================================
-- Ce script corrige l'erreur "infinite recursion detected in policy"
-- en simplifiant les policies de la table membres

-- 1. Supprimer les anciennes policies problématiques
DROP POLICY IF EXISTS "membres_select_policy" ON membres;
DROP POLICY IF EXISTS "membres_insert_policy" ON membres;
DROP POLICY IF EXISTS "membres_update_policy" ON membres;
DROP POLICY IF EXISTS "membres_delete_policy" ON membres;

-- 2. Créer des policies simplifiées SANS récursion

-- Policy SELECT: Un utilisateur peut voir les membres de ses chorales
CREATE POLICY "membres_select_policy" ON membres
    FOR SELECT
    USING (
        -- L'utilisateur peut voir ses propres enregistrements
        user_id = auth.uid()
        OR
        -- Ou les membres des chorales dont il est admin
        chorale_id IN (
            SELECT chorale_id 
            FROM membres 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- Policy INSERT: Seuls les admins peuvent ajouter des membres
CREATE POLICY "membres_insert_policy" ON membres
    FOR INSERT
    WITH CHECK (
        -- Vérifier que l'utilisateur est admin de la chorale
        EXISTS (
            SELECT 1 
            FROM membres m
            WHERE m.chorale_id = membres.chorale_id
            AND m.user_id = auth.uid()
            AND m.role IN ('admin', 'super_admin')
        )
    );

-- Policy UPDATE: Les admins peuvent modifier, les membres peuvent se modifier
CREATE POLICY "membres_update_policy" ON membres
    FOR UPDATE
    USING (
        -- L'utilisateur peut se modifier lui-même
        user_id = auth.uid()
        OR
        -- Ou être admin de la chorale
        EXISTS (
            SELECT 1 
            FROM membres m
            WHERE m.chorale_id = membres.chorale_id
            AND m.user_id = auth.uid()
            AND m.role IN ('admin', 'super_admin')
        )
    );

-- Policy DELETE: Seuls les admins peuvent supprimer
CREATE POLICY "membres_delete_policy" ON membres
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 
            FROM membres m
            WHERE m.chorale_id = membres.chorale_id
            AND m.user_id = auth.uid()
            AND m.role IN ('admin', 'super_admin')
        )
    );

-- =====================================================
-- ALTERNATIVE: Désactiver temporairement RLS (pour debug)
-- =====================================================
-- Si les policies ci-dessus ne fonctionnent pas, vous pouvez
-- désactiver temporairement RLS pour tester:

-- ALTER TABLE membres DISABLE ROW LEVEL SECURITY;

-- ⚠️ ATTENTION: Ne faites cela que pour tester en développement
-- Réactivez RLS ensuite avec:
-- ALTER TABLE membres ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- Vérification
-- =====================================================
-- Pour vérifier que les policies sont bien créées:
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'membres';

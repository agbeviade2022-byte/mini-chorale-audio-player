-- =====================================================
-- FIX : Erreur 500 sur la table chorales
-- =====================================================

SELECT '🔧 FIX : Politiques RLS pour chorales' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier l'état actuel
-- ============================================

SELECT '📋 ÉTAPE 1 : État actuel des politiques' as etape;

-- Vérifier si RLS est activé
SELECT 
    tablename,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity = true THEN '✅ RLS activé'
        ELSE '❌ RLS désactivé'
    END as statut
FROM pg_tables
WHERE tablename = 'chorales';

-- Lister les politiques existantes
SELECT 
    policyname,
    cmd,
    roles,
    qual
FROM pg_policies
WHERE tablename = 'chorales';

-- ============================================
-- ÉTAPE 2 : Supprimer les politiques restrictives
-- ============================================

SELECT '📋 ÉTAPE 2 : Suppression des politiques' as etape;

-- Supprimer toutes les politiques sur chorales
DROP POLICY IF EXISTS "everyone_select_chorales" ON chorales;
DROP POLICY IF EXISTS "super_admins_update_chorales" ON chorales;
DROP POLICY IF EXISTS "super_admins_insert_chorales" ON chorales;
DROP POLICY IF EXISTS "super_admins_delete_chorales" ON chorales;
DROP POLICY IF EXISTS "authenticated_select_chorales" ON chorales;
DROP POLICY IF EXISTS "public_select_chorales" ON chorales;

-- ============================================
-- ÉTAPE 3 : Créer des politiques permissives
-- ============================================

SELECT '📋 ÉTAPE 3 : Création de nouvelles politiques' as etape;

-- 1. TOUT LE MONDE peut voir les chorales (lecture seule)
CREATE POLICY "authenticated_users_select_chorales"
ON chorales FOR SELECT
TO authenticated
USING (true);  -- ✅ Accès complet en lecture

-- 2. Politique pour les utilisateurs anonymes (si nécessaire)
CREATE POLICY "anon_users_select_chorales"
ON chorales FOR SELECT
TO anon
USING (true);  -- ✅ Accès complet en lecture

-- 3. Super admins peuvent tout faire
CREATE POLICY "super_admins_all_chorales"
ON chorales FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
);

-- ============================================
-- ÉTAPE 4 : Vérifier les permissions
-- ============================================

SELECT '📋 ÉTAPE 4 : Vérification' as etape;

-- Tester la lecture
SELECT 
    id,
    nom,
    '✅ Lecture OK' as statut
FROM chorales
LIMIT 5;

-- Compter les chorales
SELECT 
    COUNT(*) as nb_chorales,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Chorales accessibles'
        ELSE '⚠️ Aucune chorale'
    END as resultat
FROM chorales;

-- Lister les nouvelles politiques
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual = 'true' THEN '✅ Accès complet'
        ELSE '⚠️ Accès restreint'
    END as type_acces
FROM pg_policies
WHERE tablename = 'chorales'
ORDER BY policyname;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ CHORALES ACCESSIBLES ✅✅✅' as resultat;
SELECT 'Rafraîchissez le dashboard pour voir les chorales' as note;
SELECT 'Le dropdown de sélection devrait maintenant fonctionner' as action;

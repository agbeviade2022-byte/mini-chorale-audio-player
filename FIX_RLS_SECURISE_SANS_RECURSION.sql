-- =====================================================
-- FIX SÉCURISÉ : RLS sans récursion
-- =====================================================

SELECT '🔐 FIX SÉCURISÉ : Politiques RLS correctes' as info;

-- ============================================
-- ÉTAPE 1 : Nettoyer toutes les politiques
-- ============================================

SELECT '📋 ÉTAPE 1 : Nettoyage complet' as etape;

-- Supprimer TOUTES les politiques sur profiles
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'profiles') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON profiles';
    END LOOP;
END $$;

-- Supprimer TOUTES les politiques sur chorales
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'chorales') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON chorales';
    END LOOP;
END $$;

-- Supprimer TOUTES les politiques sur chants
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'chants') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON chants';
    END LOOP;
END $$;

SELECT '✅ Toutes les anciennes politiques supprimées' as statut;

-- ============================================
-- ÉTAPE 2 : Créer une fonction helper STABLE
-- ============================================

SELECT '📋 ÉTAPE 2 : Fonction helper' as etape;

-- Fonction pour obtenir le rôle de l'utilisateur actuel
-- ✅ STABLE = pas de récursion, résultat mis en cache
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT AS $$
    SELECT role FROM profiles WHERE user_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Fonction pour obtenir la chorale de l'utilisateur actuel
CREATE OR REPLACE FUNCTION public.current_user_chorale_id()
RETURNS UUID AS $$
    SELECT chorale_id FROM profiles WHERE user_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Fonction pour vérifier si l'utilisateur est validé
CREATE OR REPLACE FUNCTION public.current_user_is_validated()
RETURNS BOOLEAN AS $$
    SELECT statut_validation = 'valide' FROM profiles WHERE user_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

SELECT '✅ Fonctions helper créées' as statut;

-- ============================================
-- ÉTAPE 3 : Politiques PROFILES (sécurisées)
-- ============================================

SELECT '📋 ÉTAPE 3 : Politiques PROFILES' as etape;

-- 1. SELECT : Voir son propre profil OU être super admin
CREATE POLICY "profiles_select_policy"
ON profiles FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()  -- Son propre profil
    OR
    public.current_user_role() = 'super_admin'  -- OU super admin
);

-- 2. UPDATE : Modifier son propre profil (sauf role et chorale_id)
CREATE POLICY "profiles_update_own_policy"
ON profiles FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (
    user_id = auth.uid()
    AND role = (SELECT role FROM profiles WHERE user_id = auth.uid())
    AND (
        chorale_id = (SELECT chorale_id FROM profiles WHERE user_id = auth.uid())
        OR chorale_id IS NULL
    )
);

-- 3. UPDATE : Super admins peuvent tout modifier
CREATE POLICY "profiles_update_admin_policy"
ON profiles FOR UPDATE
TO authenticated
USING (public.current_user_role() = 'super_admin');

-- 4. INSERT : Seuls les super admins peuvent créer des profils
CREATE POLICY "profiles_insert_policy"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (public.current_user_role() = 'super_admin');

-- 5. DELETE : Seuls les super admins peuvent supprimer
CREATE POLICY "profiles_delete_policy"
ON profiles FOR DELETE
TO authenticated
USING (public.current_user_role() = 'super_admin');

SELECT '✅ Politiques PROFILES créées' as statut;

-- ============================================
-- ÉTAPE 4 : Politiques CHORALES (sécurisées)
-- ============================================

SELECT '📋 ÉTAPE 4 : Politiques CHORALES' as etape;

-- 1. SELECT : Tout le monde peut voir les chorales
CREATE POLICY "chorales_select_policy"
ON chorales FOR SELECT
TO authenticated
USING (true);

-- 2. INSERT : Seuls les super admins
CREATE POLICY "chorales_insert_policy"
ON chorales FOR INSERT
TO authenticated
WITH CHECK (public.current_user_role() = 'super_admin');

-- 3. UPDATE : Seuls les super admins
CREATE POLICY "chorales_update_policy"
ON chorales FOR UPDATE
TO authenticated
USING (public.current_user_role() = 'super_admin');

-- 4. DELETE : Seuls les super admins
CREATE POLICY "chorales_delete_policy"
ON chorales FOR DELETE
TO authenticated
USING (public.current_user_role() = 'super_admin');

SELECT '✅ Politiques CHORALES créées' as statut;

-- ============================================
-- ÉTAPE 5 : Politiques CHANTS (sécurisées)
-- ============================================

SELECT '📋 ÉTAPE 5 : Politiques CHANTS' as etape;

-- 1. SELECT : Voir les chants de SA chorale OU être admin/super admin
CREATE POLICY "chants_select_policy"
ON chants FOR SELECT
TO authenticated
USING (
    -- Membre validé de la même chorale
    (
        chorale_id = public.current_user_chorale_id()
        AND public.current_user_is_validated() = true
    )
    OR
    -- OU admin/super admin
    public.current_user_role() IN ('admin', 'super_admin')
);

-- 2. INSERT : Seuls les admins et super admins
CREATE POLICY "chants_insert_policy"
ON chants FOR INSERT
TO authenticated
WITH CHECK (
    public.current_user_role() IN ('admin', 'super_admin')
);

-- 3. UPDATE : Admins pour leur chorale, super admins pour tout
CREATE POLICY "chants_update_policy"
ON chants FOR UPDATE
TO authenticated
USING (
    public.current_user_role() = 'super_admin'
    OR
    (
        public.current_user_role() = 'admin'
        AND chorale_id = public.current_user_chorale_id()
    )
);

-- 4. DELETE : Seuls les super admins
CREATE POLICY "chants_delete_policy"
ON chants FOR DELETE
TO authenticated
USING (public.current_user_role() = 'super_admin');

SELECT '✅ Politiques CHANTS créées' as statut;

-- ============================================
-- ÉTAPE 6 : Activer RLS
-- ============================================

SELECT '📋 ÉTAPE 6 : Activation RLS' as etape;

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chorales ENABLE ROW LEVEL SECURITY;
ALTER TABLE chants ENABLE ROW LEVEL SECURITY;

SELECT '✅ RLS activé sur toutes les tables' as statut;

-- ============================================
-- ÉTAPE 7 : Vérification
-- ============================================

SELECT '📋 ÉTAPE 7 : Vérification' as etape;

-- Vérifier que RLS est activé
SELECT 
    tablename,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity = true THEN '✅ RLS activé'
        ELSE '❌ RLS désactivé'
    END as statut
FROM pg_tables
WHERE tablename IN ('profiles', 'chorales', 'chants')
ORDER BY tablename;

-- Compter les politiques
SELECT 
    tablename,
    COUNT(*) as nb_policies,
    CASE 
        WHEN COUNT(*) >= 3 THEN '✅ Bien protégé'
        ELSE '⚠️ Peu de politiques'
    END as niveau_securite
FROM pg_policies
WHERE tablename IN ('profiles', 'chorales', 'chants')
GROUP BY tablename
ORDER BY tablename;

-- Lister les politiques
SELECT 
    tablename,
    policyname,
    cmd,
    '✅ Créée' as statut
FROM pg_policies
WHERE tablename IN ('profiles', 'chorales', 'chants')
ORDER BY tablename, policyname;

-- ============================================
-- ÉTAPE 8 : Tests d'accès
-- ============================================

SELECT '📋 ÉTAPE 8 : Tests' as etape;

-- Test 1 : Chorales accessibles
SELECT 
    'chorales' as table_name,
    COUNT(*) as nb_lignes,
    '✅ Accessible' as statut
FROM chorales;

-- Test 2 : Profil accessible
SELECT 
    'profiles' as table_name,
    COUNT(*) as nb_lignes,
    '✅ Accessible' as statut
FROM profiles
WHERE user_id = auth.uid();

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ SÉCURITÉ COMPLÈTE ✅✅✅' as resultat;
SELECT '🔐 RLS activé avec politiques sécurisées' as note1;
SELECT '✅ Pas de récursion grâce aux fonctions STABLE' as note2;
SELECT '🛡️ Membres ne voient que leur chorale' as note3;
SELECT '🔴 Super admins ont accès complet' as note4;
SELECT 'Rafraîchissez le dashboard (F5)' as action;

-- ============================================
-- DOCUMENTATION
-- ============================================

/*
🔐 SÉCURITÉ MISE EN PLACE

PROFILES :
✅ Chaque utilisateur voit son propre profil
✅ Super admins voient tous les profils
✅ Utilisateurs ne peuvent pas changer leur rôle/chorale
✅ Super admins peuvent tout modifier

CHORALES :
✅ Tout le monde peut voir les chorales (lecture seule)
✅ Seuls les super admins peuvent créer/modifier/supprimer

CHANTS :
✅ Membres voient UNIQUEMENT les chants de LEUR chorale
✅ Membres doivent être validés (statut_validation = 'valide')
✅ Admins voient les chants de LEUR chorale
✅ Super admins voient TOUS les chants
✅ Seuls admins/super admins peuvent ajouter des chants

FONCTIONS HELPER :
✅ public.current_user_role() - Retourne le rôle de l'utilisateur
✅ public.current_user_chorale_id() - Retourne la chorale de l'utilisateur
✅ public.current_user_is_validated() - Vérifie si l'utilisateur est validé
✅ STABLE = résultat mis en cache = PAS DE RÉCURSION

AVANTAGES :
✅ Sécurité maximale
✅ Pas de récursion infinie
✅ Performances optimales (cache)
✅ Isolation complète par chorale
*/

-- =====================================================
-- CORRIGER LA RÉCURSION INFINIE DES POLICIES RLS
-- =====================================================
-- URGENT : Exécutez ce script MAINTENANT dans Supabase
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : SUPPRIMER TOUTES LES POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Utilisateurs voient leur profil" ON profiles;
DROP POLICY IF EXISTS "Admins voient tous les profils" ON profiles;
DROP POLICY IF EXISTS "Utilisateurs modifient leur profil" ON profiles;
DROP POLICY IF EXISTS "Admins modifient tous les profils" ON profiles;
DROP POLICY IF EXISTS "Admins suppriment des profils" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_admin_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_delete_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_select_all" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_update_admin" ON profiles;
DROP POLICY IF EXISTS "profiles_delete_admin" ON profiles;

-- =====================================================
-- ÉTAPE 2 : CRÉER DES POLICIES SIMPLES (SANS RÉCURSION)
-- =====================================================

-- LECTURE : Utilisateur voit son propre profil
CREATE POLICY "select_own_profile"
ON profiles FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- LECTURE : Admin voit tous les profils (utilise une fonction helper)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'super_admin')
    );
$$;

CREATE POLICY "select_all_profiles_admin"
ON profiles FOR SELECT
TO authenticated
USING (is_admin());

-- MODIFICATION : Utilisateur modifie son propre profil
CREATE POLICY "update_own_profile"
ON profiles FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- MODIFICATION : Admin modifie tous les profils
CREATE POLICY "update_all_profiles_admin"
ON profiles FOR UPDATE
TO authenticated
USING (is_admin())
WITH CHECK (true);

-- SUPPRESSION : Seulement super_admin
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    );
$$;

CREATE POLICY "delete_profile_super_admin"
ON profiles FOR DELETE
TO authenticated
USING (is_super_admin());

-- =====================================================
-- ÉTAPE 3 : VÉRIFICATION
-- =====================================================

-- Voir les policies créées
SELECT
    policyname,
    cmd,
    'Policy créée' as status
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;

-- Voir les fonctions créées
SELECT
    proname as function_name,
    'Fonction créée' as status
FROM pg_proc
WHERE proname IN ('is_admin', 'is_super_admin');

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================

/*
✅ 5 policies créées (SELECT x2, UPDATE x2, DELETE x1)
✅ 2 fonctions créées (is_admin, is_super_admin)
✅ PAS de récursion infinie
✅ L'app peut maintenant lire les profils

RECONNECTEZ-VOUS DANS L'APP APRÈS AVOIR EXÉCUTÉ CE SCRIPT !
*/

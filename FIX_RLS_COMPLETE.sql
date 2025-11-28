-- =====================================================
-- FIX COMPLET : Récursion infinie RLS
-- =====================================================
-- Corrige toutes les policies RLS pour éviter récursion
-- =====================================================

SELECT '🔧 CORRECTION COMPLÈTE : Policies RLS' as info;

-- ============================================
-- ÉTAPE 1 : Supprimer TOUTES les policies problématiques
-- ============================================

SELECT '📋 ÉTAPE 1 : Suppression policies' as etape;

-- Profiles
DROP POLICY IF EXISTS "select_own_profile" ON public.profiles;
DROP POLICY IF EXISTS "select_all_for_admins" ON public.profiles;
DROP POLICY IF EXISTS "update_own_profile" ON public.profiles;
DROP POLICY IF EXISTS "update_all_for_admins" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Super admins can do everything" ON public.profiles;

-- Modules permissions
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.modules_permissions;
DROP POLICY IF EXISTS "Enable read for authenticated users" ON public.modules_permissions;
DROP POLICY IF EXISTS "Admins can manage permissions" ON public.modules_permissions;

-- User permissions
DROP POLICY IF EXISTS "Users can view own permissions" ON public.user_permissions;
DROP POLICY IF EXISTS "Admins can manage all permissions" ON public.user_permissions;

SELECT '✅ Policies supprimées' as status;

-- ============================================
-- ÉTAPE 2 : Créer une fonction helper pour vérifier le rôle
-- ============================================

SELECT '📋 ÉTAPE 2 : Création fonction helper' as etape;

-- Fonction pour obtenir le rôle de l'utilisateur connecté
-- SECURITY DEFINER pour éviter récursion
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT role FROM public.profiles WHERE user_id = auth.uid() LIMIT 1;
$$;

-- Fonction pour vérifier si l'utilisateur est admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    );
$$;

-- Fonction pour vérifier si l'utilisateur est super admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role = 'super_admin'
    );
$$;

SELECT '✅ Fonctions helper créées' as status;

-- ============================================
-- ÉTAPE 3 : Créer policies SIMPLES pour profiles
-- ============================================

SELECT '📋 ÉTAPE 3 : Policies profiles' as etape;

-- SELECT: Voir son propre profil
CREATE POLICY "profiles_select_own"
ON public.profiles
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- SELECT: Admins voient tout (utilise fonction helper)
CREATE POLICY "profiles_select_admin"
ON public.profiles
FOR SELECT
TO authenticated
USING (public.is_admin());

-- UPDATE: Modifier son propre profil
CREATE POLICY "profiles_update_own"
ON public.profiles
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- UPDATE: Admins modifient tout
CREATE POLICY "profiles_update_admin"
ON public.profiles
FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ALL: Super admins font tout
CREATE POLICY "profiles_all_super_admin"
ON public.profiles
FOR ALL
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

SELECT '✅ Policies profiles créées' as status;

-- ============================================
-- ÉTAPE 4 : Créer policies pour modules_permissions
-- ============================================

SELECT '📋 ÉTAPE 4 : Policies modules_permissions' as etape;

-- SELECT: Tous les utilisateurs authentifiés peuvent voir
CREATE POLICY "modules_permissions_select_all"
ON public.modules_permissions
FOR SELECT
TO authenticated
USING (true);

-- INSERT/UPDATE/DELETE: Seuls les admins
CREATE POLICY "modules_permissions_modify_admin"
ON public.modules_permissions
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

SELECT '✅ Policies modules_permissions créées' as status;

-- ============================================
-- ÉTAPE 5 : Créer policies pour user_permissions
-- ============================================

SELECT '📋 ÉTAPE 5 : Policies user_permissions' as etape;

-- SELECT: Voir ses propres permissions
CREATE POLICY "user_permissions_select_own"
ON public.user_permissions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- SELECT: Admins voient tout
CREATE POLICY "user_permissions_select_admin"
ON public.user_permissions
FOR SELECT
TO authenticated
USING (public.is_admin());

-- INSERT/UPDATE/DELETE: Seuls les admins
CREATE POLICY "user_permissions_modify_admin"
ON public.user_permissions
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

SELECT '✅ Policies user_permissions créées' as status;

-- ============================================
-- ÉTAPE 6 : Permissions sur les fonctions
-- ============================================

SELECT '📋 ÉTAPE 6 : Permissions fonctions' as etape;

GRANT EXECUTE ON FUNCTION public.get_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;

SELECT '✅ Permissions accordées' as status;

-- ============================================
-- ÉTAPE 7 : Vérification
-- ============================================

SELECT '📋 ÉTAPE 7 : Vérification' as etape;

-- Vérifier les fonctions
SELECT 
    routine_name,
    security_type,
    '✅ Fonction créée' as statut
FROM information_schema.routines
WHERE routine_name IN ('get_user_role', 'is_admin', 'is_super_admin')
AND routine_schema = 'public';

-- Vérifier les policies profiles
SELECT 
    policyname,
    '✅ Policy active' as statut
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Vérifier les policies modules_permissions
SELECT 
    policyname,
    '✅ Policy active' as statut
FROM pg_policies
WHERE tablename = 'modules_permissions'
ORDER BY policyname;

-- Vérifier les policies user_permissions
SELECT 
    policyname,
    '✅ Policy active' as statut
FROM pg_policies
WHERE tablename = 'user_permissions'
ORDER BY policyname;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ CORRECTION RLS COMPLÈTE TERMINÉE ✅✅✅' as resultat;
SELECT 'Rafraîchissez le dashboard (F5)' as action;
SELECT 'Les policies utilisent maintenant des fonctions helper pour éviter la récursion' as note;

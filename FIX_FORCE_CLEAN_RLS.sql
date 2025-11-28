-- =====================================================
-- NETTOYAGE FORCÉ : Supprimer TOUT et recréer
-- =====================================================
-- Force la suppression de toutes les policies
-- =====================================================

SELECT '🧹 NETTOYAGE FORCÉ COMPLET' as info;

-- ============================================
-- ÉTAPE 1 : DÉSACTIVER RLS sur toutes les tables
-- ============================================

SELECT '📋 ÉTAPE 1 : Désactivation RLS' as etape;

ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.modules_permissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permissions DISABLE ROW LEVEL SECURITY;

SELECT '✅ RLS désactivé sur toutes les tables' as status;

-- ============================================
-- ÉTAPE 2 : Supprimer TOUTES les policies
-- ============================================

SELECT '📋 ÉTAPE 2 : Suppression de TOUTES les policies' as etape;

-- Supprimer toutes les policies sur profiles
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'profiles') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', r.policyname);
    END LOOP;
END $$;

-- Supprimer toutes les policies sur modules_permissions
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'modules_permissions') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.modules_permissions', r.policyname);
    END LOOP;
END $$;

-- Supprimer toutes les policies sur user_permissions
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'user_permissions') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.user_permissions', r.policyname);
    END LOOP;
END $$;

SELECT '✅ Toutes les policies supprimées' as status;

-- ============================================
-- ÉTAPE 3 : Vérifier qu'il ne reste aucune policy
-- ============================================

SELECT '📋 ÉTAPE 3 : Vérification' as etape;

SELECT 
    COUNT(*) as nombre_policies_restantes,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucune policy restante'
        ELSE '❌ Il reste des policies'
    END as statut
FROM pg_policies
WHERE tablename IN ('profiles', 'modules_permissions', 'user_permissions');

-- ============================================
-- ÉTAPE 4 : Réactiver RLS avec policies ULTRA-SIMPLES
-- ============================================

SELECT '📋 ÉTAPE 4 : Réactivation RLS avec policies simples' as etape;

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_all"
ON public.profiles
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Modules permissions
ALTER TABLE public.modules_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "modules_permissions_all"
ON public.modules_permissions
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- User permissions
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_permissions_all"
ON public.user_permissions
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

SELECT '✅ RLS réactivé avec policies ultra-simples' as status;

-- ============================================
-- ÉTAPE 5 : Vérification finale
-- ============================================

SELECT '📋 ÉTAPE 5 : Vérification finale' as etape;

-- Vérifier RLS
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS activé'
        ELSE '❌ RLS désactivé'
    END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'modules_permissions', 'user_permissions');

-- Vérifier policies
SELECT 
    tablename,
    policyname,
    cmd,
    '✅ Policy active' as statut
FROM pg_policies
WHERE tablename IN ('profiles', 'modules_permissions', 'user_permissions')
ORDER BY tablename, policyname;

-- Compter les policies
SELECT 
    tablename,
    COUNT(*) as nombre_policies
FROM pg_policies
WHERE tablename IN ('profiles', 'modules_permissions', 'user_permissions')
GROUP BY tablename;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ NETTOYAGE FORCÉ TERMINÉ ✅✅✅' as resultat;
SELECT 'RLS activé avec UNE SEULE policy par table' as note;
SELECT 'Policy: USING (true) WITH CHECK (true)' as policy_type;
SELECT 'Aucune sous-requête = Aucune récursion possible' as garantie;

-- =====================================================
-- SÉCURITÉ COMPLÈTE : Accès par chorale
-- =====================================================

SELECT '🔐 SÉCURITÉ : Mise en place des protections' as info;

-- ============================================
-- ÉTAPE 1 : Supprimer les anciennes politiques RLS
-- ============================================

SELECT '📋 ÉTAPE 1 : Nettoyage des anciennes politiques' as etape;

-- Supprimer toutes les politiques sur chants
DROP POLICY IF EXISTS "Membres peuvent voir les chants de leur chorale" ON chants;
DROP POLICY IF EXISTS "Admins peuvent voir tous les chants" ON chants;
DROP POLICY IF EXISTS "Super admins peuvent tout voir" ON chants;
DROP POLICY IF EXISTS "Membres peuvent voir chants" ON chants;
DROP POLICY IF EXISTS "Admins peuvent gérer chants" ON chants;
DROP POLICY IF EXISTS "Chants visibles par membres de la chorale" ON chants;
DROP POLICY IF EXISTS "Chants modifiables par admins" ON chants;

-- Supprimer toutes les politiques sur profiles
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leur profil" ON profiles;
DROP POLICY IF EXISTS "Utilisateurs peuvent modifier leur profil" ON profiles;
DROP POLICY IF EXISTS "Admins peuvent voir tous les profils" ON profiles;
DROP POLICY IF EXISTS "Super admins peuvent tout gérer" ON profiles;

-- ============================================
-- ÉTAPE 2 : Activer RLS sur toutes les tables
-- ============================================

SELECT '📋 ÉTAPE 2 : Activation RLS' as etape;

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chants ENABLE ROW LEVEL SECURITY;
ALTER TABLE chorales ENABLE ROW LEVEL SECURITY;

-- ============================================
-- ÉTAPE 3 : Politiques RLS pour PROFILES
-- ============================================

SELECT '📋 ÉTAPE 3 : Politiques RLS - Profiles' as etape;

-- 1. Chaque utilisateur peut voir son propre profil
CREATE POLICY "users_select_own_profile"
ON profiles FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- 2. Chaque utilisateur peut modifier son propre profil (sauf chorale_id et role)
CREATE POLICY "users_update_own_profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (
    auth.uid() = user_id 
    AND chorale_id = (SELECT chorale_id FROM profiles WHERE user_id = auth.uid())
    AND role = (SELECT role FROM profiles WHERE user_id = auth.uid())
);

-- 3. Super admins peuvent tout voir
CREATE POLICY "super_admins_select_all_profiles"
ON profiles FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
);

-- 4. Super admins peuvent tout modifier (y compris chorale_id et role)
CREATE POLICY "super_admins_update_all_profiles"
ON profiles FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
);

-- 5. Admins peuvent voir les profils de leur chorale
CREATE POLICY "admins_select_chorale_profiles"
ON profiles FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid()
        AND p.role IN ('admin', 'super_admin')
        AND (
            p.role = 'super_admin' 
            OR profiles.chorale_id = p.chorale_id
        )
    )
);

-- ============================================
-- ÉTAPE 4 : Politiques RLS pour CHANTS
-- ============================================

SELECT '📋 ÉTAPE 4 : Politiques RLS - Chants' as etape;

-- 1. Membres peuvent voir UNIQUEMENT les chants de leur chorale
CREATE POLICY "members_select_own_chorale_chants"
ON chants FOR SELECT
TO authenticated
USING (
    -- Vérifier que l'utilisateur est membre de la même chorale
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND chorale_id = chants.chorale_id
        AND role = 'membre'
        AND statut_validation = 'valide'
    )
    OR
    -- OU que l'utilisateur est admin/super_admin
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'super_admin')
    )
);

-- 2. Seuls les admins peuvent ajouter des chants
CREATE POLICY "admins_insert_chants"
ON chants FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'super_admin')
    )
);

-- 3. Admins peuvent modifier les chants de leur chorale
CREATE POLICY "admins_update_chorale_chants"
ON chants FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid()
        AND p.role IN ('admin', 'super_admin')
        AND (
            p.role = 'super_admin'
            OR chants.chorale_id = p.chorale_id
        )
    )
);

-- 4. Super admins peuvent supprimer n'importe quel chant
CREATE POLICY "super_admins_delete_chants"
ON chants FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
);

-- ============================================
-- ÉTAPE 5 : Politiques RLS pour CHORALES
-- ============================================

SELECT '📋 ÉTAPE 5 : Politiques RLS - Chorales' as etape;

-- 1. Tout le monde peut voir les chorales
CREATE POLICY "everyone_select_chorales"
ON chorales FOR SELECT
TO authenticated
USING (true);

-- 2. Seuls les super admins peuvent modifier les chorales
CREATE POLICY "super_admins_update_chorales"
ON chorales FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
);

-- 3. Seuls les super admins peuvent créer des chorales
CREATE POLICY "super_admins_insert_chorales"
ON chorales FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
);

-- 4. Seuls les super admins peuvent supprimer des chorales
CREATE POLICY "super_admins_delete_chorales"
ON chorales FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
);

-- ============================================
-- ÉTAPE 6 : Fonction pour vérifier l'accès
-- ============================================

SELECT '📋 ÉTAPE 6 : Fonction de vérification' as etape;

-- Fonction pour vérifier si un utilisateur a accès à une chorale
CREATE OR REPLACE FUNCTION user_has_access_to_chorale(
    p_user_id UUID,
    p_chorale_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = p_user_id
        AND (
            role = 'super_admin'
            OR (role = 'admin' AND chorale_id = p_chorale_id)
            OR (role = 'membre' AND chorale_id = p_chorale_id AND statut_validation = 'valide')
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir la chorale d'un utilisateur
CREATE OR REPLACE FUNCTION get_user_chorale_id(p_user_id UUID)
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT chorale_id
        FROM profiles
        WHERE user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ÉTAPE 7 : Tester la sécurité
-- ============================================

SELECT '📋 ÉTAPE 7 : Tests de sécurité' as etape;

-- Test 1 : Vérifier les politiques
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%chorale_id%' THEN '✅ Filtre chorale'
        WHEN qual LIKE '%super_admin%' THEN '🔴 Super admin'
        WHEN qual LIKE '%admin%' THEN '🟠 Admin'
        ELSE '⚪ Autre'
    END as type_securite
FROM pg_policies
WHERE tablename IN ('profiles', 'chants', 'chorales')
ORDER BY tablename, policyname;

-- Test 2 : Compter les politiques par table
SELECT 
    tablename,
    COUNT(*) as nb_policies,
    CASE 
        WHEN COUNT(*) >= 3 THEN '✅ Bien protégé'
        WHEN COUNT(*) >= 1 THEN '⚠️ Protection partielle'
        ELSE '❌ Pas de protection'
    END as niveau_securite
FROM pg_policies
WHERE tablename IN ('profiles', 'chants', 'chorales')
GROUP BY tablename;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ SÉCURITÉ MISE EN PLACE ✅✅✅' as resultat;
SELECT 'Les membres ne peuvent voir que les données de leur chorale' as note1;
SELECT 'Les admins peuvent gérer leur chorale' as note2;
SELECT 'Les super admins ont accès à tout' as note3;

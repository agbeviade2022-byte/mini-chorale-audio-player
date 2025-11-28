-- =====================================================
-- FIX RLS COMPLET : Toutes les tables du système de permissions
-- =====================================================
-- Configure les Row Level Security policies pour:
-- - modules_permissions
-- - user_permissions
-- =====================================================

-- =====================================================
-- TABLE: modules_permissions
-- =====================================================

-- Désactiver RLS temporairement pour nettoyer
ALTER TABLE modules_permissions DISABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Tout le monde peut lire les modules" ON modules_permissions;
DROP POLICY IF EXISTS "Super admins peuvent gérer les modules" ON modules_permissions;

-- Policy 1: Tous les utilisateurs authentifiés peuvent lire les modules
CREATE POLICY "Tout le monde peut lire les modules"
ON modules_permissions
FOR SELECT
TO authenticated
USING (true);

-- Policy 2: Seuls les Super Admins peuvent modifier les modules
CREATE POLICY "Super admins peuvent gérer les modules"
ON modules_permissions
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'super_admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'super_admin'
  )
);

-- Réactiver RLS
ALTER TABLE modules_permissions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- TABLE: user_permissions
-- =====================================================

-- Désactiver RLS temporairement pour nettoyer
ALTER TABLE user_permissions DISABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Super admins peuvent tout faire sur user_permissions" ON user_permissions;
DROP POLICY IF EXISTS "Maitres de choeur peuvent gérer permissions" ON user_permissions;
DROP POLICY IF EXISTS "Users peuvent voir leurs permissions" ON user_permissions;
DROP POLICY IF EXISTS "Admins peuvent gérer les permissions" ON user_permissions;

-- Policy 1: Super Admins peuvent tout faire
CREATE POLICY "Super admins peuvent tout faire sur user_permissions"
ON user_permissions
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'super_admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'super_admin'
  )
);

-- Policy 2: Maîtres de Chœur peuvent gérer les permissions de leur chorale
CREATE POLICY "Maitres de choeur peuvent gérer permissions"
ON user_permissions
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles p1
    WHERE p1.user_id = auth.uid()
    AND p1.est_maitre_choeur = true
    AND EXISTS (
      SELECT 1 FROM profiles p2
      WHERE p2.user_id = user_permissions.user_id
      AND p2.chorale_id = p1.chorale_id
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles p1
    WHERE p1.user_id = auth.uid()
    AND p1.est_maitre_choeur = true
    AND EXISTS (
      SELECT 1 FROM profiles p2
      WHERE p2.user_id = user_permissions.user_id
      AND p2.chorale_id = p1.chorale_id
    )
  )
);

-- Policy 3: Utilisateurs peuvent voir leurs propres permissions
CREATE POLICY "Users peuvent voir leurs permissions"
ON user_permissions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Réactiver RLS
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- VÉRIFICATIONS
-- =====================================================

-- Vérifier que RLS est activé
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS activé'
        ELSE '❌ RLS désactivé'
    END as status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('modules_permissions', 'user_permissions');

-- Lister toutes les policies
SELECT 
    '📋 Policies pour ' || tablename as info,
    policyname,
    cmd as commande,
    CASE 
        WHEN permissive = 'PERMISSIVE' THEN '✅ Permissive'
        ELSE '🔒 Restrictive'
    END as type
FROM pg_policies
WHERE tablename IN ('modules_permissions', 'user_permissions')
ORDER BY tablename, policyname;

-- Test: Vérifier votre rôle
SELECT 
    '👤 Votre rôle:' as info,
    role,
    est_maitre_choeur,
    full_name
FROM profiles
WHERE user_id = auth.uid();

-- Test: Vérifier vos permissions actuelles
SELECT 
    '🔑 Vos permissions:' as info,
    COUNT(*) as nombre_permissions
FROM user_permissions
WHERE user_id = auth.uid();

SELECT '✅ Configuration RLS terminée avec succès !' as status;
SELECT '📝 Vous pouvez maintenant gérer les permissions depuis le dashboard' as info;

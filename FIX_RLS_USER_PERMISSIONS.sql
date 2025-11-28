-- =====================================================
-- FIX RLS : Policies pour user_permissions
-- =====================================================
-- Permet aux admins de gérer les permissions
-- =====================================================

-- Supprimer les anciennes policies si elles existent
DROP POLICY IF EXISTS "Super admins peuvent tout faire sur user_permissions" ON user_permissions;
DROP POLICY IF EXISTS "Admins peuvent gérer les permissions" ON user_permissions;
DROP POLICY IF EXISTS "Users peuvent voir leurs propres permissions" ON user_permissions;

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

-- Vérifier que RLS est activé
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

-- Test: Vérifier les policies
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
WHERE tablename = 'user_permissions';

SELECT '✅ Policies RLS créées avec succès pour user_permissions' as status;

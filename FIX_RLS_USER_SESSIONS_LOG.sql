-- =====================================================
-- FIX : Politique RLS pour user_sessions_log
-- =====================================================

SELECT '🔧 FIX : Politique RLS user_sessions_log' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier les politiques existantes
-- ============================================

SELECT '📋 ÉTAPE 1 : Politiques existantes' as etape;

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
WHERE tablename = 'user_sessions_log';

-- ============================================
-- ÉTAPE 2 : Supprimer les anciennes politiques
-- ============================================

SELECT '📋 ÉTAPE 2 : Suppression anciennes politiques' as etape;

-- Supprimer les anciennes politiques (noms français)
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leurs propres sessions" ON user_sessions_log;
DROP POLICY IF EXISTS "Utilisateurs peuvent créer leurs propres sessions" ON user_sessions_log;
DROP POLICY IF EXISTS "Utilisateurs peuvent mettre à jour leurs propres sessions" ON user_sessions_log;
DROP POLICY IF EXISTS "Super admins peuvent tout voir" ON user_sessions_log;

-- Supprimer les nouvelles politiques (noms anglais) si elles existent déjà
DROP POLICY IF EXISTS "user_sessions_log_select_own" ON user_sessions_log;
DROP POLICY IF EXISTS "user_sessions_log_insert_own" ON user_sessions_log;
DROP POLICY IF EXISTS "user_sessions_log_update_own" ON user_sessions_log;
DROP POLICY IF EXISTS "user_sessions_log_select_admin" ON user_sessions_log;

-- ============================================
-- ÉTAPE 3 : Créer les nouvelles politiques
-- ============================================

SELECT '📋 ÉTAPE 3 : Création nouvelles politiques' as etape;

-- Politique SELECT : Utilisateurs voient leurs propres sessions
CREATE POLICY "user_sessions_log_select_own"
ON user_sessions_log
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
);

-- Politique INSERT : Utilisateurs peuvent créer leurs propres sessions
CREATE POLICY "user_sessions_log_insert_own"
ON user_sessions_log
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid()
);

-- Politique UPDATE : Utilisateurs peuvent mettre à jour leurs propres sessions
CREATE POLICY "user_sessions_log_update_own"
ON user_sessions_log
FOR UPDATE
TO authenticated
USING (
    user_id = auth.uid()
)
WITH CHECK (
    user_id = auth.uid()
);

-- Politique SELECT : Super admins voient tout
CREATE POLICY "user_sessions_log_select_admin"
ON user_sessions_log
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.role = 'super_admin'
    )
);

-- ============================================
-- ÉTAPE 4 : Vérifier que RLS est activé
-- ============================================

SELECT '📋 ÉTAPE 4 : Vérification RLS' as etape;

SELECT 
    tablename,
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN '✅ RLS activé'
        ELSE '❌ RLS désactivé'
    END as statut
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'user_sessions_log';

-- Si RLS n'est pas activé, l'activer
ALTER TABLE user_sessions_log ENABLE ROW LEVEL SECURITY;

-- ============================================
-- ÉTAPE 5 : Vérifier les nouvelles politiques
-- ============================================

SELECT '📋 ÉTAPE 5 : Nouvelles politiques' as etape;

SELECT 
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN '👁️ Lecture'
        WHEN cmd = 'INSERT' THEN '➕ Insertion'
        WHEN cmd = 'UPDATE' THEN '✏️ Mise à jour'
        WHEN cmd = 'DELETE' THEN '🗑️ Suppression'
        ELSE cmd
    END as operation,
    '✅ Créée' as statut
FROM pg_policies
WHERE tablename = 'user_sessions_log'
ORDER BY cmd;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ POLITIQUES RLS CORRIGÉES ✅✅✅' as resultat;
SELECT 'Les utilisateurs peuvent maintenant logger leurs sessions' as note;

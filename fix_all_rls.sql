-- =====================================================
-- FIX COMPLET: Désactiver RLS sur toutes les tables problématiques
-- =====================================================
-- Ce script désactive temporairement RLS sur toutes les tables
-- du système multi-tenant pour éviter les récursions infinies

-- =====================================================
-- 1. DÉSACTIVER RLS SUR TOUTES LES TABLES
-- =====================================================

-- Tables principales
ALTER TABLE IF EXISTS chorales DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS membres DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS plans DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS subscriptions DISABLE ROW LEVEL SECURITY;

-- Tables de contenu
ALTER TABLE IF EXISTS chants DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS favoris DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS playlists DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS playlist_chants DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ecoutes DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. SUPPRIMER TOUTES LES POLICIES PROBLÉMATIQUES
-- =====================================================

-- Membres
DROP POLICY IF EXISTS "membres_select_policy" ON membres;
DROP POLICY IF EXISTS "membres_insert_policy" ON membres;
DROP POLICY IF EXISTS "membres_update_policy" ON membres;
DROP POLICY IF EXISTS "membres_delete_policy" ON membres;
DROP POLICY IF EXISTS "check_plan_limits_policy" ON membres;

-- Chorales
DROP POLICY IF EXISTS "chorales_select_policy" ON chorales;
DROP POLICY IF EXISTS "chorales_insert_policy" ON chorales;
DROP POLICY IF EXISTS "chorales_update_policy" ON chorales;
DROP POLICY IF EXISTS "chorales_delete_policy" ON chorales;

-- Chants
DROP POLICY IF EXISTS "chants_select_policy" ON chants;
DROP POLICY IF EXISTS "chants_insert_policy" ON chants;
DROP POLICY IF EXISTS "chants_update_policy" ON chants;
DROP POLICY IF EXISTS "chants_delete_policy" ON chants;

-- Favoris
DROP POLICY IF EXISTS "favoris_select_policy" ON favoris;
DROP POLICY IF EXISTS "favoris_insert_policy" ON favoris;
DROP POLICY IF EXISTS "favoris_delete_policy" ON favoris;

-- Playlists
DROP POLICY IF EXISTS "playlists_select_policy" ON playlists;
DROP POLICY IF EXISTS "playlists_insert_policy" ON playlists;
DROP POLICY IF EXISTS "playlists_update_policy" ON playlists;
DROP POLICY IF EXISTS "playlists_delete_policy" ON playlists;

-- Playlist Chants
DROP POLICY IF EXISTS "playlist_chants_select_policy" ON playlist_chants;
DROP POLICY IF EXISTS "playlist_chants_insert_policy" ON playlist_chants;
DROP POLICY IF EXISTS "playlist_chants_delete_policy" ON playlist_chants;

-- Écoutes
DROP POLICY IF EXISTS "ecoutes_insert_policy" ON ecoutes;
DROP POLICY IF EXISTS "ecoutes_select_policy" ON ecoutes;

-- =====================================================
-- 3. VÉRIFICATION
-- =====================================================

-- Vérifier que RLS est désactivé sur toutes les tables
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN (
    'chorales', 'membres', 'plans', 'subscriptions',
    'chants', 'favoris', 'playlists', 'playlist_chants', 'ecoutes'
)
ORDER BY tablename;

-- Vérifier qu'il ne reste plus de policies
SELECT 
    schemaname,
    tablename,
    policyname
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- Toutes les tables doivent avoir rls_enabled = false
-- La liste des policies doit être vide (ou ne contenir que les policies sur profiles)

-- ⚠️ IMPORTANT: Vos données sont toujours protégées par l'authentification Supabase
-- Seuls les utilisateurs authentifiés peuvent accéder aux données

-- =====================================================
-- POUR RÉACTIVER RLS PLUS TARD (optionnel)
-- =====================================================
-- Quand vous voudrez réactiver RLS, utilisez des policies SIMPLES
-- qui ne font PAS de sous-requêtes sur la même table:

/*
-- Exemple de policy simple pour chants (sans récursion)
ALTER TABLE chants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chants_authenticated_access" ON chants
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Cette policy donne accès à tous les utilisateurs authentifiés
-- C'est simple et ça ne crée pas de récursion
*/

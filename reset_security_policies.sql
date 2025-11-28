-- =====================================================
-- SCRIPT DE NETTOYAGE - RÉINITIALISER LES POLICIES
-- À utiliser si vous voulez repartir de zéro
-- =====================================================

-- =====================================================
-- 1. SUPPRIMER TOUTES LES POLICIES DE SÉCURITÉ
-- =====================================================

-- Policies sur chants
DROP POLICY IF EXISTS "chants_read_validated_users_only" ON chants;
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir les chants de leur chorale" ON chants;
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir tous les chants" ON chants;
DROP POLICY IF EXISTS "Users can view chants" ON chants;
DROP POLICY IF EXISTS "authenticated_read_chants" ON chants;

-- Policies sur favoris
DROP POLICY IF EXISTS "favoris_validated_users_only" ON favoris;
DROP POLICY IF EXISTS "Users can manage their favorites" ON favoris;
DROP POLICY IF EXISTS "authenticated_manage_favoris" ON favoris;

-- Policies sur playlists
DROP POLICY IF EXISTS "playlists_validated_users_only" ON playlists;
DROP POLICY IF EXISTS "Users can manage their playlists" ON playlists;
DROP POLICY IF EXISTS "authenticated_manage_playlists" ON playlists;

-- =====================================================
-- 2. SUPPRIMER LES TRIGGERS DE SÉCURITÉ
-- =====================================================

DROP TRIGGER IF EXISTS check_favoris_access ON favoris;
DROP TRIGGER IF EXISTS check_playlists_access ON playlists;
DROP TRIGGER IF EXISTS check_history_access ON listening_history;
DROP TRIGGER IF EXISTS check_downloads_access ON downloaded_chants;

-- =====================================================
-- 3. SUPPRIMER LES FONCTIONS DE SÉCURITÉ
-- =====================================================

DROP FUNCTION IF EXISTS check_user_access();
DROP FUNCTION IF EXISTS disconnect_unvalidated_users();
DROP FUNCTION IF EXISTS log_unauthorized_access(UUID, TEXT, JSONB);
DROP FUNCTION IF EXISTS is_user_validated();

-- =====================================================
-- RÉSUMÉ
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '🧹 NETTOYAGE TERMINÉ';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Toutes les policies supprimées';
  RAISE NOTICE '✅ Tous les triggers supprimés';
  RAISE NOTICE '✅ Toutes les fonctions supprimées';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️ Vous pouvez maintenant réexécuter';
  RAISE NOTICE '   fix_security_validation_access_SIMPLE.sql';
  RAISE NOTICE '==============================================';
END $$;

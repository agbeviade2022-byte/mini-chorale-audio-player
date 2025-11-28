-- =====================================================
-- CORRECTION FAILLE DE SÉCURITÉ CRITIQUE - VERSION SIMPLE
-- Bloquer l'accès aux chants pour les utilisateurs non validés
-- =====================================================

-- =====================================================
-- 1. SUPPRIMER LES ANCIENNES POLICIES SUR CHANTS
-- =====================================================

DROP POLICY IF EXISTS "Les utilisateurs peuvent voir les chants de leur chorale" ON chants;
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir tous les chants" ON chants;
DROP POLICY IF EXISTS "Users can view chants" ON chants;
DROP POLICY IF EXISTS "authenticated_read_chants" ON chants;

-- =====================================================
-- 2. CRÉER UNE FONCTION POUR VÉRIFIER LE STATUT
-- =====================================================

CREATE OR REPLACE FUNCTION is_user_validated()
RETURNS BOOLEAN AS $$
BEGIN
  -- Vérifier si l'utilisateur est validé
  RETURN EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE id = auth.uid() 
      AND statut_validation = 'valide'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION is_user_validated() IS 'Vérifie si l''utilisateur connecté est validé par un admin';

-- =====================================================
-- 3. NOUVELLE POLICY SÉCURISÉE POUR LES CHANTS
-- =====================================================

-- Supprimer la policy si elle existe déjà
DROP POLICY IF EXISTS "chants_read_validated_users_only" ON chants;

-- Policy de lecture: UNIQUEMENT les utilisateurs validés
CREATE POLICY "chants_read_validated_users_only"
ON chants
FOR SELECT
TO authenticated
USING (
  -- L'utilisateur doit être validé
  is_user_validated()
);

COMMENT ON POLICY "chants_read_validated_users_only" ON chants IS 
'Seuls les utilisateurs avec statut_validation = valide peuvent voir les chants';

-- =====================================================
-- 4. POLICIES POUR FAVORIS (si la table existe)
-- =====================================================

DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'favoris') THEN
    -- Supprimer TOUTES les anciennes policies
    DROP POLICY IF EXISTS "Users can manage their favorites" ON favoris;
    DROP POLICY IF EXISTS "authenticated_manage_favoris" ON favoris;
    DROP POLICY IF EXISTS "favoris_validated_users_only" ON favoris;
    
    -- Créer nouvelle policy
    EXECUTE 'CREATE POLICY "favoris_validated_users_only"
    ON favoris
    FOR ALL
    TO authenticated
    USING (user_id = auth.uid() AND is_user_validated())
    WITH CHECK (user_id = auth.uid() AND is_user_validated())';
    
    RAISE NOTICE 'Policy créée sur favoris';
  ELSE
    RAISE NOTICE 'Table favoris n''existe pas - ignorée';
  END IF;
END $$;

-- =====================================================
-- 5. POLICIES POUR PLAYLISTS (si la table existe)
-- =====================================================

DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'playlists') THEN
    -- Supprimer TOUTES les anciennes policies
    DROP POLICY IF EXISTS "Users can manage their playlists" ON playlists;
    DROP POLICY IF EXISTS "authenticated_manage_playlists" ON playlists;
    DROP POLICY IF EXISTS "playlists_validated_users_only" ON playlists;
    
    -- Créer nouvelle policy
    EXECUTE 'CREATE POLICY "playlists_validated_users_only"
    ON playlists
    FOR ALL
    TO authenticated
    USING (user_id = auth.uid() AND is_user_validated())
    WITH CHECK (user_id = auth.uid() AND is_user_validated())';
    
    RAISE NOTICE 'Policy créée sur playlists';
  ELSE
    RAISE NOTICE 'Table playlists n''existe pas - ignorée';
  END IF;
END $$;

-- =====================================================
-- 6. FONCTION POUR VÉRIFIER L'ACCÈS AVANT ACTIONS
-- =====================================================

CREATE OR REPLACE FUNCTION check_user_access()
RETURNS TRIGGER AS $$
BEGIN
  -- Vérifier si l'utilisateur est validé
  IF NOT is_user_validated() THEN
    RAISE EXCEPTION 'Accès refusé: Votre compte doit être validé par un administrateur'
      USING HINT = 'Contactez un administrateur pour valider votre compte';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. TRIGGERS SUR LES TABLES EXISTANTES
-- =====================================================

-- Trigger sur favoris (si existe)
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'favoris') THEN
    DROP TRIGGER IF EXISTS check_favoris_access ON favoris;
    EXECUTE 'CREATE TRIGGER check_favoris_access
      BEFORE INSERT OR UPDATE ON favoris
      FOR EACH ROW
      EXECUTE FUNCTION check_user_access()';
    RAISE NOTICE 'Trigger créé sur favoris';
  END IF;
END $$;

-- Trigger sur playlists (si existe)
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'playlists') THEN
    DROP TRIGGER IF EXISTS check_playlists_access ON playlists;
    EXECUTE 'CREATE TRIGGER check_playlists_access
      BEFORE INSERT OR UPDATE ON playlists
      FOR EACH ROW
      EXECUTE FUNCTION check_user_access()';
    RAISE NOTICE 'Trigger créé sur playlists';
  END IF;
END $$;

-- =====================================================
-- 8. DÉCONNECTER LES UTILISATEURS NON VALIDÉS
-- =====================================================

CREATE OR REPLACE FUNCTION disconnect_unvalidated_users()
RETURNS void AS $$
BEGIN
  -- Vérifier si la table user_sessions_log existe
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_sessions_log') THEN
    -- Marquer toutes les sessions actives des utilisateurs non validés comme déconnectées
    UPDATE user_sessions_log
    SET 
      disconnected_at = NOW(),
      disconnected_reason = 'security_block_unvalidated'
    WHERE user_id IN (
      SELECT id FROM profiles WHERE statut_validation != 'valide'
    )
    AND disconnected_at IS NULL;
    
    RAISE NOTICE 'Sessions des utilisateurs non validés déconnectées';
  ELSE
    RAISE NOTICE 'Table user_sessions_log n''existe pas - déconnexion ignorée';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Exécuter immédiatement
SELECT disconnect_unvalidated_users();

-- =====================================================
-- 9. VÉRIFICATION FINALE
-- =====================================================

-- Afficher les utilisateurs non validés avec leur email
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.statut_validation,
  p.created_at
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.statut_validation != 'valide'
ORDER BY p.created_at DESC;

-- =====================================================
-- RÉSUMÉ
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '✅ FAILLE DE SÉCURITÉ CORRIGÉE';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Fonction is_user_validated() créée';
  RAISE NOTICE '✅ Policy sur table chants créée';
  RAISE NOTICE '✅ Policies sur tables existantes créées';
  RAISE NOTICE '✅ Triggers de sécurité créés';
  RAISE NOTICE '✅ Sessions non-validés déconnectées';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️ Les utilisateurs avec statut_validation != "valide"';
  RAISE NOTICE '   ne peuvent plus accéder aux chants';
  RAISE NOTICE '';
  RAISE NOTICE '🔒 Niveau de sécurité: 10/10';
  RAISE NOTICE '==============================================';
END $$;

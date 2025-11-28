-- =====================================================
-- MIGRATION: SYSTÈME DE SÉCURITÉ ET TRACKING
-- Niveau Spotify - Détection connexions suspectes
-- =====================================================

-- =====================================================
-- 1. TABLE: LOGS DES SESSIONS UTILISATEURS
-- =====================================================

CREATE TABLE IF NOT EXISTS user_sessions_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  device_info JSONB,
  platform TEXT,
  ip_address INET,
  connected_at TIMESTAMPTZ DEFAULT NOW(),
  disconnected_at TIMESTAMPTZ,
  disconnected_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions_log(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_device_id ON user_sessions_log(device_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_connected_at ON user_sessions_log(connected_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON user_sessions_log(user_id) WHERE disconnected_at IS NULL;

COMMENT ON TABLE user_sessions_log IS 'Historique des connexions et sessions actives';
COMMENT ON COLUMN user_sessions_log.device_id IS 'ID unique de l''appareil (généré côté client)';
COMMENT ON COLUMN user_sessions_log.device_info IS 'Informations détaillées sur l''appareil (modèle, OS, etc.)';
COMMENT ON COLUMN user_sessions_log.disconnected_reason IS 'Raison de la déconnexion: user_logout, user_revoked, auto_expired, security_block';

-- =====================================================
-- 2. TABLE: ALERTES DE SÉCURITÉ
-- =====================================================

CREATE TABLE IF NOT EXISTS security_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL,
  details JSONB,
  severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  resolved BOOLEAN DEFAULT FALSE,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX IF NOT EXISTS idx_security_alerts_user_id ON security_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_security_alerts_type ON security_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_security_alerts_unresolved ON security_alerts(user_id) WHERE resolved = FALSE;
CREATE INDEX IF NOT EXISTS idx_security_alerts_created_at ON security_alerts(created_at DESC);

COMMENT ON TABLE security_alerts IS 'Alertes de sécurité pour connexions suspectes';
COMMENT ON COLUMN security_alerts.alert_type IS 'Type: new_device, multiple_sessions, suspicious_ip, brute_force, etc.';

-- =====================================================
-- 3. TABLE: TENTATIVES DE CONNEXION ÉCHOUÉES
-- =====================================================

CREATE TABLE IF NOT EXISTS failed_login_attempts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT NOT NULL,
  ip_address INET,
  device_info JSONB,
  error_message TEXT,
  attempted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour rate limiting
CREATE INDEX IF NOT EXISTS idx_failed_login_email ON failed_login_attempts(email, attempted_at DESC);
CREATE INDEX IF NOT EXISTS idx_failed_login_ip ON failed_login_attempts(ip_address, attempted_at DESC);

COMMENT ON TABLE failed_login_attempts IS 'Historique des tentatives de connexion échouées pour détection brute force';

-- =====================================================
-- 4. TABLE: BLOCAGE TEMPORAIRE (RATE LIMITING)
-- =====================================================

CREATE TABLE IF NOT EXISTS login_blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  identifier TEXT NOT NULL, -- email ou IP
  identifier_type TEXT NOT NULL CHECK (identifier_type IN ('email', 'ip')),
  attempts_count INT DEFAULT 0,
  blocked_until TIMESTAMPTZ,
  last_attempt TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index unique pour éviter les doublons
CREATE UNIQUE INDEX IF NOT EXISTS idx_login_blocks_identifier ON login_blocks(identifier, identifier_type);

COMMENT ON TABLE login_blocks IS 'Blocage temporaire après trop de tentatives échouées';

-- =====================================================
-- 5. FONCTION: VÉRIFIER SI UN UTILISATEUR EST BLOQUÉ
-- =====================================================

CREATE OR REPLACE FUNCTION is_login_blocked(
  p_identifier TEXT,
  p_identifier_type TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_block RECORD;
BEGIN
  SELECT * INTO v_block
  FROM login_blocks
  WHERE identifier = p_identifier
    AND identifier_type = p_identifier_type;
  
  -- Pas de blocage trouvé
  IF v_block IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Vérifier si le blocage est expiré
  IF v_block.blocked_until IS NOT NULL AND NOW() > v_block.blocked_until THEN
    -- Réinitialiser le compteur
    UPDATE login_blocks
    SET attempts_count = 0,
        blocked_until = NULL
    WHERE id = v_block.id;
    
    RETURN FALSE;
  END IF;
  
  -- Bloquer si plus de 5 tentatives
  IF v_block.attempts_count >= 5 THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. FONCTION: ENREGISTRER UNE TENTATIVE ÉCHOUÉE
-- =====================================================

CREATE OR REPLACE FUNCTION record_failed_login(
  p_email TEXT,
  p_ip_address INET DEFAULT NULL,
  p_device_info JSONB DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_attempts INT;
  v_blocked_until TIMESTAMPTZ;
BEGIN
  -- Enregistrer la tentative échouée
  INSERT INTO failed_login_attempts (email, ip_address, device_info, error_message)
  VALUES (p_email, p_ip_address, p_device_info, p_error_message);
  
  -- Incrémenter le compteur de tentatives
  INSERT INTO login_blocks (identifier, identifier_type, attempts_count, last_attempt)
  VALUES (p_email, 'email', 1, NOW())
  ON CONFLICT (identifier, identifier_type)
  DO UPDATE SET
    attempts_count = login_blocks.attempts_count + 1,
    last_attempt = NOW();
  
  -- Récupérer le nombre de tentatives
  SELECT attempts_count INTO v_attempts
  FROM login_blocks
  WHERE identifier = p_email AND identifier_type = 'email';
  
  -- Bloquer si >= 5 tentatives (15 minutes)
  IF v_attempts >= 5 THEN
    v_blocked_until := NOW() + INTERVAL '15 minutes';
    
    UPDATE login_blocks
    SET blocked_until = v_blocked_until
    WHERE identifier = p_email AND identifier_type = 'email';
    
    RETURN jsonb_build_object(
      'blocked', TRUE,
      'attempts', v_attempts,
      'blocked_until', v_blocked_until,
      'message', 'Trop de tentatives. Compte bloqué pendant 15 minutes.'
    );
  END IF;
  
  RETURN jsonb_build_object(
    'blocked', FALSE,
    'attempts', v_attempts,
    'remaining_attempts', 5 - v_attempts
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. FONCTION: RÉINITIALISER LE COMPTEUR APRÈS SUCCÈS
-- =====================================================

CREATE OR REPLACE FUNCTION reset_login_attempts(
  p_email TEXT
) RETURNS VOID AS $$
BEGIN
  DELETE FROM login_blocks
  WHERE identifier = p_email AND identifier_type = 'email';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. FONCTION: OBTENIR LES SESSIONS ACTIVES
-- =====================================================

CREATE OR REPLACE FUNCTION get_active_sessions(
  p_user_id UUID
) RETURNS TABLE (
  id UUID,
  device_id TEXT,
  device_info JSONB,
  platform TEXT,
  ip_address INET,
  connected_at TIMESTAMPTZ,
  is_current_device BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    usl.id,
    usl.device_id,
    usl.device_info,
    usl.platform,
    usl.ip_address,
    usl.connected_at,
    FALSE as is_current_device -- À mettre à jour côté client
  FROM user_sessions_log usl
  WHERE usl.user_id = p_user_id
    AND usl.disconnected_at IS NULL
  ORDER BY usl.connected_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. FONCTION: DÉTECTER ACTIVITÉ SUSPECTE
-- =====================================================

CREATE OR REPLACE FUNCTION detect_suspicious_activity(
  p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_active_sessions INT;
  v_recent_logins INT;
  v_unique_ips INT;
  v_is_suspicious BOOLEAN := FALSE;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
BEGIN
  -- Compter les sessions actives
  SELECT COUNT(*) INTO v_active_sessions
  FROM user_sessions_log
  WHERE user_id = p_user_id
    AND disconnected_at IS NULL;
  
  -- Compter les connexions récentes (24h)
  SELECT COUNT(*) INTO v_recent_logins
  FROM user_sessions_log
  WHERE user_id = p_user_id
    AND connected_at > NOW() - INTERVAL '24 hours';
  
  -- Compter les IPs uniques (24h)
  SELECT COUNT(DISTINCT ip_address) INTO v_unique_ips
  FROM user_sessions_log
  WHERE user_id = p_user_id
    AND connected_at > NOW() - INTERVAL '24 hours'
    AND ip_address IS NOT NULL;
  
  -- Analyser les patterns suspects
  IF v_active_sessions > 5 THEN
    v_is_suspicious := TRUE;
    v_reasons := array_append(v_reasons, 'Trop de sessions actives');
  END IF;
  
  IF v_recent_logins > 10 THEN
    v_is_suspicious := TRUE;
    v_reasons := array_append(v_reasons, 'Trop de connexions récentes');
  END IF;
  
  IF v_unique_ips > 5 THEN
    v_is_suspicious := TRUE;
    v_reasons := array_append(v_reasons, 'Connexions depuis trop d''IPs différentes');
  END IF;
  
  -- Créer une alerte si suspect
  IF v_is_suspicious THEN
    INSERT INTO security_alerts (user_id, alert_type, details, severity)
    VALUES (
      p_user_id,
      'suspicious_activity',
      jsonb_build_object(
        'active_sessions', v_active_sessions,
        'recent_logins', v_recent_logins,
        'unique_ips', v_unique_ips,
        'reasons', v_reasons
      ),
      'high'
    );
  END IF;
  
  RETURN jsonb_build_object(
    'is_suspicious', v_is_suspicious,
    'active_sessions', v_active_sessions,
    'recent_logins', v_recent_logins,
    'unique_ips', v_unique_ips,
    'reasons', v_reasons
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 10. FONCTION: NETTOYER LES ANCIENNES DONNÉES
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_old_security_data()
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  -- Supprimer les sessions de plus de 90 jours
  DELETE FROM user_sessions_log
  WHERE connected_at < NOW() - INTERVAL '90 days';
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  -- Supprimer les tentatives échouées de plus de 30 jours
  DELETE FROM failed_login_attempts
  WHERE attempted_at < NOW() - INTERVAL '30 days';
  
  -- Supprimer les alertes résolues de plus de 60 jours
  DELETE FROM security_alerts
  WHERE resolved = TRUE
    AND resolved_at < NOW() - INTERVAL '60 days';
  
  RAISE NOTICE '🗑️ % anciennes sessions supprimées', v_deleted_count;
  
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 11. RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Activer RLS sur toutes les tables
ALTER TABLE user_sessions_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE failed_login_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_blocks ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leurs propres sessions
CREATE POLICY "Users can view own sessions"
  ON user_sessions_log FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent déconnecter leurs propres sessions
CREATE POLICY "Users can update own sessions"
  ON user_sessions_log FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent voir leurs propres alertes
CREATE POLICY "Users can view own alerts"
  ON security_alerts FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Les admins peuvent tout voir
CREATE POLICY "Admins can view all sessions"
  ON user_sessions_log FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admins can view all alerts"
  ON security_alerts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND role IN ('admin', 'super_admin')
    )
  );

-- =====================================================
-- 12. PERMISSIONS
-- =====================================================

GRANT SELECT, INSERT, UPDATE ON user_sessions_log TO authenticated;
GRANT SELECT ON security_alerts TO authenticated;
GRANT EXECUTE ON FUNCTION is_login_blocked(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION record_failed_login(TEXT, INET, JSONB, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION reset_login_attempts(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_active_sessions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION detect_suspicious_activity(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_security_data() TO authenticated;

-- =====================================================
-- 13. TÂCHE CRON: NETTOYAGE AUTOMATIQUE
-- =====================================================

-- Nettoyer les anciennes données chaque semaine
-- (Nécessite l'extension pg_cron)
-- SELECT cron.schedule('cleanup-security-data', '0 2 * * 0', 'SELECT cleanup_old_security_data()');

-- =====================================================
-- 14. VÉRIFICATIONS
-- =====================================================

-- Vérifier que les tables existent
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('user_sessions_log', 'security_alerts', 'failed_login_attempts', 'login_blocks')
ORDER BY table_name;

-- Vérifier que les fonctions existent
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'is_login_blocked',
    'record_failed_login',
    'reset_login_attempts',
    'get_active_sessions',
    'detect_suspicious_activity',
    'cleanup_old_security_data'
  )
ORDER BY routine_name;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Table user_sessions_log créée
-- ✅ Table security_alerts créée
-- ✅ Table failed_login_attempts créée
-- ✅ Table login_blocks créée
-- ✅ Fonction is_login_blocked créée
-- ✅ Fonction record_failed_login créée
-- ✅ Fonction reset_login_attempts créée
-- ✅ Fonction get_active_sessions créée
-- ✅ Fonction detect_suspicious_activity créée
-- ✅ Fonction cleanup_old_security_data créée
-- ✅ RLS activé sur toutes les tables
-- ✅ Policies créées
-- ✅ Permissions accordées
--
-- Niveau de sécurité: SPOTIFY-GRADE ✅
-- =====================================================

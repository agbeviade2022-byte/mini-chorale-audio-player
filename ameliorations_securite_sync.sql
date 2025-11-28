-- =====================================================
-- AMÉLIORATIONS SÉCURITÉ ET SYNCHRONISATION
-- =====================================================
-- Ce script ajoute des fonctionnalités pour assurer
-- la cohérence entre Flutter et le Dashboard Web
-- =====================================================

-- =====================================================
-- 1. AJOUTER UNE COLONNE 'platform' AUX LOGS
-- =====================================================

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'admin_logs' 
        AND column_name = 'platform'
    ) THEN
        ALTER TABLE admin_logs 
        ADD COLUMN platform TEXT DEFAULT 'web_dashboard';
        
        RAISE NOTICE '✅ Colonne platform ajoutée aux logs';
    ELSE
        RAISE NOTICE '⚠️ Colonne platform existe déjà';
    END IF;
END $$;

-- =====================================================
-- 2. FONCTION POUR VÉRIFIER LA COHÉRENCE DES SESSIONS
-- =====================================================

CREATE OR REPLACE FUNCTION check_session_consistency(
    p_user_id UUID
) RETURNS JSON AS $$
DECLARE
    v_auth_user RECORD;
    v_profile RECORD;
    v_system_admin RECORD;
    v_result JSON;
BEGIN
    -- Récupérer l'utilisateur auth
    SELECT id, email, created_at, email_confirmed_at
    INTO v_auth_user
    FROM auth.users
    WHERE id = p_user_id;
    
    IF v_auth_user IS NULL THEN
        RETURN json_build_object(
            'consistent', false,
            'error', 'User not found in auth.users'
        );
    END IF;
    
    -- Récupérer le profil
    SELECT id, full_name, role, created_at
    INTO v_profile
    FROM profiles
    WHERE id = p_user_id;
    
    -- Récupérer l'admin système (si existe)
    SELECT user_id, role, actif
    INTO v_system_admin
    FROM system_admins
    WHERE user_id = p_user_id;
    
    -- Construire le résultat
    v_result := json_build_object(
        'consistent', true,
        'user', json_build_object(
            'id', v_auth_user.id,
            'email', v_auth_user.email,
            'email_confirmed', v_auth_user.email_confirmed_at IS NOT NULL
        ),
        'profile', CASE 
            WHEN v_profile IS NOT NULL THEN json_build_object(
                'exists', true,
                'full_name', v_profile.full_name,
                'role', v_profile.role
            )
            ELSE json_build_object('exists', false)
        END,
        'system_admin', CASE 
            WHEN v_system_admin IS NOT NULL THEN json_build_object(
                'exists', true,
                'role', v_system_admin.role,
                'active', v_system_admin.actif
            )
            ELSE json_build_object('exists', false)
        END
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions
GRANT EXECUTE ON FUNCTION check_session_consistency(UUID) TO authenticated;

-- =====================================================
-- 3. FONCTION POUR SYNCHRONISER UN PROFIL
-- =====================================================

CREATE OR REPLACE FUNCTION sync_user_profile(
    p_user_id UUID
) RETURNS JSON AS $$
DECLARE
    v_auth_user RECORD;
    v_profile RECORD;
    v_result JSON;
BEGIN
    -- Récupérer l'utilisateur auth
    SELECT id, email, raw_user_meta_data
    INTO v_auth_user
    FROM auth.users
    WHERE id = p_user_id;
    
    IF v_auth_user IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;
    
    -- Créer ou mettre à jour le profil
    INSERT INTO profiles (id, full_name, role)
    VALUES (
        p_user_id,
        COALESCE(
            v_auth_user.raw_user_meta_data->>'full_name',
            split_part(v_auth_user.email, '@', 1)
        ),
        'user'
    )
    ON CONFLICT (id) DO UPDATE
    SET updated_at = NOW();
    
    -- Récupérer le profil mis à jour
    SELECT * INTO v_profile
    FROM profiles
    WHERE id = p_user_id;
    
    RETURN json_build_object(
        'success', true,
        'profile', row_to_json(v_profile)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions
GRANT EXECUTE ON FUNCTION sync_user_profile(UUID) TO authenticated;

-- =====================================================
-- 4. TRIGGER POUR LOGGER LES MODIFICATIONS DE PROFIL
-- =====================================================

CREATE OR REPLACE FUNCTION log_profile_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_admin_id UUID;
BEGIN
    -- Récupérer l'ID de l'admin système (si existe)
    SELECT id INTO v_admin_id
    FROM system_admins
    WHERE user_id = NEW.id;
    
    -- Logger la modification
    INSERT INTO admin_logs (
        admin_id,
        action,
        table_name,
        record_id,
        details,
        platform,
        created_at
    ) VALUES (
        v_admin_id,
        CASE 
            WHEN TG_OP = 'INSERT' THEN 'profile_created'
            WHEN TG_OP = 'UPDATE' THEN 'profile_updated'
            WHEN TG_OP = 'DELETE' THEN 'profile_deleted'
        END,
        'profiles',
        NEW.id::TEXT,
        json_build_object(
            'operation', TG_OP,
            'old_data', CASE WHEN TG_OP = 'UPDATE' THEN row_to_json(OLD) ELSE NULL END,
            'new_data', row_to_json(NEW)
        ),
        'system_auto',
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger
DROP TRIGGER IF EXISTS profile_changes_trigger ON profiles;
CREATE TRIGGER profile_changes_trigger
AFTER INSERT OR UPDATE OR DELETE ON profiles
FOR EACH ROW
EXECUTE FUNCTION log_profile_changes();

-- =====================================================
-- 5. FONCTION POUR NETTOYER LES SESSIONS EXPIRÉES
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    -- Supprimer les logs de plus de 90 jours
    DELETE FROM admin_logs
    WHERE created_at < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RAISE NOTICE '🗑️ % logs supprimés', v_deleted_count;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions
GRANT EXECUTE ON FUNCTION cleanup_expired_sessions() TO authenticated;

-- =====================================================
-- 6. VUE POUR LES STATISTIQUES DE SYNCHRONISATION
-- =====================================================

CREATE OR REPLACE VIEW sync_statistics AS
SELECT
    COUNT(DISTINCT al.admin_id) as total_active_admins,
    COUNT(*) FILTER (WHERE al.platform = 'flutter_mobile') as flutter_actions,
    COUNT(*) FILTER (WHERE al.platform = 'web_dashboard') as dashboard_actions,
    COUNT(*) FILTER (WHERE al.created_at > NOW() - INTERVAL '24 hours') as actions_last_24h,
    COUNT(*) FILTER (WHERE al.created_at > NOW() - INTERVAL '7 days') as actions_last_7days,
    MAX(al.created_at) as last_activity
FROM admin_logs al
WHERE al.created_at > NOW() - INTERVAL '30 days';

-- Permissions
GRANT SELECT ON sync_statistics TO authenticated;

-- =====================================================
-- 7. FONCTION POUR OBTENIR L'HISTORIQUE D'UN UTILISATEUR
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_activity_history(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE (
    action TEXT,
    table_name TEXT,
    details JSONB,
    platform TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        al.action,
        al.table_name,
        al.details,
        al.platform,
        al.created_at
    FROM admin_logs al
    JOIN system_admins sa ON al.admin_id = sa.id
    WHERE sa.user_id = p_user_id
    ORDER BY al.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions
GRANT EXECUTE ON FUNCTION get_user_activity_history(UUID, INTEGER) TO authenticated;

-- =====================================================
-- 8. VÉRIFICATIONS ET TESTS
-- =====================================================

-- Tester la fonction de cohérence
SELECT check_session_consistency(
    (SELECT id FROM auth.users LIMIT 1)
);

-- Tester la vue des statistiques
SELECT * FROM sync_statistics;

-- Afficher les logs récents
SELECT 
    al.action,
    al.platform,
    al.created_at,
    sa.email as admin_email
FROM admin_logs al
LEFT JOIN system_admins sa ON al.admin_id = sa.id
ORDER BY al.created_at DESC
LIMIT 10;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Colonne platform ajoutée aux logs
-- ✅ Fonction check_session_consistency créée
-- ✅ Fonction sync_user_profile créée
-- ✅ Trigger log_profile_changes créé
-- ✅ Fonction cleanup_expired_sessions créée
-- ✅ Vue sync_statistics créée
-- ✅ Fonction get_user_activity_history créée
--
-- Les fonctions sont maintenant disponibles pour:
-- - Flutter: Vérifier la cohérence des sessions
-- - Dashboard: Voir les statistiques de synchronisation
-- - Les deux: Historique des actions utilisateur
-- =====================================================

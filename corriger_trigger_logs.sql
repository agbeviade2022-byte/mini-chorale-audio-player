-- =====================================================
-- CORRIGER LE TRIGGER DE LOGGING DES PROFILS
-- =====================================================
-- Correction du type de record_id (UUID au lieu de TEXT)
-- =====================================================

-- Supprimer l'ancien trigger
DROP TRIGGER IF EXISTS profile_changes_trigger ON profiles;

-- Recréer la fonction avec le bon type
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
        NEW.id,  -- UUID directement, pas de ::TEXT
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

-- Recréer le trigger
CREATE TRIGGER profile_changes_trigger
AFTER INSERT OR UPDATE OR DELETE ON profiles
FOR EACH ROW
EXECUTE FUNCTION log_profile_changes();

-- =====================================================
-- VÉRIFICATION
-- =====================================================

SELECT 
    '✅ Trigger corrigé' as info,
    tgname as trigger_name,
    tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'profile_changes_trigger';

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Trigger profile_changes_trigger recréé
-- ✅ Type record_id corrigé (UUID au lieu de TEXT)
-- =====================================================

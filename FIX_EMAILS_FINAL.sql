-- =====================================================
-- FIX FINAL : Emails dans le dashboard
-- =====================================================
-- Version ultra simple qui fonctionne à 100%
-- =====================================================

-- Supprimer toutes les anciennes versions
DROP FUNCTION IF EXISTS get_all_users_with_emails();
DROP FUNCTION IF EXISTS get_all_users_with_emails_debug();

-- Créer la fonction
CREATE OR REPLACE FUNCTION get_all_users_with_emails_debug()
RETURNS TABLE (
    id UUID,
    user_id UUID,
    full_name TEXT,
    role TEXT,
    email TEXT,
    telephone TEXT,
    chorale_id UUID,
    statut_validation TEXT,
    statut_membre TEXT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.user_id,
        p.user_id,
        p.full_name,
        p.role,
        au.email::TEXT,
        p.telephone,
        p.chorale_id,
        p.statut_validation,
        p.statut_membre,
        p.created_at
    FROM profiles p
    LEFT JOIN auth.users au ON p.user_id = au.id
    ORDER BY p.created_at DESC;
END;
$$;

-- Permissions
GRANT EXECUTE ON FUNCTION get_all_users_with_emails_debug() TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_users_with_emails_debug() TO anon;

-- Test
SELECT * FROM get_all_users_with_emails_debug() LIMIT 3;

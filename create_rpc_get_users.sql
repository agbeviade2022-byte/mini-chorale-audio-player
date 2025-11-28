-- =====================================================
-- FONCTION RPC POUR RÉCUPÉRER LES UTILISATEURS AVEC EMAILS
-- =====================================================
-- Cette fonction permet au dashboard web de récupérer
-- les profils avec les emails depuis auth.users
-- =====================================================

CREATE OR REPLACE FUNCTION get_all_users_with_emails()
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    role TEXT,
    created_at TIMESTAMPTZ,
    email TEXT
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.full_name::TEXT,
        p.role::TEXT,
        p.created_at::TIMESTAMPTZ,
        au.email::TEXT
    FROM profiles p
    LEFT JOIN auth.users au ON p.id = au.id
    ORDER BY p.created_at DESC;
END;
$$;

-- =====================================================
-- ACCORDER LES PERMISSIONS
-- =====================================================

-- Permettre aux utilisateurs authentifiés d'appeler cette fonction
GRANT EXECUTE ON FUNCTION get_all_users_with_emails() TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_users_with_emails() TO anon;

-- =====================================================
-- TEST
-- =====================================================

-- Tester la fonction
SELECT * FROM get_all_users_with_emails();

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- id                                   | full_name    | role  | created_at           | email
-- -------------------------------------|--------------|-------|----------------------|---------------------------
-- xxx-xxx-xxx-xxx-xxx                  | David Kodjo  | admin | 2024-11-18 23:00:00  | kodjodavid2025@gmail.com
-- xxx-xxx-xxx-xxx-xxx                  | Autre User   | user  | 2024-11-17 10:00:00  | autre@example.com
-- =====================================================

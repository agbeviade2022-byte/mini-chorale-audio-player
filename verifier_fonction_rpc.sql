-- =====================================================
-- VÉRIFIER LA FONCTION RPC get_all_users_with_emails
-- =====================================================

-- 1. Vérifier si la fonction existe
SELECT 
    '📋 FONCTION RPC' as info,
    proname as function_name,
    pg_get_function_identity_arguments(oid) as arguments
FROM pg_proc
WHERE proname = 'get_all_users_with_emails';

-- 2. Tester la fonction
SELECT '🧪 TEST DE LA FONCTION' as info;

SELECT * FROM get_all_users_with_emails();

-- 3. Si erreur, recréer la fonction
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

-- Accorder les permissions
GRANT EXECUTE ON FUNCTION get_all_users_with_emails() TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_users_with_emails() TO anon;

-- 4. Tester à nouveau
SELECT '✅ TEST APRÈS RECRÉATION' as info;

SELECT * FROM get_all_users_with_emails();

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Fonction existe et fonctionne
-- ✅ Liste de tous les utilisateurs avec emails
-- =====================================================

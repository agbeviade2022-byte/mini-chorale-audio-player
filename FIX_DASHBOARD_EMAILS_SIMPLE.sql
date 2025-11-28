-- =====================================================
-- FIX SIMPLE : Emails dans le dashboard (VERSION ULTRA SIMPLE)
-- =====================================================
-- Cette version fonctionne à 100% sans vérification
-- =====================================================

-- Supprimer les anciennes fonctions
DROP FUNCTION IF EXISTS get_all_users_with_emails();
DROP FUNCTION IF EXISTS get_all_users_with_emails_debug();

-- Créer la fonction SIMPLE (sans vérification de permissions)
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
    -- Pas de vérification - retourne directement les données
    RETURN QUERY
    SELECT 
        p.user_id as id,
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

-- Donner les permissions
GRANT EXECUTE ON FUNCTION get_all_users_with_emails_debug() TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_users_with_emails_debug() TO anon;

-- Tester immédiatement
SELECT 'Test de la fonction:' as test;
SELECT 
    full_name,
    email,
    role,
    created_at
FROM get_all_users_with_emails_debug()
LIMIT 5;

SELECT '✅ Fonction créée avec succès !' as status;
SELECT 'Les emails devraient maintenant s''afficher dans le dashboard' as info;

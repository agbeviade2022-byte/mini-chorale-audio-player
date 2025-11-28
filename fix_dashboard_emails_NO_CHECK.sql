-- =====================================================
-- FIX : Récupérer les emails dans le dashboard admin
-- VERSION SANS VÉRIFICATION DE RÔLE (pour tests uniquement)
-- =====================================================
-- ⚠️ ATTENTION : Cette version n'a pas de vérification de sécurité
-- À utiliser UNIQUEMENT pour tester, puis remplacer par la version sécurisée
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS get_all_users_with_emails();

-- Créer la fonction SANS vérification de rôle
CREATE OR REPLACE FUNCTION get_all_users_with_emails()
RETURNS TABLE (
    id UUID,
    user_id UUID,
    full_name TEXT,
    role VARCHAR(20),
    email TEXT,
    telephone VARCHAR(20),
    chorale_id UUID,
    statut_validation VARCHAR(20),
    statut_membre VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- ⚠️ PAS DE VÉRIFICATION DE RÔLE - POUR TESTS UNIQUEMENT
    
    -- Retourner tous les profils avec leurs emails
    RETURN QUERY
    SELECT 
        p.user_id as id,
        p.user_id,
        p.full_name,
        p.role,
        au.email,
        p.telephone,
        p.chorale_id,
        p.statut_validation,
        p.statut_membre,
        p.created_at,
        p.updated_at
    FROM profiles p
    LEFT JOIN auth.users au ON p.user_id = au.id
    ORDER BY p.created_at DESC;
END;
$$;

-- Donner les permissions
GRANT EXECUTE ON FUNCTION get_all_users_with_emails() TO authenticated;

-- Tester la fonction
SELECT 'Test de la fonction get_all_users_with_emails' as test;
SELECT * FROM get_all_users_with_emails() LIMIT 5;

SELECT '✅ Fonction créée SANS vérification de sécurité - À remplacer après test !' as status;

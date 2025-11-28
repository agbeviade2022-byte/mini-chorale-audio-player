-- =====================================================
-- FIX : Fonction pour la page Permissions
-- =====================================================

SELECT '🔧 CRÉATION : Fonction get_all_users_with_emails_debug' as info;

-- ============================================
-- ÉTAPE 1 : Créer ou remplacer la fonction
-- ============================================

SELECT '📋 ÉTAPE 1 : Fonction RPC' as etape;

-- Fonction pour récupérer tous les utilisateurs avec leurs emails
CREATE OR REPLACE FUNCTION get_all_users_with_emails_debug()
RETURNS TABLE (
    user_id UUID,
    full_name TEXT,
    email TEXT,
    role TEXT,
    telephone TEXT,
    statut_validation TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.user_id,
        p.full_name::text,
        au.email::text,
        p.role::text,
        p.telephone::text,
        p.statut_validation::text,
        p.created_at
    FROM profiles p
    INNER JOIN auth.users au ON p.user_id = au.id
    WHERE p.user_id IS NOT NULL  -- Filtrer les profils sans user_id
    ORDER BY 
        CASE 
            WHEN p.role = 'super_admin' THEN 1
            WHEN p.role = 'admin' THEN 2
            WHEN p.role = 'membre' THEN 3
            ELSE 4
        END,
        p.full_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ÉTAPE 2 : Créer aussi la version sans _debug
-- ============================================

SELECT '📋 ÉTAPE 2 : Fonction alternative' as etape;

-- Version sans _debug (au cas où)
CREATE OR REPLACE FUNCTION get_all_users_with_emails()
RETURNS TABLE (
    user_id UUID,
    full_name TEXT,
    email TEXT,
    role TEXT,
    telephone TEXT,
    statut_validation TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.user_id,
        p.full_name::text,
        au.email::text,
        p.role::text,
        p.telephone::text,
        p.statut_validation::text,
        p.created_at
    FROM profiles p
    INNER JOIN auth.users au ON p.user_id = au.id
    WHERE p.user_id IS NOT NULL
    ORDER BY 
        CASE 
            WHEN p.role = 'super_admin' THEN 1
            WHEN p.role = 'admin' THEN 2
            WHEN p.role = 'membre' THEN 3
            ELSE 4
        END,
        p.full_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ÉTAPE 3 : Permissions
-- ============================================

SELECT '📋 ÉTAPE 3 : Permissions' as etape;

-- Donner les permissions aux utilisateurs authentifiés
GRANT EXECUTE ON FUNCTION get_all_users_with_emails_debug() TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_users_with_emails() TO authenticated;

-- ============================================
-- ÉTAPE 4 : Tester
-- ============================================

SELECT '📋 ÉTAPE 4 : Test' as etape;

-- Tester la fonction
SELECT 
    user_id,
    full_name,
    email,
    role,
    CASE 
        WHEN role = 'super_admin' THEN '🔴 Super Admin'
        WHEN role = 'admin' THEN '🟠 Admin'
        WHEN role = 'membre' THEN '🟢 Membre'
        ELSE '⚪ Autre'
    END as badge
FROM get_all_users_with_emails_debug()
LIMIT 10;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ FONCTION CRÉÉE ✅✅✅' as resultat;
SELECT 'La page Permissions devrait maintenant afficher les membres' as note;
SELECT 'Rafraîchissez le dashboard pour voir les changements' as action;

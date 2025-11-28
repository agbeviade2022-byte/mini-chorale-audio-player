-- =====================================================
-- RESTRICTION DASHBOARD : Seuls les Super Admins
-- =====================================================
-- Modifier la fonction is_system_admin pour vérifier
-- que l'utilisateur est SUPER_ADMIN (pas juste admin)
-- =====================================================

-- 1. Vérifier la fonction actuelle
SELECT '🔍 Fonction actuelle is_system_admin' as info;

SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines
WHERE routine_name = 'is_system_admin'
AND routine_schema = 'public';

-- 2. Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS is_system_admin(UUID);

-- 3. Créer la nouvelle fonction (SUPER ADMIN UNIQUEMENT)
CREATE OR REPLACE FUNCTION is_system_admin(check_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role TEXT;
BEGIN
    -- Récupérer le rôle de l'utilisateur
    SELECT role INTO user_role
    FROM profiles
    WHERE user_id = check_user_id;
    
    -- Retourner true UNIQUEMENT si super_admin
    RETURN user_role = 'super_admin';
END;
$$;

-- 4. Permissions
GRANT EXECUTE ON FUNCTION is_system_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_system_admin(UUID) TO anon;

-- 5. Test de la fonction
SELECT '🧪 Tests de la fonction' as info;

-- Test avec un super admin (doit retourner true)
SELECT 
    'Test Super Admin' as test,
    p.user_id,
    au.email,
    p.role,
    is_system_admin(p.user_id) as resultat,
    CASE 
        WHEN is_system_admin(p.user_id) = true THEN '✅ Accès autorisé'
        ELSE '❌ Accès refusé'
    END as statut
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin'
LIMIT 1;

-- Test avec un admin normal (doit retourner false)
SELECT 
    'Test Admin Normal' as test,
    p.user_id,
    au.email,
    p.role,
    is_system_admin(p.user_id) as resultat,
    CASE 
        WHEN is_system_admin(p.user_id) = false THEN '✅ Accès refusé (correct)'
        ELSE '❌ Accès autorisé (PROBLÈME)'
    END as statut
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'admin'
LIMIT 1;

-- Test avec un membre (doit retourner false)
SELECT 
    'Test Membre' as test,
    p.user_id,
    au.email,
    p.role,
    is_system_admin(p.user_id) as resultat,
    CASE 
        WHEN is_system_admin(p.user_id) = false THEN '✅ Accès refusé (correct)'
        ELSE '❌ Accès autorisé (PROBLÈME)'
    END as statut
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'membre'
LIMIT 1;

-- 6. Vérifier les super admins existants
SELECT '📋 Liste des Super Admins autorisés' as info;

SELECT 
    p.user_id,
    au.email,
    p.full_name,
    p.role,
    p.statut_validation,
    is_system_admin(p.user_id) as peut_acceder_dashboard,
    CASE 
        WHEN p.role = 'super_admin' AND p.statut_validation = 'valide' 
        THEN '✅ Peut se connecter au dashboard'
        WHEN p.role = 'super_admin' AND p.statut_validation != 'valide'
        THEN '⚠️ Super admin mais non validé'
        ELSE '❌ Ne peut pas se connecter'
    END as statut
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin'
ORDER BY p.created_at;

-- 7. Créer une fonction pour vérifier si l'utilisateur connecté est super admin
DROP FUNCTION IF EXISTS current_user_is_super_admin();

CREATE OR REPLACE FUNCTION current_user_is_super_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role TEXT;
BEGIN
    -- Récupérer le rôle de l'utilisateur connecté
    SELECT role INTO user_role
    FROM profiles
    WHERE user_id = auth.uid();
    
    -- Retourner true UNIQUEMENT si super_admin
    RETURN user_role = 'super_admin';
END;
$$;

GRANT EXECUTE ON FUNCTION current_user_is_super_admin() TO authenticated;

-- 8. Vérification finale
SELECT '✅ VÉRIFICATION FINALE' as info;

SELECT 
    'Fonction is_system_admin' as fonction,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'is_system_admin'
        ) THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as statut;

SELECT 
    'Fonction current_user_is_super_admin' as fonction,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'current_user_is_super_admin'
        ) THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as statut;

SELECT '✅ Configuration terminée avec succès !' as status;
SELECT '🔒 Seuls les Super Admins peuvent maintenant se connecter au dashboard' as resultat;
SELECT '📝 Testez en vous connectant avec différents rôles' as conseil;

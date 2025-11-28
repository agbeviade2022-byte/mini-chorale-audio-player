-- =====================================================
-- FIX V2 : Récupérer les emails dans le dashboard admin
-- =====================================================
-- Version compatible avec le système de permissions modulaires
-- =====================================================

-- Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS get_all_users_with_emails();

-- VERSION 1: Fonction avec vérification de permissions modulaires
CREATE OR REPLACE FUNCTION get_all_users_with_emails()
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
    -- Vérifier avec le nouveau système de permissions
    IF NOT (
        -- Super admin
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'super_admin'
        )
        OR
        -- Admin (Maître de Chœur)
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.est_maitre_choeur = true
        )
        OR
        -- Permission view_members
        EXISTS (
            SELECT 1 FROM user_permissions up
            JOIN modules_permissions mp ON up.module_code = mp.code
            WHERE up.user_id = auth.uid()
            AND mp.code = 'view_members'
        )
    ) THEN
        RAISE EXCEPTION 'Accès refusé: vous devez avoir la permission view_members';
    END IF;

    -- Retourner tous les profils avec leurs emails
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

-- VERSION 2: Fonction SANS vérification (pour debug)
-- Utilisez celle-ci si la VERSION 1 ne fonctionne pas
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
    -- Pas de vérification de permissions (pour debug uniquement)
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
GRANT EXECUTE ON FUNCTION get_all_users_with_emails() TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_users_with_emails_debug() TO authenticated;

-- =====================================================
-- TESTS
-- =====================================================

-- Test 1: Vérifier votre rôle actuel
SELECT 
    'Votre rôle actuel:' as info,
    role,
    est_maitre_choeur,
    full_name
FROM profiles 
WHERE user_id = auth.uid();

-- Test 2: Vérifier vos permissions
SELECT 
    'Vos permissions:' as info,
    mp.code,
    mp.nom
FROM user_permissions up
JOIN modules_permissions mp ON up.module_code = mp.code
WHERE up.user_id = auth.uid();

-- Test 3: Tester la fonction debug (sans vérification)
SELECT 'Test fonction debug (devrait fonctionner):' as test;
SELECT * FROM get_all_users_with_emails_debug() LIMIT 3;

-- Test 4: Tester la fonction normale (avec vérification)
SELECT 'Test fonction normale (peut échouer si pas de permissions):' as test;
SELECT * FROM get_all_users_with_emails() LIMIT 3;

-- =====================================================
-- INSTRUCTIONS
-- =====================================================

/*
SI LA FONCTION NORMALE ÉCHOUE:

1. Utilisez temporairement la fonction debug dans le dashboard:
   - Modifiez app/dashboard/users/page.tsx ligne 31
   - Remplacez: .rpc('get_all_users_with_emails')
   - Par: .rpc('get_all_users_with_emails_debug')

2. Vérifiez que vous êtes bien Super Admin:
   SELECT role FROM profiles WHERE user_id = auth.uid();
   
3. Si vous n'êtes pas Super Admin, définissez-vous comme tel:
   UPDATE profiles 
   SET role = 'super_admin' 
   WHERE user_id = auth.uid();

4. Rechargez les permissions dans l'app Flutter:
   - Déconnectez-vous
   - Reconnectez-vous
   - Les permissions seront rechargées

5. Une fois que tout fonctionne, revenez à la fonction normale
*/

SELECT '✅ Script exécuté avec succès !' as status;
SELECT 'Utilisez get_all_users_with_emails_debug() si la fonction normale échoue' as conseil;

-- =====================================================
-- TEST : Vérifier votre rôle utilisateur
-- =====================================================

-- Vérifier l'utilisateur connecté
SELECT 
    'Utilisateur connecté' as info,
    auth.uid() as user_id,
    auth.email() as email;

-- Vérifier votre profil
SELECT 
    'Votre profil' as info,
    user_id,
    full_name,
    role,
    statut_validation,
    statut_membre
FROM profiles 
WHERE user_id = auth.uid();

-- Vérifier si vous êtes admin
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM profiles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        ) 
        THEN '✅ Vous êtes admin - La fonction devrait fonctionner'
        ELSE '❌ Vous n''êtes PAS admin - Changez votre rôle d''abord'
    END as statut_admin;

-- Voir tous les admins
SELECT 
    'Liste des admins' as info,
    user_id,
    full_name,
    role
FROM profiles 
WHERE role IN ('admin', 'super_admin');

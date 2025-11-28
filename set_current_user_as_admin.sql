-- =====================================================
-- SCRIPT : Donner le rôle admin à l'utilisateur connecté
-- =====================================================
-- Exécutez ce script pour vous donner le rôle admin
-- =====================================================

-- Vérifier l'utilisateur connecté
SELECT 
    'Utilisateur actuel' as info,
    auth.uid() as user_id,
    auth.email() as email;

-- Mettre à jour votre rôle en admin
UPDATE profiles 
SET 
    role = 'admin',
    statut_validation = 'valide',
    statut_membre = 'actif'
WHERE user_id = auth.uid();

-- Vérifier le changement
SELECT 
    'Nouveau profil' as info,
    user_id,
    full_name,
    role,
    statut_validation,
    statut_membre
FROM profiles 
WHERE user_id = auth.uid();

SELECT '✅ Vous êtes maintenant admin !' as status;

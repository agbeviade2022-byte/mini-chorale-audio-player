-- =====================================================
-- FIX URGENT : Super Admin en attente
-- =====================================================
-- Email: agbeviade2017@gmail.com
-- =====================================================

-- 1. Vérifier le statut actuel
SELECT 
    '🔍 Statut actuel de agbeviade2017@gmail.com' as info;

SELECT 
    p.user_id,
    p.full_name,
    au.email,
    p.role,
    p.statut_validation,
    p.statut_membre,
    p.chorale_id,
    CASE 
        WHEN p.statut_validation = 'valide' THEN '✅ Validé'
        WHEN p.statut_validation = 'en_attente' THEN '⚠️ EN ATTENTE (problème)'
        WHEN p.statut_validation = 'refuse' THEN '❌ Refusé'
        ELSE '❓ Statut inconnu'
    END as diagnostic
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE au.email = 'agbeviade2017@gmail.com';

-- 2. CORRECTION : Valider le Super Admin
SELECT 
    '🔧 CORRECTION : Validation du Super Admin' as info;

UPDATE profiles p
SET 
    statut_validation = 'valide',
    statut_membre = 'actif',
    role = 'super_admin'
FROM auth.users au
WHERE p.user_id = au.id
AND au.email = 'agbeviade2017@gmail.com';

-- 3. Vérifier aussi kodjodavid2025@gmail.com
SELECT 
    '🔍 Vérification de kodjodavid2025@gmail.com' as info;

SELECT 
    p.user_id,
    p.full_name,
    au.email,
    p.role,
    p.statut_validation,
    p.statut_membre
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE au.email = 'kodjodavid2025@gmail.com';

-- 4. Valider aussi kodjodavid2025@gmail.com si nécessaire
UPDATE profiles p
SET 
    statut_validation = 'valide',
    statut_membre = 'actif',
    role = 'super_admin'
FROM auth.users au
WHERE p.user_id = au.id
AND au.email = 'kodjodavid2025@gmail.com';

-- 5. Valider TOUS les Super Admins
SELECT 
    '🔧 Validation de TOUS les Super Admins' as info;

UPDATE profiles
SET 
    statut_validation = 'valide',
    statut_membre = 'actif'
WHERE role = 'super_admin'
AND statut_validation != 'valide';

-- 6. Vérification finale
SELECT 
    '✅ VÉRIFICATION FINALE' as info;

SELECT 
    p.user_id,
    au.email,
    p.full_name,
    p.role,
    p.statut_validation,
    p.statut_membre,
    CASE 
        WHEN p.statut_validation = 'valide' AND p.role = 'super_admin' 
        THEN '✅ OK - Peut se connecter'
        ELSE '❌ Problème'
    END as statut_final
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin'
ORDER BY au.email;

-- 7. Retirer de la vue membres_en_attente
SELECT 
    '📋 Membres encore en attente (ne devrait pas inclure les admins)' as info;

SELECT 
    user_id,
    email,
    full_name,
    statut_validation
FROM membres_en_attente
WHERE email IN ('agbeviade2017@gmail.com', 'kodjodavid2025@gmail.com');

-- Si des admins apparaissent, c'est qu'ils ne sont pas validés

SELECT '✅ Correction terminée avec succès !' as status;
SELECT '🔄 Reconnectez-vous dans l''application Flutter' as conseil;
SELECT '📱 Vous devriez maintenant avoir accès complet' as resultat;

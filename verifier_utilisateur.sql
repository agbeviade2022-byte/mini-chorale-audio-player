-- =====================================================
-- VÉRIFIER SI L'UTILISATEUR EXISTE
-- =====================================================
-- Email: kodjodavid2025@gmail.com
-- =====================================================

-- 1. Vérifier dans auth.users
SELECT 
    '👤 UTILISATEUR (auth.users)' as info,
    id,
    email,
    email_confirmed_at,
    created_at,
    updated_at,
    CASE 
        WHEN encrypted_password IS NOT NULL THEN '✅ Mot de passe défini'
        ELSE '❌ Pas de mot de passe'
    END as statut_mdp
FROM auth.users
WHERE email = 'kodjodavid2025@gmail.com';

-- 2. Vérifier dans profiles
SELECT 
    '📋 PROFIL (profiles)' as info,
    p.id,
    au.email,
    p.full_name,
    p.role,
    p.created_at,
    CASE 
        WHEN p.id IS NOT NULL THEN '✅ Profil existe'
        ELSE '❌ Profil manquant'
    END as statut
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
WHERE au.email = 'kodjodavid2025@gmail.com';

-- 3. Vérifier dans system_admins
SELECT 
    '🔐 ADMIN SYSTÈME (system_admins)' as info,
    sa.user_id,
    sa.email,
    sa.role,
    sa.actif,
    sa.created_at,
    CASE 
        WHEN sa.user_id IS NOT NULL THEN '✅ Admin système'
        ELSE '❌ Pas admin système'
    END as statut
FROM auth.users au
LEFT JOIN system_admins sa ON au.id = sa.user_id
WHERE au.email = 'kodjodavid2025@gmail.com';

-- 4. Vérifier les permissions
SELECT 
    '✅ PERMISSIONS (admin_permissions)' as info,
    COUNT(ap.permission_id) as nb_permissions,
    CASE 
        WHEN COUNT(ap.permission_id) > 0 THEN '✅ A des permissions'
        ELSE '❌ Aucune permission'
    END as statut
FROM auth.users au
LEFT JOIN system_admins sa ON au.id = sa.user_id
LEFT JOIN admin_permissions ap ON sa.id = ap.admin_id
WHERE au.email = 'kodjodavid2025@gmail.com'
GROUP BY au.id;

-- 5. Tester la fonction is_system_admin
SELECT 
    '🧪 TEST FONCTION is_system_admin' as info,
    au.id as user_id,
    au.email,
    is_system_admin(au.id) as est_admin,
    CASE 
        WHEN is_system_admin(au.id) = true THEN '✅ Fonction OK'
        ELSE '❌ Fonction retourne false'
    END as statut
FROM auth.users au
WHERE au.email = 'kodjodavid2025@gmail.com';

-- =====================================================
-- RÉSUMÉ
-- =====================================================

SELECT 
    '📊 RÉSUMÉ COMPLET' as info,
    CASE 
        WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'kodjodavid2025@gmail.com') 
        THEN '✅ Utilisateur existe'
        ELSE '❌ Utilisateur n''existe pas'
    END as utilisateur,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM profiles p 
            JOIN auth.users au ON p.id = au.id 
            WHERE au.email = 'kodjodavid2025@gmail.com'
        ) 
        THEN '✅ Profil existe'
        ELSE '❌ Profil manquant'
    END as profil,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM system_admins sa 
            WHERE sa.email = 'kodjodavid2025@gmail.com'
        ) 
        THEN '✅ Admin système'
        ELSE '❌ Pas admin système'
    END as admin_systeme,
    (
        SELECT COUNT(*) 
        FROM admin_permissions ap 
        JOIN system_admins sa ON ap.admin_id = sa.id
        WHERE sa.email = 'kodjodavid2025@gmail.com'
    ) as nb_permissions;

-- =====================================================
-- INTERPRÉTATION
-- =====================================================
-- Si vous voyez:
-- ✅ Utilisateur existe → Le compte est créé
-- ✅ Profil existe → Le profil est lié
-- ✅ Admin système → Vous êtes admin
-- nb_permissions: 21 → Toutes les permissions
-- ✅ Fonction OK → La fonction is_system_admin fonctionne
--
-- Si vous voyez:
-- ❌ Utilisateur n'existe pas → Exécuter creer_compte_avec_mdp.sql
-- ❌ Profil manquant → Exécuter fix_profil.sql
-- ❌ Pas admin système → Exécuter create_super_admin.sql
-- nb_permissions: 0 → Exécuter la partie permissions de creer_compte_avec_mdp.sql
-- =====================================================

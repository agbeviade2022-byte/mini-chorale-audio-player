-- =====================================================
-- DIAGNOSTIC ET CORRECTION : Profils manquants
-- =====================================================
-- Identifie et corrige les utilisateurs sans profil
-- =====================================================

-- 1. DIAGNOSTIC : Trouver les utilisateurs orphelins
SELECT 
    '🔍 DIAGNOSTIC: Utilisateurs dans auth.users mais pas dans profiles' as info;

SELECT 
    au.id as user_id,
    au.email,
    au.created_at,
    '❌ Profil manquant' as status
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL
ORDER BY au.created_at DESC;

-- 2. DIAGNOSTIC : Permissions orphelines
SELECT 
    '🔍 DIAGNOSTIC: Permissions pour des utilisateurs inexistants' as info;

SELECT 
    up.user_id,
    mp.nom as permission,
    '❌ Utilisateur inexistant' as status
FROM user_permissions up
JOIN modules_permissions mp ON up.module_code = mp.code
LEFT JOIN profiles p ON up.user_id = p.user_id
WHERE p.user_id IS NULL;

-- 3. CORRECTION : Créer les profils manquants
SELECT 
    '🔧 CORRECTION: Création des profils manquants' as info;

INSERT INTO profiles (user_id, full_name, role, created_at)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'full_name', SPLIT_PART(au.email, '@', 1)) as full_name,
    'membre' as role,
    au.created_at
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL
ON CONFLICT (user_id) DO NOTHING;

-- 4. VÉRIFICATION : Compter les profils créés
SELECT 
    '✅ VÉRIFICATION: Profils créés' as info,
    COUNT(*) as nombre_profils_crees
FROM profiles
WHERE created_at >= NOW() - INTERVAL '1 minute';

-- 5. NETTOYAGE : Supprimer les permissions orphelines
SELECT 
    '🧹 NETTOYAGE: Suppression des permissions orphelines' as info;

DELETE FROM user_permissions
WHERE user_id NOT IN (SELECT user_id FROM profiles);

-- 6. VÉRIFICATION FINALE
SELECT 
    '📊 VÉRIFICATION FINALE' as info;

SELECT 
    'auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'profiles' as table_name,
    COUNT(*) as count
FROM profiles
UNION ALL
SELECT 
    'user_permissions (utilisateurs uniques)' as table_name,
    COUNT(DISTINCT user_id) as count
FROM user_permissions;

-- 7. LISTE DES UTILISATEURS AVEC LEUR STATUT
SELECT 
    '👥 LISTE DES UTILISATEURS' as info;

SELECT 
    p.user_id,
    p.full_name,
    au.email,
    p.role,
    CASE 
        WHEN p.user_id IS NOT NULL THEN '✅ Profil OK'
        ELSE '❌ Profil manquant'
    END as statut
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
ORDER BY p.created_at DESC;

SELECT '✅ Script terminé avec succès !' as status;
SELECT '📝 Rechargez le dashboard et réessayez' as conseil;

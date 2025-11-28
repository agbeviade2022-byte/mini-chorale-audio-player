-- =====================================================
-- DEBUG : Permissions utilisateur
-- =====================================================

-- ⚠️⚠️⚠️ REMPLACEZ VOTRE EMAIL ICI ⚠️⚠️⚠️
DO $$
DECLARE
    user_email TEXT := 'agbeviade2017@gmail.com';  -- 👈 CHANGEZ ICI
BEGIN
    -- Stocker l'email dans une variable de session temporaire
    PERFORM set_config('app.user_email', user_email, true);
END $$;

SELECT '🔍 DEBUG : Permissions utilisateur' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier le profil de l'utilisateur connecté
-- ============================================

SELECT '📋 ÉTAPE 1 : Profil utilisateur' as etape;

SELECT 
    p.id as profile_id,
    p.user_id,
    au.email,
    p.full_name,
    p.role,
    p.statut_validation,
    p.chorale_id,
    CASE 
        WHEN p.role = 'super_admin' THEN '✅ Super Admin'
        WHEN p.role = 'admin' THEN '✅ Admin'
        WHEN p.role = 'membre' THEN '👤 Membre'
        ELSE '⚠️ Rôle inconnu'
    END as statut_role
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
WHERE au.email = current_setting('app.user_email');

-- ============================================
-- ÉTAPE 2 : Vérifier les permissions de l'utilisateur
-- ============================================

SELECT '📋 ÉTAPE 2 : Permissions utilisateur' as etape;

-- Permissions via RPC (comme dans l'app)
SELECT * FROM get_user_permissions(
    (SELECT p.id FROM profiles p 
     INNER JOIN auth.users au ON p.user_id = au.id 
     WHERE au.email = current_setting('app.user_email'))
);

-- ============================================
-- ÉTAPE 3 : Vérifier les permissions directement
-- ============================================

SELECT '📋 ÉTAPE 3 : Permissions directes' as etape;

SELECT 
    up.id,
    mp.code,
    mp.nom,
    mp.description,
    up.attribue_le,
    up.expire_le,
    CASE 
        WHEN up.expire_le IS NULL THEN '✅ Permanent'
        WHEN up.expire_le > NOW() THEN '✅ Actif'
        ELSE '❌ Expiré'
    END as statut
FROM user_permissions up
INNER JOIN modules_permissions mp ON up.module_code = mp.code
INNER JOIN profiles p ON up.user_id = p.id
INNER JOIN auth.users au ON p.user_id = au.id
WHERE au.email = current_setting('app.user_email')
ORDER BY mp.ordre;

-- ============================================
-- ÉTAPE 4 : Vérifier tous les modules disponibles
-- ============================================

SELECT '📋 ÉTAPE 4 : Tous les modules' as etape;

SELECT 
    code,
    nom,
    description,
    ordre,
    '✅ Disponible' as statut
FROM modules_permissions
ORDER BY ordre;

-- ============================================
-- ÉTAPE 5 : Vérifier si le profil existe bien
-- ============================================

SELECT '📋 ÉTAPE 5 : Vérification profil' as etape;

SELECT 
    COUNT(*) as nombre_profils,
    CASE 
        WHEN COUNT(*) = 1 THEN '✅ Profil unique'
        WHEN COUNT(*) = 0 THEN '❌ Aucun profil'
        ELSE '⚠️ Doublons détectés'
    END as statut
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
WHERE au.email = current_setting('app.user_email');

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '📊 RÉSUMÉ' as info;

SELECT 
    'Rôle' as element,
    (SELECT p.role FROM profiles p 
     INNER JOIN auth.users au ON p.user_id = au.id 
     WHERE au.email = current_setting('app.user_email')) as valeur
UNION ALL
SELECT 
    'Nombre de permissions' as element,
    COUNT(*)::text as valeur
FROM user_permissions up
INNER JOIN profiles p ON up.user_id = p.id
INNER JOIN auth.users au ON p.user_id = au.id
WHERE au.email = current_setting('app.user_email');

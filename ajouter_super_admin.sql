-- =====================================================
-- AJOUTER SUPER ADMIN - kodjodavid2025@gmail.com
-- =====================================================
-- Script pour s'assurer que votre compte est super_admin
-- et présent dans system_admins
-- =====================================================

-- =====================================================
-- 1. VÉRIFIER L'UTILISATEUR ACTUEL
-- =====================================================

SELECT 
    '🔍 ÉTAT ACTUEL' as info,
    u.id,
    u.email,
    u.email_confirmed_at,
    p.full_name,
    p.role,
    CASE WHEN sa.user_id IS NOT NULL THEN 'Oui' ELSE 'Non' END as is_system_admin
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
LEFT JOIN system_admins sa ON u.id = sa.user_id
WHERE u.email = 'kodjodavid2025@gmail.com';

-- =====================================================
-- 2. METTRE À JOUR LE PROFIL EN SUPER_ADMIN
-- =====================================================

UPDATE profiles
SET role = 'super_admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com');

-- =====================================================
-- 3. AJOUTER À SYSTEM_ADMINS
-- =====================================================

INSERT INTO system_admins (user_id, email, created_at)
SELECT 
    id,
    email,
    NOW()
FROM auth.users
WHERE email = 'kodjodavid2025@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- 4. CONFIRMER L'EMAIL (si pas déjà fait)
-- =====================================================

UPDATE auth.users
SET email_confirmed_at = COALESCE(email_confirmed_at, NOW())
WHERE email = 'kodjodavid2025@gmail.com';

-- =====================================================
-- 5. RÉINITIALISER LE MOT DE PASSE
-- =====================================================

UPDATE auth.users
SET encrypted_password = crypt('Admin@2024', gen_salt('bf'))
WHERE email = 'kodjodavid2025@gmail.com';

-- =====================================================
-- 6. VÉRIFICATION FINALE
-- =====================================================

SELECT 
    '✅ RÉSULTAT FINAL' as info,
    u.id,
    u.email,
    u.email_confirmed_at as email_confirme,
    p.full_name,
    p.role,
    CASE WHEN sa.user_id IS NOT NULL THEN '✅ Oui' ELSE '❌ Non' END as is_system_admin,
    p.created_at
FROM auth.users u
JOIN profiles p ON u.id = p.id
LEFT JOIN system_admins sa ON u.id = sa.user_id
WHERE u.email = 'kodjodavid2025@gmail.com';

-- =====================================================
-- 7. VÉRIFIER LES PERMISSIONS
-- =====================================================

-- Tester la fonction is_system_admin
SELECT 
    '🔐 TEST PERMISSIONS' as info,
    is_system_admin(u.id) as est_admin_systeme
FROM auth.users u
WHERE u.email = 'kodjodavid2025@gmail.com';

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ role: super_admin
-- ✅ is_system_admin: Oui
-- ✅ email_confirme: Date (pas NULL)
-- ✅ est_admin_systeme: true
--
-- Vous pouvez maintenant:
-- 1. Vous connecter au dashboard web
-- 2. Accéder à toutes les fonctionnalités admin
-- 3. Gérer les utilisateurs, chorales et chants
-- =====================================================

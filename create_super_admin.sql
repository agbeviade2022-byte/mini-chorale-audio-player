-- =====================================================
-- CRÉER LE SUPER ADMIN: kodjodavid2025@gmail.com
-- =====================================================

-- =====================================================
-- 1. RÉCUPÉRER ET AFFICHER LE USER_ID
-- =====================================================

SELECT 
    '🔍 VOTRE USER ID' as info,
    id as user_id,
    email,
    created_at
FROM auth.users 
WHERE email = 'kodjodavid2025@gmail.com';

-- =====================================================
-- 2. CRÉER LE SUPER ADMIN
-- =====================================================

DO $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer le user_id
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = 'kodjodavid2025@gmail.com';
    
    -- Vérifier que l'utilisateur existe
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur avec email kodjodavid2025@gmail.com non trouvé. Veuillez d''abord créer un compte avec cet email.';
    END IF;
    
    -- Créer le super admin
    INSERT INTO system_admins (user_id, email, role, permissions)
    VALUES (
        v_user_id,
        'kodjodavid2025@gmail.com',
        'super_admin',
        '["all"]'::jsonb
    )
    ON CONFLICT (user_id) DO UPDATE
    SET 
        role = 'super_admin',
        permissions = '["all"]'::jsonb,
        actif = true,
        updated_at = NOW();
    
    RAISE NOTICE '✅ Super admin créé avec succès pour kodjodavid2025@gmail.com';
END $$;

-- =====================================================
-- 3. DONNER TOUTES LES PERMISSIONS
-- =====================================================

DO $$
DECLARE
    v_admin_id UUID;
    v_permission_id UUID;
BEGIN
    -- Récupérer l'ID du super admin
    SELECT id INTO v_admin_id
    FROM system_admins
    WHERE email = 'kodjodavid2025@gmail.com';
    
    -- Ajouter toutes les permissions
    FOR v_permission_id IN 
        SELECT id FROM permissions
    LOOP
        INSERT INTO admin_permissions (admin_id, permission_id)
        VALUES (v_admin_id, v_permission_id)
        ON CONFLICT (admin_id, permission_id) DO NOTHING;
    END LOOP;
    
    RAISE NOTICE '✅ Toutes les permissions ajoutées';
END $$;

-- =====================================================
-- 4. VÉRIFICATION
-- =====================================================

-- Afficher les infos du super admin
SELECT 
    '✅ SUPER ADMIN CRÉÉ' as statut,
    sa.id,
    sa.user_id,
    sa.email,
    sa.role,
    sa.actif,
    sa.created_at,
    COUNT(ap.id) as nb_permissions
FROM system_admins sa
LEFT JOIN admin_permissions ap ON sa.id = ap.admin_id
WHERE sa.email = 'kodjodavid2025@gmail.com'
GROUP BY sa.id, sa.user_id, sa.email, sa.role, sa.actif, sa.created_at;

-- Lister toutes les permissions du super admin
SELECT 
    '📋 PERMISSIONS DU SUPER ADMIN' as info,
    p.nom,
    p.description,
    p.module
FROM system_admins sa
JOIN admin_permissions ap ON sa.id = ap.admin_id
JOIN permissions p ON ap.permission_id = p.id
WHERE sa.email = 'kodjodavid2025@gmail.com'
ORDER BY p.module, p.nom;

-- Tester la fonction is_system_admin
SELECT 
    '🧪 TEST is_system_admin()' as test,
    is_system_admin(id) as est_admin
FROM auth.users
WHERE email = 'kodjodavid2025@gmail.com';

-- Tester la fonction has_permission
SELECT 
    '🧪 TEST has_permission()' as test,
    has_permission(id, 'chorales.delete') as peut_supprimer_chorales,
    has_permission(id, 'users.ban') as peut_bannir_users,
    has_permission(id, 'system.settings') as peut_modifier_settings
FROM auth.users
WHERE email = 'kodjodavid2025@gmail.com';

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Super admin créé pour kodjodavid2025@gmail.com
-- ✅ 21 permissions ajoutées
-- ✅ is_system_admin() retourne true
-- ✅ has_permission() retourne true pour toutes les permissions

-- =====================================================
-- PROCHAINES ÉTAPES
-- =====================================================
/*
Dans votre app Flutter, vous pouvez maintenant:

1. Vérifier si l'utilisateur est super admin:
   final isAdmin = await supabase.rpc('is_system_admin', 
     params: {'check_user_id': currentUserId});

2. Afficher le dashboard admin si isAdmin == true

3. Utiliser les permissions pour contrôler l'accès:
   final canDelete = await supabase.rpc('has_permission', params: {
     'check_user_id': currentUserId,
     'permission_name': 'chorales.delete',
   });

4. Logger toutes les actions admin:
   await supabase.rpc('log_admin_action', params: {
     'p_user_id': currentUserId,
     'p_action': 'DELETE_CHORALE',
     'p_table_name': 'chorales',
     'p_record_id': choraleId,
   });
*/

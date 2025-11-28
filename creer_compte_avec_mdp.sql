-- =====================================================
-- CRÉER LE COMPTE ADMIN AVEC MOT DE PASSE
-- =====================================================
-- Email: kodjodavid2025@gmail.com
-- Mot de passe: Admin@2024
-- =====================================================

-- 1. Créer l'utilisateur dans auth.users
DO $$
DECLARE
    v_user_id UUID;
    v_existing_id UUID;
BEGIN
    -- Vérifier si l'utilisateur existe déjà
    SELECT id INTO v_existing_id
    FROM auth.users
    WHERE email = 'kodjodavid2025@gmail.com';
    
    IF v_existing_id IS NOT NULL THEN
        RAISE NOTICE '⚠️ Utilisateur existe déjà avec ID: %', v_existing_id;
        RAISE NOTICE '💡 Mise à jour du mot de passe...';
        
        -- Mettre à jour le mot de passe
        UPDATE auth.users
        SET 
            encrypted_password = crypt('Admin@2024', gen_salt('bf')),
            email_confirmed_at = NOW(),
            updated_at = NOW()
        WHERE id = v_existing_id;
        
        RAISE NOTICE '✅ Mot de passe mis à jour pour: %', v_existing_id;
    ELSE
        -- Générer un nouvel ID
        v_user_id := gen_random_uuid();
        
        -- Créer l'utilisateur
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            email_change,
            email_change_token_new,
            recovery_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            v_user_id,
            'authenticated',
            'authenticated',
            'kodjodavid2025@gmail.com',
            crypt('Admin@2024', gen_salt('bf')), -- MOT DE PASSE ICI
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{}',
            NOW(),
            NOW(),
            '',
            '',
            '',
            ''
        );
        
        RAISE NOTICE '✅ Utilisateur créé avec ID: %', v_user_id;
    END IF;
END $$;

-- 2. Créer le profil
DO $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = 'kodjodavid2025@gmail.com';
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non trouvé';
    END IF;
    
    -- Créer le profil
    INSERT INTO profiles (id, full_name, role)
    VALUES (
        v_user_id,
        'David Kodjo',
        'admin'
    )
    ON CONFLICT (id) DO UPDATE
    SET 
        full_name = 'David Kodjo',
        role = 'admin';
    
    RAISE NOTICE '✅ Profil créé pour: %', v_user_id;
END $$;

-- 3. Ajouter aux admins système
DO $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = 'kodjodavid2025@gmail.com';
    
    -- Ajouter aux admins système
    INSERT INTO system_admins (user_id, email, role, actif)
    VALUES (v_user_id, 'kodjodavid2025@gmail.com', 'super_admin', true)
    ON CONFLICT (user_id) DO UPDATE
    SET 
        email = 'kodjodavid2025@gmail.com',
        role = 'super_admin',
        actif = true,
        updated_at = NOW();
    
    RAISE NOTICE '✅ Ajouté aux admins système';
END $$;

-- 4. Attribuer toutes les permissions
DO $$
DECLARE
    v_admin_id UUID;
    v_permission RECORD;
BEGIN
    -- Récupérer l'ID de l'admin système
    SELECT id INTO v_admin_id
    FROM system_admins
    WHERE email = 'kodjodavid2025@gmail.com';
    
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'Admin système non trouvé';
    END IF;
    
    -- Attribuer toutes les permissions
    FOR v_permission IN SELECT id FROM permissions
    LOOP
        INSERT INTO admin_permissions (admin_id, permission_id)
        VALUES (v_admin_id, v_permission.id)
        ON CONFLICT (admin_id, permission_id) DO NOTHING;
    END LOOP;
    
    RAISE NOTICE '✅ Toutes les permissions attribuées';
END $$;

-- =====================================================
-- VÉRIFICATIONS
-- =====================================================

-- Vérifier l'utilisateur
SELECT 
    '👤 UTILISATEUR' as info,
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users
WHERE email = 'kodjodavid2025@gmail.com';

-- Vérifier le profil
SELECT 
    '📋 PROFIL' as info,
    p.id,
    au.email,
    p.full_name,
    p.role,
    p.created_at
FROM profiles p
JOIN auth.users au ON p.id = au.id
WHERE au.email = 'kodjodavid2025@gmail.com';

-- Vérifier admin système
SELECT 
    '🔐 ADMIN SYSTÈME' as info,
    sa.user_id,
    sa.email,
    sa.role,
    sa.actif,
    sa.created_at
FROM system_admins sa
WHERE sa.email = 'kodjodavid2025@gmail.com';

-- Vérifier les permissions
SELECT 
    '✅ PERMISSIONS' as info,
    COUNT(*) as nb_permissions
FROM admin_permissions ap
JOIN system_admins sa ON ap.admin_id = sa.id
WHERE sa.email = 'kodjodavid2025@gmail.com';

-- Tester la fonction is_system_admin
SELECT 
    '🧪 TEST FONCTION' as info,
    is_system_admin(au.id) as est_admin
FROM auth.users au
WHERE au.email = 'kodjodavid2025@gmail.com';

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Utilisateur créé avec ID: xxx-xxx-xxx
-- ✅ Profil créé pour: xxx-xxx-xxx
-- ✅ Ajouté aux admins système
-- ✅ Toutes les permissions attribuées
--
-- 👤 UTILISATEUR
-- id: xxx-xxx-xxx
-- email: kodjodavid2025@gmail.com
-- email_confirmed_at: 2024-11-18 23:07:00
--
-- 📋 PROFIL
-- id: xxx-xxx-xxx
-- email: kodjodavid2025@gmail.com
-- full_name: David Kodjo
-- role: admin
--
-- 🔐 ADMIN SYSTÈME
-- user_id: xxx-xxx-xxx
-- email: kodjodavid2025@gmail.com
-- role: super_admin
-- actif: true
--
-- ✅ PERMISSIONS
-- nb_permissions: 21
--
-- 🧪 TEST FONCTION
-- est_admin: true
-- =====================================================

-- =====================================================
-- INFORMATIONS DE CONNEXION
-- =====================================================
-- Email: kodjodavid2025@gmail.com
-- Mot de passe: Admin@2024
--
-- Dashboard: http://localhost:3000/login
-- =====================================================

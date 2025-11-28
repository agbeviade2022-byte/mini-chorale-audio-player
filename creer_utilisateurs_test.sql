-- =====================================================
-- CRÉER DES UTILISATEURS DE TEST
-- =====================================================
-- Ce script crée plusieurs utilisateurs de test pour
-- tester le dashboard et la synchronisation
-- =====================================================

-- =====================================================
-- 1. VÉRIFIER LES UTILISATEURS EXISTANTS
-- =====================================================

SELECT 
    '📊 UTILISATEURS EXISTANTS' as info,
    COUNT(*) as total_users
FROM auth.users;

SELECT 
    au.id,
    au.email,
    au.created_at,
    p.full_name,
    p.role
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
ORDER BY au.created_at DESC;

-- =====================================================
-- 2. CRÉER DES UTILISATEURS DE TEST
-- =====================================================

-- Utilisateur 1: Membre de chorale
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'membre1@chorale.com';
BEGIN
    -- Vérifier si l'utilisateur existe déjà
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = v_email;
    
    IF v_user_id IS NULL THEN
        -- Créer l'utilisateur dans auth.users
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
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            v_email,
            crypt('Membre@2024', gen_salt('bf')),
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"Marie Dupont"}',
            NOW(),
            NOW(),
            '',
            '',
            '',
            ''
        )
        RETURNING id INTO v_user_id;
        
        -- Créer le profil
        INSERT INTO profiles (id, full_name, role)
        VALUES (v_user_id, 'Marie Dupont', 'membre');
        
        RAISE NOTICE '✅ Utilisateur créé: % (ID: %)', v_email, v_user_id;
    ELSE
        RAISE NOTICE '⚠️ Utilisateur existe déjà: %', v_email;
    END IF;
END $$;

-- Utilisateur 2: Utilisateur standard
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'user1@chorale.com';
BEGIN
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = v_email;
    
    IF v_user_id IS NULL THEN
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
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            v_email,
            crypt('User@2024', gen_salt('bf')),
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"Jean Martin"}',
            NOW(),
            NOW(),
            '',
            '',
            '',
            ''
        )
        RETURNING id INTO v_user_id;
        
        INSERT INTO profiles (id, full_name, role)
        VALUES (v_user_id, 'Jean Martin', 'user');
        
        RAISE NOTICE '✅ Utilisateur créé: % (ID: %)', v_email, v_user_id;
    ELSE
        RAISE NOTICE '⚠️ Utilisateur existe déjà: %', v_email;
    END IF;
END $$;

-- Utilisateur 3: Administrateur
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'admin2@chorale.com';
BEGIN
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = v_email;
    
    IF v_user_id IS NULL THEN
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
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            v_email,
            crypt('Admin@2024', gen_salt('bf')),
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"Sophie Bernard"}',
            NOW(),
            NOW(),
            '',
            '',
            '',
            ''
        )
        RETURNING id INTO v_user_id;
        
        INSERT INTO profiles (id, full_name, role)
        VALUES (v_user_id, 'Sophie Bernard', 'admin');
        
        -- Ajouter dans system_admins
        INSERT INTO system_admins (user_id, email, role, actif)
        VALUES (v_user_id, v_email, 'admin', true);
        
        RAISE NOTICE '✅ Administrateur créé: % (ID: %)', v_email, v_user_id;
    ELSE
        RAISE NOTICE '⚠️ Utilisateur existe déjà: %', v_email;
    END IF;
END $$;

-- Utilisateur 4: Membre de chorale 2
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'membre2@chorale.com';
BEGIN
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = v_email;
    
    IF v_user_id IS NULL THEN
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
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            v_email,
            crypt('Membre@2024', gen_salt('bf')),
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"Pierre Dubois"}',
            NOW(),
            NOW(),
            '',
            '',
            '',
            ''
        )
        RETURNING id INTO v_user_id;
        
        INSERT INTO profiles (id, full_name, role)
        VALUES (v_user_id, 'Pierre Dubois', 'membre');
        
        RAISE NOTICE '✅ Utilisateur créé: % (ID: %)', v_email, v_user_id;
    ELSE
        RAISE NOTICE '⚠️ Utilisateur existe déjà: %', v_email;
    END IF;
END $$;

-- Utilisateur 5: Utilisateur standard 2
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'user2@chorale.com';
BEGIN
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = v_email;
    
    IF v_user_id IS NULL THEN
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
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            v_email,
            crypt('User@2024', gen_salt('bf')),
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"Claire Petit"}',
            NOW(),
            NOW(),
            '',
            '',
            '',
            ''
        )
        RETURNING id INTO v_user_id;
        
        INSERT INTO profiles (id, full_name, role)
        VALUES (v_user_id, 'Claire Petit', 'user');
        
        RAISE NOTICE '✅ Utilisateur créé: % (ID: %)', v_email, v_user_id;
    ELSE
        RAISE NOTICE '⚠️ Utilisateur existe déjà: %', v_email;
    END IF;
END $$;

-- =====================================================
-- 3. VÉRIFIER LES UTILISATEURS CRÉÉS
-- =====================================================

SELECT 
    '✅ RÉSULTAT FINAL' as info,
    COUNT(*) as total_users
FROM auth.users;

SELECT 
    au.email,
    p.full_name,
    p.role,
    CASE 
        WHEN sa.id IS NOT NULL THEN '✅ Admin système'
        ELSE '👤 Utilisateur'
    END as type_compte
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
LEFT JOIN system_admins sa ON au.id = sa.user_id
ORDER BY p.role DESC, au.created_at DESC;

-- =====================================================
-- 4. TESTER LA FONCTION RPC
-- =====================================================

SELECT * FROM get_all_users_with_emails();

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ 6 utilisateurs créés:
-- 1. kodjodavid2025@gmail.com - David Kodjo (super_admin)
-- 2. admin2@chorale.com - Sophie Bernard (admin)
-- 3. membre1@chorale.com - Marie Dupont (membre)
-- 4. membre2@chorale.com - Pierre Dubois (membre)
-- 5. user1@chorale.com - Jean Martin (user)
-- 6. user2@chorale.com - Claire Petit (user)
--
-- MOTS DE PASSE:
-- - Admins: Admin@2024
-- - Membres: Membre@2024
-- - Users: User@2024
-- =====================================================

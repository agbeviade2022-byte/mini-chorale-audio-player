-- =====================================================
-- CRÉER DES UTILISATEURS DE TEST (VERSION SIMPLIFIÉE)
-- =====================================================
-- Cette version utilise une approche plus simple
-- pour créer des utilisateurs de test
-- =====================================================

-- =====================================================
-- 1. NETTOYER LES PROFILS SANS EMAIL
-- =====================================================

-- Supprimer les profils qui n'ont pas d'utilisateur auth correspondant
DELETE FROM profiles
WHERE id NOT IN (SELECT id FROM auth.users);

SELECT '✅ Profils orphelins supprimés' as info;

-- =====================================================
-- 2. VÉRIFIER LES UTILISATEURS EXISTANTS
-- =====================================================

SELECT 
    '📊 UTILISATEURS EXISTANTS' as info,
    COUNT(*) as total_users
FROM auth.users;

SELECT 
    au.id,
    au.email,
    p.full_name,
    p.role
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
ORDER BY au.created_at DESC;

-- =====================================================
-- 3. CRÉER DES UTILISATEURS DE TEST
-- =====================================================
-- Note: Ces utilisateurs seront créés via l'interface
-- Supabase ou l'application Flutter pour éviter les
-- problèmes de synchronisation entre auth.users et profiles
-- =====================================================

-- Pour créer des utilisateurs de test, utilisez plutôt:
-- 1. L'interface Supabase Authentication
-- 2. L'application Flutter (inscription)
-- 3. Ou le script ci-dessous avec la bonne structure

-- =====================================================
-- ALTERNATIVE: Créer via SQL (méthode correcte)
-- =====================================================

-- Utilisateur 1: Membre
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'marie.dupont@chorale.com';
BEGIN
    -- Vérifier si existe déjà
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email;
    
    IF v_user_id IS NULL THEN
        -- Créer dans auth.users
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
            crypt('Test@2024', gen_salt('bf')),
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
        
        -- Le profil sera créé automatiquement par le trigger handle_new_user
        -- Mais on peut le mettre à jour pour être sûr
        UPDATE profiles 
        SET role = 'membre', full_name = 'Marie Dupont'
        WHERE id = v_user_id;
        
        RAISE NOTICE '✅ Utilisateur créé: % (ID: %)', v_email, v_user_id;
    ELSE
        RAISE NOTICE '⚠️ Utilisateur existe déjà: %', v_email;
    END IF;
END $$;

-- Utilisateur 2: User standard
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'jean.martin@chorale.com';
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email;
    
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
            crypt('Test@2024', gen_salt('bf')),
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
        
        UPDATE profiles 
        SET role = 'user', full_name = 'Jean Martin'
        WHERE id = v_user_id;
        
        RAISE NOTICE '✅ Utilisateur créé: % (ID: %)', v_email, v_user_id;
    ELSE
        RAISE NOTICE '⚠️ Utilisateur existe déjà: %', v_email;
    END IF;
END $$;

-- Utilisateur 3: Admin
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'sophie.bernard@chorale.com';
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email;
    
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
            crypt('Test@2024', gen_salt('bf')),
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
        
        UPDATE profiles 
        SET role = 'admin', full_name = 'Sophie Bernard'
        WHERE id = v_user_id;
        
        -- Ajouter dans system_admins
        INSERT INTO system_admins (user_id, email, role, actif)
        VALUES (v_user_id, v_email, 'admin', true)
        ON CONFLICT (user_id) DO NOTHING;
        
        RAISE NOTICE '✅ Admin créé: % (ID: %)', v_email, v_user_id;
    ELSE
        RAISE NOTICE '⚠️ Utilisateur existe déjà: %', v_email;
    END IF;
END $$;

-- Utilisateur 4: Membre 2
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'pierre.dubois@chorale.com';
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email;
    
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
            crypt('Test@2024', gen_salt('bf')),
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
        
        UPDATE profiles 
        SET role = 'membre', full_name = 'Pierre Dubois'
        WHERE id = v_user_id;
        
        RAISE NOTICE '✅ Utilisateur créé: % (ID: %)', v_email, v_user_id;
    ELSE
        RAISE NOTICE '⚠️ Utilisateur existe déjà: %', v_email;
    END IF;
END $$;

-- Utilisateur 5: User 2
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'claire.petit@chorale.com';
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email;
    
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
            crypt('Test@2024', gen_salt('bf')),
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
        
        UPDATE profiles 
        SET role = 'user', full_name = 'Claire Petit'
        WHERE id = v_user_id;
        
        RAISE NOTICE '✅ Utilisateur créé: % (ID: %)', v_email, v_user_id;
    ELSE
        RAISE NOTICE '⚠️ Utilisateur existe déjà: %', v_email;
    END IF;
END $$;

-- =====================================================
-- 4. VÉRIFIER LES RÉSULTATS
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
-- 5. TESTER LA FONCTION RPC
-- =====================================================

SELECT * FROM get_all_users_with_emails();

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Profils orphelins supprimés
-- ✅ 6 utilisateurs au total:
-- 1. kodjodavid2025@gmail.com - David Kodjo (super_admin)
-- 2. sophie.bernard@chorale.com - Sophie Bernard (admin)
-- 3. marie.dupont@chorale.com - Marie Dupont (membre)
-- 4. pierre.dubois@chorale.com - Pierre Dubois (membre)
-- 5. jean.martin@chorale.com - Jean Martin (user)
-- 6. claire.petit@chorale.com - Claire Petit (user)
--
-- MOT DE PASSE POUR TOUS: Test@2024
-- =====================================================

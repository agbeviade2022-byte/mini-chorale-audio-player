-- =====================================================
-- CRÉER LES PROFILS MANQUANTS
-- =====================================================
-- Script pour créer les profils des utilisateurs qui
-- n'en ont pas (à cause du trigger défaillant)
-- =====================================================

-- =====================================================
-- 1. IDENTIFIER LES UTILISATEURS SANS PROFIL
-- =====================================================

SELECT 
    '🔍 UTILISATEURS SANS PROFIL' as info,
    u.id,
    u.email,
    u.raw_user_meta_data->>'full_name' as full_name,
    u.created_at
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL
ORDER BY u.created_at DESC;

-- =====================================================
-- 2. CRÉER LES PROFILS MANQUANTS
-- =====================================================

-- Créer automatiquement les profils pour tous les utilisateurs sans profil
INSERT INTO profiles (id, full_name, role, created_at)
SELECT 
    u.id,
    COALESCE(u.raw_user_meta_data->>'full_name', 'Utilisateur') as full_name,
    'user' as role,
    u.created_at
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 3. VÉRIFIER LES PROFILS CRÉÉS
-- =====================================================

SELECT 
    '✅ VÉRIFICATION' as info,
    COUNT(*) as total_users,
    COUNT(p.id) as users_with_profile,
    COUNT(*) - COUNT(p.id) as users_without_profile
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id;

-- =====================================================
-- 4. AFFICHER LES PROFILS RÉCEMMENT CRÉÉS
-- =====================================================

SELECT 
    '📋 PROFILS RÉCENTS' as info,
    p.id,
    p.full_name,
    p.role,
    u.email,
    p.created_at
FROM profiles p
JOIN auth.users u ON p.id = u.id
ORDER BY p.created_at DESC
LIMIT 10;

-- =====================================================
-- 5. CORRIGER LE TRIGGER handle_new_user
-- =====================================================

-- Recréer le trigger avec gestion d'erreur améliorée
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Créer le profil
  INSERT INTO public.profiles (id, full_name, role, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
    'user',
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
    updated_at = NOW();
  
  RAISE NOTICE '✅ Profil créé pour utilisateur: % (%)', NEW.email, NEW.id;
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Logger l'erreur mais ne pas bloquer l'inscription
    RAISE WARNING '❌ Erreur lors de la création du profil pour %: %', NEW.email, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recréer le trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 6. TESTER LE TRIGGER
-- =====================================================

-- Test: Créer un utilisateur de test
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'test.trigger@chorale.com';
BEGIN
    -- Supprimer s'il existe déjà
    DELETE FROM auth.users WHERE email = v_email;
    
    -- Créer un nouvel utilisateur
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
        '{"full_name":"Test Trigger"}',
        NOW(),
        NOW(),
        '',
        '',
        '',
        ''
    )
    RETURNING id INTO v_user_id;
    
    RAISE NOTICE '✅ Utilisateur de test créé: % (ID: %)', v_email, v_user_id;
    
    -- Attendre un peu pour que le trigger s'exécute
    PERFORM pg_sleep(0.5);
    
    -- Vérifier que le profil a été créé
    IF EXISTS (SELECT 1 FROM profiles WHERE id = v_user_id) THEN
        RAISE NOTICE '✅ Profil créé automatiquement par le trigger';
    ELSE
        RAISE NOTICE '❌ Profil non créé - Trigger ne fonctionne pas';
    END IF;
    
    -- Nettoyer
    DELETE FROM auth.users WHERE id = v_user_id;
    RAISE NOTICE '✅ Test terminé et nettoyé';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- =====================================================
-- 7. VÉRIFIER LES TRIGGERS ACTIFS
-- =====================================================

SELECT 
    '✅ TRIGGERS ACTIFS' as info,
    tgname as trigger_name,
    tgrelid::regclass as table_name,
    tgenabled as enabled,
    pg_get_triggerdef(oid) as definition
FROM pg_trigger
WHERE tgname = 'on_auth_user_created'
ORDER BY tgname;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Profils manquants créés
-- ✅ Trigger corrigé et fonctionnel
-- ✅ Test réussi
--
-- Maintenant tous les utilisateurs ont un profil
-- et les nouvelles inscriptions créeront automatiquement
-- un profil grâce au trigger corrigé
-- =====================================================

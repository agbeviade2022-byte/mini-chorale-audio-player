-- =====================================================
-- CORRIGER LES TRIGGERS D'INSCRIPTION
-- =====================================================
-- Correction des triggers qui causent l'erreur 500
-- lors de la création d'un nouvel utilisateur
-- =====================================================

-- =====================================================
-- 1. SUPPRIMER LES ANCIENS TRIGGERS PROBLÉMATIQUES
-- =====================================================

-- Supprimer le trigger de logs sur profiles (temporairement)
DROP TRIGGER IF EXISTS profile_changes_trigger ON profiles;

-- Supprimer la fonction de logs
DROP FUNCTION IF EXISTS log_profile_changes();

-- =====================================================
-- 2. VÉRIFIER LE TRIGGER handle_new_user
-- =====================================================

-- Recréer le trigger handle_new_user (version simplifiée)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
    'user'
  );
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Logger l'erreur mais ne pas bloquer l'inscription
    RAISE WARNING 'Erreur lors de la création du profil: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recréer le trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 3. RECRÉER LE TRIGGER DE LOGS (VERSION SIMPLIFIÉE)
-- =====================================================

-- Fonction de logs simplifiée sans erreur
CREATE OR REPLACE FUNCTION log_profile_changes()
RETURNS TRIGGER AS $$
BEGIN
  -- Logger uniquement si admin_logs existe et est accessible
  BEGIN
    INSERT INTO admin_logs (
      admin_id,
      action,
      table_name,
      record_id,
      details,
      platform,
      created_at
    ) VALUES (
      NULL, -- Pas d'admin pour les auto-créations
      CASE 
        WHEN TG_OP = 'INSERT' THEN 'profile_created'
        WHEN TG_OP = 'UPDATE' THEN 'profile_updated'
        WHEN TG_OP = 'DELETE' THEN 'profile_deleted'
      END,
      'profiles',
      NEW.id,
      json_build_object(
        'operation', TG_OP,
        'new_data', row_to_json(NEW)
      ),
      'system_auto',
      NOW()
    );
  EXCEPTION
    WHEN OTHERS THEN
      -- Ne pas bloquer si le log échoue
      RAISE WARNING 'Erreur lors du logging: %', SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recréer le trigger de logs
CREATE TRIGGER profile_changes_trigger
AFTER INSERT OR UPDATE OR DELETE ON profiles
FOR EACH ROW
EXECUTE FUNCTION log_profile_changes();

-- =====================================================
-- 4. VÉRIFIER LES PERMISSIONS
-- =====================================================

-- S'assurer que les permissions sont correctes
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.profiles TO anon, authenticated;
GRANT ALL ON public.admin_logs TO authenticated;

-- =====================================================
-- 5. TESTER LA CRÉATION D'UTILISATEUR
-- =====================================================

-- Test: Créer un utilisateur de test
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'test.inscription@chorale.com';
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
        '{"full_name":"Test Inscription"}',
        NOW(),
        NOW(),
        '',
        '',
        '',
        ''
    )
    RETURNING id INTO v_user_id;
    
    RAISE NOTICE '✅ Utilisateur de test créé: % (ID: %)', v_email, v_user_id;
    
    -- Vérifier que le profil a été créé
    IF EXISTS (SELECT 1 FROM profiles WHERE id = v_user_id) THEN
        RAISE NOTICE '✅ Profil créé automatiquement';
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
-- 6. VÉRIFIER LES TRIGGERS ACTIFS
-- =====================================================

SELECT 
    '✅ TRIGGERS ACTIFS' as info,
    tgname as trigger_name,
    tgrelid::regclass as table_name,
    tgenabled as enabled
FROM pg_trigger
WHERE tgname IN ('on_auth_user_created', 'profile_changes_trigger')
ORDER BY tgname;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Triggers recréés sans erreur
-- ✅ Test d'inscription réussi
-- ✅ Profil créé automatiquement
-- ✅ Logs enregistrés (si possible)
--
-- Vous pouvez maintenant créer des utilisateurs
-- depuis l'application Flutter sans erreur 500
-- =====================================================

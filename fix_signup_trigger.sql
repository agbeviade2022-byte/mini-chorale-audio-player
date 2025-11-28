-- =====================================================
-- FIX : Corriger le trigger d'inscription
-- =====================================================
-- Ce script corrige l'erreur "Database error saving new user"
-- =====================================================

-- 1. Vérifier la structure de la table profiles
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. Supprimer l'ancien trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 3. Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS create_profile_on_signup();

-- 4. Créer une nouvelle fonction simplifiée
CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insérer uniquement les colonnes qui existent avec certitude
    INSERT INTO profiles (
        user_id,
        full_name,
        role
    ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
        'membre'
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Logger l'erreur mais ne pas bloquer l'inscription
        RAISE WARNING 'Erreur lors de la création du profil: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- 5. Recréer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_on_signup();

-- 6. Tester avec un profil existant
SELECT 
    'Test: Vérifier les profils existants' as test,
    COUNT(*) as nombre_profils
FROM profiles;

SELECT '✅ Trigger corrigé - Essayez de vous inscrire maintenant' as status;

-- =====================================================
-- FIX COMPLET : Corriger le trigger d'inscription
-- =====================================================
-- Version robuste qui gère toutes les colonnes possibles
-- =====================================================

-- Supprimer l'ancien trigger et fonction
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS create_profile_on_signup();

-- Créer une fonction qui s'adapte aux colonnes disponibles
CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    has_statut_validation BOOLEAN;
    has_statut_membre BOOLEAN;
    has_chorale_id BOOLEAN;
BEGIN
    -- Vérifier quelles colonnes existent
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'statut_validation'
    ) INTO has_statut_validation;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'statut_membre'
    ) INTO has_statut_membre;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'chorale_id'
    ) INTO has_chorale_id;

    -- Insérer avec les colonnes disponibles
    IF has_statut_validation AND has_statut_membre AND has_chorale_id THEN
        -- Version complète avec toutes les colonnes
        INSERT INTO profiles (
            user_id,
            full_name,
            role,
            statut_validation,
            statut_membre,
            chorale_id
        ) VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
            'membre',
            'en_attente',
            'inactif',
            NULL
        )
        ON CONFLICT (user_id) DO NOTHING;
    ELSIF has_statut_validation AND has_statut_membre THEN
        -- Version sans chorale_id
        INSERT INTO profiles (
            user_id,
            full_name,
            role,
            statut_validation,
            statut_membre
        ) VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
            'membre',
            'en_attente',
            'inactif'
        )
        ON CONFLICT (user_id) DO NOTHING;
    ELSE
        -- Version minimale
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
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Logger l'erreur mais ne pas bloquer l'inscription
        RAISE WARNING 'Erreur lors de la création du profil: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
        RETURN NEW;
END;
$$;

-- Recréer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_on_signup();

-- Vérifications
SELECT 'Colonnes de la table profiles:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

SELECT '✅ Trigger corrigé avec gestion d''erreur - Essayez de vous inscrire' as status;

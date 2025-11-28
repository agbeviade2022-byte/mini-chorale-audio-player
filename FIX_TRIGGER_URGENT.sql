-- =====================================================
-- FIX URGENT : Créer trigger inscription
-- =====================================================
-- Erreur: Database error saving new user (500)
-- Cause: Trigger manquant ou défaillant
-- =====================================================

-- ============================================
-- ÉTAPE 1 : Vérifier/Créer la table profiles
-- ============================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    telephone TEXT,
    role TEXT DEFAULT 'membre' CHECK (role IN ('membre', 'admin', 'super_admin')),
    statut_validation TEXT DEFAULT 'en_attente' CHECK (statut_validation IN ('en_attente', 'valide', 'refuse')),
    statut_membre TEXT DEFAULT 'inactif' CHECK (statut_membre IN ('actif', 'inactif', 'suspendu')),
    chorale_id UUID REFERENCES public.chorales(id) ON DELETE SET NULL,
    avatar_url TEXT,
    date_naissance DATE,
    adresse TEXT,
    ville TEXT,
    code_postal TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_chorale_id ON public.profiles(chorale_id);
CREATE INDEX IF NOT EXISTS idx_profiles_statut_validation ON public.profiles(statut_validation);

-- Activer RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

SELECT '✅ Table profiles créée/vérifiée' as status;

-- ============================================
-- ÉTAPE 2 : Créer fonction de validation
-- ============================================

CREATE OR REPLACE FUNCTION public.validate_user_metadata(metadata JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_full_name TEXT;
    v_cleaned_name TEXT;
BEGIN
    -- Récupérer le nom
    v_full_name := metadata->>'full_name';
    
    -- Si NULL ou vide
    IF v_full_name IS NULL OR LENGTH(TRIM(v_full_name)) = 0 THEN
        RETURN jsonb_build_object('full_name', NULL, 'valid', false);
    END IF;
    
    -- Nettoyer
    v_cleaned_name := TRIM(v_full_name);
    
    -- Supprimer HTML
    v_cleaned_name := REGEXP_REPLACE(v_cleaned_name, '<[^>]*>', '', 'g');
    
    -- Supprimer caractères dangereux
    v_cleaned_name := REGEXP_REPLACE(v_cleaned_name, '[<>"''`]', '', 'g');
    
    -- Limiter longueur
    v_cleaned_name := SUBSTRING(v_cleaned_name, 1, 100);
    
    -- Vérifier si encore valide
    IF LENGTH(TRIM(v_cleaned_name)) = 0 THEN
        RETURN jsonb_build_object('full_name', NULL, 'valid', false);
    END IF;
    
    RETURN jsonb_build_object('full_name', v_cleaned_name, 'valid', true);
END;
$$;

SELECT '✅ Fonction validate_user_metadata créée' as status;

-- ============================================
-- ÉTAPE 3 : Créer fonction trigger
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_validated_metadata JSONB;
    v_full_name TEXT;
    v_email_username TEXT;
BEGIN
    -- Valider les métadonnées
    v_validated_metadata := public.validate_user_metadata(NEW.raw_user_meta_data);
    v_full_name := v_validated_metadata->>'full_name';
    
    -- Si pas de nom valide, utiliser email
    IF v_full_name IS NULL THEN
        v_email_username := SPLIT_PART(NEW.email, '@', 1);
        v_full_name := 'Utilisateur_' || SUBSTRING(v_email_username, 1, 20);
    END IF;
    
    -- Créer le profil
    INSERT INTO public.profiles (
        user_id,
        full_name,
        role,
        statut_validation,
        statut_membre,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        v_full_name,
        'membre',
        'en_attente',
        'inactif',
        NEW.created_at,
        NEW.created_at
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Logger l'erreur mais ne pas bloquer l'inscription
    RAISE WARNING 'Erreur création profil pour user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

SELECT '✅ Fonction handle_new_user créée' as status;

-- ============================================
-- ÉTAPE 4 : Créer le trigger
-- ============================================

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Créer le nouveau trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

SELECT '✅ Trigger on_auth_user_created créé' as status;

-- ============================================
-- ÉTAPE 5 : Créer les policies RLS de base
-- ============================================

-- Supprimer anciennes policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile limited" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

-- Policy: Utilisateur peut voir son profil
CREATE POLICY "Users can view own profile"
ON public.profiles
FOR SELECT
USING (user_id = auth.uid());

-- Policy: Utilisateur peut modifier son profil (limité)
CREATE POLICY "Users can update own profile limited"
ON public.profiles
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (
    user_id = auth.uid()
    AND role = (SELECT role FROM public.profiles WHERE user_id = auth.uid())
    AND statut_validation = (SELECT statut_validation FROM public.profiles WHERE user_id = auth.uid())
);

-- Policy: Admins peuvent tout voir
CREATE POLICY "Admins can view all profiles"
ON public.profiles
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'super_admin')
    )
);

SELECT '✅ Policies RLS créées' as status;

-- ============================================
-- ÉTAPE 6 : Vérification finale
-- ============================================

SELECT '📊 VÉRIFICATION FINALE' as info;

-- Vérifier trigger
SELECT 
    '✅ Trigger: ' || trigger_name as verification
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created'
UNION ALL
-- Vérifier fonction
SELECT 
    '✅ Fonction: ' || routine_name as verification
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
UNION ALL
-- Vérifier table
SELECT 
    '✅ Table: ' || table_name as verification
FROM information_schema.tables
WHERE table_name = 'profiles'
AND table_schema = 'public';

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ CORRECTION TERMINÉE ✅✅✅' as resultat;
SELECT 'Vous pouvez maintenant réessayer l''inscription dans Flutter' as action;
SELECT 'Email de test: ofcoursekd@gmail.com' as test;

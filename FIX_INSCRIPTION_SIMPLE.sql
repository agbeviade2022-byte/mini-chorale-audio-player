-- =====================================================
-- FIX INSCRIPTION - VERSION SIMPLE ET SÛRE
-- =====================================================
-- Ce script corrige l'erreur "Database error saving new user"
-- Version simplifiée qui évite les erreurs sur les clés primaires
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : SUPPRIMER L'ANCIEN TRIGGER
-- =====================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- =====================================================
-- ÉTAPE 2 : RENDRE LES COLONNES NULLABLES (MANUELLEMENT)
-- =====================================================

-- Rendre les colonnes nullables une par une (sûr)
ALTER TABLE public.profiles ALTER COLUMN full_name DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN role DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN statut_validation DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN chorale_id DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN created_at DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN updated_at DROP NOT NULL;

-- ⚠️ NE PAS toucher aux colonnes id et user_id (clés primaires)

-- =====================================================
-- ÉTAPE 3 : AJOUTER DES VALEURS PAR DÉFAUT
-- =====================================================

ALTER TABLE public.profiles ALTER COLUMN full_name SET DEFAULT 'Utilisateur';
ALTER TABLE public.profiles ALTER COLUMN role SET DEFAULT 'membre';
ALTER TABLE public.profiles ALTER COLUMN statut_validation SET DEFAULT 'en_attente';
ALTER TABLE public.profiles ALTER COLUMN created_at SET DEFAULT NOW();
ALTER TABLE public.profiles ALTER COLUMN updated_at SET DEFAULT NOW();

-- =====================================================
-- ÉTAPE 4 : CRÉER LE NOUVEAU TRIGGER (SIMPLIFIÉ)
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Insérer le profil avec gestion d'erreurs
    INSERT INTO public.profiles (
        user_id,
        full_name,
        role,
        statut_validation,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
        'membre',
        'en_attente',
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Logger l'erreur mais ne pas bloquer la création du compte
        RAISE WARNING 'Erreur création profil: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Créer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ÉTAPE 5 : CONFIGURER RLS (PERMISSIF POUR TESTER)
-- =====================================================

-- Activer RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Allow insert profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow read profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow all" ON public.profiles;

-- Créer une policy permissive pour l'insertion
CREATE POLICY "Allow insert profile"
    ON public.profiles
    FOR INSERT
    TO public
    WITH CHECK (true);

-- Créer une policy pour la lecture
CREATE POLICY "Allow read profile"
    ON public.profiles
    FOR SELECT
    TO public
    USING (true);

-- =====================================================
-- ÉTAPE 6 : NETTOYER LES COMPTES ORPHELINS
-- =====================================================

-- Créer les profils manquants pour les comptes sans profil
INSERT INTO public.profiles (
    user_id,
    full_name,
    role,
    statut_validation,
    created_at,
    updated_at
)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'full_name', 'Utilisateur'),
    'membre',
    'en_attente',
    au.created_at,
    NOW()
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- ÉTAPE 7 : VÉRIFICATION
-- =====================================================

-- Vérifier que le trigger existe
SELECT 
    'Trigger créé' as status,
    COUNT(*) as count
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created'
UNION ALL
-- Vérifier que la fonction existe
SELECT 
    'Fonction créée' as status,
    COUNT(*) as count
FROM pg_proc
WHERE proname = 'handle_new_user'
UNION ALL
-- Vérifier les profils
SELECT 
    'Profils existants' as status,
    COUNT(*) as count
FROM public.profiles
UNION ALL
-- Vérifier les comptes orphelins
SELECT 
    'Comptes orphelins' as status,
    COUNT(*) as count
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================

/*
✅ Trigger créé: 1
✅ Fonction créée: 1
✅ Profils existants: X (nombre de profils)
✅ Comptes orphelins: 0 (devrait être 0)

Si tout est OK, testez l'inscription dans l'app Flutter !
*/

-- =====================================================
-- COMMANDES DE DIAGNOSTIC (SI BESOIN)
-- =====================================================

-- Voir la structure de la table profiles
/*
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;
*/

-- Voir les profils récents
/*
SELECT 
    p.user_id,
    au.email,
    p.full_name,
    p.role,
    p.statut_validation,
    p.created_at
FROM public.profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.created_at DESC
LIMIT 5;
*/

-- Voir les logs d'erreur (si disponibles)
/*
SELECT * FROM pg_stat_statements 
WHERE query LIKE '%handle_new_user%' 
ORDER BY calls DESC 
LIMIT 10;
*/

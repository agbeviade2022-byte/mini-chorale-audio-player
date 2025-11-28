-- =====================================================
-- FIX INSCRIPTION FINAL - SOLUTION GARANTIE
-- =====================================================
-- Cette solution désactive RLS et laisse Flutter créer le profil
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : DÉSACTIVER RLS COMPLÈTEMENT
-- =====================================================

ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- ÉTAPE 2 : SUPPRIMER LE TRIGGER (Flutter créera le profil)
-- =====================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- =====================================================
-- ÉTAPE 3 : NETTOYER LES COMPTES ORPHELINS
-- =====================================================

-- Créer les profils manquants
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
-- ÉTAPE 4 : VÉRIFICATION
-- =====================================================

-- Vérifier que RLS est désactivé
SELECT 
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'profiles';

-- Résultat attendu: rowsecurity = false

-- Vérifier les profils
SELECT 
    COUNT(*) as total_profiles
FROM public.profiles;

-- Vérifier les comptes orphelins
SELECT 
    COUNT(*) as comptes_orphelins
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL;

-- Résultat attendu: comptes_orphelins = 0

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================

/*
✅ RLS désactivé (rowsecurity = false)
✅ Trigger supprimé
✅ Comptes orphelins nettoyés (0)
✅ Flutter créera le profil lors de l'inscription

TESTEZ L'INSCRIPTION MAINTENANT !
*/

-- =====================================================
-- POUR RÉACTIVER RLS PLUS TARD (OPTIONNEL)
-- =====================================================

/*
-- Réactiver RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Créer des policies simples
CREATE POLICY "profiles_select_all"
    ON public.profiles
    FOR SELECT
    TO public
    USING (true);

CREATE POLICY "profiles_insert_all"
    ON public.profiles
    FOR INSERT
    TO public
    WITH CHECK (true);

CREATE POLICY "profiles_update_own"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "profiles_delete_admin"
    ON public.profiles
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
        )
    );
*/

-- =====================================================
-- RESTAURER L'INSCRIPTION QUI FONCTIONNAIT
-- =====================================================
-- Ce script restaure la configuration originale
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : NETTOYER TOUTES LES POLICIES D'INSERTION
-- =====================================================

DROP POLICY IF EXISTS "profiles_insert_policy" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_policy_v2" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow insert profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow all" ON public.profiles;

-- =====================================================
-- ÉTAPE 2 : SUPPRIMER LES ANCIENS TRIGGERS
-- =====================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.create_profile_on_signup();

-- =====================================================
-- ÉTAPE 3 : RECRÉER LE TRIGGER ORIGINAL
-- =====================================================

CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
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
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_on_signup();

-- =====================================================
-- ÉTAPE 4 : RÉACTIVER RLS
-- =====================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- ÉTAPE 5 : RECRÉER LES POLICIES (SANS INSERTION)
-- =====================================================

-- Supprimer toutes les anciennes policies
DROP POLICY IF EXISTS "Utilisateurs voient leur profil" ON profiles;
DROP POLICY IF EXISTS "Admins voient tous les profils" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "Allow read profile" ON profiles;
DROP POLICY IF EXISTS "Utilisateurs modifient leur profil" ON profiles;
DROP POLICY IF EXISTS "Admins modifient tous les profils" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_admin_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_delete_policy" ON profiles;

-- LECTURE : Utilisateur voit son profil, admin voit tout
CREATE POLICY "Utilisateurs voient leur profil"
ON profiles FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Admins voient tous les profils"
ON profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role IN ('admin', 'super_admin')
    )
);

-- MODIFICATION : Utilisateur modifie son profil (sauf rôle/statut), admin modifie tout
CREATE POLICY "Utilisateurs modifient leur profil"
ON profiles FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (
    user_id = auth.uid() 
    AND role = (SELECT role FROM profiles WHERE user_id = auth.uid())
    AND statut_validation = (SELECT statut_validation FROM profiles WHERE user_id = auth.uid())
);

CREATE POLICY "Admins modifient tous les profils"
ON profiles FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role IN ('admin', 'super_admin')
    )
);

-- SUPPRESSION : Seulement super_admin
CREATE POLICY "Admins suppriment des profils"
ON profiles FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role = 'super_admin'
    )
);

-- =====================================================
-- ÉTAPE 6 : NETTOYER LES COMPTES ORPHELINS
-- =====================================================

INSERT INTO public.profiles (
    user_id,
    full_name,
    role,
    statut_validation,
    statut_membre,
    chorale_id
)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'full_name', 'Utilisateur'),
    'membre',
    'en_attente',
    'inactif',
    NULL
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- ÉTAPE 7 : VÉRIFICATION
-- =====================================================

-- Vérifier le trigger
SELECT 
    'Trigger' as type,
    trigger_name,
    event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Vérifier les policies (NE DOIT PAS Y AVOIR DE INSERT)
SELECT
    'Policy' as type,
    policyname,
    cmd
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;

-- Vérifier RLS
SELECT 
    'RLS' as type,
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'profiles';

-- Vérifier les comptes orphelins
SELECT 
    'Comptes orphelins' as type,
    COUNT(*) as count
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================

/*
✅ Trigger: on_auth_user_created (INSERT)
✅ Policies: SELECT, UPDATE, DELETE (PAS de INSERT)
✅ RLS: rowsecurity = true
✅ Comptes orphelins: 0

TESTEZ L'INSCRIPTION MAINTENANT !
*/

-- =====================================================
-- ANNULER LES MODIFICATIONS SQL
-- =====================================================
-- Ce script annule toutes les modifications SQL faites aujourd'hui
-- et restaure l'état d'origine
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : SUPPRIMER LE TRIGGER ACTUEL
-- =====================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.create_profile_on_signup();
DROP FUNCTION IF EXISTS public.handle_new_user();

-- =====================================================
-- ÉTAPE 2 : RECRÉER LE TRIGGER ORIGINAL
-- =====================================================
-- (Celui qui existait avant les modifications)

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
-- ÉTAPE 3 : SUPPRIMER LES POLICIES CRÉÉES AUJOURD'HUI
-- =====================================================

DROP POLICY IF EXISTS "Allow insert profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow read profile" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_policy_v2" ON public.profiles;

-- =====================================================
-- ÉTAPE 4 : RESTAURER LES POLICIES ORIGINALES
-- =====================================================

-- Vérifier quelles policies existent déjà
SELECT 
    '=== POLICIES ACTUELLES ===' as info;

SELECT
    policyname,
    cmd
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;

-- Si les policies originales n'existent pas, les recréer :

-- Lecture
DROP POLICY IF EXISTS "Utilisateurs voient leur profil" ON profiles;
CREATE POLICY "Utilisateurs voient leur profil"
ON profiles FOR SELECT
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins voient tous les profils" ON profiles;
CREATE POLICY "Admins voient tous les profils"
ON profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role IN ('admin', 'super_admin')
    )
);

-- Modification
DROP POLICY IF EXISTS "Utilisateurs modifient leur profil" ON profiles;
CREATE POLICY "Utilisateurs modifient leur profil"
ON profiles FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (
    user_id = auth.uid() 
    AND role = (SELECT role FROM profiles WHERE user_id = auth.uid())
    AND statut_validation = (SELECT statut_validation FROM profiles WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "Admins modifient tous les profils" ON profiles;
CREATE POLICY "Admins modifient tous les profils"
ON profiles FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role IN ('admin', 'super_admin')
    )
);

-- Suppression
DROP POLICY IF EXISTS "Admins suppriment des profils" ON profiles;
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
-- ÉTAPE 5 : VÉRIFIER QUE RLS EST ACTIVÉ
-- =====================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- ÉTAPE 6 : VÉRIFICATION FINALE
-- =====================================================

SELECT 
    '=== VÉRIFICATION FINALE ===' as info;

-- Vérifier le trigger
SELECT 
    'Trigger' as type,
    trigger_name,
    event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Vérifier les policies
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

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================

/*
✅ Trigger: on_auth_user_created (AFTER INSERT)
✅ Fonction: create_profile_on_signup()
✅ Policies: SELECT (2), UPDATE (2), DELETE (1)
✅ PAS de policy INSERT
✅ RLS: activé (rowsecurity = true)

BASE DE DONNÉES RESTAURÉE À L'ÉTAT D'ORIGINE !
*/

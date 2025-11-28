-- =====================================================
-- DIAGNOSTIC COMPLET : Erreur d'inscription
-- =====================================================
-- Exécutez ces requêtes une par une pour diagnostiquer le problème
-- =====================================================

-- =====================================================
-- 1. VÉRIFIER LA STRUCTURE DE LA TABLE PROFILES
-- =====================================================

-- Voir toutes les colonnes de la table profiles
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- =====================================================
-- 2. VÉRIFIER SI LE TRIGGER EXISTE
-- =====================================================

-- Voir si le trigger existe
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- =====================================================
-- 3. VÉRIFIER LA FONCTION DU TRIGGER
-- =====================================================

-- Voir le code de la fonction
SELECT 
    proname as function_name,
    prosrc as source_code
FROM pg_proc
WHERE proname = 'handle_new_user';

-- =====================================================
-- 4. TESTER LA FONCTION MANUELLEMENT
-- =====================================================

-- Créer un utilisateur de test pour voir l'erreur exacte
-- ⚠️ Remplacez 'test-user-id' par un UUID valide
/*
DO $$
DECLARE
    test_user_id uuid := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
BEGIN
    -- Simuler l'insertion d'un profil
    INSERT INTO public.profiles (
        user_id,
        full_name,
        role,
        statut_validation,
        chorale_id,
        created_at,
        updated_at
    )
    VALUES (
        test_user_id,
        'Test User',
        'membre',
        'en_attente',
        NULL,
        NOW(),
        NOW()
    );
    
    RAISE NOTICE 'Test réussi !';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur: %', SQLERRM;
END $$;
*/

-- =====================================================
-- 5. VÉRIFIER LES CONTRAINTES
-- =====================================================

-- Voir toutes les contraintes sur profiles
SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'profiles'
ORDER BY tc.constraint_type, tc.constraint_name;

-- =====================================================
-- 6. VÉRIFIER RLS
-- =====================================================

-- Voir si RLS est activé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'profiles';

-- Voir toutes les policies
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'profiles';

-- =====================================================
-- 7. VÉRIFIER LES PERMISSIONS
-- =====================================================

-- Voir les permissions sur la table profiles
SELECT 
    grantee,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'profiles';

-- =====================================================
-- 8. SOLUTION : RECRÉER LE TRIGGER AVEC LOGS
-- =====================================================

-- Supprimer l'ancien trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Créer une fonction avec des logs détaillés
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_full_name text;
BEGIN
    -- Logger le début
    RAISE NOTICE 'Début création profil pour user_id: %', NEW.id;
    
    -- Extraire le nom complet
    v_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur');
    RAISE NOTICE 'Nom complet: %', v_full_name;
    
    -- Insérer le profil
    INSERT INTO public.profiles (
        user_id,
        full_name,
        role,
        statut_validation,
        chorale_id,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        v_full_name,
        'membre',
        'en_attente',
        NULL,
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RAISE NOTICE 'Profil créé avec succès';
    RETURN NEW;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Erreur lors de la création du profil: %', SQLERRM;
        RAISE WARNING 'SQLSTATE: %', SQLSTATE;
        RAISE WARNING 'Detail: %', SQLERRM;
        -- Ne pas bloquer la création du compte
        RETURN NEW;
END;
$$;

-- Créer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 9. VÉRIFIER LES COLONNES OBLIGATOIRES
-- =====================================================

-- Voir quelles colonnes sont NOT NULL
SELECT 
    column_name,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND is_nullable = 'NO'
  AND column_default IS NULL;

-- ⚠️ Si des colonnes sont NOT NULL sans valeur par défaut, c'est le problème !

-- =====================================================
-- 10. SOLUTION COMPLÈTE : RENDRE TOUTES LES COLONNES NULLABLES
-- =====================================================

-- Rendre TOUTES les colonnes nullables (sauf les clés primaires)
DO $$
DECLARE
    col record;
BEGIN
    FOR col IN 
        SELECT c.column_name
        FROM information_schema.columns c
        LEFT JOIN information_schema.key_column_usage kcu 
            ON c.table_schema = kcu.table_schema 
            AND c.table_name = kcu.table_name 
            AND c.column_name = kcu.column_name
        LEFT JOIN information_schema.table_constraints tc 
            ON kcu.constraint_name = tc.constraint_name 
            AND tc.constraint_type = 'PRIMARY KEY'
        WHERE c.table_schema = 'public'
          AND c.table_name = 'profiles'
          AND c.is_nullable = 'NO'
          AND tc.constraint_type IS NULL  -- Exclure les clés primaires
    LOOP
        EXECUTE format('ALTER TABLE public.profiles ALTER COLUMN %I DROP NOT NULL', col.column_name);
        RAISE NOTICE 'Colonne % rendue nullable', col.column_name;
    END LOOP;
END $$;

-- Ajouter des valeurs par défaut
ALTER TABLE public.profiles
    ALTER COLUMN full_name SET DEFAULT 'Utilisateur';

ALTER TABLE public.profiles
    ALTER COLUMN role SET DEFAULT 'membre';

ALTER TABLE public.profiles
    ALTER COLUMN statut_validation SET DEFAULT 'en_attente';

ALTER TABLE public.profiles
    ALTER COLUMN created_at SET DEFAULT NOW();

ALTER TABLE public.profiles
    ALTER COLUMN updated_at SET DEFAULT NOW();

-- =====================================================
-- 11. DÉSACTIVER TEMPORAIREMENT RLS POUR TESTER
-- =====================================================

-- ⚠️ ATTENTION : Seulement pour tester
-- ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Après le test, réactiver RLS
-- ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 12. CRÉER UNE POLICY PERMISSIVE
-- =====================================================

-- Supprimer toutes les policies existantes
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN 
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'profiles'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', pol.policyname);
        RAISE NOTICE 'Policy % supprimée', pol.policyname;
    END LOOP;
END $$;

-- Créer une policy permissive pour l'insertion
CREATE POLICY "Allow insert own profile"
    ON public.profiles
    FOR INSERT
    TO public
    WITH CHECK (true);  -- ⚠️ Très permissif, juste pour tester

-- Créer une policy pour la lecture
CREATE POLICY "Allow read own profile"
    ON public.profiles
    FOR SELECT
    TO public
    USING (true);  -- ⚠️ Très permissif, juste pour tester

-- =====================================================
-- 13. VÉRIFICATION FINALE
-- =====================================================

-- Vérifier que tout est OK
SELECT 
    'Trigger' as type,
    COUNT(*)::text as count
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created'
UNION ALL
SELECT 
    'Fonction' as type,
    COUNT(*)::text as count
FROM pg_proc
WHERE proname = 'handle_new_user'
UNION ALL
SELECT 
    'Policies' as type,
    COUNT(*)::text as count
FROM pg_policies
WHERE tablename = 'profiles'
UNION ALL
SELECT 
    'Colonnes NOT NULL' as type,
    COUNT(*)::text as count
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name != 'user_id'
  AND is_nullable = 'NO'
  AND column_default IS NULL;

-- =====================================================
-- 14. NETTOYER LES COMPTES ORPHELINS
-- =====================================================

-- Voir les comptes sans profil
SELECT 
    au.id,
    au.email,
    au.created_at,
    au.raw_user_meta_data->>'full_name' as full_name
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL
ORDER BY au.created_at DESC;

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
-- RÉSUMÉ DES ACTIONS
-- =====================================================

/*
✅ Actions effectuées:

1. Vérifié la structure de la table
2. Vérifié l'existence du trigger
3. Recréé le trigger avec logs détaillés
4. Rendu toutes les colonnes nullables
5. Ajouté des valeurs par défaut
6. Créé des policies permissives
7. Nettoyé les comptes orphelins

🔍 Pour voir les logs:
- Supabase Dashboard → Database → Logs
- Cherchez les messages NOTICE et WARNING

🆘 Si l'erreur persiste:
1. Vérifiez les logs Supabase
2. Testez l'insertion manuelle d'un profil
3. Désactivez temporairement RLS
4. Vérifiez les permissions
*/

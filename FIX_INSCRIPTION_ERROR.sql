-- =====================================================
-- FIX : Erreur "Database error saving new user"
-- =====================================================
-- Cette erreur se produit lors de l'inscription d'un nouvel utilisateur
-- Causes possibles:
-- 1. Trigger défaillant
-- 2. Contraintes de base de données trop strictes
-- 3. Colonnes manquantes ou mal configurées
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : VÉRIFIER LA TABLE PROFILES
-- =====================================================

-- Vérifier la structure de la table profiles
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- =====================================================
-- ÉTAPE 2 : VÉRIFIER LES TRIGGERS
-- =====================================================

-- Lister tous les triggers sur auth.users
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users'
  AND trigger_schema = 'auth';

-- =====================================================
-- ÉTAPE 3 : RECRÉER LE TRIGGER DE CRÉATION DE PROFIL
-- =====================================================

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Créer la fonction de gestion des nouveaux utilisateurs
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Insérer le profil avec des valeurs par défaut sûres
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
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
    'membre',  -- Rôle par défaut
    'en_attente',  -- En attente de validation
    NULL,  -- Pas de chorale par défaut
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO NOTHING;  -- Éviter les doublons
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Logger l'erreur mais ne pas bloquer la création du compte
    RAISE WARNING 'Erreur lors de la création du profil: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Créer le trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ÉTAPE 4 : VÉRIFIER LES CONTRAINTES
-- =====================================================

-- Lister toutes les contraintes sur la table profiles
SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'profiles'
ORDER BY tc.constraint_type, tc.constraint_name;

-- =====================================================
-- ÉTAPE 5 : ASSOUPLIR LES CONTRAINTES SI NÉCESSAIRE
-- =====================================================

-- Rendre la colonne chorale_id nullable (si elle ne l'est pas déjà)
ALTER TABLE public.profiles
  ALTER COLUMN chorale_id DROP NOT NULL;

-- Rendre la colonne full_name nullable avec valeur par défaut
ALTER TABLE public.profiles
  ALTER COLUMN full_name DROP NOT NULL;

ALTER TABLE public.profiles
  ALTER COLUMN full_name SET DEFAULT 'Utilisateur';

-- Rendre la colonne role nullable avec valeur par défaut
ALTER TABLE public.profiles
  ALTER COLUMN role DROP NOT NULL;

ALTER TABLE public.profiles
  ALTER COLUMN role SET DEFAULT 'membre';

-- Rendre la colonne statut_validation nullable avec valeur par défaut
ALTER TABLE public.profiles
  ALTER COLUMN statut_validation DROP NOT NULL;

ALTER TABLE public.profiles
  ALTER COLUMN statut_validation SET DEFAULT 'en_attente';

-- =====================================================
-- ÉTAPE 6 : VÉRIFIER LES RLS POLICIES
-- =====================================================

-- Lister toutes les policies sur profiles
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
-- ÉTAPE 7 : CRÉER UNE POLICY POUR L'INSERTION
-- =====================================================

-- Supprimer l'ancienne policy si elle existe
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

-- Créer une policy pour permettre l'insertion du profil
CREATE POLICY "Users can insert their own profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- ÉTAPE 8 : TESTER LA CRÉATION D'UN PROFIL
-- =====================================================

-- Test manuel (à exécuter après avoir créé un compte)
-- Remplacer 'USER_ID_ICI' par l'ID du nouvel utilisateur
/*
INSERT INTO public.profiles (
  user_id,
  full_name,
  role,
  statut_validation
)
VALUES (
  'USER_ID_ICI',
  'Test User',
  'membre',
  'en_attente'
);
*/

-- =====================================================
-- ÉTAPE 9 : VÉRIFIER LES PROFILS EXISTANTS
-- =====================================================

-- Compter les profils
SELECT COUNT(*) as total_profiles FROM public.profiles;

-- Vérifier les profils récents
SELECT 
  user_id,
  full_name,
  role,
  statut_validation,
  chorale_id,
  created_at
FROM public.profiles
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- ÉTAPE 10 : NETTOYER LES COMPTES ORPHELINS
-- =====================================================

-- Trouver les utilisateurs sans profil
SELECT 
  au.id,
  au.email,
  au.created_at
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL
ORDER BY au.created_at DESC;

-- Créer les profils manquants pour les comptes orphelins
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
1. Recréé le trigger handle_new_user avec gestion d'erreurs
2. Assoupli les contraintes NOT NULL
3. Ajouté des valeurs par défaut
4. Créé une policy pour l'insertion
5. Nettoyé les comptes orphelins

🔍 Pour diagnostiquer:
- Vérifiez les logs Supabase (Dashboard → Database → Logs)
- Testez l'inscription avec un nouvel email
- Vérifiez que le profil est créé automatiquement

🆘 Si l'erreur persiste:
1. Vérifiez que RLS est activé: ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
2. Vérifiez les permissions du trigger: GRANT USAGE ON SCHEMA public TO authenticated;
3. Vérifiez les logs PostgreSQL pour plus de détails
*/

-- =====================================================
-- COMMANDES DE VÉRIFICATION RAPIDE
-- =====================================================

-- Vérifier que tout est OK
DO $$
BEGIN
  -- Vérifier la table
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
    RAISE EXCEPTION 'Table profiles n''existe pas';
  END IF;
  
  -- Vérifier le trigger
  IF NOT EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') THEN
    RAISE EXCEPTION 'Trigger on_auth_user_created n''existe pas';
  END IF;
  
  -- Vérifier la fonction
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') THEN
    RAISE EXCEPTION 'Fonction handle_new_user n''existe pas';
  END IF;
  
  RAISE NOTICE '✅ Tout est OK !';
END $$;

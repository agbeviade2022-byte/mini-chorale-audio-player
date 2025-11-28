# ✅ FIX RAPIDE : Erreur d'inscription

## 🎯 PROBLÈME

```
Database error saving new user (erreur 500)
```

## ✅ SOLUTION RAPIDE

### **Exécutez ce script SQL dans Supabase :**

```sql
-- 1. Supprimer l'ancien trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. Créer le nouveau trigger (SANS la colonne email)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
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
    'membre',
    'en_attente',
    NULL,
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Erreur: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- 3. Créer le trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 4. Assouplir les contraintes
ALTER TABLE public.profiles
  ALTER COLUMN chorale_id DROP NOT NULL;

ALTER TABLE public.profiles
  ALTER COLUMN full_name DROP NOT NULL;

ALTER TABLE public.profiles
  ALTER COLUMN full_name SET DEFAULT 'Utilisateur';

ALTER TABLE public.profiles
  ALTER COLUMN role SET DEFAULT 'membre';

ALTER TABLE public.profiles
  ALTER COLUMN statut_validation SET DEFAULT 'en_attente';

-- 5. Créer la policy d'insertion
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

CREATE POLICY "Users can insert their own profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 6. Nettoyer les comptes orphelins
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

-- 7. Vérifier que tout est OK
SELECT 
  'Trigger créé' as status,
  COUNT(*) as count
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created'
UNION ALL
SELECT 
  'Profils créés' as status,
  COUNT(*) as count
FROM public.profiles;
```

---

## 🚀 APRÈS AVOIR EXÉCUTÉ LE SCRIPT

```
1. Ouvrez l'app Flutter
2. Testez l'inscription
3. ✅ Devrait fonctionner !
```

---

## 🔍 VÉRIFICATION

```sql
-- Vérifier les profils récents
SELECT 
  user_id,
  full_name,
  role,
  statut_validation,
  created_at
FROM public.profiles
ORDER BY created_at DESC
LIMIT 5;
```

---

## ⚠️ NOTE IMPORTANTE

**La table `profiles` n'a PAS de colonne `email`.**

L'email est stocké dans `auth.users`, pas dans `profiles`.

Pour récupérer l'email d'un utilisateur :

```sql
SELECT 
  p.user_id,
  au.email,  -- Email depuis auth.users
  p.full_name,
  p.role
FROM public.profiles p
LEFT JOIN auth.users au ON p.user_id = au.id;
```

---

**EXÉCUTEZ LE SCRIPT ET TESTEZ ! 🚀**

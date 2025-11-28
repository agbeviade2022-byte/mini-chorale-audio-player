# 🆘 GUIDE DE DÉPANNAGE : Erreur d'inscription

## 🎯 PROBLÈME

```
Database error saving new user (erreur 500)
```

L'erreur persiste même après avoir exécuté les scripts de fix.

---

## 🔍 ÉTAPE 1 : VÉRIFIER LES LOGS SUPABASE

### **Accéder aux logs :**

```
1. Ouvrez Supabase Dashboard
2. Cliquez sur votre projet
3. Database → Logs
4. Filtrez par "error" ou "warning"
5. Cherchez les logs récents lors de l'inscription
```

### **Ce qu'il faut chercher :**

```
- "Erreur lors de la création du profil"
- "column does not exist"
- "violates not-null constraint"
- "violates foreign key constraint"
- "permission denied"
```

---

## 🔧 ÉTAPE 2 : EXÉCUTER LE DIAGNOSTIC

### **Ouvrez Supabase SQL Editor et exécutez :**

```sql
-- Voir la structure de la table profiles
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;
```

### **Vérifiez :**

```
✅ Toutes les colonnes (sauf user_id) doivent être nullable (is_nullable = 'YES')
✅ Les colonnes importantes doivent avoir des valeurs par défaut
```

### **Si des colonnes sont NOT NULL sans défaut :**

```sql
-- Rendre toutes les colonnes nullables
ALTER TABLE public.profiles ALTER COLUMN full_name DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN role DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN statut_validation DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN chorale_id DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN created_at DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN updated_at DROP NOT NULL;
```

---

## 🔧 ÉTAPE 3 : VÉRIFIER LE TRIGGER

### **Vérifier si le trigger existe :**

```sql
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
```

### **Si le trigger n'existe pas :**

```sql
-- Créer le trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.profiles (
        user_id,
        full_name,
        role,
        statut_validation
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
        'membre',
        'en_attente'
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Erreur: %', SQLERRM;
        RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
```

---

## 🔧 ÉTAPE 4 : VÉRIFIER RLS

### **Vérifier si RLS est activé :**

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'profiles';
```

### **Voir les policies :**

```sql
SELECT policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'profiles';
```

### **Solution temporaire (POUR TESTER UNIQUEMENT) :**

```sql
-- Désactiver RLS temporairement
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Testez l'inscription

-- Réactiver RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
```

### **Si ça fonctionne sans RLS, créez une policy permissive :**

```sql
-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

-- Créer une policy permissive
CREATE POLICY "Allow insert profile"
    ON public.profiles
    FOR INSERT
    TO public
    WITH CHECK (true);
```

---

## 🔧 ÉTAPE 5 : TESTER L'INSERTION MANUELLE

### **Testez si vous pouvez insérer un profil manuellement :**

```sql
-- Générer un UUID de test
SELECT gen_random_uuid() as test_id;

-- Copier l'UUID et l'utiliser ci-dessous
INSERT INTO public.profiles (
    user_id,
    full_name,
    role,
    statut_validation
)
VALUES (
    'VOTRE_UUID_ICI',  -- Remplacer par l'UUID généré
    'Test User',
    'membre',
    'en_attente'
);
```

### **Si l'insertion échoue :**

```
❌ Notez l'erreur exacte
❌ C'est le problème à résoudre
```

---

## 🔧 ÉTAPE 6 : SOLUTION RADICALE

### **Si rien ne fonctionne, exécutez ce script complet :**

```sql
-- 1. Désactiver RLS temporairement
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer le trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Rendre toutes les colonnes nullables (sauf les clés primaires)
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
          AND tc.constraint_type IS NULL
    LOOP
        EXECUTE format('ALTER TABLE public.profiles ALTER COLUMN %I DROP NOT NULL', col.column_name);
    END LOOP;
END $$;

-- 4. Ajouter des valeurs par défaut
ALTER TABLE public.profiles ALTER COLUMN full_name SET DEFAULT 'Utilisateur';
ALTER TABLE public.profiles ALTER COLUMN role SET DEFAULT 'membre';
ALTER TABLE public.profiles ALTER COLUMN statut_validation SET DEFAULT 'en_attente';
ALTER TABLE public.profiles ALTER COLUMN created_at SET DEFAULT NOW();
ALTER TABLE public.profiles ALTER COLUMN updated_at SET DEFAULT NOW();

-- 5. Recréer le trigger simplifié
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.profiles (user_id, full_name, role, statut_validation)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
        'membre',
        'en_attente'
    )
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 6. Réactiver RLS avec policy permissive
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all" ON public.profiles;
CREATE POLICY "Allow all"
    ON public.profiles
    FOR ALL
    TO public
    USING (true)
    WITH CHECK (true);

-- 7. Nettoyer les comptes orphelins
INSERT INTO public.profiles (user_id, full_name, role, statut_validation)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'full_name', 'Utilisateur'),
    'membre',
    'en_attente'
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL
ON CONFLICT (user_id) DO NOTHING;
```

---

## 🚀 ÉTAPE 7 : TESTER L'INSCRIPTION

```
1. Ouvrez l'app Flutter
2. Allez sur l'écran d'inscription
3. Remplissez le formulaire avec un NOUVEL email
4. Cliquez sur "S'inscrire"
5. Vérifiez les logs Supabase
```

---

## 🔍 ÉTAPE 8 : VÉRIFIER QUE LE PROFIL EST CRÉÉ

```sql
-- Voir les profils récents
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
```

---

## 🆘 CAUSES FRÉQUENTES

### **1. Colonne NOT NULL sans valeur par défaut**

```sql
-- Solution
ALTER TABLE public.profiles ALTER COLUMN nom_colonne DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN nom_colonne SET DEFAULT 'valeur';
```

### **2. RLS trop restrictif**

```sql
-- Solution temporaire
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
```

### **3. Trigger qui échoue silencieusement**

```sql
-- Solution : Ajouter des logs
RAISE WARNING 'Erreur: %', SQLERRM;
```

### **4. Contrainte de clé étrangère**

```sql
-- Voir les contraintes
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'profiles';

-- Supprimer une contrainte problématique
ALTER TABLE public.profiles DROP CONSTRAINT nom_contrainte;
```

### **5. Permissions insuffisantes**

```sql
-- Donner toutes les permissions
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO anon;
GRANT ALL ON public.profiles TO service_role;
```

---

## 📊 CHECKLIST DE VÉRIFICATION

```
☐ Les logs Supabase montrent l'erreur exacte
☐ Toutes les colonnes (sauf user_id) sont nullables
☐ Les colonnes importantes ont des valeurs par défaut
☐ Le trigger existe et fonctionne
☐ RLS est configuré correctement
☐ Les policies permettent l'insertion
☐ L'insertion manuelle fonctionne
☐ Les comptes orphelins sont nettoyés
☐ L'inscription fonctionne dans l'app
☐ Le profil est créé automatiquement
```

---

## 🎯 RÉSUMÉ

### **Problème le plus fréquent :**

```
❌ Colonne NOT NULL sans valeur par défaut
❌ RLS trop restrictif
❌ Trigger qui échoue
```

### **Solution la plus efficace :**

```
✅ Rendre toutes les colonnes nullables
✅ Ajouter des valeurs par défaut
✅ Créer une policy permissive
✅ Ajouter des logs dans le trigger
```

---

## 📋 FICHIERS UTILES

1. **DIAGNOSTIC_INSCRIPTION.sql**
   - Script complet de diagnostic
   
2. **FIX_INSCRIPTION_ERROR.sql**
   - Script de correction
   
3. **FIX_INSCRIPTION_RAPIDE.md**
   - Solution rapide

---

**SUIVEZ LES ÉTAPES UNE PAR UNE ! 🚀**

**L'une d'elles résoudra le problème ! ✅**

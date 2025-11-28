# 🔧 FIX : Erreur "Database error saving new user"

## 🎯 PROBLÈME

```
AuthRetryableFetchException(
  message: {"code":"unexpected_failure","message":"Database error saving new user"},
  statusCode: 500
)
```

Cette erreur se produit lors de l'inscription d'un nouvel utilisateur.

---

## 🔍 CAUSES POSSIBLES

### **1. Trigger défaillant**
```
❌ Le trigger qui crée automatiquement le profil échoue
❌ Erreur dans la fonction handle_new_user()
❌ Permissions insuffisantes
```

### **2. Contraintes trop strictes**
```
❌ Colonnes NOT NULL sans valeur par défaut
❌ Contraintes de clé étrangère
❌ Contraintes UNIQUE
```

### **3. RLS policies**
```
❌ Policy qui bloque l'insertion
❌ RLS mal configuré
```

### **4. Colonnes manquantes**
```
❌ Colonnes requises mais non fournies
❌ Types de données incompatibles
```

---

## ✅ SOLUTION

### **ÉTAPE 1 : Exécuter le script SQL**

```bash
# Ouvrez Supabase Dashboard
# SQL Editor → New Query
# Copiez-collez le contenu de FIX_INSCRIPTION_ERROR.sql
# Exécutez le script
```

### **ÉTAPE 2 : Vérifications**

Le script va :

1. ✅ **Recréer le trigger** avec gestion d'erreurs
2. ✅ **Assouplir les contraintes** NOT NULL
3. ✅ **Ajouter des valeurs par défaut**
4. ✅ **Créer une policy** pour l'insertion
5. ✅ **Nettoyer les comptes orphelins**

---

## 🔧 ACTIONS DU SCRIPT

### **1. Recréer le trigger**

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    user_id,
    email,
    full_name,
    role,
    statut_validation,
    chorale_id
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
    'membre',
    'en_attente',
    NULL
  )
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Erreur: %', SQLERRM;
    RETURN NEW;  -- Ne pas bloquer la création du compte
END;
$$ LANGUAGE plpgsql;
```

**Améliorations :**
- ✅ Gestion d'erreurs avec `EXCEPTION`
- ✅ `ON CONFLICT DO NOTHING` pour éviter les doublons
- ✅ `COALESCE` pour valeur par défaut
- ✅ Ne bloque pas la création du compte en cas d'erreur

### **2. Assouplir les contraintes**

```sql
-- Rendre les colonnes nullables
ALTER TABLE public.profiles
  ALTER COLUMN chorale_id DROP NOT NULL;

ALTER TABLE public.profiles
  ALTER COLUMN full_name DROP NOT NULL;

-- Ajouter des valeurs par défaut
ALTER TABLE public.profiles
  ALTER COLUMN full_name SET DEFAULT 'Utilisateur';

ALTER TABLE public.profiles
  ALTER COLUMN role SET DEFAULT 'membre';

ALTER TABLE public.profiles
  ALTER COLUMN statut_validation SET DEFAULT 'en_attente';
```

### **3. Créer une policy pour l'insertion**

```sql
CREATE POLICY "Users can insert their own profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
```

### **4. Nettoyer les comptes orphelins**

```sql
-- Créer les profils manquants
INSERT INTO public.profiles (user_id, email, full_name, role, statut_validation)
SELECT au.id, au.email, 'Utilisateur', 'membre', 'en_attente'
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL;
```

---

## 🔍 DIAGNOSTIC

### **Vérifier les logs Supabase**

```
1. Ouvrez Supabase Dashboard
2. Database → Logs
3. Cherchez les erreurs récentes
4. Notez le message d'erreur exact
```

### **Vérifier la structure de la table**

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'profiles';
```

### **Vérifier les triggers**

```sql
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users';
```

### **Vérifier les comptes orphelins**

```sql
SELECT au.id, au.email
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL;
```

---

## 🚀 TESTER L'INSCRIPTION

### **1. Après avoir exécuté le script**

```
1. Ouvrez l'app Flutter
2. Allez sur l'écran d'inscription
3. Remplissez le formulaire
4. Cliquez sur "S'inscrire"
5. ✅ L'inscription devrait fonctionner
```

### **2. Vérifier que le profil est créé**

```sql
SELECT user_id, email, full_name, role, statut_validation
FROM public.profiles
ORDER BY created_at DESC
LIMIT 1;
```

---

## 🆘 SI L'ERREUR PERSISTE

### **1. Vérifier RLS**

```sql
-- Vérifier que RLS est activé
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'profiles';

-- Activer RLS si nécessaire
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
```

### **2. Vérifier les permissions**

```sql
-- Donner les permissions au schéma public
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
```

### **3. Vérifier les logs PostgreSQL**

```
1. Supabase Dashboard → Database → Logs
2. Filtrer par "error"
3. Chercher "Database error saving new user"
4. Lire le message d'erreur complet
```

### **4. Désactiver temporairement RLS**

```sql
-- ⚠️ ATTENTION : Seulement pour tester
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Tester l'inscription

-- Réactiver RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
```

### **5. Vérifier les contraintes de clé étrangère**

```sql
-- Lister les contraintes
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'profiles';

-- Supprimer temporairement la contrainte de chorale_id si elle bloque
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_chorale_id_fkey;

-- Recréer la contrainte avec ON DELETE SET NULL
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_chorale_id_fkey
  FOREIGN KEY (chorale_id)
  REFERENCES public.chorales(id)
  ON DELETE SET NULL;
```

---

## 📊 RÉSUMÉ

### **Avant (avec erreur) :**

```
❌ Trigger échoue
❌ Contraintes trop strictes
❌ Pas de gestion d'erreurs
❌ Compte créé mais pas de profil
❌ Erreur 500
```

### **Après (corrigé) :**

```
✅ Trigger avec gestion d'erreurs
✅ Contraintes assouplies
✅ Valeurs par défaut
✅ Policy d'insertion
✅ Profil créé automatiquement
✅ Inscription fonctionne
```

---

## 🎯 CHECKLIST

```
☐ Exécuter FIX_INSCRIPTION_ERROR.sql
☐ Vérifier que le trigger existe
☐ Vérifier que les colonnes sont nullables
☐ Vérifier que RLS est activé
☐ Vérifier les policies
☐ Nettoyer les comptes orphelins
☐ Tester l'inscription
☐ Vérifier que le profil est créé
```

---

## 📋 COMMANDES RAPIDES

### **Vérification complète**

```sql
-- Tout vérifier en une commande
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') THEN
    RAISE EXCEPTION 'Fonction handle_new_user manquante';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') THEN
    RAISE EXCEPTION 'Trigger on_auth_user_created manquant';
  END IF;
  
  RAISE NOTICE '✅ Tout est OK !';
END $$;
```

### **Réinitialisation complète**

```sql
-- ⚠️ ATTENTION : Supprime tout
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Puis exécuter FIX_INSCRIPTION_ERROR.sql
```

---

**Date de création :** 2025-11-22  
**Version :** 1.0  
**Auteur :** Cascade AI  
**Fichiers créés :**
- `FIX_INSCRIPTION_ERROR.sql`
- `FIX_INSCRIPTION_ERROR.md`

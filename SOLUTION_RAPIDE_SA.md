# 🚨 AUCUN UTILISATEUR TROUVÉ - SOLUTION RAPIDE

## 🔍 DIAGNOSTIC

Les comptes `kodjodavid2025@gmail.com` et `agbeviade2017@gmail.com` n'existent pas dans la base de données.

**Résultat:** `Success. No rows returned`

---

## ✅ SOLUTION RAPIDE EN 3 ÉTAPES

### **ÉTAPE 1: Voir TOUS les utilisateurs existants**

```sql
SELECT 
  p.id as profile_id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.created_at DESC
LIMIT 20;
```

**Objectif:** Trouver les vrais emails qui existent dans votre base

---

### **ÉTAPE 2: Selon le résultat**

#### **CAS A: Vous voyez des utilisateurs avec d'autres emails**
```
profile_id | full_name | email              | role   | statut_validation
-----------+-----------+--------------------+--------+------------------
uuid-1     | David     | autre@email.com    | membre | valide
uuid-2     | John      | test@email.com     | membre | valide
```

**Action:** Utilisez un de ces emails pour créer le SA:
```sql
UPDATE profiles
SET role = 'super_admin'
WHERE user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'autre@email.com'  -- ⚠️ Email trouvé
);
```

---

#### **CAS B: Aucun utilisateur du tout**
```
(0 rows)
```

**Action:** Créer un Super Admin manuellement:

**Option 1: Via Supabase Dashboard (RECOMMANDÉ)**
1. Aller sur Supabase Dashboard
2. Authentication > Users > Add User
3. Email: `kodjodavid2025@gmail.com`
4. Password: `VotreMotDePasse123!`
5. Cocher "Auto Confirm User"
6. Cliquer "Create User"

**Puis exécuter:**
```sql
-- Créer le profil
INSERT INTO profiles (user_id, full_name, role, statut_validation)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com'),
  'David Kodjo',
  'super_admin',
  'valide'
);
```

---

**Option 2: Tout en SQL (si vous avez les droits)**
```sql
-- Créer l'utilisateur dans auth.users
-- NOTE: Cette méthode nécessite des privilèges élevés
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'kodjodavid2025@gmail.com',
  crypt('VotreMotDePasse123!', gen_salt('bf')),  -- ⚠️ Changez le mot de passe
  NOW(),
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
);

-- Puis créer le profil
INSERT INTO profiles (user_id, full_name, role, statut_validation)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com'),
  'David Kodjo',
  'super_admin',
  'valide'
);
```

---

### **ÉTAPE 3: Vérifier**

```sql
SELECT 
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin';
```

**Résultat attendu:**
```
full_name   | email                      | role        | statut_validation
------------+----------------------------+-------------+------------------
David Kodjo | kodjodavid2025@gmail.com   | super_admin | valide
```

---

## 🎯 ACTION IMMÉDIATE

**Exécutez cette requête MAINTENANT:**

```sql
SELECT 
  p.id as profile_id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.created_at DESC
LIMIT 20;
```

**Puis dites-moi:**
1. Combien d'utilisateurs vous voyez ?
2. Quels sont leurs emails ?
3. Y a-t-il un compte que vous reconnaissez ?

---

## 📄 FICHIERS CRÉÉS

1. ✅ `DIAGNOSTIC_UTILISATEURS.sql` - Requêtes de diagnostic complètes
2. ✅ `SOLUTION_RAPIDE_SA.md` - Ce guide

---

**Exécutez la requête de l'ÉTAPE 1 et envoyez-moi le résultat ! 🔍**

# 🚀 CRÉER L'UTILISATEUR DANS SUPABASE DASHBOARD

## ⚠️ PROBLÈME

L'utilisateur `agbeviade2017@gmail.com` n'existe pas dans `auth.users`.

**Résultat de la requête:** `No rows returned`

---

## ✅ SOLUTION: Créer l'utilisateur via Supabase Dashboard

### **ÉTAPE 1: Ouvrir Supabase Dashboard**

1. Aller sur [https://supabase.com](https://supabase.com)
2. Se connecter à votre compte
3. Sélectionner votre projet

---

### **ÉTAPE 2: Aller dans Authentication**

1. Dans le menu latéral gauche, cliquer sur **"Authentication"**
2. Cliquer sur **"Users"**

---

### **ÉTAPE 3: Ajouter un utilisateur**

1. Cliquer sur le bouton **"Add User"** (bouton vert en haut à droite)

2. **Remplir le formulaire:**
   ```
   Email: agbeviade2017@gmail.com
   Password: VotreMotDePasse123!
   ```
   ⚠️ **Choisissez un mot de passe fort que vous retiendrez**

3. **IMPORTANT:** ✅ **Cocher la case "Auto Confirm User"**
   - Cette case permet de confirmer automatiquement l'email
   - Sans cela, l'utilisateur devra confirmer son email

4. Cliquer sur **"Create User"**

---

### **ÉTAPE 4: Vérifier que l'utilisateur a été créé**

Vous devriez voir `agbeviade2017@gmail.com` dans la liste des utilisateurs.

---

### **ÉTAPE 5: Revenir dans SQL Editor et exécuter**

**Une fois l'utilisateur créé, exécutez ces requêtes SQL:**

```sql
-- 1. Vérifier que l'utilisateur existe maintenant
SELECT 
  id,
  email,
  email_confirmed_at
FROM auth.users
WHERE email = 'agbeviade2017@gmail.com';

-- Résultat attendu:
-- id                                   | email                    | email_confirmed_at
-- -------------------------------------+--------------------------+-------------------------
-- uuid-here                            | agbeviade2017@gmail.com  | 2025-11-20 14:04:00

-- =====================================================

-- 2. Lier le profil existant à cet utilisateur
UPDATE profiles
SET user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'agbeviade2017@gmail.com'
)
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu: UPDATE 1

-- =====================================================

-- 3. Mettre en Super Admin
UPDATE profiles
SET role = 'super_admin'
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu: UPDATE 1

-- =====================================================

-- 4. VÉRIFICATION FINALE
SELECT 
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin';

-- Résultat attendu:
-- full_name   | email                    | role        | statut_validation
-- ------------+--------------------------+-------------+------------------
-- Kodjo David | agbeviade2017@gmail.com  | super_admin | valide
```

---

## 📸 CAPTURES D'ÉCRAN DU PROCESSUS

### **1. Menu Authentication > Users**
```
[Supabase Dashboard]
├── Authentication (menu latéral)
│   └── Users
│       └── [Add User] (bouton vert)
```

### **2. Formulaire Add User**
```
┌─────────────────────────────────────┐
│ Add User                            │
├─────────────────────────────────────┤
│ Email:                              │
│ [agbeviade2017@gmail.com]           │
│                                     │
│ Password:                           │
│ [VotreMotDePasse123!]               │
│                                     │
│ ✅ Auto Confirm User                │
│                                     │
│ [Cancel]  [Create User]             │
└─────────────────────────────────────┘
```

---

## 🎯 CHECKLIST

- [ ] Ouvrir Supabase Dashboard
- [ ] Aller dans Authentication > Users
- [ ] Cliquer sur "Add User"
- [ ] Remplir Email: `agbeviade2017@gmail.com`
- [ ] Remplir Password: `VotreMotDePasse123!`
- [ ] ✅ Cocher "Auto Confirm User"
- [ ] Cliquer "Create User"
- [ ] Vérifier que l'utilisateur apparaît dans la liste
- [ ] Revenir dans SQL Editor
- [ ] Exécuter les 4 requêtes SQL ci-dessus

---

## ⚡ ALTERNATIVE RAPIDE

Si vous ne pouvez pas accéder au Dashboard, utilisez **David Kodjo** à la place:

```sql
-- Mettre David Kodjo en Super Admin directement
UPDATE profiles
SET role = 'super_admin'
WHERE id = 'fec9ae76-52a9-43ac-814a-f1e44eb02397';

-- Vérifier
SELECT 
  full_name,
  role
FROM profiles
WHERE id = 'fec9ae76-52a9-43ac-814a-f1e44eb02397';
```

**Note:** David Kodjo est déjà `admin`, donc il a déjà des droits élevés.

---

## 📞 BESOIN D'AIDE ?

Si vous avez des difficultés à créer l'utilisateur dans le Dashboard:
1. Envoyez-moi une capture d'écran
2. Ou utilisez l'alternative avec David Kodjo
3. Ou dites-moi l'erreur que vous rencontrez

---

**Allez maintenant dans Supabase Dashboard pour créer l'utilisateur ! 🚀**

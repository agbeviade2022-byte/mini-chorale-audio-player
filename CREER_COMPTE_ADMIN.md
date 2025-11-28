# 🔐 Créer votre compte Super Admin

## ⚠️ Important

Le script `create_super_admin.sql` **ne crée PAS** le compte utilisateur.  
Il **transforme** un compte existant en super admin.

## 📋 Marche à suivre

### Option 1: Créer le compte via votre application Flutter (RECOMMANDÉ) ✅

**Étapes:**

1. **Lancer l'application**
   ```bash
   flutter run
   ```

2. **S'inscrire**
   - Aller sur l'écran d'inscription
   - Email: `kodjodavid2025@gmail.com`
   - Mot de passe: `votre_mot_de_passe_sécurisé`
   - Créer le compte

3. **Vérifier l'email** (si activé dans Supabase)
   - Vérifier votre boîte mail
   - Cliquer sur le lien de confirmation

4. **Exécuter le script super admin**
   - Aller sur Supabase → SQL Editor
   - Exécuter `create_super_admin.sql`
   - ✅ Votre compte est maintenant super admin !

---

### Option 2: Créer le compte directement dans Supabase 🔧

**Étapes:**

1. **Aller sur Supabase**
   - https://app.supabase.com
   - Sélectionner votre projet

2. **Aller dans Authentication**
   - Cliquer sur "Authentication" dans le menu
   - Cliquer sur "Users"
   - Cliquer sur "Add user" (ou "Invite user")

3. **Créer l'utilisateur**
   - Email: `kodjodavid2025@gmail.com`
   - Password: `votre_mot_de_passe_sécurisé`
   - ✅ Auto Confirm User (cocher cette case)
   - Cliquer sur "Create user"

4. **Vérifier que l'utilisateur existe**
   
   Dans SQL Editor:
   ```sql
   SELECT id, email, created_at 
   FROM auth.users 
   WHERE email = 'kodjodavid2025@gmail.com';
   ```
   
   **Résultat attendu:**
   ```
   id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   email: kodjodavid2025@gmail.com
   created_at: 2024-11-18...
   ```

5. **Exécuter le script super admin**
   
   Dans SQL Editor:
   - Copier TOUT le contenu de `create_super_admin.sql`
   - Coller et Run
   
   **Résultat attendu:**
   ```
   ✅ Super admin créé avec succès
   ✅ Toutes les permissions ajoutées
   est_admin: true
   ```

---

### Option 3: Créer le compte via SQL (AVANCÉ) 🛠️

**Script SQL complet:**

```sql
-- =====================================================
-- CRÉER UN COMPTE UTILISATEUR ET LE RENDRE SUPER ADMIN
-- =====================================================

-- 1. Créer l'utilisateur dans auth.users
-- ⚠️ REMPLACER 'VOTRE_MOT_DE_PASSE' par un vrai mot de passe
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
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
    crypt('VOTRE_MOT_DE_PASSE', gen_salt('bf')), -- ⚠️ CHANGER ICI
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"David Kodjo"}'::jsonb,
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
);

-- 2. Créer le profil
INSERT INTO profiles (id, email, full_name)
SELECT 
    id,
    email,
    'David Kodjo'
FROM auth.users
WHERE email = 'kodjodavid2025@gmail.com';

-- 3. Vérifier
SELECT id, email FROM auth.users WHERE email = 'kodjodavid2025@gmail.com';
```

**⚠️ ATTENTION:** Cette méthode est complexe et peut échouer. Préférez l'Option 1 ou 2.

---

## ✅ Vérification

Après avoir créé le compte, vérifiez:

```sql
-- Vérifier que l'utilisateur existe
SELECT id, email, email_confirmed_at 
FROM auth.users 
WHERE email = 'kodjodavid2025@gmail.com';
```

**Résultat attendu:**
```
id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
email: kodjodavid2025@gmail.com
email_confirmed_at: 2024-11-18... (pas NULL)
```

Si `email_confirmed_at` est NULL, confirmez l'email:

```sql
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email = 'kodjodavid2025@gmail.com';
```

---

## 🚀 Après la création du compte

**Exécuter:** `create_super_admin.sql`

Ce script va:
1. ✅ Trouver votre user_id
2. ✅ Créer l'entrée dans `system_admins`
3. ✅ Ajouter les 21 permissions
4. ✅ Tester que tout fonctionne

**Résultat final:**

```
✅ SUPER ADMIN CRÉÉ
email: kodjodavid2025@gmail.com
role: super_admin
nb_permissions: 21

🧪 TEST is_system_admin()
est_admin: true ✅
```

---

## 🎯 Résumé

### Méthode recommandée:

1. **Créer le compte** via l'app Flutter (s'inscrire normalement)
2. **Exécuter** `create_super_admin.sql` dans Supabase
3. **Se reconnecter** dans l'app
4. **Vérifier** que le bouton admin apparaît

### Ou via Supabase:

1. **Authentication → Users → Add user**
2. Email: kodjodavid2025@gmail.com
3. Password: votre_mot_de_passe
4. ✅ Auto Confirm User
5. **Exécuter** `create_super_admin.sql`

**Après ça, vous serez super admin !** 🚀

---

## 📚 Fichiers

1. **`CREER_COMPTE_ADMIN.md`** - Ce guide
2. **`create_super_admin.sql`** - À exécuter APRÈS avoir créé le compte
3. **`ETAPES_SUIVANTES.md`** - Suite du processus

**Créez d'abord votre compte, puis exécutez le script !** ✅

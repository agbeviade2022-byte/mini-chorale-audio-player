# 🔐 GUIDE : Système de Permissions

## 🎯 COMPRENDRE LES RÔLES

### **3 Rôles disponibles :**

```
┌─────────────────────────────────────────────────────┐
│  🔴 SUPER_ADMIN                                     │
│  - Toutes les permissions automatiquement           │
│  - Boutons NON cliquables (permissions fixes)       │
│  - Gère les autres admins                           │
│  - Accès complet au système                         │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  🟠 ADMIN                                            │
│  - Permissions personnalisables                      │
│  - Boutons CLIQUABLES (vous gérez les permissions)  │
│  - Peut avoir certaines permissions seulement        │
│  - Accès limité selon les permissions                │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  🟢 MEMBRE                                           │
│  - Aucune permission admin                           │
│  - N'apparaît PAS dans la page Permissions          │
│  - Accès uniquement aux fonctionnalités de base     │
│  - Peut consulter les chants de sa chorale          │
└─────────────────────────────────────────────────────┘
```

---

## 🔍 POURQUOI LES BOUTONS NE FONCTIONNENT PAS ?

### **Situation actuelle :**

```
Page Permissions :
┌──────────────────────────────────────────────┐
│  AGREVIADE        DAVID KODJO                │
│  SUPER_ADMIN      SUPER_ADMIN                │
│     ✅               ✅     ← Non cliquables  │
│     ✅               ✅                       │
│     ✅               ✅                       │
└──────────────────────────────────────────────┘
```

**Raison :** Les deux utilisateurs sont **SUPER_ADMIN**, donc :
- ✅ Ils ont **toutes** les permissions automatiquement
- ❌ Les boutons ne sont **pas cliquables** (c'est normal)
- ℹ️ C'est le comportement **attendu** pour les super admins

---

## ✅ COMMENT TESTER LES PERMISSIONS ?

### **OPTION 1 : Créer un utilisateur "admin"**

#### **Étape 1 : Créer un compte via l'app Flutter**

1. ✅ Ouvrez l'app Flutter
2. ✅ Inscrivez un nouvel utilisateur (ex: `admin.test@chorale.com`)
3. ✅ Attendez la validation

#### **Étape 2 : Valider et changer le rôle**

Dans le dashboard admin :

1. ✅ Allez dans **"Validation des membres"**
2. ✅ Validez le nouvel utilisateur
3. ✅ **Attribuez-lui une chorale**

#### **Étape 3 : Changer le rôle en "admin"**

Dans Supabase SQL Editor :

```sql
-- Changer le rôle en "admin"
UPDATE profiles 
SET role = 'admin'
WHERE user_id = (
    SELECT id FROM auth.users 
    WHERE email = 'admin.test@chorale.com'
);
```

#### **Étape 4 : Rafraîchir le dashboard**

```bash
# Dans le navigateur
F5
```

**Résultat :**

```
Page Permissions :
┌──────────────────────────────────────────────────────┐
│  AGREVIADE        DAVID KODJO      Admin Test        │
│  SUPER_ADMIN      SUPER_ADMIN      ADMIN             │
│     ✅               ✅               🔘  ← Cliquable │
│     ✅               ✅               ✅               │
│     ✅               ✅               🔘               │
└──────────────────────────────────────────────────────┘
```

---

### **OPTION 2 : Changer temporairement un super_admin en admin**

**⚠️ Attention : Gardez au moins 1 super_admin !**

```sql
-- Changer AGREVIADE en admin (temporaire)
UPDATE profiles 
SET role = 'admin'
WHERE user_id = (
    SELECT id FROM auth.users 
    WHERE email = 'agbeviade2017@gmail.com'
);

-- Tester les permissions...

-- Remettre en super_admin après les tests
UPDATE profiles 
SET role = 'super_admin'
WHERE user_id = (
    SELECT id FROM auth.users 
    WHERE email = 'agbeviade2017@gmail.com'
);
```

---

## 🎨 UTILISATION DE LA PAGE PERMISSIONS

### **Avec un utilisateur "admin" :**

```
1. Cliquez sur un bouton gris (🔘)
   ↓
2. Il devient vert (✅)
   ↓
3. L'admin a maintenant cette permission
   ↓
4. Il peut accéder à cette fonctionnalité
```

### **Exemple concret :**

```
Admin Test :
  - Ajouter des chants : ✅ (activé)
  - Voir les membres : 🔘 (désactivé)
  - Gérer les chorales : 🔘 (désactivé)

→ Admin Test peut SEULEMENT ajouter des chants
→ Il ne peut PAS voir les membres ni gérer les chorales
```

---

## 📊 ARCHITECTURE DU SYSTÈME

### **Base de données :**

```sql
-- Table profiles
profiles
├── user_id (UUID)
├── full_name (TEXT)
├── role (TEXT)  ← 'super_admin', 'admin', 'membre'
└── ...

-- Table modules_permissions
modules_permissions
├── id (UUID)
├── code (TEXT)  ← 'add_chants', 'view_members', etc.
├── nom (TEXT)
├── categorie (TEXT)
└── ...

-- Table user_permissions (jonction)
user_permissions
├── user_id (UUID)  → profiles.user_id
└── module_code (TEXT)  → modules_permissions.code
```

### **Logique :**

```
SI role = 'super_admin' ALORS
    → Toutes les permissions automatiquement
    → Ignore user_permissions
    
SI role = 'admin' ALORS
    → Permissions selon user_permissions
    → Peut avoir certaines permissions seulement
    
SI role = 'membre' ALORS
    → Aucune permission admin
    → Accès de base uniquement
```

---

## 🔧 COMMANDES UTILES

### **Voir tous les rôles :**

```sql
SELECT 
    au.email,
    p.full_name,
    p.role,
    CASE 
        WHEN p.role = 'super_admin' THEN '🔴 Toutes permissions'
        WHEN p.role = 'admin' THEN '🟠 Permissions personnalisables'
        WHEN p.role = 'membre' THEN '🟢 Aucune permission admin'
    END as description
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
ORDER BY p.role;
```

### **Voir les permissions d'un utilisateur :**

```sql
SELECT 
    au.email,
    p.full_name,
    p.role,
    mp.nom as permission,
    mp.categorie
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
LEFT JOIN user_permissions up ON p.user_id = up.user_id
LEFT JOIN modules_permissions mp ON up.module_code = mp.code
WHERE au.email = 'admin.test@chorale.com'
ORDER BY mp.categorie, mp.nom;
```

### **Ajouter une permission manuellement :**

```sql
-- Ajouter la permission "add_chants" à un admin
INSERT INTO user_permissions (user_id, module_code)
VALUES (
    (SELECT id FROM auth.users WHERE email = 'admin.test@chorale.com'),
    'add_chants'
);
```

### **Retirer une permission :**

```sql
-- Retirer la permission "add_chants"
DELETE FROM user_permissions
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'admin.test@chorale.com')
AND module_code = 'add_chants';
```

---

## 📋 RECOMMANDATIONS

### **Structure recommandée :**

```
🔴 1 Super Admin (vous)
   → Gère tout le système
   → Crée les autres admins
   → Attribue les permissions

🟠 2-3 Admins
   → Gèrent les chorales
   → Valident les membres
   → Ajoutent des chants
   → Permissions limitées selon leur rôle

🟢 Tous les autres = Membres
   → Consultent les chants
   → Téléchargent les audios
   → Aucune permission admin
```

### **Bonnes pratiques :**

1. ✅ **Gardez au moins 1 super_admin** (vous)
2. ✅ **Créez des admins** pour les autres responsables
3. ✅ **Donnez uniquement les permissions nécessaires**
4. ✅ **Révisez régulièrement** les permissions
5. ✅ **Retirez les permissions** des anciens admins

---

## 🆘 DÉPANNAGE

### **Les boutons ne sont pas cliquables**

**Cause :** L'utilisateur est super_admin

**Solution :** C'est normal, les super_admins ont toutes les permissions automatiquement

---

### **Aucun utilisateur n'apparaît**

**Cause :** Fonction RPC manquante

**Solution :** Exécutez `FIX_PERMISSIONS_PAGE_FUNCTION.sql`

---

### **Erreur lors du clic sur un bouton**

**Cause :** Problème de permissions RLS ou user_id invalide

**Solution :** 
1. Vérifiez la console (F12)
2. Vérifiez que l'utilisateur a un `user_id` valide
3. Vérifiez les politiques RLS sur `user_permissions`

---

## 📞 SUPPORT

Pour créer un utilisateur admin de test, exécutez :
```
CREATE_ADMIN_TEST_USER.sql
```

---

**Date de création :** 2025-11-21  
**Version :** 1.0  
**Auteur :** Cascade AI

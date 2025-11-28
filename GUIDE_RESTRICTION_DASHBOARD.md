# 🔒 RESTRICTION DASHBOARD : Seuls les Super Admins

## 📋 OBJECTIF

**Avant:** Tous les admins et super admins peuvent se connecter au dashboard

**Après:** **SEULS les Super Admins** peuvent se connecter au dashboard

---

## ✅ SOLUTION

### **ÉTAPE 1 : Exécuter le script SQL**

**Fichier:** `RESTRICT_DASHBOARD_SUPER_ADMIN.sql`

**Ce qu'il fait:**
1. ✅ Modifie la fonction `is_system_admin()`
2. ✅ Vérifie que le rôle est **exactement** `'super_admin'`
3. ✅ Crée une fonction helper `current_user_is_super_admin()`
4. ✅ Teste avec différents rôles

**Exécution:**
```bash
# 1. Ouvrir Supabase SQL Editor
# 2. Copier TOUT le contenu de RESTRICT_DASHBOARD_SUPER_ADMIN.sql
# 3. Coller et cliquer sur "Run"
```

---

### **ÉTAPE 2 : Vérifier les résultats**

Après exécution, vous devriez voir:

```
🧪 Tests de la fonction

Test Super Admin
| email | role | resultat | statut |
|-------|------|----------|--------|
| kodjodavid2025@gmail.com | super_admin | true | ✅ Accès autorisé |

Test Admin Normal
| email | role | resultat | statut |
|-------|------|----------|--------|
| admin@test.com | admin | false | ✅ Accès refusé (correct) |

Test Membre
| email | role | resultat | statut |
|-------|------|----------|--------|
| membre@test.com | membre | false | ✅ Accès refusé (correct) |

✅ Configuration terminée avec succès !
🔒 Seuls les Super Admins peuvent maintenant se connecter au dashboard
```

---

## 🧪 TESTS

### **Test 1 : Super Admin peut se connecter**

```bash
# 1. Ouvrir http://localhost:3000
# 2. Se connecter avec:
Email: kodjodavid2025@gmail.com
Password: ****

# RÉSULTAT ATTENDU:
✅ Connexion réussie
✅ Redirection vers /dashboard
✅ Accès complet
```

---

### **Test 2 : Admin normal NE PEUT PAS se connecter**

```bash
# 1. Créer un admin normal (si vous n'en avez pas)
INSERT INTO profiles (user_id, full_name, role, statut_validation)
VALUES (
  'admin-user-id',
  'Admin Normal',
  'admin',  -- Pas super_admin
  'valide'
);

# 2. Essayer de se connecter
Email: admin@test.com
Password: ****

# RÉSULTAT ATTENDU:
❌ Erreur: "Accès refusé: Vous n'êtes pas administrateur système"
❌ Déconnexion automatique
❌ Reste sur la page de login
```

---

### **Test 3 : Membre NE PEUT PAS se connecter**

```bash
# 1. Essayer de se connecter avec un membre
Email: membre@test.com
Password: ****

# RÉSULTAT ATTENDU:
❌ Erreur: "Accès refusé: Vous n'êtes pas administrateur système"
❌ Déconnexion automatique
❌ Reste sur la page de login
```

---

### **Test 4 : Maître de Chœur NE PEUT PAS se connecter**

```bash
# 1. Essayer de se connecter avec un maître de chœur
Email: maitre@test.com
Password: ****

# RÉSULTAT ATTENDU:
❌ Erreur: "Accès refusé: Vous n'êtes pas administrateur système"
❌ Déconnexion automatique
❌ Reste sur la page de login
```

---

## 🔍 VÉRIFICATION SQL

### **Vérifier qui peut se connecter:**

```sql
SELECT 
    au.email,
    p.full_name,
    p.role,
    is_system_admin(p.user_id) as peut_acceder_dashboard,
    CASE 
        WHEN is_system_admin(p.user_id) = true 
        THEN '✅ Peut se connecter'
        ELSE '❌ Ne peut PAS se connecter'
    END as statut
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
ORDER BY p.role, au.email;
```

**Résultat attendu:**

```
| email | role | peut_acceder_dashboard | statut |
|-------|------|------------------------|--------|
| kodjodavid2025@gmail.com | super_admin | true | ✅ Peut se connecter |
| agbeviade2017@gmail.com | super_admin | true | ✅ Peut se connecter |
| admin@test.com | admin | false | ❌ Ne peut PAS se connecter |
| maitre@test.com | maitre_choeur | false | ❌ Ne peut PAS se connecter |
| membre@test.com | membre | false | ❌ Ne peut PAS se connecter |
```

---

## 📊 MATRICE D'ACCÈS

| Rôle | Dashboard Web | App Flutter |
|------|---------------|-------------|
| **Super Admin** | ✅ OUI | ✅ OUI (tous les menus) |
| **Admin** | ❌ NON | ✅ OUI (menus limités) |
| **Maître de Chœur** | ❌ NON | ✅ OUI (sa chorale) |
| **Membre** | ❌ NON | ✅ OUI (chants uniquement) |
| **Non validé** | ❌ NON | ⏳ Écran d'attente |

---

## 🔒 SÉCURITÉ

### **Fonction `is_system_admin()`**

```sql
CREATE OR REPLACE FUNCTION is_system_admin(check_user_id UUID)
RETURNS BOOLEAN
AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role
    FROM profiles
    WHERE user_id = check_user_id;
    
    -- ✅ Retourne true UNIQUEMENT si super_admin
    RETURN user_role = 'super_admin';
END;
$$;
```

**Vérifications:**
- ✅ Vérifie le rôle dans la table `profiles`
- ✅ Retourne `true` UNIQUEMENT pour `'super_admin'`
- ✅ Retourne `false` pour tous les autres rôles
- ✅ Retourne `false` si l'utilisateur n'existe pas

---

## 🚨 DÉPANNAGE

### **Problème : Super Admin ne peut pas se connecter**

**Vérifier le statut:**
```sql
SELECT 
    au.email,
    p.role,
    p.statut_validation,
    is_system_admin(p.user_id) as resultat
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE au.email = 'kodjodavid2025@gmail.com';
```

**Solutions:**
```sql
-- Si le rôle n'est pas super_admin
UPDATE profiles
SET role = 'super_admin'
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com');

-- Si le statut n'est pas validé
UPDATE profiles
SET statut_validation = 'valide'
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com');
```

---

### **Problème : Admin normal peut encore se connecter**

**Vérifier la fonction:**
```sql
SELECT is_system_admin('admin-user-id');
-- Doit retourner: false
```

**Si retourne true:**
```sql
-- Vérifier le rôle
SELECT role FROM profiles WHERE user_id = 'admin-user-id';

-- Si le rôle est 'super_admin', le changer
UPDATE profiles
SET role = 'admin'
WHERE user_id = 'admin-user-id';
```

---

### **Problème : Erreur "function is_system_admin does not exist"**

**Recréer la fonction:**
```bash
# Exécuter à nouveau RESTRICT_DASHBOARD_SUPER_ADMIN.sql
```

---

## 📝 NOTES IMPORTANTES

### **1. Dashboard Web vs App Flutter**

- **Dashboard Web:** Réservé aux Super Admins uniquement
- **App Flutter:** Accessible à tous les utilisateurs validés (avec permissions selon le rôle)

### **2. Rôles disponibles**

```
super_admin  → Accès TOTAL (dashboard + app)
admin        → Accès app uniquement (pas dashboard)
maitre_choeur → Accès app uniquement (sa chorale)
membre       → Accès app uniquement (chants)
```

### **3. Validation requise**

Même un Super Admin doit avoir `statut_validation = 'valide'` pour se connecter.

---

## ✅ CHECKLIST

Après avoir exécuté le script:

- [ ] ✅ Super Admin peut se connecter au dashboard
- [ ] ✅ Admin normal NE PEUT PAS se connecter
- [ ] ✅ Membre NE PEUT PAS se connecter
- [ ] ✅ Maître de Chœur NE PEUT PAS se connecter
- [ ] ✅ Message d'erreur clair affiché
- [ ] ✅ Déconnexion automatique si non autorisé

---

## 🎯 RÉSUMÉ

**Problème:** Tous les admins peuvent se connecter au dashboard

**Solution:** Modifier `is_system_admin()` pour vérifier `role = 'super_admin'`

**Résultat:** 
- ✅ Seuls les Super Admins peuvent se connecter
- ✅ Tous les autres rôles sont refusés
- ✅ Message d'erreur clair

---

**Exécutez `RESTRICT_DASHBOARD_SUPER_ADMIN.sql` MAINTENANT ! 🚀**

**Temps:** 2 minutes ⏱️

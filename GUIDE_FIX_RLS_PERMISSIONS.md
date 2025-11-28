# 🔒 FIX ERREUR RLS : Row Level Security sur user_permissions

## ❌ ERREUR

```
code: "42501"
message: "new row violates row-level security policy for table \"user_permissions\""
```

**Cause:** Les Row Level Security (RLS) policies empêchent l'insertion dans `user_permissions` car vous n'avez pas les permissions nécessaires.

---

## ✅ SOLUTION RAPIDE

### **Exécutez ce script dans Supabase SQL Editor:**

**Fichier:** `FIX_RLS_COMPLET_PERMISSIONS.sql`

Ce script va:
1. ✅ Configurer les policies RLS pour `modules_permissions`
2. ✅ Configurer les policies RLS pour `user_permissions`
3. ✅ Autoriser les Super Admins à tout faire
4. ✅ Autoriser les Maîtres de Chœur à gérer leur chorale
5. ✅ Permettre aux utilisateurs de voir leurs propres permissions

---

## 📝 ÉTAPES

### **1. Ouvrir Supabase Dashboard**
- Allez sur https://supabase.com/dashboard
- Sélectionnez votre projet
- Cliquez sur **SQL Editor**

### **2. Exécuter le script**
- Copiez TOUT le contenu de `FIX_RLS_COMPLET_PERMISSIONS.sql`
- Collez dans l'éditeur SQL
- Cliquez sur **Run**

### **3. Vérifier les résultats**

Vous devriez voir:
```
✅ RLS activé pour modules_permissions
✅ RLS activé pour user_permissions

📋 Policies créées:
- Super admins peuvent tout faire sur user_permissions
- Maitres de choeur peuvent gérer permissions
- Users peuvent voir leurs permissions
- Tout le monde peut lire les modules
- Super admins peuvent gérer les modules

👤 Votre rôle: super_admin
🔑 Vos permissions: 16 permissions

✅ Configuration RLS terminée avec succès !
```

### **4. Recharger le dashboard**
- Retournez sur http://localhost:3000/dashboard/permissions
- Rafraîchissez la page (F5)
- Essayez d'activer/désactiver une permission
- ✅ Devrait fonctionner maintenant !

---

## 🔍 COMPRENDRE LES POLICIES RLS

### **Policy 1: Super Admins**
```sql
-- Les Super Admins peuvent TOUT faire
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'super_admin'
  )
)
```

**Permet:**
- ✅ Créer des permissions (INSERT)
- ✅ Modifier des permissions (UPDATE)
- ✅ Supprimer des permissions (DELETE)
- ✅ Voir toutes les permissions (SELECT)

### **Policy 2: Maîtres de Chœur**
```sql
-- Les Maîtres de Chœur peuvent gérer leur chorale
USING (
  EXISTS (
    SELECT 1 FROM profiles p1
    WHERE p1.user_id = auth.uid()
    AND p1.est_maitre_choeur = true
    AND p2.chorale_id = p1.chorale_id
  )
)
```

**Permet:**
- ✅ Gérer les permissions des membres de leur chorale uniquement
- ❌ Ne peuvent pas gérer les autres chorales

### **Policy 3: Utilisateurs**
```sql
-- Les utilisateurs peuvent voir leurs propres permissions
USING (user_id = auth.uid())
```

**Permet:**
- ✅ Voir leurs propres permissions (SELECT)
- ❌ Ne peuvent pas modifier

---

## 🧪 TESTS APRÈS CORRECTION

### **Test 1: Activer une permission**
1. Allez sur http://localhost:3000/dashboard/permissions
2. Trouvez un utilisateur (ex: un admin)
3. Cliquez sur ❌ pour activer une permission
4. ✅ L'icône devient ✅
5. ✅ Pas d'erreur RLS

### **Test 2: Révoquer une permission**
1. Cliquez sur ✅ pour désactiver une permission
2. ✅ L'icône devient ❌
3. ✅ Pas d'erreur RLS

### **Test 3: Vérifier en SQL**
```sql
-- Voir toutes les permissions d'un utilisateur
SELECT 
    p.full_name,
    mp.nom as permission,
    mp.code
FROM user_permissions up
JOIN profiles p ON up.user_id = p.user_id
JOIN modules_permissions mp ON up.module_code = mp.code
WHERE p.full_name = 'NOM_UTILISATEUR'
ORDER BY mp.categorie, mp.nom;
```

---

## 🔒 SÉCURITÉ

### **Qui peut faire quoi:**

| Action | Super Admin | Maître de Chœur | Membre |
|--------|-------------|-----------------|--------|
| Voir tous les modules | ✅ | ✅ | ✅ |
| Voir ses permissions | ✅ | ✅ | ✅ |
| Attribuer permissions (tous) | ✅ | ❌ | ❌ |
| Attribuer permissions (sa chorale) | ✅ | ✅ | ❌ |
| Modifier modules | ✅ | ❌ | ❌ |

---

## 🚨 SI ÇA NE FONCTIONNE TOUJOURS PAS

### **Vérifier votre rôle:**
```sql
SELECT role, est_maitre_choeur, full_name
FROM profiles
WHERE user_id = auth.uid();
```

**Si vous n'êtes pas Super Admin:**
```sql
-- Vous définir comme Super Admin
UPDATE profiles
SET role = 'super_admin'
WHERE user_id = auth.uid();
```

### **Vérifier les policies:**
```sql
-- Lister toutes les policies
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename = 'user_permissions';
```

### **Désactiver temporairement RLS (DANGER):**
```sql
-- ⚠️ À utiliser uniquement pour tester !
ALTER TABLE user_permissions DISABLE ROW LEVEL SECURITY;

-- Après les tests, RÉACTIVER:
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;
```

---

## 📊 ARCHITECTURE RLS COMPLÈTE

```
┌─────────────────────────────────────────────────────────┐
│                    SUPABASE RLS                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  TABLE: modules_permissions                             │
│  ├─ Policy: Tout le monde peut lire                    │
│  └─ Policy: Super admins peuvent modifier              │
│                                                         │
│  TABLE: user_permissions                                │
│  ├─ Policy: Super admins peuvent tout faire            │
│  ├─ Policy: Maîtres de chœur (leur chorale)           │
│  └─ Policy: Users peuvent voir leurs permissions       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 RÉSUMÉ

**Problème:**
- ❌ Erreur RLS 42501 lors de l'attribution de permissions

**Solution:**
- ✅ Exécuter `FIX_RLS_COMPLET_PERMISSIONS.sql`
- ✅ Configure les policies pour Super Admins et Maîtres de Chœur
- ✅ Autorise la gestion des permissions

**Résultat:**
- ✅ Attribution de permissions fonctionne
- ✅ Révocation de permissions fonctionne
- ✅ Sécurité maintenue (RLS actif)
- ✅ Dashboard opérationnel

---

**Exécutez le script SQL maintenant et le problème sera résolu ! 🚀**

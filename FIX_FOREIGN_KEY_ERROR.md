# 🔧 FIX ERREUR 23503 : Clé étrangère invalide

## ❌ ERREUR

```
code: "23503"
message: "insert or update on table \"user_permissions\" violates foreign key constraint \"user_permissions_user_id_fkey\""
details: "Key is not present in table \"profiles\"."
```

**Cause:** Le `user_id` utilisé n'existe pas dans la table `profiles`.

---

## ✅ SOLUTION APPLIQUÉE

### **Ajout de vérification dans `permissions/page.tsx`**

Avant d'attribuer une permission, le code vérifie maintenant que l'utilisateur existe:

```typescript
// Vérifier que l'utilisateur existe dans profiles
const { data: profileCheck, error: checkError } = await supabase
  .from('profiles')
  .select('user_id, full_name')
  .eq('user_id', userId)
  .single()

if (checkError || !profileCheck) {
  throw new Error(`Utilisateur ${userId} introuvable dans la base de données`)
}
```

### **Logs de debug ajoutés**

```typescript
console.log('🔍 Toggle permission:', { userId, moduleCode, hasPermission })
console.log('✅ Utilisateur trouvé:', profileCheck.full_name)
console.log('✅ Permission attribuée/révoquée')
```

---

## 🧪 TESTS À EFFECTUER

### **Test 1: Recharger le dashboard**
1. Allez sur http://localhost:3000/dashboard/permissions
2. Rafraîchissez la page (F5)
3. Ouvrez la console (F12)

### **Test 2: Essayer d'attribuer une permission**
1. Cliquez sur ❌ pour activer une permission
2. Regardez la console

**Résultats possibles:**

#### **✅ Cas 1: Succès**
```
🔍 Toggle permission: { userId: "abc-123", moduleCode: "add_chants", hasPermission: false }
✅ Utilisateur trouvé: Jean Dupont
✅ Permission attribuée
```

#### **❌ Cas 2: Utilisateur introuvable**
```
🔍 Toggle permission: { userId: "xyz-789", moduleCode: "add_chants", hasPermission: false }
❌ Utilisateur introuvable dans profiles: xyz-789
Erreur: Utilisateur xyz-789 introuvable dans la base de données
```

---

## 🔍 DIAGNOSTIC

### **Si l'utilisateur est introuvable:**

**Vérifier en SQL:**
```sql
-- Vérifier si l'utilisateur existe
SELECT user_id, full_name, role
FROM profiles
WHERE user_id = 'USER_ID_ICI';
```

**Si aucun résultat:**
- L'utilisateur n'existe pas dans `profiles`
- Peut-être supprimé ou jamais créé
- Vérifier dans `auth.users`:

```sql
SELECT id, email, created_at
FROM auth.users
WHERE id = 'USER_ID_ICI';
```

### **Si l'utilisateur existe dans auth.users mais pas dans profiles:**

**Créer le profil manquant:**
```sql
INSERT INTO profiles (user_id, full_name, role)
VALUES (
  'USER_ID_ICI',
  'Nom de l\'utilisateur',
  'membre'
);
```

---

## 🔧 CAUSES POSSIBLES

### **1. Utilisateur supprimé de profiles mais pas de auth.users**
```sql
-- Vérifier les utilisateurs orphelins
SELECT au.id, au.email
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL;
```

**Solution:** Créer les profils manquants ou supprimer les utilisateurs orphelins.

### **2. Mauvais user_id passé à la fonction**

Vérifier dans le code que vous utilisez bien `user.user_id` et non `user.id`:

```typescript
// ❌ INCORRECT
togglePermission(user.id, module.code, hasPermission)

// ✅ CORRECT
togglePermission(user.user_id, module.code, hasPermission)
```

### **3. Données corrompues**

```sql
-- Nettoyer les permissions orphelines
DELETE FROM user_permissions
WHERE user_id NOT IN (SELECT user_id FROM profiles);
```

---

## 📊 VÉRIFICATIONS COMPLÈTES

### **1. Vérifier la structure de la contrainte:**
```sql
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'user_permissions';
```

**Résultat attendu:**
```
constraint_name: user_permissions_user_id_fkey
table_name: user_permissions
column_name: user_id
foreign_table_name: profiles
foreign_column_name: user_id
```

### **2. Vérifier l'intégrité des données:**
```sql
-- Compter les utilisateurs
SELECT 
    'auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'profiles' as table_name,
    COUNT(*) as count
FROM profiles
UNION ALL
SELECT 
    'user_permissions' as table_name,
    COUNT(DISTINCT user_id) as count
FROM user_permissions;
```

---

## 🎯 RÉSUMÉ

### **Problème:**
- ❌ Erreur 23503: clé étrangère invalide
- ❌ `user_id` n'existe pas dans `profiles`

### **Solution:**
- ✅ Ajout de vérification avant insertion
- ✅ Logs de debug pour identifier le problème
- ✅ Message d'erreur clair pour l'utilisateur

### **Prochaines étapes:**
1. ✅ Recharger le dashboard
2. ✅ Essayer d'attribuer une permission
3. ✅ Regarder les logs dans la console
4. ✅ Identifier quel `user_id` pose problème
5. ✅ Corriger en SQL si nécessaire

---

## 🚀 APRÈS CORRECTION

**Rechargez le dashboard et testez ! Les logs vous diront exactement quel est le problème ! 🔍**

**Si un utilisateur est introuvable, vous verrez son `user_id` dans la console et pourrez le corriger en SQL.**

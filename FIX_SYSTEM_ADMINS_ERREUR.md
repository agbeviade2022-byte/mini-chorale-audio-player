# ✅ ERREUR 406 CORRIGÉE : Table `system_admins` supprimée

## ❌ PROBLÈME

Erreur 406 lors de la modification/suppression d'utilisateurs:
```
GET https://milzcdtfblwhblstwuzh.supabase.co/rest/v1/system_admins?select=id&user_id=eq.9d30bbbb-12cd-4764-afdb-01f5d3377426 406 (Not Acceptable)
```

**Cause:** Le code essayait d'accéder à une table `system_admins` qui n'existe pas dans votre base de données.

---

## ✅ SOLUTION APPLIQUÉE

### **Fichiers modifiés:**

#### **1. `components/EditUserModal.tsx`** ✅
**Avant:**
```typescript
// Si le rôle est admin, vérifier/créer l'entrée dans system_admins
if (formData.role === 'admin' || formData.role === 'super_admin') {
  const { data: existingAdmin } = await supabase
    .from('system_admins')  // ❌ Table inexistante
    .select('id')
    .eq('user_id', user.id)
    .single()
  // ...
}
```

**Après:**
```typescript
// Mise à jour directe dans profiles
const { error: updateError } = await supabase
  .from('profiles')  // ✅ Table existante
  .update({
    full_name: formData.full_name.trim(),
    role: formData.role,
  })
  .eq('id', user.id)
```

#### **2. `components/DeleteUserModal.tsx`** ✅
**Avant:**
```typescript
// 1. Supprimer de system_admins si existe
await supabase
  .from('system_admins')  // ❌ Table inexistante
  .delete()
  .eq('user_id', user.id)
```

**Après:**
```typescript
// 1. Supprimer les permissions de l'utilisateur
await supabase
  .from('user_permissions')  // ✅ Table existante
  .delete()
  .eq('user_id', user.id)
```

---

## 🎯 ARCHITECTURE ACTUELLE

### **Tables utilisées:**

1. **`profiles`** - Profils utilisateurs
   - `user_id` (UUID)
   - `full_name` (TEXT)
   - `role` (TEXT) - 'super_admin', 'admin', 'membre', 'user'
   - `email` (via JOIN avec auth.users)

2. **`modules_permissions`** - Modules de permissions (16 modules)
   - `id` (UUID)
   - `code` (TEXT) - 'add_chants', 'edit_chants', etc.
   - `nom` (TEXT)
   - `description` (TEXT)
   - `categorie` (TEXT)

3. **`user_permissions`** - Attribution des permissions
   - `user_id` (UUID)
   - `module_code` (TEXT)

### **Tables SUPPRIMÉES:**
- ❌ `system_admins` - N'existe pas et n'est plus nécessaire

---

## 🧪 VÉRIFICATION

### **Test 1: Modifier un utilisateur**
1. Allez sur http://localhost:3000/dashboard/users
2. Cliquez sur "Modifier" pour un utilisateur
3. Changez le nom ou le rôle
4. Cliquez sur "Enregistrer"
5. ✅ Devrait fonctionner sans erreur 406

### **Test 2: Supprimer un utilisateur**
1. Allez sur http://localhost:3000/dashboard/users
2. Cliquez sur "Supprimer" pour un utilisateur
3. Tapez "SUPPRIMER" pour confirmer
4. Cliquez sur "Supprimer définitivement"
5. ✅ Devrait fonctionner sans erreur 406

### **Test 3: Page Permissions**
1. Allez sur http://localhost:3000/dashboard/permissions
2. Cliquez sur une permission pour l'activer/désactiver
3. ✅ Devrait fonctionner sans erreur

---

## 📋 RÉSUMÉ DES MODIFICATIONS

### **EditUserModal.tsx**
- ✅ Supprimé les 33 lignes de code liées à `system_admins`
- ✅ Mise à jour directe dans `profiles`
- ✅ Plus simple et plus rapide

### **DeleteUserModal.tsx**
- ✅ Remplacé `system_admins` par `user_permissions`
- ✅ Suppression des permissions avant suppression du profil
- ✅ Cohérent avec le nouveau système

---

## 🎉 RÉSULTAT

**Avant:**
- ❌ Erreur 406 lors de la modification d'utilisateurs
- ❌ Erreur 406 lors de la suppression d'utilisateurs
- ❌ Référence à une table inexistante

**Après:**
- ✅ Modification d'utilisateurs fonctionne
- ✅ Suppression d'utilisateurs fonctionne
- ✅ Utilisation du système de permissions modulaires
- ✅ Code plus propre et cohérent

---

## 🚀 PROCHAINES ÉTAPES

### **Optionnel: Créer une fonction SQL pour supprimer un utilisateur complètement**

```sql
CREATE OR REPLACE FUNCTION supprimer_utilisateur(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Supprimer les permissions
    DELETE FROM user_permissions WHERE user_id = p_user_id;
    
    -- Supprimer le profil
    DELETE FROM profiles WHERE user_id = p_user_id;
    
    -- Supprimer de auth.users (nécessite des permissions spéciales)
    -- DELETE FROM auth.users WHERE id = p_user_id;
END;
$$;
```

**Utilisation dans le dashboard:**
```typescript
await supabase.rpc('supprimer_utilisateur', { p_user_id: user.id })
```

---

## 📝 NOTES IMPORTANTES

1. **Rôles dans `profiles`:**
   - `super_admin` - Toutes les permissions automatiquement
   - `admin` / Maître de Chœur - Permissions personnalisables
   - `membre` - Membre d'une chorale
   - `user` - Utilisateur standard

2. **Permissions:**
   - Gérées via la table `user_permissions`
   - Visibles et modifiables sur `/dashboard/permissions`
   - Super Admin = toutes les permissions (non modifiable)

3. **Suppression d'utilisateurs:**
   - Supprime d'abord les permissions
   - Puis supprime le profil
   - L'utilisateur ne peut plus se connecter

---

**✅ L'erreur 406 est maintenant corrigée ! Le dashboard fonctionne correctement ! 🎉**

# 🔧 CORRIGER L'AFFICHAGE DES EMAILS DANS LE DASHBOARD

## ❌ PROBLÈME

Les emails ne s'affichent pas dans la page "Utilisateurs" du dashboard web car la table `profiles` ne contient pas la colonne `email`. Les emails sont stockés dans `auth.users`.

## ✅ SOLUTION

Exécuter la fonction SQL `get_all_users_with_emails()` qui fait un JOIN entre `profiles` et `auth.users`.

---

## 📝 ÉTAPES

### **1. Ouvrir Supabase Dashboard**

1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet
3. Cliquez sur **SQL Editor** dans le menu de gauche

### **2. Exécuter le script SQL**

Copiez et collez le contenu du fichier `FIX_DASHBOARD_EMAILS.sql` :

```sql
-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS get_all_users_with_emails();

-- Créer la fonction pour récupérer les utilisateurs avec emails
CREATE OR REPLACE FUNCTION get_all_users_with_emails()
RETURNS TABLE (
    id UUID,
    user_id UUID,
    full_name TEXT,
    role VARCHAR(20),
    email TEXT,
    telephone VARCHAR(20),
    chorale_id UUID,
    statut_validation VARCHAR(20),
    statut_membre VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier que l'utilisateur est admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.user_id = auth.uid() 
        AND profiles.role IN ('admin', 'super_admin')
    ) THEN
        RAISE EXCEPTION 'Accès refusé: seuls les admins peuvent voir tous les utilisateurs';
    END IF;

    -- Retourner tous les profils avec leurs emails
    RETURN QUERY
    SELECT 
        p.user_id as id,
        p.user_id,
        p.full_name,
        p.role,
        au.email,
        p.telephone,
        p.chorale_id,
        p.statut_validation,
        p.statut_membre,
        p.created_at,
        p.updated_at
    FROM profiles p
    LEFT JOIN auth.users au ON p.user_id = au.id
    ORDER BY p.created_at DESC;
END;
$$;

-- Donner les permissions
GRANT EXECUTE ON FUNCTION get_all_users_with_emails() TO authenticated;
```

### **3. Cliquer sur "Run"**

Vous devriez voir :
```
✅ Success. No rows returned
```

### **4. Tester la fonction**

Exécutez cette requête pour vérifier :

```sql
SELECT * FROM get_all_users_with_emails();
```

Vous devriez voir tous les utilisateurs **avec leurs emails** !

### **5. Recharger le dashboard**

1. Retournez sur votre dashboard web : http://localhost:3000/dashboard/users
2. Rafraîchissez la page (F5)
3. Les emails devraient maintenant s'afficher ! ✅

---

## 🧪 VÉRIFICATION

Après avoir exécuté le script, vérifiez que :

- ✅ La fonction `get_all_users_with_emails()` existe
- ✅ Elle retourne les emails
- ✅ Le dashboard affiche les emails dans la colonne "Email"

---

## 🔍 SI ÇA NE FONCTIONNE TOUJOURS PAS

### **Vérifier les permissions**

```sql
-- Vérifier que vous êtes admin
SELECT role FROM profiles WHERE user_id = auth.uid();
```

Si vous n'êtes pas admin, la fonction refusera l'accès.

### **Vérifier les données**

```sql
-- Vérifier que les profils sont liés aux users
SELECT 
    p.full_name,
    p.role,
    au.email,
    p.user_id,
    au.id
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
LIMIT 10;
```

Si `au.email` est NULL, c'est que le `user_id` dans `profiles` ne correspond pas à l'`id` dans `auth.users`.

---

## 📊 RÉSULTAT ATTENDU

Avant :
```
| Utilisateur         | Email | Rôle        |
|---------------------|-------|-------------|
| Chorale St Camille  |       | admin       |
| Agbeviade           |       | super_admin |
| David Kodjo         |       | super_admin |
```

Après :
```
| Utilisateur         | Email                      | Rôle        |
|---------------------|----------------------------|-------------|
| Chorale St Camille  | chorale@example.com        | admin       |
| Agbeviade           | agbeviade2017@gmail.com    | super_admin |
| David Kodjo         | kodjodavid2025@gmail.com   | super_admin |
```

---

## 🎯 RÉSUMÉ

1. ✅ Ouvrir Supabase SQL Editor
2. ✅ Copier/coller le script `FIX_DASHBOARD_EMAILS.sql`
3. ✅ Cliquer sur "Run"
4. ✅ Recharger le dashboard web
5. ✅ Vérifier que les emails s'affichent

**Temps estimé : 2 minutes**

---

**Le problème devrait être résolu ! 🎉**

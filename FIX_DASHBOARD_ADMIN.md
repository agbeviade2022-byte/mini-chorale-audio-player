# 🔧 Fix Dashboard Admin - Emails manquants

## 🐛 Problème

Les emails n'apparaissent pas dans la page "Utilisateurs" du dashboard admin car :
- La table `profiles` ne contient pas de colonne `email`
- Les emails sont stockés dans `auth.users`
- Le dashboard essaie d'utiliser une fonction RPC `get_all_users_with_emails()` qui n'existe pas

---

## ✅ Solution

### 1. **Créer la fonction SQL**

Exécutez le script suivant dans Supabase SQL Editor :

```sql
-- Fichier : fix_dashboard_emails.sql
```

Cette fonction :
- ✅ Fait un JOIN entre `profiles` et `auth.users`
- ✅ Retourne tous les utilisateurs avec leurs emails
- ✅ Vérifie que l'utilisateur connecté est admin
- ✅ Est sécurisée avec `SECURITY DEFINER`

---

## 📁 Scripts disponibles

### Option 1 : Fix rapide (recommandé)
```bash
fix_dashboard_emails.sql
```
- Crée uniquement la fonction nécessaire
- Rapide à exécuter
- Pas d'impact sur les données existantes

### Option 2 : Migration complète
```bash
migration_validation_membres_EXECUTABLE.sql
```
- Inclut la fonction + toutes les autres modifications
- À utiliser si vous n'avez pas encore exécuté la migration

---

## 🧪 Test

Après avoir exécuté le script :

1. **Dans Supabase SQL Editor** :
```sql
SELECT * FROM get_all_users_with_emails();
```

2. **Dans le dashboard admin** :
   - Rechargez la page "Utilisateurs"
   - Les emails devraient maintenant s'afficher ✅

---

## 📊 Structure de la fonction

```sql
CREATE OR REPLACE FUNCTION get_all_users_with_emails()
RETURNS TABLE (
    id UUID,
    user_id UUID,
    full_name TEXT,
    role VARCHAR(20),
    email TEXT,              -- ← Récupéré depuis auth.users
    telephone VARCHAR(20),
    chorale_id UUID,
    statut_validation VARCHAR(20),
    statut_membre VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
```

---

## 🔐 Sécurité

La fonction vérifie que l'utilisateur connecté est admin :

```sql
IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.user_id = auth.uid() 
    AND profiles.role IN ('admin', 'super_admin')
) THEN
    RAISE EXCEPTION 'Accès refusé';
END IF;
```

---

## 🎯 Résultat attendu

### Avant
```
UTILISATEUR | EMAIL | RÔLE
------------|-------|------
kd          |       | admin
azerty      |       | user
David Kodjo |       | admin
```

### Après
```
UTILISATEUR | EMAIL                    | RÔLE
------------|--------------------------|------
kd          | agbeviade2017@gmail.com | admin
azerty      | azerty@example.com      | user
David Kodjo | david@example.com       | admin
```

---

## 🚀 Déploiement

1. **Exécuter le script SQL**
   ```sql
   -- Dans Supabase SQL Editor
   -- Copier/coller le contenu de fix_dashboard_emails.sql
   ```

2. **Recharger le dashboard**
   ```bash
   # Pas besoin de redémarrer le serveur
   # Juste recharger la page dans le navigateur
   ```

3. **Vérifier**
   - Aller sur la page "Utilisateurs"
   - Les emails doivent s'afficher
   - La recherche par email doit fonctionner

---

## 🐛 Dépannage

### Erreur : "function get_all_users_with_emails() does not exist"
**Solution :** Exécutez `fix_dashboard_emails.sql`

### Erreur : "Accès refusé"
**Solution :** Vérifiez que vous êtes connecté en tant qu'admin/super_admin

### Les emails sont toujours vides
**Solution :** 
1. Vérifiez que les utilisateurs ont bien un email dans `auth.users`
2. Testez la fonction directement dans SQL Editor
3. Vérifiez les logs du dashboard (F12 → Console)

---

## 📝 Notes

- Cette fonction est également utilisée par l'écran de validation des membres Flutter
- Elle respecte les RLS policies de Supabase
- Elle est optimisée avec un LEFT JOIN pour éviter les erreurs si un profil n'a pas d'utilisateur auth correspondant

---

**Date :** 19 novembre 2025  
**Version :** 1.0  
**Auteur :** Cascade AI Assistant

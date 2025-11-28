# 🚨 FIX URGENT : Profils manquants

## ❌ PROBLÈME

```
code: "23503"
message: "insert or update on table \"user_permissions\" violates foreign key constraint"
details: "Key is not present in table \"profiles\"."
```

**Cause:** Des utilisateurs existent dans `auth.users` mais pas dans `profiles`.

---

## ✅ SOLUTION EN 3 ÉTAPES (5 minutes)

### **ÉTAPE 1: Identifier le problème**

**Dans la console du navigateur (F12), regardez les logs:**
```
❌ Utilisateur introuvable dans profiles: abc-123-xyz-456
```

**Notez le `user_id` affiché.**

---

### **ÉTAPE 2: Exécuter le script de correction**

1. **Ouvrez Supabase SQL Editor**
   - https://supabase.com/dashboard → Votre projet → SQL Editor

2. **Copiez TOUT le contenu de `FIX_PROFILES_MANQUANTS.sql`**

3. **Collez et cliquez sur "Run"**

**Le script va:**
- ✅ Identifier les utilisateurs sans profil
- ✅ Créer automatiquement les profils manquants
- ✅ Nettoyer les permissions orphelines
- ✅ Afficher un rapport complet

---

### **ÉTAPE 3: Vérifier les résultats**

**Vous devriez voir:**

```
🔍 DIAGNOSTIC: Utilisateurs dans auth.users mais pas dans profiles
| user_id | email | status |
|---------|-------|--------|
| abc-123 | user@example.com | ❌ Profil manquant |

🔧 CORRECTION: Création des profils manquants
✅ 1 profil créé

📊 VÉRIFICATION FINALE
| table_name | count |
|------------|-------|
| auth.users | 3 |
| profiles   | 3 |
| user_permissions | 2 |

✅ Script terminé avec succès !
```

---

## 🧪 TESTER APRÈS CORRECTION

### **1. Recharger le dashboard**
```
http://localhost:3000/dashboard/permissions
```

### **2. Essayer d'attribuer une permission**
1. Cliquez sur ❌ pour activer une permission
2. Regardez la console (F12)

**Résultat attendu:**
```
🔍 Toggle permission: { userId: "abc-123", ... }
✅ Utilisateur trouvé: Jean Dupont
✅ Permission attribuée
```

### **3. Vérifier que la permission est bien attribuée**
- ✅ L'icône devient ✅ (verte)
- ✅ Pas d'erreur dans la console
- ✅ La liste se rafraîchit

---

## 🔍 COMPRENDRE LE PROBLÈME

### **Pourquoi ça arrive ?**

**Scénario 1: Inscription incomplète**
```
1. Utilisateur s'inscrit (créé dans auth.users)
2. Erreur avant la création du profil
3. Profil jamais créé dans profiles
```

**Scénario 2: Suppression partielle**
```
1. Profil supprimé de profiles
2. Utilisateur reste dans auth.users
3. Permissions orphelines
```

**Scénario 3: Migration de données**
```
1. Données importées dans auth.users
2. Profils pas créés automatiquement
```

---

## 🛡️ PRÉVENTION FUTURE

### **Trigger automatique (Optionnel)**

Créer un trigger qui crée automatiquement un profil quand un utilisateur s'inscrit:

```sql
-- Fonction trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name, role, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
    'membre',
    NEW.created_at
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

**Avantage:** Plus jamais de profils manquants !

---

## 📊 VÉRIFICATIONS RÉGULIÈRES

### **Script de monitoring (à exécuter régulièrement):**

```sql
-- Vérifier l'intégrité des données
SELECT 
    'Utilisateurs sans profil' as check_type,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ OK'
        ELSE '❌ Action requise'
    END as status
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
WHERE p.user_id IS NULL

UNION ALL

SELECT 
    'Permissions orphelines' as check_type,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ OK'
        ELSE '❌ Action requise'
    END as status
FROM user_permissions up
LEFT JOIN profiles p ON up.user_id = p.user_id
WHERE p.user_id IS NULL;
```

---

## 🎯 RÉSUMÉ

### **Problème:**
- ❌ Utilisateurs dans `auth.users` mais pas dans `profiles`
- ❌ Impossible d'attribuer des permissions

### **Solution:**
1. ✅ Exécuter `FIX_PROFILES_MANQUANTS.sql`
2. ✅ Profils créés automatiquement
3. ✅ Permissions orphelines nettoyées

### **Résultat:**
- ✅ Attribution de permissions fonctionne
- ✅ Tous les utilisateurs ont un profil
- ✅ Base de données cohérente

---

## 🚀 ACTION IMMÉDIATE

**Exécutez `FIX_PROFILES_MANQUANTS.sql` MAINTENANT !**

**Temps estimé:** 2 minutes ⏱️

**Le problème sera résolu définitivement ! 🎉**

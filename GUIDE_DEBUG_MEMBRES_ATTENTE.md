# 🔍 DEBUG : Nom et email non récupérés

## ❌ PROBLÈME

Les noms et emails des membres en attente ne s'affichent pas dans le dashboard.

**Causes possibles:**
1. Utilisateurs sans profil dans `profiles`
2. Champ `full_name` vide ou NULL
3. Problème de jointure avec `auth.users`

---

## ✅ SOLUTION RAPIDE

### **Exécutez ce script de diagnostic:**

**Fichier:** `DEBUG_MEMBRES_EN_ATTENTE.sql`

**Ce qu'il fait:**
1. ✅ Vérifie les utilisateurs en attente
2. ✅ Vérifie si les emails sont disponibles
3. ✅ Teste la vue `membres_en_attente`
4. ✅ **CORRIGE automatiquement** les noms manquants
5. ✅ **CRÉE** les profils manquants
6. ✅ Affiche un résumé

---

## 🧪 RÉSULTAT ATTENDU

Après exécution:

```
1️⃣ Utilisateurs en attente dans profiles
| user_id | full_name | statut_validation |
|---------|-----------|-------------------|
| abc-123 | Jean Dupont | en_attente |
| def-456 | NULL | en_attente | ❌

2️⃣ Vérification dans auth.users
| user_id | full_name | email | statut |
|---------|-----------|-------|--------|
| abc-123 | Jean Dupont | jean@example.com | ✅ Email trouvé |
| def-456 | NULL | marie@example.com | ✅ Email trouvé |

🔧 CORRECTION : Mise à jour des noms manquants
✅ 1 profil mis à jour

✅ Vérification après correction
| user_id | full_name | email | jours_attente |
|---------|-----------|-------|---------------|
| abc-123 | Jean Dupont | jean@example.com | 2 |
| def-456 | marie | marie@example.com | 1 |

📊 RÉSUMÉ FINAL
| total_en_attente | avec_nom | avec_email |
|------------------|----------|------------|
| 2 | 2 | 2 |

✅ Diagnostic et correction terminés
```

---

## 🎯 APRÈS L'EXÉCUTION

### **1. Rechargez le dashboard**
```
http://localhost:3000/dashboard/validation
```

### **2. Vérifiez que les noms et emails s'affichent**

**Résultat attendu:**
```
┌─────────────────────────────────────────────┐
│ Validation des membres                     │
├─────────────────────────────────────────────┤
│ 👤 Jean Dupont                             │
│ 📧 Email: jean@example.com                 │
│ ⏰ 2 jours d'attente                       │
│ [Valider] [Refuser]                        │
├─────────────────────────────────────────────┤
│ 👤 marie                                   │
│ 📧 Email: marie@example.com                │
│ ⏰ 1 jour d'attente                        │
│ [Valider] [Refuser]                        │
└─────────────────────────────────────────────┘
```

---

## 🔍 CE QUE LE SCRIPT CORRIGE

### **Problème 1: Noms manquants**
```sql
UPDATE profiles p
SET full_name = COALESCE(
    NULLIF(p.full_name, ''),           -- Garder le nom existant s'il existe
    au.raw_user_meta_data->>'full_name', -- Sinon prendre des métadonnées
    SPLIT_PART(au.email, '@', 1)       -- Sinon utiliser la partie avant @
)
```

**Exemple:**
- Email: `marie.dupont@example.com`
- Nom généré: `marie.dupont`

### **Problème 2: Profils manquants**
```sql
INSERT INTO profiles (user_id, full_name, role, statut_validation)
SELECT 
    au.id,
    SPLIT_PART(au.email, '@', 1),
    'membre',
    'en_attente'
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM profiles WHERE user_id = au.id)
```

---

## 📋 VÉRIFICATION MANUELLE

### **Vérifier la vue:**
```sql
SELECT * FROM membres_en_attente;
```

**Colonnes attendues:**
- `user_id` ✅
- `email` ✅ (depuis auth.users)
- `full_name` ✅ (depuis profiles)
- `telephone` ✅
- `jours_attente` ✅

### **Vérifier un utilisateur spécifique:**
```sql
SELECT 
    p.user_id,
    p.full_name,
    au.email,
    p.statut_validation
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE au.email = 'EMAIL_ICI@example.com';
```

---

## 🎯 RÉSUMÉ

**Problème:**
- ❌ Noms et emails non affichés
- ❌ Profils manquants ou incomplets

**Solution:**
- ✅ Exécuter `DEBUG_MEMBRES_EN_ATTENTE.sql`
- ✅ Correction automatique des noms
- ✅ Création des profils manquants

**Résultat:**
- ✅ Tous les membres ont un nom
- ✅ Tous les emails sont affichés
- ✅ Dashboard fonctionnel

---

**Exécutez `DEBUG_MEMBRES_EN_ATTENTE.sql` MAINTENANT ! 🚀**

**Temps:** 1 minute ⏱️

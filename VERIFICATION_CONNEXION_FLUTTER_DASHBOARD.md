# 🔗 VÉRIFICATION : Connexion Flutter ↔ Dashboard

## 📊 FLUX COMPLET

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUX D'INSCRIPTION                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. FLUTTER APP                                                 │
│     └─> RegisterScreen                                         │
│         └─> AuthNotifier.signUp()                              │
│             └─> EnhancedAuthService.signUp()                   │
│                 └─> Supabase.auth.signUp()                     │
│                     │                                           │
│                     ├─> auth.users (créé)                      │
│                     │   └─> Trigger: on_auth_user_created      │
│                     │       └─> profiles (créé)                │
│                     │           ├─> statut_validation='en_attente' │
│                     │           ├─> role='membre'              │
│                     │           └─> full_name (depuis metadata) │
│                     │                                           │
│                     └─> Session sauvegardée dans Hive          │
│                                                                 │
│  2. BASE DE DONNÉES (Supabase)                                 │
│     ├─> auth.users (table)                                     │
│     │   ├─> id (UUID)                                          │
│     │   ├─> email                                              │
│     │   ├─> encrypted_password                                 │
│     │   └─> raw_user_meta_data (full_name)                    │
│     │                                                           │
│     └─> profiles (table)                                       │
│         ├─> user_id (FK → auth.users.id)                      │
│         ├─> full_name                                          │
│         ├─> email (NULL - pas stocké ici)                     │
│         ├─> role = 'membre'                                    │
│         ├─> statut_validation = 'en_attente'                  │
│         └─> chorale_id = NULL                                  │
│                                                                 │
│  3. VUE SQL                                                     │
│     └─> membres_en_attente (view)                             │
│         ├─> JOIN profiles + auth.users                        │
│         ├─> Récupère email depuis auth.users                  │
│         ├─> Filtre: statut_validation='en_attente'           │
│         └─> Visible uniquement par admins                     │
│                                                                 │
│  4. DASHBOARD WEB                                               │
│     └─> ValidationPage                                         │
│         └─> SELECT * FROM membres_en_attente                  │
│             └─> Affiche:                                       │
│                 ├─> full_name                                  │
│                 ├─> email (depuis auth.users)                 │
│                 ├─> telephone                                  │
│                 ├─> jours_attente                             │
│                 └─> Boutons: Valider / Refuser                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✅ POINTS DE CONNEXION VÉRIFIÉS

### **1. Flutter → Supabase Auth**

**Code Flutter:**
```dart
// lib/services/enhanced_auth_service.dart (ligne 163-169)
final response = await _supabase.auth.signUp(
  email: email,
  password: password,
  data: {
    'full_name': fullName,  // ✅ Métadonnées envoyées
  },
);
```

**✅ CONNEXION OK:**
- Email et password envoyés à Supabase Auth
- `full_name` envoyé dans `raw_user_meta_data`
- Compte créé dans `auth.users`

---

### **2. Supabase Auth → Trigger SQL**

**Trigger SQL:**
```sql
-- Devrait exister dans Supabase
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

**Fonction trigger:**
```sql
CREATE FUNCTION handle_new_user()
AS $$
BEGIN
  INSERT INTO profiles (
    user_id,
    full_name,  -- ✅ Depuis NEW.raw_user_meta_data->>'full_name'
    role,       -- ✅ Forcé à 'membre'
    statut_validation,  -- ✅ Forcé à 'en_attente'
    statut_membre,      -- ✅ Forcé à 'inactif'
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
    'membre',
    'en_attente',
    'inactif'
  );
END;
$$;
```

**✅ CONNEXION OK:**
- Trigger se déclenche automatiquement
- Profil créé dans `profiles`
- `full_name` récupéré depuis métadonnées

---

### **3. Profiles → Vue membres_en_attente**

**Vue SQL:**
```sql
CREATE VIEW membres_en_attente AS
SELECT 
    p.user_id,
    au.email::TEXT,              -- ✅ Email depuis auth.users
    p.full_name,                 -- ✅ Nom depuis profiles
    p.telephone,
    p.created_at,
    p.statut_validation,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER as jours_attente
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id  -- ✅ JOIN
WHERE p.statut_validation = 'en_attente'
ORDER BY p.created_at ASC;
```

**✅ CONNEXION OK:**
- `LEFT JOIN` entre `profiles` et `auth.users`
- Email récupéré depuis `auth.users`
- Nom récupéré depuis `profiles`
- Filtre sur `statut_validation = 'en_attente'`

---

### **4. Vue → Dashboard Web**

**Code Dashboard:**
```typescript
// app/dashboard/validation/page.tsx (ligne 32-35)
const { data, error } = await supabase
  .from('membres_en_attente')  // ✅ Requête sur la vue
  .select('*')
  .order('created_at', { ascending: false })
```

**Affichage:**
```typescript
// ligne 146-156
<h3>{member.full_name}</h3>       {/* ✅ Nom affiché */}
<p>📧 Email: {member.email}</p>   {/* ✅ Email affiché */}
<p>📱 Téléphone: {member.telephone}</p>  {/* ✅ Si existe */}
```

**✅ CONNEXION OK:**
- Dashboard interroge la vue `membres_en_attente`
- Affiche `full_name` et `email`
- Affiche le nombre de jours d'attente

---

## 🔍 VÉRIFICATIONS À EFFECTUER

### **Test 1 : Vérifier le trigger existe**

```sql
-- Exécuter dans Supabase SQL Editor
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
```

**Résultat attendu:**
```
trigger_name: on_auth_user_created
event_manipulation: INSERT
event_object_table: users
action_statement: EXECUTE FUNCTION public.handle_new_user()
```

**Si vide:** ❌ Le trigger n'existe pas !

---

### **Test 2 : Vérifier la fonction handle_new_user**

```sql
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
AND routine_schema = 'public';
```

**Résultat attendu:**
```
routine_name: handle_new_user
routine_definition: [code de la fonction]
```

**Si vide:** ❌ La fonction n'existe pas !

---

### **Test 3 : Vérifier la vue membres_en_attente**

```sql
SELECT 
    table_name,
    view_definition
FROM information_schema.views
WHERE table_name = 'membres_en_attente';
```

**Résultat attendu:**
```
table_name: membres_en_attente
view_definition: [SQL de la vue avec LEFT JOIN]
```

**Si vide:** ❌ La vue n'existe pas !

---

### **Test 4 : Test d'inscription complet**

```bash
# 1. Dans Flutter App
# S'inscrire avec:
Email: test@example.com
Nom: Test User
Password: Test123!

# 2. Vérifier dans Supabase SQL Editor
SELECT 
    au.email,
    p.full_name,
    p.role,
    p.statut_validation
FROM auth.users au
JOIN profiles p ON p.user_id = au.id
WHERE au.email = 'test@example.com';
```

**Résultat attendu:**
```
email: test@example.com
full_name: Test User
role: membre
statut_validation: en_attente
```

---

### **Test 5 : Vérifier dans le dashboard**

```bash
# 1. Ouvrir http://localhost:3000/dashboard/validation
# 2. Se connecter en tant que super_admin
# 3. Vérifier que "Test User" apparaît dans la liste
```

**Résultat attendu:**
```
✅ Nom: Test User
✅ Email: test@example.com
✅ Jours d'attente: 0
✅ Boutons: Valider / Refuser
```

---

## 🚨 PROBLÈMES POSSIBLES

### **Problème 1 : Trigger n'existe pas**

**Symptôme:**
- Inscription réussie dans Flutter
- Compte créé dans `auth.users`
- ❌ MAIS pas de profil dans `profiles`
- ❌ Dashboard ne montre rien

**Solution:**
```sql
-- Créer le trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

---

### **Problème 2 : Vue n'existe pas**

**Symptôme:**
- Profil créé correctement
- ❌ Dashboard affiche erreur "relation membres_en_attente does not exist"

**Solution:**
```sql
-- Créer la vue
CREATE VIEW membres_en_attente AS
SELECT 
    p.user_id,
    au.email::TEXT,
    p.full_name,
    p.telephone,
    p.created_at,
    p.statut_validation,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER as jours_attente
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
ORDER BY p.created_at ASC;

GRANT SELECT ON membres_en_attente TO authenticated;
```

---

### **Problème 3 : Email NULL dans dashboard**

**Symptôme:**
- Nom affiché correctement
- ❌ Email vide ou NULL

**Cause:**
- Vue utilise `JOIN` au lieu de `LEFT JOIN`
- Ou email pas dans `auth.users`

**Solution:**
```sql
-- Vérifier l'email
SELECT id, email FROM auth.users WHERE email = 'test@example.com';

-- Si email existe, recréer la vue avec LEFT JOIN
DROP VIEW IF EXISTS membres_en_attente;
CREATE VIEW membres_en_attente AS
SELECT 
    p.user_id,
    COALESCE(au.email::TEXT, 'email@manquant.com') as email,  -- ✅ COALESCE
    p.full_name,
    ...
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id  -- ✅ LEFT JOIN
WHERE p.statut_validation = 'en_attente';
```

---

### **Problème 4 : Nom "Utilisateur" générique**

**Symptôme:**
- Email affiché correctement
- ❌ Nom affiché: "Utilisateur" ou "Utilisateur_abc123"

**Cause:**
- `full_name` pas envoyé dans métadonnées
- Ou trigger utilise le fallback

**Solution:**
```dart
// Vérifier dans Flutter
data: {
  'full_name': fullName,  // ✅ Bien envoyé
}

// Vérifier dans SQL
SELECT raw_user_meta_data FROM auth.users WHERE email = 'test@example.com';
-- Devrait contenir: {"full_name": "Test User"}
```

---

## 📊 CHECKLIST DE VÉRIFICATION

- [ ] ✅ Trigger `on_auth_user_created` existe
- [ ] ✅ Fonction `handle_new_user()` existe
- [ ] ✅ Vue `membres_en_attente` existe
- [ ] ✅ Permissions `GRANT SELECT` sur la vue
- [ ] ✅ Test inscription Flutter réussie
- [ ] ✅ Profil créé dans `profiles`
- [ ] ✅ Email récupéré depuis `auth.users`
- [ ] ✅ Nom affiché correctement dans dashboard
- [ ] ✅ Email affiché correctement dans dashboard
- [ ] ✅ Jours d'attente calculés correctement

---

## 🎯 RÉSUMÉ

**CONNEXION FLUTTER → DASHBOARD:**

1. ✅ Flutter envoie `email`, `password`, `full_name`
2. ✅ Supabase Auth crée compte dans `auth.users`
3. ✅ Trigger crée profil dans `profiles`
4. ✅ Vue `membres_en_attente` JOIN les deux tables
5. ✅ Dashboard affiche les données

**POINTS CRITIQUES:**
- Trigger doit exister et fonctionner
- Vue doit utiliser `LEFT JOIN`
- Email vient de `auth.users`
- Nom vient de `profiles`

**SI PROBLÈME:**
- Exécuter les tests SQL ci-dessus
- Vérifier les logs Flutter
- Vérifier les logs Dashboard (console F12)
- Exécuter `FIX_ROOT_INSCRIPTION_VALIDATION.sql` si nécessaire

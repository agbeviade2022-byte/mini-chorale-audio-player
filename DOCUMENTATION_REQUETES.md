# 📊 DOCUMENTATION COMPLÈTE : Requêtes Flutter ↔ Dashboard ↔ BDD

## 🎯 OBJECTIF
Documenter toutes les requêtes SQL et vérifier la cohérence entre Flutter, Dashboard et la base de données.

---

## 📱 FLUTTER - Requêtes Supabase

### **1. AUTHENTIFICATION (`enhanced_auth_service.dart`)**

#### Login
```dart
// Ligne 79
final profile = await getUserProfile();

// Ligne 305
.from('profiles')
.select()
.eq('user_id', currentUser!.id)  // ✅ CORRIGÉ
.maybeSingle()
```

**Type attendu:** `user_id` = UUID (auth.users.id)

---

### **2. PERMISSIONS (`permissions_service.dart`)**

#### Récupérer permissions utilisateur
```dart
// Ligne 16
.from('profiles')
.select('id, role')
.eq('user_id', userId)  // ✅ user_id = UUID
.single()

// Ligne 34
.rpc('get_user_permissions', params: {'check_user_id': profileId})
```

**Type attendu:** 
- `user_id` = UUID (auth.users.id)
- `profileId` = INTEGER (profiles.id)

#### Récupérer rôle
```dart
// Ligne 89
.from('profiles')
.select('role')
.eq('user_id', userId)  // ✅ user_id = UUID
.single()
```

---

### **3. CHORALES (`chorale_service.dart`)**

#### Récupérer toutes les chorales
```dart
// Ligne 10-14
.from('chorales')
.select()
.eq('statut', 'actif')  // ⚠️ FILTRE: seulement actives
.order('nom', ascending: true)
```

**Type attendu:** `chorales.id` = UUID ou String

#### Récupérer chorale par ID
```dart
// Ligne 31
.from('chorales')
.select()
.eq('id', id)  // ✅ id = String (converti depuis UUID)
.maybeSingle()
```

#### Compter membres d'une chorale
```dart
// Ligne 128
.from('profiles')
.select('id')
.eq('chorale_id', choraleId)  // ✅ chorale_id = String
.count()
```

---

### **4. CHANTS (`supabase_chants_service.dart`)**

#### Récupérer chant par ID
```dart
// Ligne 57
.from('chants')
.select()
.eq('id', id)  // ✅ id = String (UUID)
.single()
```

#### Mettre à jour chant
```dart
// Ligne 118
.from('chants')
.update(updates)
.eq('id', id)  // ✅ id = String (UUID)
.select()
.single()
```

---

### **5. SYNC (`sync_service.dart`)**

#### Synchroniser profil
```dart
// Ligne 214
.from('profiles')
.select()
.eq('user_id', session.userId)  // ✅ CORRIGÉ: user_id = UUID
.single()

// Ligne 271
.from('profiles')
.select()
.eq('user_id', session.userId)  // ✅ CORRIGÉ: user_id = UUID
.maybeSingle()
```

---

## 🌐 DASHBOARD - Requêtes Supabase (Next.js)

### **1. VALIDATION (`app/dashboard/validation/page.tsx`)**

#### Récupérer membres en attente
```typescript
// Ligne 33 - NOUVEAU
const { data } = await supabase.rpc('get_membres_en_attente')
```

**Type retourné:**
- `user_id` = UUID (auth.users.id)
- `email` = TEXT
- `full_name` = TEXT
- `statut_validation` = TEXT

---

### **2. CHORALES (`app/dashboard/chorales/page.tsx`)**

#### Récupérer toutes les chorales
```typescript
// Ligne 26-28
.from('chorales')
.select('*')
.order('created_at', { ascending: false })  // ⚠️ DIFFÉRENT de Flutter
```

**Différence avec Flutter:**
- Dashboard: Affiche TOUTES les chorales
- Flutter: Filtre par `statut='actif'`

#### Compter membres par chorale
```typescript
// Ligne 38-39
.from('profiles')
.select('id', { count: 'exact', head: true })
.eq('chorale_id', chorale.id)  // ✅ chorale.id
```

---

### **3. CHANTS (`app/dashboard/chants/page.tsx`)**

#### Récupérer chants
```typescript
// Ligne 30-56 - CORRIGÉ
// Deux requêtes séparées puis jointure en mémoire
const { data: chantsData } = await supabase
  .from('chants')
  .select('*')

const { data: choralesData } = await supabase
  .from('chorales')
  .select('id, nom')
```

**Raison:** Contournement du problème de foreign key non reconnue

---

### **4. PERMISSIONS (`app/dashboard/permissions/page.tsx`)**

#### Récupérer utilisateurs avec permissions
```typescript
// Récupère tous les profils
.from('profiles')
.select('*')

// Pour chaque utilisateur, récupère ses permissions
.from('user_permissions')
.select('module_code')
.eq('user_id', user.user_id)  // ⚠️ ATTENTION: user.user_id (pas user.id)
```

**Type attendu:** `user_id` = UUID (auth.users.id)

---

## 🗄️ BASE DE DONNÉES - Structure

### **1. TABLE `profiles`**

```sql
id              INTEGER (PK, auto-increment)
user_id         UUID (FK → auth.users.id) UNIQUE
full_name       VARCHAR(255)
email           VARCHAR(255)  -- ⚠️ Peut être NULL
role            VARCHAR(50)   -- 'super_admin', 'admin', 'membre'
statut_validation VARCHAR(50) -- 'en_attente', 'valide', 'refuse'
chorale_id      UUID (FK → chorales.id)
telephone       VARCHAR(50)
created_at      TIMESTAMP
updated_at      TIMESTAMP
```

**Clés importantes:**
- `id` = INTEGER (utilisé dans `user_permissions.user_id`)
- `user_id` = UUID (lien avec `auth.users.id`)
- `chorale_id` = UUID (lien avec `chorales.id`)

---

### **2. TABLE `chorales`**

```sql
id              UUID (PK)
nom             VARCHAR(255)
slug            VARCHAR(255) UNIQUE
description     TEXT
statut          VARCHAR(50)  -- 'actif', 'inactif'
created_at      TIMESTAMP
updated_at      TIMESTAMP
```

**Type d'ID:** UUID (compatible String en Flutter/TypeScript)

---

### **3. TABLE `chants`**

```sql
id              UUID (PK)
titre           VARCHAR(255)
chorale_id      UUID (FK → chorales.id)
auteur          VARCHAR(255)
duree           INTEGER
created_at      TIMESTAMP
```

**Type d'ID:** UUID

---

### **4. TABLE `user_permissions`**

```sql
id              INTEGER (PK, auto-increment)
user_id         INTEGER (FK → profiles.id)  -- ⚠️ profiles.id, PAS user_id
module_code     VARCHAR(50) (FK → modules_permissions.code)
attribue_le     TIMESTAMP
expire_le       TIMESTAMP
```

**IMPORTANT:** `user_id` ici = `profiles.id` (INTEGER), pas `auth.users.id` (UUID)

---

### **5. TABLE `auth.users` (Supabase Auth)**

```sql
id              UUID (PK)
email           VARCHAR(255)
email_confirmed_at TIMESTAMP
created_at      TIMESTAMP
deleted_at      TIMESTAMP
```

---

## 🔗 RELATIONS ET COHÉRENCE

### **1. Profiles ↔ Auth.users**

```
auth.users.id (UUID) ←→ profiles.user_id (UUID)
```

**Requêtes Flutter:**
```dart
.eq('user_id', currentUser!.id)  // ✅ CORRECT
```

**Requêtes Dashboard:**
```typescript
.eq('user_id', user.user_id)  // ✅ CORRECT
```

---

### **2. Profiles ↔ Chorales**

```
chorales.id (UUID) ←→ profiles.chorale_id (UUID)
```

**Requêtes Flutter:**
```dart
.eq('chorale_id', choraleId)  // ✅ String (UUID)
```

**Requêtes Dashboard:**
```typescript
.eq('chorale_id', chorale.id)  // ✅ UUID
```

---

### **3. User_permissions ↔ Profiles**

```
profiles.id (INTEGER) ←→ user_permissions.user_id (INTEGER)
```

**⚠️ ATTENTION:** Ici `user_id` = `profiles.id` (INTEGER), pas `auth.users.id` (UUID)

**Requêtes Flutter:**
```dart
// Récupère d'abord profiles.id
const profileId = profileResponse['id'];  // INTEGER

// Puis utilise dans RPC
.rpc('get_user_permissions', params: {'check_user_id': profileId})
```

---

## ⚠️ INCOHÉRENCES DÉTECTÉES

### **1. ❌ CRITIQUE: Profils sans `user_id`**

**Problème:** Des profils existent avec `user_id = NULL`

**Impact:**
- Impossible de récupérer le profil depuis Flutter
- Impossible de valider l'utilisateur
- Crée des doublons à chaque connexion

**Solution:**
```sql
DELETE FROM profiles WHERE user_id IS NULL;
```

---

### **2. ⚠️ ATTENTION: Filtrage différent chorales**

**Flutter:**
```dart
.eq('statut', 'actif')  // Seulement chorales actives
```

**Dashboard:**
```typescript
// Pas de filtre - Affiche toutes les chorales
```

**Impact:** Les listes peuvent être différentes

**Solution:** Décider si le dashboard doit aussi filtrer par statut

---

### **3. ⚠️ ATTENTION: Tri différent chorales**

**Flutter:**
```dart
.order('nom', ascending: true)  // Tri par nom
```

**Dashboard:**
```typescript
.order('created_at', { ascending: false })  // Tri par date
```

**Impact:** Ordre différent dans les listes

---

### **4. ⚠️ ATTENTION: Confusion `user_id`**

**Deux significations différentes:**

1. **`profiles.user_id`** = UUID (auth.users.id)
2. **`user_permissions.user_id`** = INTEGER (profiles.id)

**Solution:** Renommer `user_permissions.user_id` en `profile_id` pour clarté

---

## ✅ POINTS POSITIFS

1. ✅ Correction `.eq('user_id', ...)` dans `enhanced_auth_service.dart`
2. ✅ Correction `.eq('user_id', ...)` dans `sync_service.dart`
3. ✅ Utilisation correcte des UUID pour chorales et chants
4. ✅ RPC `get_membres_en_attente()` avec filtres corrects
5. ✅ Permissions chargées correctement (16 permissions)

---

## 🔧 RECOMMANDATIONS

### **1. Nettoyage urgent**
```sql
-- Supprimer profils orphelins
DELETE FROM profiles WHERE user_id IS NULL;

-- Vérifier doublons
SELECT user_id, COUNT(*) 
FROM profiles 
GROUP BY user_id 
HAVING COUNT(*) > 1;
```

### **2. Harmoniser les requêtes**
- Dashboard devrait aussi filtrer par `statut='actif'`
- Ou Flutter devrait afficher toutes les chorales

### **3. Renommer pour clarté**
```sql
-- Renommer user_permissions.user_id en profile_id
ALTER TABLE user_permissions 
RENAME COLUMN user_id TO profile_id;
```

### **4. Ajouter contraintes FK manquantes**
```sql
-- Vérifier que toutes les FK existent
-- profiles.chorale_id → chorales.id
-- chants.chorale_id → chorales.id
-- user_permissions.user_id → profiles.id
```

---

## 📋 CHECKLIST DE VÉRIFICATION

- [ ] Exécuter `AUDIT_COMPLET_COHERENCE.sql`
- [ ] Vérifier les alertes critiques
- [ ] Supprimer les profils sans `user_id`
- [ ] Vérifier les doublons de `user_id`
- [ ] Harmoniser le filtrage des chorales
- [ ] Documenter la différence `user_id` vs `profile_id`
- [ ] Tester le flux complet Flutter → Dashboard
- [ ] Vérifier que les IDs sont cohérents

---

**Date de création:** 2025-11-21
**Auteur:** Cascade AI
**Version:** 1.0

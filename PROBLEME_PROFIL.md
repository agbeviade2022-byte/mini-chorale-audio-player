# 🔧 Problème de profil - Solution

## ❌ Le problème

Vous vous êtes inscrit avec **kodjodavid2025@gmail.com** mais l'app vous connecte à un autre profil.

## 🔍 Causes possibles

1. **Session Hive persistante** - Une ancienne session est encore en cache
2. **Profil non créé** - Le profil n'a pas été créé automatiquement
3. **Plusieurs comptes** - Il y a plusieurs comptes dans la base
4. **Bug de synchronisation** - Problème entre auth.users et profiles

## ✅ Solutions

### Solution 1: Se déconnecter et vider le cache (RAPIDE) ⚡

**Dans l'application:**

1. **Se déconnecter**
   - Cliquer sur le bouton de déconnexion
   - Ou aller dans Paramètres → Déconnexion

2. **Fermer complètement l'app**
   - Fermer l'app
   - Arrêter le processus Flutter

3. **Vider le cache Hive** (optionnel mais recommandé)
   
   Ajouter ce code temporaire dans votre `main.dart`:
   
   ```dart
   // TEMPORAIRE - Pour vider le cache Hive
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     // Vider le cache Hive
     await Hive.initFlutter();
     await Hive.deleteBoxFromDisk('session');
     await Hive.deleteBoxFromDisk('settings');
     
     // Continuer normalement...
     late HiveSessionService hiveSessionService;
     await hiveSessionService.initialize();
     // ...
   }
   ```

4. **Relancer l'app**
   ```bash
   flutter run
   ```

5. **Se reconnecter**
   - Email: kodjodavid2025@gmail.com
   - Mot de passe: votre_mot_de_passe

---

### Solution 2: Vérifier et corriger le profil dans Supabase 🔧

**Étape 1: Diagnostiquer**

Exécuter `verifier_compte.sql` dans Supabase SQL Editor:

```sql
-- Voir tous les comptes
SELECT id, email, created_at FROM auth.users;

-- Voir tous les profils
SELECT id, email, full_name FROM profiles;
```

**Étape 2: Corriger le profil**

Exécuter `fix_profil.sql` dans Supabase SQL Editor:

Ce script va:
- ✅ Vérifier si votre profil existe
- ✅ Créer le profil si manquant
- ✅ Mettre à jour le profil si existant
- ✅ Vérifier la correspondance auth.users ↔ profiles

**Étape 3: Se reconnecter**

Dans l'app:
1. Se déconnecter
2. Se reconnecter avec kodjodavid2025@gmail.com

---

### Solution 3: Supprimer les anciens comptes (si nécessaire) 🗑️

**Si vous avez plusieurs comptes de test:**

```sql
-- Voir tous les comptes
SELECT id, email, created_at FROM auth.users;

-- Supprimer un compte spécifique (ATTENTION!)
-- Remplacer 'ancien_email@example.com' par l'email à supprimer
DELETE FROM auth.users WHERE email = 'ancien_email@example.com';
```

**⚠️ ATTENTION:** Ne supprimez PAS kodjodavid2025@gmail.com !

---

### Solution 4: Vérifier le code de l'app 🔍

**Vérifier que l'app utilise bien le bon user:**

Dans votre code, vérifiez:

```dart
// Dans auth_provider.dart ou enhanced_auth_service.dart
final currentUser = Supabase.instance.client.auth.currentUser;
print('🔍 User connecté: ${currentUser?.email}');
print('🔍 User ID: ${currentUser?.id}');

// Vérifier le profil chargé
final profile = await Supabase.instance.client
    .from('profiles')
    .select()
    .eq('id', currentUser!.id)
    .single();
print('🔍 Profil: ${profile}');
```

---

## 🧪 Tests après correction

### Test 1: Vérifier l'utilisateur connecté

Dans l'app, ajouter un print temporaire:

```dart
// Dans votre HomeScreen ou après connexion
final user = Supabase.instance.client.auth.currentUser;
print('✅ Connecté en tant que: ${user?.email}');
print('✅ User ID: ${user?.id}');
```

### Test 2: Vérifier le profil chargé

```dart
final profile = await Supabase.instance.client
    .from('profiles')
    .select()
    .eq('id', user!.id)
    .single();
print('✅ Profil: ${profile['email']} - ${profile['full_name']}');
```

### Test 3: Vérifier Hive

```dart
final session = await hiveSessionService.getSession();
print('✅ Session Hive: ${session?.email}');
```

---

## 📋 Checklist de débogage

- [ ] Se déconnecter de l'app
- [ ] Fermer complètement l'app
- [ ] Exécuter `verifier_compte.sql` dans Supabase
- [ ] Vérifier que kodjodavid2025@gmail.com existe dans auth.users
- [ ] Exécuter `fix_profil.sql` pour créer/corriger le profil
- [ ] Vider le cache Hive (optionnel)
- [ ] Relancer l'app
- [ ] Se reconnecter avec kodjodavid2025@gmail.com
- [ ] Vérifier les logs (email connecté)
- [ ] Vérifier que le bon profil s'affiche

---

## 🎯 Solution rapide (TL;DR)

**Méthode la plus simple:**

1. **Dans l'app:** Se déconnecter
2. **Supabase SQL Editor:** Exécuter `fix_profil.sql`
3. **Dans l'app:** Se reconnecter avec kodjodavid2025@gmail.com
4. **Vérifier:** Le bon profil s'affiche

**Si ça ne marche pas:**

1. Fermer l'app
2. Vider le cache Hive (code dans Solution 1)
3. Relancer et se reconnecter

---

## 📚 Fichiers créés

1. **`verifier_compte.sql`** - Diagnostiquer le problème
2. **`fix_profil.sql`** - Corriger le profil
3. **`PROBLEME_PROFIL.md`** - Ce guide

**Exécutez d'abord `verifier_compte.sql` pour voir ce qui se passe !** 🔍

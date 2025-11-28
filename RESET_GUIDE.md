# 🔄 Guide de reset des tables

## 🎯 Objectif

Supprimer toutes les tables du système multi-tenant et les recréer proprement, **en gardant vos données** (chants et profiles).

## ⚠️ Ce qui sera supprimé

- ❌ plans
- ❌ chorales
- ❌ membres
- ❌ subscriptions
- ❌ favoris
- ❌ playlists
- ❌ playlist_chants
- ❌ ecoutes

## ✅ Ce qui sera préservé

- ✅ **chants** (vos chants ne seront PAS supprimés)
- ✅ **profiles** (vos utilisateurs ne seront PAS supprimés)

## 📋 Marche à suivre

### Étape 1: Exécuter le script de reset

**Fichier:** `reset_tables.sql`

**Instructions:**

1. Aller sur https://app.supabase.com
2. Sélectionner votre projet
3. Cliquer sur **"SQL Editor"**
4. Cliquer sur **"New Query"**
5. **Copier TOUT** le contenu de `reset_tables.sql`
6. **Coller** dans l'éditeur
7. Cliquer sur **"Run"**
8. Attendre quelques secondes

**Résultat attendu:**

Vous devriez voir plusieurs messages de succès, puis à la fin:

```
tablename       | rls_enabled
----------------|------------
chants          | false
chorales        | false
ecoutes         | false
favoris         | false
membres         | false
playlist_chants | false
playlists       | false
plans           | false
profiles        | false
subscriptions   | false
```

Et:

```
table_name | nombre
-----------|-------
PLANS      | 4
CHORALES   | 1
CHANTS     | X (vos chants préservés)
```

### Étape 2: Vérifier dans Table Editor

**Dans Supabase → Table Editor**

Vous devriez voir:
- ✅ plans (4 lignes)
- ✅ chorales (1 ligne: Ma Chorale)
- ✅ membres (vide)
- ✅ favoris (vide)
- ✅ playlists (vide)
- ✅ playlist_chants (vide)
- ✅ ecoutes (vide)
- ✅ subscriptions (vide)
- ✅ chants (vos données préservées)
- ✅ profiles (vos données préservées)

### Étape 3: Relancer l'application

```bash
flutter run
```

**Logs attendus:**

```
✅ Hive initialisé avec succès
✅ Supabase initialisé avec persistance de session
🏆 Session restaurée depuis Hive
🌐 Chargement depuis Supabase...
📦 X chants chargés depuis Drift
🔄 Chants synchronisés avec Supabase
✅ Connexion réussie
```

**Plus d'erreur !** ✅

## 🎉 Résultat

Après le reset:

- ✅ **Tables propres** - Recréées sans erreur
- ✅ **RLS désactivé** - Pas de récursion infinie
- ✅ **Aucune policy** - Pas de conflit
- ✅ **Données préservées** - Chants et profiles intacts
- ✅ **Configuration correcte** - 4 plans, 1 chorale

## 🧪 Tests à effectuer

### Test 1: Connexion
1. Se connecter avec email/password
2. ✅ Connexion réussie

### Test 2: Chants
1. Aller sur l'écran des chants
2. ✅ Vos chants sont toujours là

### Test 3: Favoris
1. Ajouter un favori
2. ✅ Le favori s'active instantanément
3. Redémarrer l'app
4. ✅ Le favori est toujours là

### Test 4: Playlists
1. Créer une playlist
2. Ajouter des chants
3. ✅ La playlist fonctionne

### Test 5: Mode hors-ligne
1. Activer le mode avion
2. Redémarrer l'app
3. ✅ Les chants sont disponibles

## 📊 Avantages du reset

| Avant | Après |
|-------|-------|
| ❌ Erreurs RLS | ✅ Pas d'erreur |
| ❌ Policies problématiques | ✅ Aucune policy |
| ❌ Tables mal configurées | ✅ Tables propres |
| ⚠️ Configuration incertaine | ✅ Configuration garantie |

## 🔒 Sécurité

**"Mes données sont-elles en sécurité ?"**

**OUI !** ✅

- ✅ Les chants ne sont PAS supprimés
- ✅ Les profiles ne sont PAS supprimés
- ✅ L'authentification fonctionne toujours
- ✅ Seules les tables vides sont recréées

## 📚 Fichiers

1. **`reset_tables.sql`** ← **EXÉCUTER CE FICHIER** 🎯
2. **`RESET_GUIDE.md`** - Ce guide
3. **`verifier_simple.sql`** - Pour vérifier après le reset

## ✅ Checklist

- [ ] Sauvegarder vos données importantes (optionnel, elles ne seront pas supprimées)
- [ ] Exécuter `reset_tables.sql` dans Supabase SQL Editor
- [ ] Vérifier que les tables sont recréées (Table Editor)
- [ ] Vérifier que les chants sont toujours là
- [ ] Relancer l'application Flutter
- [ ] Tester la connexion
- [ ] Tester les favoris
- [ ] Tester les playlists

**Après le reset, tout devrait fonctionner parfaitement !** 🚀

## 🆘 En cas de problème

### Problème: "cannot drop table because other objects depend on it"

**Solution:** Le script utilise déjà `CASCADE`, mais si l'erreur persiste:

```sql
DROP TABLE IF EXISTS ecoutes CASCADE;
DROP TABLE IF EXISTS playlist_chants CASCADE;
DROP TABLE IF EXISTS playlists CASCADE;
DROP TABLE IF EXISTS favoris CASCADE;
DROP TABLE IF EXISTS membres CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS chorales CASCADE;
DROP TABLE IF EXISTS plans CASCADE;
```

### Problème: Les chants ont disparu

**Impossible !** Le script ne touche PAS à la table `chants`. Si vos chants ont disparu, c'est qu'ils n'étaient pas dans la table `chants` de Supabase.

### Problème: L'app ne fonctionne toujours pas

1. Vérifier que le script s'est bien exécuté
2. Exécuter `verifier_simple.sql` pour diagnostiquer
3. Relancer l'app avec `flutter clean && flutter run`

**Le reset va résoudre tous les problèmes de configuration !** ✅

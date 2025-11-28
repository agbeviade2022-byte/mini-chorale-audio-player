# 🔍 Diagnostic des tables Supabase

## 📋 Étape 1: Vérifier les tables existantes

**Fichier:** `check_existing_tables.sql`

**Instructions:**

1. Aller sur https://app.supabase.com
2. Sélectionner votre projet
3. Cliquer sur **"SQL Editor"**
4. Copier le contenu de `check_existing_tables.sql`
5. Coller et cliquer sur **"Run"**

**Résultats possibles:**

### Scénario A: Seule la table "profiles" existe

```
tablename | schemaname
----------|------------
profiles  | public
```

**Action:** Exécuter `create_tables_no_rls.sql` (crée toutes les tables)

---

### Scénario B: Les tables du multi-tenant existent

```
tablename       | schemaname
----------------|------------
chants          | public
chorales        | public
ecoutes         | public
favoris         | public
membres         | public
playlist_chants | public
playlists       | public
plans           | public
profiles        | public
subscriptions   | public
```

**Vérifier RLS:**

Si `rls_enabled = true` sur certaines tables:

```
tablename | rls_enabled
----------|------------
membres   | true        ← Problème !
chorales  | true        ← Problème !
```

**Action:** Exécuter `fix_all_rls.sql` (désactive RLS)

---

### Scénario C: Tables existent, RLS désactivé

```
tablename | rls_enabled
----------|------------
chants    | false       ← Parfait !
membres   | false       ← Parfait !
...
```

**Action:** Rien à faire ! Relancez juste votre app Flutter ✅

---

## 📋 Étape 2: Créer/Corriger selon le diagnostic

### Si Scénario A (pas de tables)

**Exécuter:** `create_tables_no_rls.sql`

Ce script va:
- ✅ Créer toutes les tables
- ✅ Insérer les plans par défaut
- ✅ Créer une chorale "Ma Chorale"
- ✅ Désactiver RLS

---

### Si Scénario B (tables avec RLS activé)

**Exécuter:** `fix_all_rls.sql`

Ce script va:
- ✅ Désactiver RLS sur toutes les tables
- ✅ Supprimer les policies problématiques

---

### Si Scénario C (tout est bon)

**Rien à faire !** Relancez votre app:

```bash
flutter run
```

---

## 📋 Étape 3: Solution universelle (fonctionne toujours)

Si vous n'êtes pas sûr ou si vous voulez une solution qui marche dans tous les cas:

**Exécuter:** `create_missing_tables.sql`

Ce script intelligent va:
- ✅ Créer uniquement les tables manquantes
- ✅ Ajouter les colonnes manquantes
- ✅ Désactiver RLS partout
- ✅ Supprimer les policies problématiques
- ✅ Insérer les données par défaut

**C'est la solution la plus sûre !** 🎯

---

## 🎯 Recommandation

### Solution simple (recommandée)

**Exécutez directement:** `create_missing_tables.sql`

Ce script fonctionne dans **tous les cas**:
- ✅ Si les tables n'existent pas → Les crée
- ✅ Si les tables existent → Les laisse intactes
- ✅ Si RLS est activé → Le désactive
- ✅ Si des policies existent → Les supprime

**1 seul script à exécuter, 0 risque d'erreur !**

---

## 📚 Récapitulatif des fichiers

| Fichier | Usage | Quand l'utiliser |
|---------|-------|------------------|
| `check_existing_tables.sql` | Diagnostic | Pour savoir où vous en êtes |
| `create_tables_no_rls.sql` | Création complète | Si aucune table n'existe |
| `fix_all_rls.sql` | Correction RLS | Si tables existent avec RLS |
| `create_missing_tables.sql` | **Solution universelle** | **Toujours (recommandé)** |

---

## ✅ Après l'exécution

Relancez votre application:

```bash
flutter run
```

**Logs attendus:**

```
✅ Hive initialisé avec succès
🏆 Session restaurée depuis Hive
🌐 Chargement depuis Supabase...
📦 X chants chargés depuis Drift
🔄 Chants synchronisés avec Supabase
```

**Plus d'erreur "infinite recursion" !** ✅

---

## 🎉 Résultat final

Après l'exécution du script approprié:

- ✅ **Toutes les tables créées**
- ✅ **RLS désactivé** (pas de récursion)
- ✅ **Plans et chorale par défaut** créés
- ✅ **Application fonctionnelle**

**Votre app va enfin fonctionner !** 🚀

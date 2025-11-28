# ✅ Checklist de vérification Supabase

## 📋 Comment vérifier

### Méthode 1: Script SQL (Recommandé)

**Fichier:** `verifier_supabase.sql`

**Instructions:**
1. Aller sur https://app.supabase.com
2. Sélectionner votre projet
3. Cliquer sur **"SQL Editor"**
4. Copier **TOUT** le contenu de `verifier_supabase.sql`
5. Coller et cliquer sur **"Run"**
6. Analyser les résultats ci-dessous

---

### Méthode 2: Vérification manuelle

#### Étape 1: Vérifier les tables

**Dans Supabase → Table Editor**

Vous devez voir ces tables:
- [ ] ✅ plans
- [ ] ✅ chorales
- [ ] ✅ membres
- [ ] ✅ favoris
- [ ] ✅ playlists
- [ ] ✅ playlist_chants
- [ ] ✅ ecoutes
- [ ] ✅ chants (déjà existante)
- [ ] ✅ profiles (déjà existante)

**Si une table manque:** Exécuter `create_tables_minimal.sql`

---

#### Étape 2: Vérifier RLS

**Dans SQL Editor, exécuter:**

```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Résultat attendu:** Toutes les tables doivent avoir `rowsecurity = false`

```
tablename       | rowsecurity
----------------|------------
chants          | false       ✅
chorales        | false       ✅
ecoutes         | false       ✅
favoris         | false       ✅
membres         | false       ✅
playlist_chants | false       ✅
playlists       | false       ✅
plans           | false       ✅
profiles        | false       ✅
```

**Si `rowsecurity = true`:** Exécuter `fix_all_rls.sql`

---

#### Étape 3: Vérifier les policies RLS

**Dans SQL Editor, exécuter:**

```sql
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

**Résultat attendu:** Aucune ligne (liste vide)

**Si des policies existent:** Exécuter `fix_all_rls.sql`

---

#### Étape 4: Vérifier les plans

**Dans SQL Editor, exécuter:**

```sql
SELECT nom, prix_mensuel, max_membres, max_chants 
FROM plans 
ORDER BY prix_mensuel;
```

**Résultat attendu:** 4 plans

```
nom         | prix_mensuel | max_membres | max_chants
------------|--------------|-------------|------------
Gratuit     | 0.00         | 10          | 50
Standard    | 9.99         | 50          | 500
Premium     | 29.99        | 200         | 2000
Entreprise  | 99.99        | 999999      | 999999
```

**Si moins de 4 plans:** Exécuter `create_tables_minimal.sql`

---

#### Étape 5: Vérifier les chorales

**Dans SQL Editor, exécuter:**

```sql
SELECT nom, slug, statut 
FROM chorales;
```

**Résultat attendu:** Au moins 1 chorale

```
nom         | slug        | statut
------------|-------------|--------
Ma Chorale  | ma-chorale  | actif
```

**Si aucune chorale:** Exécuter `create_tables_minimal.sql`

---

#### Étape 6: Vérifier les chants

**Dans SQL Editor, exécuter:**

```sql
SELECT COUNT(*) as nombre_chants FROM chants;
```

**Résultat attendu:** 0 ou plus (normal si vous n'avez pas encore ajouté de chants)

---

## ✅ Configuration correcte

Votre Supabase est bien configuré si:

- [x] ✅ Toutes les tables existent (9 tables minimum)
- [x] ✅ RLS désactivé sur toutes les tables (`rowsecurity = false`)
- [x] ✅ Aucune policy RLS active
- [x] ✅ 4 plans créés
- [x] ✅ Au moins 1 chorale créée

**Si tous les points sont cochés → Votre Supabase est prêt !** 🎉

---

## ⚠️ Problèmes courants

### Problème 1: RLS activé

**Symptôme:** `rowsecurity = true` sur certaines tables

**Solution:**
```sql
ALTER TABLE membres DISABLE ROW LEVEL SECURITY;
ALTER TABLE chorales DISABLE ROW LEVEL SECURITY;
ALTER TABLE chants DISABLE ROW LEVEL SECURITY;
ALTER TABLE favoris DISABLE ROW LEVEL SECURITY;
```

Ou exécuter `fix_all_rls.sql`

---

### Problème 2: Policies RLS existent

**Symptôme:** Des policies apparaissent dans `pg_policies`

**Solution:**
```sql
DROP POLICY IF EXISTS "membres_select_policy" ON membres;
DROP POLICY IF EXISTS "chorales_select_policy" ON chorales;
DROP POLICY IF EXISTS "chants_select_policy" ON chants;
```

Ou exécuter `fix_all_rls.sql`

---

### Problème 3: Tables manquantes

**Symptôme:** Certaines tables n'existent pas

**Solution:** Exécuter `create_tables_minimal.sql`

---

### Problème 4: Pas de plans

**Symptôme:** La table `plans` est vide

**Solution:** Exécuter juste la section INSERT de `create_tables_minimal.sql`:

```sql
INSERT INTO plans (nom, prix_mensuel, max_membres, max_chants, max_stockage_mb, features)
VALUES 
    ('Gratuit', 0, 10, 50, 100, '["Lecteur audio basique"]'::jsonb),
    ('Standard', 9.99, 50, 500, 1000, '["Lecteur audio avancé"]'::jsonb),
    ('Premium', 29.99, 200, 2000, 5000, '["Tout Standard"]'::jsonb),
    ('Entreprise', 99.99, 999999, 999999, 999999, '["Tout Premium"]'::jsonb)
ON CONFLICT (nom) DO NOTHING;
```

---

## 🚀 Après vérification

Si tout est ✅, testez votre application:

```bash
flutter run
```

**Logs attendus:**

```
✅ Hive initialisé avec succès
📊 Stats Hive: {session: true, settings: false}
✅ Supabase initialisé avec persistance de session
🏆 Session restaurée depuis Hive
🌐 Chargement depuis Supabase...
📦 0 chants chargés depuis Drift (normal si première utilisation)
✅ Connexion réussie
```

**Tests à effectuer:**

1. **Connexion** - Se connecter avec email/password ✅
2. **Ajouter un chant** (si admin) - Le chant apparaît ✅
3. **Favoris** - Cliquer sur le cœur, le favori s'active ✅
4. **Mode hors-ligne** - Activer mode avion, les chants restent visibles ✅

---

## 📚 Fichiers de vérification

1. **`verifier_supabase.sql`** - Script de vérification automatique ⭐
2. **`CHECKLIST_VERIFICATION.md`** - Ce guide
3. **`create_tables_minimal.sql`** - Pour créer les tables manquantes
4. **`fix_all_rls.sql`** - Pour corriger RLS

---

## 🎯 Résumé

**Pour vérifier rapidement:**

1. Exécuter `verifier_supabase.sql` dans Supabase SQL Editor
2. Regarder la section "RÉSUMÉ" à la fin
3. Si tout est ✅ → Relancer l'app Flutter
4. Si des ⚠️ → Suivre les instructions de correction

**Votre app devrait maintenant fonctionner parfaitement !** 🚀

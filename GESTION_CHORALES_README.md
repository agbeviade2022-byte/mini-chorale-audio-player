# 🎵 Gestion des Chorales - Guide Complet

## ✅ Ce qui a été implémenté

### 📁 Fichiers créés

#### 1. **Script SQL : `ajouter_chorale.sql`**
Script pour ajouter manuellement des chorales dans Supabase.

**Utilisation :**
```sql
-- Exemple simple
INSERT INTO chorales (nom, slug, description, statut)
VALUES ('Ma Chorale', 'ma-chorale', 'Description', 'actif')
ON CONFLICT (slug) DO NOTHING;
```

**Fonctionnalités :**
- ✅ Ajouter une chorale simple
- ✅ Ajouter une chorale avec toutes les informations
- ✅ Exemples de 5 chorales pré-remplies
- ✅ Modifier une chorale existante
- ✅ Supprimer une chorale (avec précautions)
- ✅ Statistiques des chorales

#### 2. **Écran Admin : `lib/screens/admin/chorales_management_screen.dart`**
Interface complète pour gérer les chorales depuis l'application Flutter.

**Fonctionnalités :**
- ✅ Liste de toutes les chorales
- ✅ Créer une nouvelle chorale
- ✅ Modifier une chorale existante
- ✅ Supprimer une chorale (avec confirmation)
- ✅ Voir les détails d'une chorale
- ✅ Génération automatique du slug
- ✅ Validation des formulaires
- ✅ Gestion des erreurs
- ✅ Refresh pour recharger la liste

---

## 🚀 Comment utiliser

### Option A : Via l'application Flutter (Recommandé pour les admins)

#### 1. Ajouter le lien dans le menu admin

Ajoutez ce code dans `lib/screens/home/home_screen.dart` dans le drawer admin :

```dart
// Dans le Drawer, après les autres options admin
ListTile(
  leading: const Icon(Icons.groups),
  title: const Text('Gestion des Chorales'),
  onTap: () {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChoralesManagementScreen(),
      ),
    );
  },
),
```

#### 2. Importer l'écran

En haut du fichier `home_screen.dart`, ajoutez :

```dart
import 'package:mini_chorale_audio_player/screens/admin/chorales_management_screen.dart';
```

#### 3. Accéder à l'écran

1. Connectez-vous en tant que **super admin**
2. Ouvrez le menu (drawer)
3. Cliquez sur "Gestion des Chorales"
4. Créez, modifiez ou supprimez des chorales

---

### Option B : Via SQL Supabase (Recommandé pour le setup initial)

#### 1. Ouvrir Supabase

1. Allez sur [supabase.com](https://supabase.com)
2. Connectez-vous à votre projet
3. Allez dans **SQL Editor**

#### 2. Exécuter le script

1. Ouvrez le fichier `ajouter_chorale.sql`
2. Copiez les exemples de chorales que vous voulez créer
3. Collez dans l'éditeur SQL
4. Cliquez sur **Run**

#### 3. Vérifier

```sql
SELECT id, nom, slug, ville, nombre_membres, statut
FROM chorales
ORDER BY nom;
```

---

## 📋 Structure d'une Chorale

### Champs obligatoires

- **nom** : Nom complet de la chorale (ex: "Chorale Saint-Michel")
- **slug** : Identifiant URL-friendly (ex: "chorale-saint-michel")
- **statut** : 'actif' ou 'inactif'

### Champs optionnels

- **description** : Description de la chorale
- **logo_url** : URL du logo
- **couleur_theme** : Couleur en hex (ex: "#6366F1")
- **email_contact** : Email de contact
- **telephone** : Numéro de téléphone
- **adresse** : Adresse postale
- **ville** : Ville
- **pays** : Pays (défaut: "France")
- **site_web** : URL du site web
- **nombre_membres** : Mis à jour automatiquement

---

## 🎯 Cas d'usage

### 1. Créer une nouvelle chorale

**Via l'app :**
1. Ouvrir "Gestion des Chorales"
2. Cliquer sur le bouton "+"
3. Remplir le formulaire
4. Cliquer sur "Créer"

**Via SQL :**
```sql
INSERT INTO chorales (nom, slug, description, ville, statut)
VALUES ('Ma Nouvelle Chorale', 'ma-nouvelle-chorale', 'Description', 'Paris', 'actif');
```

### 2. Modifier une chorale

**Via l'app :**
1. Ouvrir "Gestion des Chorales"
2. Cliquer sur les 3 points de la chorale
3. Sélectionner "Modifier"
4. Modifier les champs
5. Cliquer sur "Modifier"

**Via SQL :**
```sql
UPDATE chorales
SET description = 'Nouvelle description',
    ville = 'Lyon',
    updated_at = NOW()
WHERE slug = 'ma-chorale';
```

### 3. Supprimer une chorale

⚠️ **ATTENTION** : Cela supprimera aussi tous les membres !

**Via l'app :**
1. Ouvrir "Gestion des Chorales"
2. Cliquer sur les 3 points de la chorale
3. Sélectionner "Supprimer"
4. Confirmer

**Via SQL (avec précaution) :**
```sql
-- Étape 1 : Réassigner les membres à une autre chorale
UPDATE profiles
SET chorale_id = (SELECT id FROM chorales WHERE slug = 'chorale-principale')
WHERE chorale_id = (SELECT id FROM chorales WHERE slug = 'chorale-a-supprimer');

-- Étape 2 : Supprimer la chorale
DELETE FROM chorales WHERE slug = 'chorale-a-supprimer';
```

### 4. Voir les statistiques

**Via SQL :**
```sql
SELECT 
    c.nom as chorale,
    c.ville,
    c.nombre_membres as compteur,
    COUNT(p.id) as membres_reels,
    c.statut
FROM chorales c
LEFT JOIN profiles p ON p.chorale_id = c.id
GROUP BY c.id, c.nom, c.ville, c.nombre_membres, c.statut
ORDER BY c.nombre_membres DESC;
```

---

## 🔐 Permissions

### Qui peut gérer les chorales ?

**Dans l'application :**
- ✅ **Super Admin** : Peut tout faire (créer, modifier, supprimer)
- ❌ **Admin** : Ne peut pas gérer les chorales (seulement voir la sienne)
- ❌ **Utilisateur** : Ne peut pas gérer les chorales

**Dans Supabase :**
- ✅ Toute personne ayant accès au dashboard Supabase

### RLS Policies

Les policies Supabase sont configurées dans `migration_chorale_obligatoire.sql` :

```sql
-- Les utilisateurs peuvent voir leur chorale
CREATE POLICY "Utilisateurs voient leur chorale"
ON chorales FOR SELECT
USING (
    id IN (
        SELECT chorale_id FROM profiles WHERE user_id = auth.uid()
    )
);

-- Les admins peuvent modifier leur chorale
CREATE POLICY "Admins modifient leur chorale"
ON chorales FOR UPDATE
USING (
    id IN (
        SELECT chorale_id FROM profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);
```

---

## 🧪 Tests à effectuer

### Tests de création

- [ ] Créer une chorale via l'app → Doit réussir
- [ ] Créer une chorale avec un slug existant → Doit échouer
- [ ] Créer une chorale sans nom → Doit échouer
- [ ] Vérifier que le slug est généré automatiquement
- [ ] Vérifier que la chorale apparaît dans la liste

### Tests de modification

- [ ] Modifier le nom d'une chorale → Doit réussir
- [ ] Modifier le slug d'une chorale → Doit être désactivé
- [ ] Vérifier que `updated_at` est mis à jour

### Tests de suppression

- [ ] Supprimer une chorale vide → Doit réussir
- [ ] Supprimer une chorale avec des membres → Doit supprimer les membres aussi
- [ ] Vérifier que la chorale n'apparaît plus dans la liste

### Tests de permissions

- [ ] Un utilisateur normal ne peut pas accéder à l'écran → Doit être bloqué
- [ ] Un admin peut voir l'écran → Doit réussir
- [ ] Un super admin peut tout faire → Doit réussir

---

## 🐛 Dépannage

### Erreur : "Slug already exists"

**Cause :** Une chorale avec ce slug existe déjà.

**Solution :** Choisissez un autre slug ou supprimez l'ancienne chorale.

### Erreur : "Cannot delete chorale with members"

**Cause :** La chorale a des membres.

**Solution :** Réassignez d'abord les membres à une autre chorale.

### L'écran ne s'affiche pas

**Causes possibles :**
1. L'import n'est pas ajouté dans `home_screen.dart`
2. Le lien n'est pas ajouté dans le drawer
3. L'utilisateur n'est pas admin

**Solution :** Vérifiez les imports et les permissions.

### Le slug n'est pas généré automatiquement

**Cause :** Le listener n'est pas configuré.

**Solution :** Vérifiez que `_nomController.addListener(_generateSlug)` est appelé dans `initState()`.

---

## 📊 Exemples de chorales

Le script `ajouter_chorale.sql` contient 5 exemples de chorales :

1. **Chorale des Anges** (Lyon) - Gospel
2. **Harmonie Vocale** (Marseille) - Classique
3. **Voix d'Espoir** (Toulouse) - Contemporaine
4. **Chœur Céleste** (Bordeaux) - Liturgique
5. **Cantique Nouveau** (Lille) - Louange

Vous pouvez les créer toutes en une fois :

```sql
-- Exécutez la section "EXEMPLES DE CHORALES À AJOUTER" du script
```

---

## 🔄 Workflow recommandé

### Pour le lancement initial

1. **Exécuter le script SQL** `migration_chorale_obligatoire.sql`
   - Crée la table `chorales`
   - Crée la "Chorale Principale" par défaut
   - Configure les policies

2. **Ajouter des chorales** via `ajouter_chorale.sql`
   - Créer 3-5 chorales pour tester
   - Utiliser les exemples fournis

3. **Tester l'inscription**
   - Vérifier que le dropdown affiche les chorales
   - S'inscrire avec une chorale

4. **Ajouter le lien dans l'app**
   - Modifier `home_screen.dart`
   - Tester l'accès à l'écran de gestion

### Pour l'utilisation quotidienne

1. **Les admins utilisent l'app** pour gérer les chorales
2. **Les super admins** peuvent créer de nouvelles chorales
3. **Les modifications** se font via l'interface
4. **SQL** est utilisé uniquement pour les opérations en masse

---

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez les logs Flutter
2. Vérifiez les logs Supabase
3. Vérifiez que la table `chorales` existe
4. Vérifiez que les policies sont configurées
5. Vérifiez que l'utilisateur est bien super admin

---

## ✅ Checklist de déploiement

- [ ] Script `migration_chorale_obligatoire.sql` exécuté
- [ ] Table `chorales` créée
- [ ] Chorale par défaut créée
- [ ] Script `ajouter_chorale.sql` disponible
- [ ] Écran `chorales_management_screen.dart` créé
- [ ] Lien ajouté dans le menu admin
- [ ] Import ajouté dans `home_screen.dart`
- [ ] Tests de création effectués
- [ ] Tests de modification effectués
- [ ] Tests de suppression effectués
- [ ] Permissions vérifiées

---

**Date de création :** 19 novembre 2025  
**Version :** 1.0.0  
**Auteur :** Cascade AI Assistant

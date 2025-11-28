# 🎵 Système d'Appartenance Obligatoire à une Chorale

## 📋 Vue d'ensemble

Ce document décrit l'implémentation du système d'appartenance obligatoire à une chorale pour tous les utilisateurs (administrateurs et membres) dans l'application Mini-Chorale Audio Player.

## ✅ Ce qui a été implémenté

### 1. **Base de données (Supabase)**

#### Nouvelles tables créées :
- ✅ `chorales` : Gestion des chorales
- ✅ `invitations` : Système d'invitation par email

#### Modifications de la table `profiles` :
- ✅ Ajout de la colonne `chorale_id` (obligatoire)
- ✅ Ajout de colonnes supplémentaires : `pupitre`, `telephone`, `date_adhesion`, `statut_membre`
- ✅ Contrainte `NOT NULL` sur `chorale_id`

#### Fonctionnalités SQL :
- ✅ Trigger automatique pour créer le profil avec chorale lors de l'inscription
- ✅ Fonction pour mettre à jour automatiquement le nombre de membres
- ✅ Fonction pour expirer les invitations
- ✅ RLS (Row Level Security) policies configurées

### 2. **Application Flutter**

#### Nouveaux fichiers créés :
- ✅ `lib/models/chorale.dart` : Modèle Chorale
- ✅ `lib/services/chorale_service.dart` : Service de gestion des chorales
- ✅ `lib/providers/chorale_provider.dart` : Providers Riverpod pour les chorales

#### Fichiers modifiés :
- ✅ `lib/screens/auth/register.dart` : Ajout du dropdown de sélection de chorale
- ✅ `lib/providers/auth_provider.dart` : Ajout du paramètre `choraleId`
- ✅ `lib/services/enhanced_auth_service.dart` : Gestion du `choraleId` lors de l'inscription

## 🚀 Instructions de déploiement

### Étape 1 : Exécuter le script SQL sur Supabase

1. Connectez-vous à votre dashboard Supabase
2. Allez dans **SQL Editor**
3. Ouvrez le fichier `migration_chorale_obligatoire.sql`
4. Copiez tout le contenu et exécutez-le dans l'éditeur SQL
5. Vérifiez qu'il n'y a pas d'erreurs

**⚠️ IMPORTANT :** Ce script va :
- Créer une chorale par défaut nommée "Chorale Principale"
- Assigner tous les profils existants à cette chorale par défaut
- Rendre le champ `chorale_id` obligatoire

### Étape 2 : Tester l'application Flutter

1. Relancez l'application Flutter :
   ```bash
   flutter run -d emulator-5554
   ```

2. Testez l'inscription :
   - Allez sur l'écran d'inscription
   - Remplissez tous les champs
   - **Sélectionnez une chorale** dans le dropdown
   - Cliquez sur "S'inscrire"

3. Vérifiez que :
   - Le dropdown affiche bien les chorales disponibles
   - L'inscription échoue si aucune chorale n'est sélectionnée
   - L'inscription réussit avec une chorale sélectionnée

### Étape 3 : Vérifier dans Supabase

1. Allez dans **Table Editor** > **profiles**
2. Vérifiez que le nouveau profil a bien un `chorale_id`
3. Allez dans **Table Editor** > **chorales**
4. Vérifiez que le `nombre_membres` a été incrémenté

## 📊 Structure de la base de données

### Table `chorales`

```sql
CREATE TABLE chorales (
    id UUID PRIMARY KEY,
    nom VARCHAR(255) NOT NULL UNIQUE,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    logo_url TEXT,
    couleur_theme VARCHAR(7) DEFAULT '#6366F1',
    email_contact VARCHAR(255),
    telephone VARCHAR(50),
    adresse TEXT,
    ville VARCHAR(100),
    pays VARCHAR(100) DEFAULT 'France',
    site_web TEXT,
    nombre_membres INTEGER DEFAULT 0,
    statut VARCHAR(20) DEFAULT 'actif',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table `profiles` (modifiée)

```sql
ALTER TABLE profiles 
ADD COLUMN chorale_id UUID NOT NULL REFERENCES chorales(id),
ADD COLUMN pupitre VARCHAR(50),
ADD COLUMN telephone VARCHAR(50),
ADD COLUMN date_adhesion TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN statut_membre VARCHAR(20) DEFAULT 'actif';
```

### Table `invitations`

```sql
CREATE TABLE invitations (
    id UUID PRIMARY KEY,
    chorale_id UUID NOT NULL REFERENCES chorales(id),
    email VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    pupitre VARCHAR(50),
    token VARCHAR(255) NOT NULL UNIQUE,
    invite_par UUID REFERENCES profiles(id),
    statut VARCHAR(20) DEFAULT 'en_attente',
    expire_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 🔐 Sécurité (RLS Policies)

### Policies pour `chorales`

- ✅ Les utilisateurs peuvent voir leur chorale
- ✅ Les admins peuvent modifier leur chorale

### Policies pour `profiles`

- ✅ Les utilisateurs peuvent voir leur propre profil
- ✅ Les utilisateurs peuvent voir les profils de leur chorale
- ✅ Les utilisateurs peuvent modifier leur propre profil
- ✅ Les admins peuvent voir tous les profils de leur chorale
- ✅ Les admins peuvent modifier les profils de leur chorale

### Policies pour `invitations`

- ✅ Les admins peuvent créer des invitations pour leur chorale
- ✅ Les admins peuvent voir les invitations de leur chorale
- ✅ Les invités peuvent voir leur invitation par token

## 🎯 Fonctionnalités futures (non implémentées)

### 1. Système d'invitation par email

**Fonctionnement prévu :**
1. Un admin crée une invitation avec un email
2. Un token unique est généré
3. Un email est envoyé avec un lien d'inscription
4. L'utilisateur clique sur le lien et s'inscrit
5. Le profil est automatiquement lié à la chorale

**Fichiers à créer :**
- `lib/screens/admin/invitations_screen.dart`
- `lib/services/invitation_service.dart`
- `lib/providers/invitation_provider.dart`

### 2. Gestion multi-chorales

**Fonctionnalité :**
- Un utilisateur peut appartenir à plusieurs chorales
- Table de liaison `membres_chorales`
- Sélection de la chorale active dans l'app

### 3. Écran de gestion de chorale pour les admins

**Fonctionnalités :**
- Modifier les informations de la chorale
- Voir la liste des membres
- Gérer les invitations
- Statistiques de la chorale

## 🧪 Tests à effectuer

### Tests d'inscription

- [ ] Inscription sans sélectionner de chorale → Doit échouer
- [ ] Inscription avec une chorale sélectionnée → Doit réussir
- [ ] Vérifier que le profil a bien un `chorale_id` dans Supabase
- [ ] Vérifier que le `nombre_membres` de la chorale a été incrémenté

### Tests de connexion

- [ ] Connexion avec un compte existant → Doit fonctionner
- [ ] Vérifier que le profil a bien un `chorale_id`
- [ ] Si le profil n'a pas de `chorale_id`, il doit être assigné à la chorale par défaut

### Tests RLS

- [ ] Un utilisateur ne peut voir que les profils de sa chorale
- [ ] Un admin peut voir tous les profils de sa chorale
- [ ] Un utilisateur ne peut pas voir les profils d'une autre chorale

## 📝 Notes importantes

### Migration des données existantes

Le script SQL assigne automatiquement tous les profils existants à la "Chorale Principale". Si vous avez déjà des utilisateurs, ils seront tous dans cette chorale par défaut.

**Pour réassigner des utilisateurs à d'autres chorales :**

```sql
-- Créer une nouvelle chorale
INSERT INTO chorales (nom, slug, description)
VALUES ('Ma Chorale', 'ma-chorale', 'Description de ma chorale');

-- Réassigner des utilisateurs
UPDATE profiles
SET chorale_id = (SELECT id FROM chorales WHERE slug = 'ma-chorale')
WHERE email IN ('user1@example.com', 'user2@example.com');
```

### Suppression d'une chorale

⚠️ **ATTENTION :** La suppression d'une chorale supprimera tous les profils associés (CASCADE).

Pour éviter cela, réassignez d'abord les membres à une autre chorale :

```sql
-- Réassigner tous les membres à une autre chorale
UPDATE profiles
SET chorale_id = (SELECT id FROM chorales WHERE slug = 'chorale-principale')
WHERE chorale_id = 'id-de-la-chorale-a-supprimer';

-- Puis supprimer la chorale
DELETE FROM chorales WHERE id = 'id-de-la-chorale-a-supprimer';
```

## 🐛 Dépannage

### Erreur : "chorale_id cannot be null"

**Cause :** Le profil n'a pas de `chorale_id` assigné.

**Solution :**
```sql
UPDATE profiles
SET chorale_id = (SELECT id FROM chorales WHERE slug = 'chorale-principale' LIMIT 1)
WHERE chorale_id IS NULL;
```

### Erreur : "No chorales found"

**Cause :** Aucune chorale n'existe dans la base de données.

**Solution :**
```sql
INSERT INTO chorales (nom, slug, description, statut)
VALUES ('Chorale Principale', 'chorale-principale', 'Chorale par défaut', 'actif');
```

### Le dropdown des chorales est vide

**Causes possibles :**
1. Aucune chorale n'existe dans la base de données
2. Toutes les chorales ont le statut 'inactif'
3. Problème de connexion à Supabase

**Solution :**
1. Vérifiez dans Supabase que des chorales existent
2. Vérifiez que les chorales ont le statut 'actif'
3. Vérifiez les logs de l'application Flutter

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez les logs de l'application Flutter
2. Vérifiez les logs de Supabase (Dashboard > Logs)
3. Vérifiez que toutes les tables et policies existent
4. Vérifiez que le trigger `on_auth_user_created` fonctionne

## ✅ Checklist de déploiement

- [ ] Script SQL exécuté sur Supabase
- [ ] Chorale par défaut créée
- [ ] Tous les profils existants ont un `chorale_id`
- [ ] Application Flutter relancée
- [ ] Test d'inscription réussi
- [ ] Test de connexion réussi
- [ ] Vérification dans Supabase effectuée

---

**Date de création :** 19 novembre 2025  
**Version :** 1.0.0  
**Auteur :** Cascade AI Assistant

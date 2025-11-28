# 🔐 Système de Validation Sécurisée des Membres

## 📋 Vue d'ensemble

Ce système implémente un processus de validation strict où :
- ✅ Les utilisateurs s'inscrivent SANS choisir de chorale
- ✅ Leur email est confirmé automatiquement par Supabase
- ✅ Ils n'ont PAS accès aux chants tant qu'un admin ne les valide pas
- ✅ Seuls les admins/super_admins peuvent attribuer une chorale et valider
- ✅ Historique complet de toutes les validations

---

## 🚀 Flux d'inscription et validation

### 1. **Inscription de l'utilisateur**
```
Utilisateur remplit le formulaire
    ↓
Compte créé dans Supabase Auth
    ↓
Email de confirmation envoyé
    ↓
Profil créé avec statut_validation = 'en_attente'
    ↓
Redirection vers écran d'attente
```

### 2. **Validation par l'admin**
```
Admin se connecte
    ↓
Accède à "Validation des Membres"
    ↓
Voit la liste des membres en attente
    ↓
Sélectionne une chorale pour le membre
    ↓
Valide le membre
    ↓
Membre peut maintenant accéder aux chants
```

---

## 📁 Fichiers créés/modifiés

### 🗄️ Base de données (SQL)

#### `migration_validation_membres.sql`
- Ajoute `statut_validation` à la table `profiles`
- Crée la table `validations_membres` (historique)
- Crée les fonctions `valider_membre()` et `refuser_membre()`
- Met à jour les RLS policies pour bloquer l'accès aux chants
- Crée les vues `membres_en_attente` et `stats_validations`

**À exécuter dans Supabase SQL Editor**

### 📱 Application Flutter

#### Écrans créés :
1. **`lib/screens/auth/waiting_validation_screen.dart`**
   - Écran d'attente après inscription
   - Informe l'utilisateur qu'il doit attendre la validation
   - Design moderne et rassurant

2. **`lib/screens/admin/members_validation_screen.dart`**
   - Liste des membres en attente
   - Recherche par nom/email
   - Validation avec attribution de chorale
   - Refus avec commentaire

#### Fichiers modifiés :
1. **`lib/screens/auth/register.dart`**
   - ❌ Supprimé : Dropdown de sélection de chorale
   - ✅ Ajouté : Redirection vers écran d'attente

2. **`lib/providers/auth_provider.dart`**
   - ❌ Supprimé : Paramètre `choraleId` obligatoire
   - ✅ Simplifié : Inscription sans chorale

3. **`lib/services/enhanced_auth_service.dart`**
   - ❌ Supprimé : Envoi de `chorale_id` dans les métadonnées
   - ✅ Modifié : Inscription simple avec statut en attente

4. **`lib/screens/home/home_screen.dart`**
   - ✅ Ajouté : Lien vers "Validation des Membres" dans le menu admin

---

## 🔐 Sécurité : RLS Policies

### Chants (table `chants`)

```sql
-- Seuls les membres VALIDÉS peuvent voir les chants
CREATE POLICY "Membres validés voient chants de leur chorale"
ON chants FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = auth.uid() 
        AND chorale_id = chants.chorale_id
        AND statut_validation = 'valide'
        AND statut_membre = 'actif'
    )
);
```

### Profiles (table `profiles`)

```sql
-- Les utilisateurs voient leur propre profil
CREATE POLICY "Utilisateurs voient leur profil"
ON profiles FOR SELECT
USING (user_id = auth.uid());

-- Les admins voient tous les profils
CREATE POLICY "Admins voient tous les profils"
ON profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role IN ('admin', 'super_admin')
    )
);
```

---

## 🎯 Utilisation

### Pour un nouvel utilisateur

1. Ouvrir l'application
2. Cliquer sur "S'inscrire"
3. Remplir le formulaire (nom, email, mot de passe)
4. Confirmer l'email (lien reçu par email)
5. Voir l'écran d'attente
6. Attendre la validation par un admin

### Pour un admin

1. Se connecter à l'application
2. Ouvrir le menu (drawer)
3. Cliquer sur "Validation des Membres"
4. Voir la liste des membres en attente
5. Pour chaque membre :
   - Cliquer sur "Valider"
   - Sélectionner une chorale
   - Confirmer
   
   OU
   
   - Cliquer sur "Refuser"
   - Ajouter un commentaire (optionnel)
   - Confirmer

---

## 📊 Base de données

### Table `profiles` (modifiée)

| Colonne | Type | Description |
|---------|------|-------------|
| `chorale_id` | UUID | Nullable maintenant |
| `statut_validation` | VARCHAR(20) | 'en_attente', 'valide', 'refuse' |
| `statut_membre` | VARCHAR(20) | 'actif', 'inactif', 'suspendu' |

### Table `validations_membres` (nouvelle)

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Clé primaire |
| `user_id` | UUID | Membre validé/refusé |
| `validateur_id` | UUID | Admin qui a validé |
| `chorale_id` | UUID | Chorale attribuée |
| `ancien_statut` | VARCHAR(20) | Statut avant |
| `nouveau_statut` | VARCHAR(20) | Statut après |
| `commentaire` | TEXT | Commentaire optionnel |
| `created_at` | TIMESTAMP | Date de validation |

---

## 🔧 Fonctions SQL

### `valider_membre()`

```sql
SELECT valider_membre(
    'user-id'::UUID,           -- ID de l'utilisateur
    'chorale-id'::UUID,        -- ID de la chorale
    auth.uid(),                -- ID du validateur
    'Membre validé'            -- Commentaire
);
```

### `refuser_membre()`

```sql
SELECT refuser_membre(
    'user-id'::UUID,           -- ID de l'utilisateur
    auth.uid(),                -- ID du validateur
    'Documents incomplets'     -- Raison
);
```

---

## 📈 Vues SQL

### `membres_en_attente`

Liste tous les membres en attente de validation avec le nombre de jours d'attente.

```sql
SELECT * FROM membres_en_attente;
```

### `stats_validations`

Statistiques globales sur les validations.

```sql
SELECT * FROM stats_validations;
```

---

## ✅ Checklist de déploiement

### 1. Base de données

- [ ] Exécuter `migration_validation_membres.sql` dans Supabase
- [ ] Vérifier que les policies sont créées
- [ ] Vérifier que les fonctions sont créées
- [ ] Tester les vues

### 2. Application Flutter

- [ ] Vérifier que tous les imports sont corrects
- [ ] Compiler l'application sans erreur
- [ ] Tester l'inscription (doit rediriger vers écran d'attente)
- [ ] Tester la validation admin
- [ ] Tester le refus admin

### 3. Supabase Configuration

- [ ] Authentication > Settings > Enable email confirmations : ON
- [ ] Authentication > Settings > Confirm email : ON
- [ ] Vérifier les templates d'emails

---

## 🧪 Tests

### Test 1 : Inscription utilisateur

1. Créer un nouveau compte
2. Vérifier que l'écran d'attente s'affiche
3. Vérifier dans Supabase que `statut_validation = 'en_attente'`
4. Vérifier que l'utilisateur ne peut pas accéder aux chants

### Test 2 : Validation admin

1. Se connecter en tant qu'admin
2. Aller dans "Validation des Membres"
3. Valider un membre avec une chorale
4. Vérifier que le membre peut maintenant accéder aux chants

### Test 3 : Refus admin

1. Se connecter en tant qu'admin
2. Aller dans "Validation des Membres"
3. Refuser un membre
4. Vérifier que `statut_validation = 'refuse'`

---

## 🐛 Dépannage

### Problème : Les membres validés ne voient pas les chants

**Solution :** Vérifier les RLS policies sur la table `chants`

```sql
SELECT * FROM pg_policies WHERE tablename = 'chants';
```

### Problème : Erreur lors de la validation

**Solution :** Vérifier que les fonctions existent

```sql
SELECT proname FROM pg_proc WHERE proname IN ('valider_membre', 'refuser_membre');
```

### Problème : L'écran d'attente ne s'affiche pas

**Solution :** Vérifier l'import dans `register.dart`

```dart
import 'package:mini_chorale_audio_player/screens/auth/waiting_validation_screen.dart';
```

---

## 📞 Support

Pour toute question ou problème :
1. Vérifier les logs Supabase
2. Vérifier les logs Flutter (console)
3. Consulter la table `validations_membres` pour l'historique

---

## 🎉 Avantages de ce système

✅ **Sécurité maximale** : Aucun accès sans validation admin
✅ **Contrôle total** : Les admins décident qui entre et dans quelle chorale
✅ **Traçabilité** : Historique complet de toutes les validations
✅ **UX claire** : L'utilisateur sait exactement où il en est
✅ **Flexible** : Possibilité de refuser avec commentaire
✅ **Scalable** : Fonctionne pour des milliers d'utilisateurs

---

**Date de création :** 19 novembre 2025  
**Version :** 1.0  
**Auteur :** Cascade AI Assistant

# 🧪 GUIDE COMPLET : Tests de Sécurité

## 📋 TABLE DES MATIÈRES

1. [Tests SQL (Supabase)](#tests-sql)
2. [Tests Dashboard Web](#tests-dashboard-web)
3. [Tests Application Flutter](#tests-flutter)
4. [Tests de Pénétration](#tests-penetration)
5. [Tests Automatisés](#tests-automatises)

---

## 🗄️ TESTS SQL (SUPABASE)

### **ÉTAPE 1 : Tester AVANT la correction**

#### **Test 1.1 : Escalade de privilèges (DOIT ÉCHOUER APRÈS FIX)**

```sql
-- Se connecter en tant qu'utilisateur normal
-- Essayer de se promouvoir super_admin

-- 1. Créer un utilisateur de test
INSERT INTO auth.users (id, email)
VALUES ('test-user-id', 'hacker@test.com');

INSERT INTO profiles (user_id, full_name, role)
VALUES ('test-user-id', 'Hacker', 'membre');

-- 2. Se connecter avec cet utilisateur (via Supabase Auth)
-- Puis essayer de se promouvoir:

UPDATE profiles
SET role = 'super_admin'
WHERE user_id = 'test-user-id';

-- AVANT FIX: ✅ Succès (PROBLÈME!)
-- APRÈS FIX: ❌ Erreur "new row violates row-level security policy"
```

**Résultat attendu APRÈS correction:**
```
ERROR: new row violates row-level security policy for table "profiles"
```

---

#### **Test 1.2 : Bypass SECURITY DEFINER (DOIT ÉCHOUER APRÈS FIX)**

```sql
-- Se connecter en tant qu'utilisateur normal
-- Essayer de valider un membre sans être admin

SELECT valider_membre(
    'target-user-id'::UUID,
    'chorale-id'::UUID,
    'fake-admin-id'::UUID,
    'Hack'
);

-- AVANT FIX: ✅ Succès (PROBLÈME!)
-- APRÈS FIX: ❌ Erreur "Non autorisé: seuls les admins peuvent valider"
```

**Résultat attendu APRÈS correction:**
```
ERROR: Non autorisé: seuls les admins peuvent valider des membres
```

---

#### **Test 1.3 : Accès anonyme aux données (DOIT ÉCHOUER APRÈS FIX)**

```sql
-- Se déconnecter complètement (mode anonyme)
-- Essayer d'accéder aux membres en attente

SELECT * FROM membres_en_attente;

-- AVANT FIX: ✅ Retourne des données (PROBLÈME!)
-- APRÈS FIX: ❌ Erreur "permission denied" ou 0 résultats
```

---

### **ÉTAPE 2 : Tester APRÈS la correction**

#### **Test 2.1 : Super Admin peut tout faire**

```sql
-- Se connecter en tant que super_admin
-- Vérifier qu'il peut modifier les rôles

UPDATE profiles
SET role = 'admin'
WHERE user_id = 'target-user-id';

-- RÉSULTAT ATTENDU: ✅ Succès
```

#### **Test 2.2 : Admin peut valider des membres**

```sql
-- Se connecter en tant qu'admin
-- Valider un membre

SELECT valider_membre(
    'pending-user-id'::UUID,
    'chorale-id'::UUID,
    auth.uid(),  -- ID de l'admin connecté
    'Validation test'
);

-- RÉSULTAT ATTENDU: ✅ Succès
```

#### **Test 2.3 : Membre ne peut PAS modifier d'autres profils**

```sql
-- Se connecter en tant que membre
-- Essayer de modifier un autre profil

UPDATE profiles
SET full_name = 'Hacked'
WHERE user_id != auth.uid();

-- RÉSULTAT ATTENDU: ❌ 0 rows updated
```

#### **Test 2.4 : Membre peut voir ses propres permissions**

```sql
-- Se connecter en tant que membre
-- Voir ses permissions

SELECT * FROM user_permissions
WHERE user_id = auth.uid();

-- RÉSULTAT ATTENDU: ✅ Retourne ses permissions uniquement
```

---

## 🌐 TESTS DASHBOARD WEB

### **ÉTAPE 1 : Tests manuels**

#### **Test 1.1 : Connexion et rôles**

```bash
# 1. Ouvrir le dashboard
http://localhost:3000

# 2. Se connecter avec un membre normal
Email: membre@test.com
Password: ****

# 3. Vérifier les restrictions
✅ Peut voir son profil
❌ Ne peut PAS voir "Permissions"
❌ Ne peut PAS voir "Validation"
❌ Ne peut PAS voir "Utilisateurs"
```

#### **Test 1.2 : Connexion Super Admin**

```bash
# 1. Se connecter avec super_admin
Email: kodjodavid2025@gmail.com
Password: ****

# 2. Vérifier les accès
✅ Peut voir "Permissions"
✅ Peut voir "Validation"
✅ Peut voir "Utilisateurs"
✅ Peut modifier les permissions
✅ Peut valider des membres
```

#### **Test 1.3 : Tentative d'escalade de privilèges**

```bash
# 1. Se connecter en tant que membre
# 2. Ouvrir la console (F12)
# 3. Essayer de modifier son rôle:

await supabase
  .from('profiles')
  .update({ role: 'super_admin' })
  .eq('user_id', myUserId)

# RÉSULTAT ATTENDU:
# ❌ Erreur: "new row violates row-level security policy"
```

---

### **ÉTAPE 2 : Tests avec outils**

#### **Test 2.1 : Postman / Insomnia**

```bash
# 1. Créer une requête POST
URL: https://[PROJECT_ID].supabase.co/rest/v1/profiles
Headers:
  apikey: [ANON_KEY]
  Authorization: Bearer [USER_TOKEN]
  Content-Type: application/json

Body:
{
  "user_id": "test-user-id",
  "role": "super_admin"
}

# RÉSULTAT ATTENDU:
# ❌ 403 Forbidden ou erreur RLS
```

#### **Test 2.2 : Tester les permissions**

```bash
# 1. Créer une requête POST
URL: https://[PROJECT_ID].supabase.co/rest/v1/user_permissions
Headers:
  apikey: [ANON_KEY]
  Authorization: Bearer [MEMBRE_TOKEN]  # Token d'un membre normal
  Content-Type: application/json

Body:
{
  "user_id": "target-user-id",
  "module_code": "add_chants"
}

# RÉSULTAT ATTENDU:
# ❌ 403 Forbidden (seuls les super admins peuvent)
```

---

## 📱 TESTS APPLICATION FLUTTER

### **ÉTAPE 1 : Tests manuels**

#### **Test 1.1 : Connexion et validation**

```bash
# 1. Lancer l'app
flutter run

# 2. S'inscrire avec un nouveau compte
Email: newuser@test.com
Password: Test123!

# 3. Vérifier
✅ Écran "En attente de validation" s'affiche
❌ Pas d'accès aux chants
❌ Pas d'accès aux fonctionnalités

# 4. Valider le compte via dashboard web

# 5. Se reconnecter
✅ Accès aux chants
✅ Fonctionnalités disponibles
```

#### **Test 1.2 : Permissions modulaires**

```bash
# 1. Se connecter en tant que membre
# 2. Vérifier les menus

❌ "Ajouter un chant" caché (pas de permission add_chants)
❌ "Gestion Chorales" caché (pas de permission manage_chorales)
✅ "Mes Chants" visible
✅ "Favoris" visible

# 3. Attribuer la permission add_chants via dashboard

# 4. Redémarrer l'app
✅ "Ajouter un chant" maintenant visible
```

#### **Test 1.3 : Super Admin**

```bash
# 1. Se connecter en tant que super_admin
Email: kodjodavid2025@gmail.com

# 2. Vérifier
✅ Badge "Super Admin" affiché
✅ Tous les menus visibles
✅ "Validation des Membres" visible
✅ "Créer Maître de Chœur" visible
```

---

### **ÉTAPE 2 : Tests automatisés Flutter**

#### **Test 2.1 : Créer des tests unitaires**

```dart
// test/services/auth_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_chorale_audio_player/services/enhanced_auth_service.dart';

void main() {
  group('EnhancedAuthService', () {
    late EnhancedAuthService authService;

    setUp(() {
      authService = EnhancedAuthService();
    });

    test('Inscription crée un profil en attente', () async {
      final result = await authService.signUp(
        email: 'test@example.com',
        password: 'Test123!',
        fullName: 'Test User',
      );

      expect(result.success, true);
      expect(result.profile?.statutValidation, 'en_attente');
      expect(result.profile?.role, 'membre');
    });

    test('Super admin a toutes les permissions', () async {
      // Se connecter en tant que super admin
      await authService.signIn(
        email: 'kodjodavid2025@gmail.com',
        password: 'password',
      );

      final permissions = await authService.getUserPermissions();
      
      // Super admin doit avoir toutes les permissions
      expect(permissions.length, greaterThan(10));
      expect(permissions.contains('add_chants'), true);
      expect(permissions.contains('manage_chorales'), true);
    });

    test('Membre sans permission ne peut pas ajouter de chant', () async {
      // Se connecter en tant que membre
      await authService.signIn(
        email: 'membre@test.com',
        password: 'password',
      );

      final permissions = await authService.getUserPermissions();
      
      expect(permissions.contains('add_chants'), false);
    });
  });
}
```

#### **Test 2.2 : Tests d'intégration**

```dart
// integration_test/app_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_chorale_audio_player/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tests de sécurité', () {
    testWidgets('Utilisateur non validé voit écran d\'attente', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Se connecter avec un compte non validé
      await tester.enterText(
        find.byKey(Key('email_field')),
        'pending@test.com',
      );
      await tester.enterText(
        find.byKey(Key('password_field')),
        'Test123!',
      );
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Vérifier qu'on est sur l'écran d'attente
      expect(find.text('En attente de validation'), findsOneWidget);
      expect(find.text('Mes Chants'), findsNothing);
    });

    testWidgets('Super admin voit tous les menus', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Se connecter en tant que super admin
      await tester.enterText(
        find.byKey(Key('email_field')),
        'kodjodavid2025@gmail.com',
      );
      await tester.enterText(
        find.byKey(Key('password_field')),
        'password',
      );
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Ouvrir le menu
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Vérifier que tous les menus admin sont visibles
      expect(find.text('Validation des Membres'), findsOneWidget);
      expect(find.text('Gestion des Chorales'), findsOneWidget);
      expect(find.text('Créer Maître de Chœur'), findsOneWidget);
    });
  });
}
```

---

## 🔓 TESTS DE PÉNÉTRATION

### **Test 1 : Injection SQL**

```typescript
// Dashboard - Essayer d'injecter du SQL
const maliciousInput = "'; DROP TABLE profiles; --"

await supabase
  .from('user_permissions')
  .insert({
    user_id: maliciousInput,
    module_code: 'test'
  })

// RÉSULTAT ATTENDU:
// ❌ Erreur de validation UUID
// ✅ Table profiles toujours intacte
```

### **Test 2 : XSS (Cross-Site Scripting)**

```typescript
// Dashboard - Essayer d'injecter du JavaScript
const maliciousName = '<script>alert("XSS")</script>'

await supabase
  .from('profiles')
  .update({ full_name: maliciousName })
  .eq('user_id', myUserId)

// Recharger la page
// RÉSULTAT ATTENDU:
// ❌ Pas d'alerte JavaScript
// ✅ Le texte est échappé et affiché tel quel
```

### **Test 3 : CSRF (Cross-Site Request Forgery)**

```html
<!-- Créer une page malveillante -->
<html>
<body>
<script>
  // Essayer de faire une requête depuis un autre domaine
  fetch('https://[PROJECT_ID].supabase.co/rest/v1/profiles', {
    method: 'POST',
    headers: {
      'apikey': '[ANON_KEY]',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      user_id: 'victim-id',
      role: 'super_admin'
    })
  })
</script>
</body>
</html>

<!-- RÉSULTAT ATTENDU: -->
<!-- ❌ Bloqué par CORS -->
<!-- ❌ Pas de token d'authentification valide -->
```

### **Test 4 : Brute Force**

```bash
# Essayer de deviner un mot de passe
for i in {1..100}; do
  curl -X POST https://[PROJECT_ID].supabase.co/auth/v1/token \
    -H "apikey: [ANON_KEY]" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"admin@test.com\",\"password\":\"password$i\"}"
done

# RÉSULTAT ATTENDU:
# ❌ Bloqué après X tentatives (rate limiting)
# ✅ Supabase a un rate limiting intégré
```

---

## 🤖 TESTS AUTOMATISÉS

### **Test 1 : Script de test complet**

```bash
# test_security.sh

#!/bin/bash

echo "🧪 Tests de sécurité automatisés"
echo "================================"

# Variables
PROJECT_URL="https://[PROJECT_ID].supabase.co"
ANON_KEY="[ANON_KEY]"
ADMIN_TOKEN="[ADMIN_TOKEN]"
MEMBER_TOKEN="[MEMBER_TOKEN]"

# Test 1: Membre ne peut pas se promouvoir
echo "Test 1: Escalade de privilèges..."
RESULT=$(curl -s -X PATCH "$PROJECT_URL/rest/v1/profiles?user_id=eq.member-id" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $MEMBER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"role":"super_admin"}')

if [[ $RESULT == *"violates row-level security"* ]]; then
  echo "✅ Test 1 PASSÉ: Escalade bloquée"
else
  echo "❌ Test 1 ÉCHOUÉ: Escalade possible!"
  exit 1
fi

# Test 2: Anonyme ne peut pas voir les membres en attente
echo "Test 2: Accès anonyme..."
RESULT=$(curl -s -X GET "$PROJECT_URL/rest/v1/membres_en_attente" \
  -H "apikey: $ANON_KEY")

if [[ $RESULT == "[]" ]] || [[ $RESULT == *"permission denied"* ]]; then
  echo "✅ Test 2 PASSÉ: Accès anonyme bloqué"
else
  echo "❌ Test 2 ÉCHOUÉ: Données exposées!"
  exit 1
fi

# Test 3: Membre ne peut pas attribuer de permissions
echo "Test 3: Attribution de permissions..."
RESULT=$(curl -s -X POST "$PROJECT_URL/rest/v1/user_permissions" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $MEMBER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"target-id","module_code":"add_chants"}')

if [[ $RESULT == *"violates row-level security"* ]]; then
  echo "✅ Test 3 PASSÉ: Attribution bloquée"
else
  echo "❌ Test 3 ÉCHOUÉ: Attribution possible!"
  exit 1
fi

# Test 4: Admin peut attribuer des permissions
echo "Test 4: Admin attribue permissions..."
RESULT=$(curl -s -X POST "$PROJECT_URL/rest/v1/user_permissions" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"target-id","module_code":"add_chants"}')

if [[ $RESULT != *"error"* ]]; then
  echo "✅ Test 4 PASSÉ: Admin peut attribuer"
else
  echo "❌ Test 4 ÉCHOUÉ: Admin bloqué!"
  exit 1
fi

echo ""
echo "✅ Tous les tests sont passés!"
```

### **Test 2 : CI/CD avec GitHub Actions**

```yaml
# .github/workflows/security-tests.yml

name: Tests de Sécurité

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  security-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run unit tests
      run: flutter test
    
    - name: Run integration tests
      run: flutter test integration_test
    
    - name: Security scan
      run: |
        flutter pub global activate dart_code_metrics
        flutter pub global run dart_code_metrics:metrics analyze lib
    
    - name: Check for vulnerabilities
      run: flutter pub outdated
```

---

## 📊 CHECKLIST DE TESTS

### **Avant déploiement:**

- [ ] ✅ Test escalade de privilèges (doit échouer)
- [ ] ✅ Test SECURITY DEFINER bypass (doit échouer)
- [ ] ✅ Test accès anonyme (doit échouer)
- [ ] ✅ Test injection SQL (doit échouer)
- [ ] ✅ Test XSS (doit être échappé)
- [ ] ✅ Super admin peut tout faire
- [ ] ✅ Admin peut valider des membres
- [ ] ✅ Membre ne peut modifier que son profil
- [ ] ✅ Utilisateur non validé voit écran d'attente
- [ ] ✅ Permissions modulaires fonctionnent

### **Tests de performance:**

- [ ] ✅ Dashboard charge en < 2 secondes
- [ ] ✅ App Flutter démarre en < 3 secondes
- [ ] ✅ Pas de fuite mémoire
- [ ] ✅ Rate limiting fonctionne

---

## 🎯 RÉSUMÉ

**Tests SQL:** Vérifier RLS policies et fonctions
**Tests Dashboard:** Vérifier restrictions d'accès
**Tests Flutter:** Vérifier permissions et validation
**Tests Pénétration:** Essayer de hacker le système
**Tests Automatisés:** CI/CD pour chaque commit

**TEMPS TOTAL:** 2-3 heures pour tous les tests

**FRÉQUENCE:**
- Tests manuels: Avant chaque déploiement
- Tests automatisés: À chaque commit
- Tests de pénétration: 1 fois par mois

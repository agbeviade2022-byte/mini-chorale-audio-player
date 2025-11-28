# 🔐 ROOT DE SÉCURITÉ : Inscription → Validation

## 📊 VUE D'ENSEMBLE

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUX D'INSCRIPTION                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. INSCRIPTION (Flutter)                                       │
│     └─> Supabase Auth                                          │
│         └─> Trigger auto                                       │
│             └─> Création profil                                │
│                                                                 │
│  2. ÉTAT: EN ATTENTE                                           │
│     └─> statut_validation = 'en_attente'                      │
│     └─> Écran d'attente (Flutter)                             │
│     └─> Visible dans dashboard admin                          │
│                                                                 │
│  3. VALIDATION (Dashboard Admin)                               │
│     └─> Super Admin valide                                    │
│         └─> Fonction valider_membre()                         │
│             └─> Mise à jour profil                            │
│                                                                 │
│  4. ÉTAT: VALIDÉ                                               │
│     └─> statut_validation = 'valide'                          │
│     └─> Accès complet (Flutter)                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔴 ÉTAPE 1 : INSCRIPTION (Flutter App)

### **Code Flutter**

```dart
// lib/screens/auth/register.dart

Future<void> _handleRegister() async {
  try {
    // 1. Appel à Supabase Auth
    final response = await _supabase.auth.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      data: {
        'full_name': _fullNameController.text,  // ⚠️ Métadonnées
      }
    );
    
    // 2. Vérifier la réponse
    if (response.user != null) {
      // ✅ Compte créé dans auth.users
      // ⏳ Profil en cours de création (trigger)
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingValidationScreen(),
        ),
      );
    }
  } catch (e) {
    // ❌ Erreur
  }
}
```

### **🔒 Points de sécurité:**

1. **Validation côté client**
   ```dart
   // ✅ Validation email
   if (!EmailValidator.validate(email)) {
     throw 'Email invalide';
   }
   
   // ✅ Validation mot de passe
   if (password.length < 8) {
     throw 'Mot de passe trop court';
   }
   ```

2. **Données envoyées**
   ```dart
   data: {
     'full_name': fullName,  // ⚠️ Non vérifié côté serveur
   }
   ```

   **🚨 FAILLE:** Pas de validation serveur des métadonnées
   
   **Exploitation possible:**
   ```dart
   data: {
     'full_name': '<script>alert("XSS")</script>',  // ❌ XSS
     'role': 'super_admin',  // ❌ Tentative d'escalade
   }
   ```

---

## 🟡 ÉTAPE 2 : CRÉATION COMPTE (Supabase Auth)

### **Supabase Auth (Backend)**

```sql
-- Ce qui se passe dans auth.users

INSERT INTO auth.users (
  id,                    -- ✅ UUID généré par Supabase
  email,                 -- ✅ Validé par Supabase
  encrypted_password,    -- ✅ Hashé avec bcrypt
  email_confirmed_at,    -- NULL (si confirmation requise)
  raw_user_meta_data,    -- ⚠️ Métadonnées NON VALIDÉES
  created_at
) VALUES (
  gen_random_uuid(),
  'user@example.com',
  crypt('password', gen_salt('bf')),
  NULL,
  '{"full_name": "User Name"}',  -- ⚠️ Peut contenir n'importe quoi
  NOW()
);
```

### **🔒 Points de sécurité:**

1. **✅ Sécurisé:**
   - UUID généré aléatoirement
   - Email validé (format)
   - Mot de passe hashé (bcrypt)
   - Pas de duplication d'email

2. **⚠️ Risques:**
   - Métadonnées non validées
   - Pas de rate limiting par défaut
   - Email non confirmé (si désactivé)

---

## 🟢 ÉTAPE 3 : TRIGGER AUTO (Création Profil)

### **Trigger SQL**

```sql
-- Fonction trigger (devrait exister)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    user_id,
    full_name,
    role,
    statut_validation,
    statut_membre,
    created_at
  ) VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',  -- ⚠️ Depuis métadonnées
      SPLIT_PART(NEW.email, '@', 1)          -- ✅ Fallback
    ),
    'membre',                                 -- ✅ Rôle par défaut
    'en_attente',                            -- ✅ Validation requise
    'inactif',                               -- ✅ Inactif par défaut
    NEW.created_at
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

### **🔒 Points de sécurité:**

1. **✅ Sécurisé:**
   - Rôle forcé à `'membre'`
   - Statut forcé à `'en_attente'`
   - Pas de choix de chorale (NULL)
   - Membre inactif par défaut

2. **🚨 FAILLES:**
   
   **Faille #1: SECURITY DEFINER**
   ```sql
   SECURITY DEFINER  -- ❌ Exécute avec privilèges postgres
   ```
   - Bypass potentiel des RLS
   - Devrait être `SECURITY INVOKER`

   **Faille #2: Métadonnées non validées**
   ```sql
   full_name = NEW.raw_user_meta_data->>'full_name'  -- ⚠️ Non validé
   ```
   - Peut contenir du HTML/JavaScript
   - Peut contenir des caractères spéciaux
   - Pas de limite de longueur

   **Faille #3: Pas de vérification d'existence**
   ```sql
   INSERT INTO profiles ...  -- ⚠️ Pas de ON CONFLICT
   ```
   - Peut créer des doublons si trigger appelé 2x
   - Devrait avoir `ON CONFLICT (user_id) DO NOTHING`

---

## 🔵 ÉTAPE 4 : ÉTAT EN ATTENTE (Flutter)

### **Écran d'attente**

```dart
// lib/screens/auth/waiting_validation_screen.dart

class WaitingValidationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Icon(Icons.hourglass_empty),
            Text('En attente de validation'),
            Text('Un administrateur doit valider votre compte'),
            // ⏳ Pas d'accès aux chants
          ],
        ),
      ),
    );
  }
}
```

### **Vérification RLS**

```sql
-- RLS Policy sur chants (devrait exister)
CREATE POLICY "Seuls les membres validés peuvent voir les chants"
ON chants
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND statut_validation = 'valide'  -- ✅ Validation requise
  )
);
```

### **🔒 Points de sécurité:**

1. **✅ Sécurisé:**
   - RLS bloque l'accès aux chants
   - Utilisateur ne peut rien faire
   - Message clair affiché

2. **⚠️ Risques:**
   
   **Risque #1: Session active**
   ```dart
   // L'utilisateur a un token valide
   final session = await _supabase.auth.getSession();
   // ✅ session != null
   ```
   - Peut faire des requêtes API
   - Peut essayer de bypass les RLS
   - Token valide pendant 1h

   **Risque #2: Peut modifier son profil**
   ```dart
   await _supabase
     .from('profiles')
     .update({ 'role': 'super_admin' })  // ⚠️ Tentative
     .eq('user_id', userId);
   ```
   - Si RLS mal configuré → Escalade
   - Devrait être bloqué par RLS

---

## 🟣 ÉTAPE 5 : DASHBOARD ADMIN (Visualisation)

### **Vue membres_en_attente**

```sql
CREATE VIEW membres_en_attente AS
SELECT 
    p.user_id,
    au.email::TEXT,                    -- ✅ Email depuis auth.users
    p.full_name,
    p.telephone,
    p.created_at,
    p.statut_validation,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER as jours_attente
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
AND EXISTS (                           -- ✅ Vérification rôle
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'super_admin')
)
ORDER BY p.created_at ASC;
```

### **Dashboard React**

```typescript
// app/dashboard/validation/page.tsx

const { data: pendingMembers } = await supabase
  .from('membres_en_attente')
  .select('*')
  .order('created_at', { ascending: false });

// Affichage
pendingMembers.map(member => (
  <div key={member.user_id}>
    <h3>{member.full_name}</h3>        {/* ⚠️ Peut contenir XSS */}
    <p>{member.email}</p>
    <button onClick={() => validate(member)}>Valider</button>
  </div>
))
```

### **🔒 Points de sécurité:**

1. **✅ Sécurisé:**
   - Vue vérifie le rôle admin
   - Seuls les admins voient les membres
   - Emails récupérés depuis auth.users

2. **🚨 FAILLES:**
   
   **Faille #1: XSS dans full_name**
   ```typescript
   <h3>{member.full_name}</h3>  // ⚠️ Si contient <script>
   ```
   - React échappe par défaut (✅)
   - Mais si utilisé dans dangerouslySetInnerHTML (❌)

   **Faille #2: Données personnelles exposées**
   ```sql
   SELECT email, telephone  -- ⚠️ RGPD
   ```
   - Emails visibles par tous les admins
   - Téléphones visibles
   - Pas de logs d'accès

---

## 🟢 ÉTAPE 6 : VALIDATION (Super Admin)

### **Fonction valider_membre()**

```sql
CREATE FUNCTION valider_membre(
    p_user_id UUID,
    p_chorale_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER  -- ✅ Utilise permissions appelant
AS $$
DECLARE
    v_validateur_role TEXT;
BEGIN
    -- 1. Vérifier que l'appelant est le validateur
    IF p_validateur_id != auth.uid() THEN
        RAISE EXCEPTION 'Non autorisé';  -- ✅ Sécurité
    END IF;
    
    -- 2. Vérifier le rôle du validateur
    SELECT role INTO v_validateur_role
    FROM profiles
    WHERE user_id = auth.uid();
    
    IF v_validateur_role NOT IN ('admin', 'super_admin') THEN
        RAISE EXCEPTION 'Seuls les admins';  -- ✅ Sécurité
    END IF;
    
    -- 3. Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'valide',     -- ✅ Validation
        chorale_id = p_chorale_id,        -- ✅ Attribution chorale
        statut_membre = 'actif'           -- ✅ Activation
    WHERE user_id = p_user_id;
    
    -- 4. Historique
    INSERT INTO validations_membres (
        user_id, validateur_id, action, commentaire
    ) VALUES (
        p_user_id, p_validateur_id, 'validation', p_commentaire
    );
    
    RETURN jsonb_build_object('success', true);
END;
$$;
```

### **🔒 Points de sécurité:**

1. **✅ Sécurisé:**
   - Vérifie que l'appelant est le validateur
   - Vérifie le rôle (admin/super_admin)
   - SECURITY INVOKER (pas DEFINER)
   - Historique des validations
   - Pas de modification du rôle

2. **⚠️ Risques:**
   
   **Risque #1: Pas de vérification de la chorale**
   ```sql
   chorale_id = p_chorale_id  -- ⚠️ Pas de vérification
   ```
   - Peut assigner à une chorale inexistante
   - Devrait vérifier: `EXISTS (SELECT 1 FROM chorales WHERE id = p_chorale_id)`

   **Risque #2: Pas de vérification de l'utilisateur**
   ```sql
   WHERE user_id = p_user_id  -- ⚠️ Pas de vérification
   ```
   - Peut valider un utilisateur inexistant
   - Devrait vérifier: `EXISTS (SELECT 1 FROM profiles WHERE user_id = p_user_id)`

---

## 🔵 ÉTAPE 7 : ACCÈS COMPLET (Flutter)

### **Reconnexion**

```dart
// Après validation, l'utilisateur se reconnecte

final response = await _supabase.auth.signIn(
  email: email,
  password: password,
);

// Récupérer le profil
final profile = await _supabase
  .from('profiles')
  .select('*')
  .eq('user_id', response.user!.id)
  .single();

if (profile['statut_validation'] == 'valide') {
  // ✅ Accès complet
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => HomeScreen()),
  );
} else {
  // ⏳ Toujours en attente
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => WaitingValidationScreen()),
  );
}
```

### **RLS Policies actives**

```sql
-- L'utilisateur peut maintenant accéder aux chants
CREATE POLICY "Membres validés peuvent voir chants"
ON chants
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND statut_validation = 'valide'  -- ✅ Validé
    AND chorale_id IS NOT NULL        -- ✅ A une chorale
  )
);
```

---

## 🚨 RÉSUMÉ DES FAILLES

| # | Étape | Faille | Sévérité | Impact |
|---|-------|--------|----------|--------|
| 1 | Inscription | Métadonnées non validées | 🟡 MOYENNE | XSS possible |
| 2 | Trigger | SECURITY DEFINER | 🔴 HAUTE | Bypass RLS |
| 3 | Trigger | Pas de validation full_name | 🟡 MOYENNE | XSS/Injection |
| 4 | En attente | Session active | 🟡 MOYENNE | Tentatives bypass |
| 5 | Dashboard | XSS dans affichage | 🟡 MOYENNE | XSS (mitigé par React) |
| 6 | Dashboard | Données RGPD exposées | 🟠 HAUTE | Violation RGPD |
| 7 | Validation | Pas de vérif chorale | 🟡 MOYENNE | Données corrompues |
| 8 | Validation | Pas de vérif user | 🟡 MOYENNE | Erreurs silencieuses |

---

## ✅ CORRECTIONS RECOMMANDÉES

Voir fichier: `FIX_ROOT_INSCRIPTION_VALIDATION.sql`

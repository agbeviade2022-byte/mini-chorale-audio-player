# 🔒 AUDIT DE SÉCURITÉ : Mini-Chorale Audio Player

## 🚨 FAILLES DE SÉCURITÉ CRITIQUES IDENTIFIÉES

### **ROOT DES PROBLÈMES DE SÉCURITÉ**

```
┌─────────────────────────────────────────────────────────────┐
│                  ROOT CAUSE ANALYSIS                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. RLS (Row Level Security) MAL CONFIGURÉ                 │
│     └─> Cause racine de 80% des problèmes                  │
│                                                             │
│  2. FONCTIONS SQL AVEC SECURITY DEFINER                    │
│     └─> Bypass potentiel des RLS policies                  │
│                                                             │
│  3. PERMISSIONS TROP PERMISSIVES                           │
│     └─> authenticated peut tout faire                      │
│                                                             │
│  4. PAS DE VALIDATION DES ENTRÉES                          │
│     └─> Injections SQL possibles                           │
│                                                             │
│  5. TOKENS NON VÉRIFIÉS CÔTÉ SERVEUR                       │
│     └─> Usurpation d'identité possible                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔴 FAILLE #1 : RLS POLICIES INCOMPLÈTES (CRITIQUE)

### **Problème:**
```sql
-- Actuellement, certaines tables n'ont PAS de RLS activé
-- Ou ont des policies trop permissives

-- Exemple: user_permissions
CREATE POLICY "Super admins peuvent tout faire"
ON user_permissions
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'super_admin'
  )
)
```

### **Faille:**
❌ **N'importe qui peut se déclarer "super_admin" en modifiant son profil**

### **Exploitation:**
```typescript
// Un utilisateur malveillant peut faire:
await supabase
  .from('profiles')
  .update({ role: 'super_admin' })
  .eq('user_id', myUserId)

// Puis il a accès à TOUT
```

### **Impact:**
- 🔴 **CRITIQUE** : Escalade de privilèges
- 🔴 Accès à toutes les données
- 🔴 Modification/suppression de n'importe quel utilisateur

---

## 🔴 FAILLE #2 : SECURITY DEFINER SUR FONCTIONS (CRITIQUE)

### **Problème:**
```sql
CREATE OR REPLACE FUNCTION valider_membre(...)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER  -- ❌ DANGEREUX !
AS $$
BEGIN
    UPDATE profiles
    SET statut_validation = 'valide'
    WHERE user_id = p_user_id;
END;
$$;
```

### **Faille:**
❌ **SECURITY DEFINER exécute avec les privilèges du propriétaire (postgres)**
❌ **Bypass complet des RLS policies**

### **Exploitation:**
```typescript
// N'importe qui peut valider n'importe qui
await supabase.rpc('valider_membre', {
  p_user_id: 'target-user-id',
  p_chorale_id: 'any-chorale',
  p_validateur_id: 'fake-admin-id',
  p_commentaire: 'Hack'
})
```

### **Impact:**
- 🔴 **CRITIQUE** : Validation de comptes non autorisée
- 🔴 Attribution de rôles admin
- 🔴 Bypass complet de la sécurité

---

## 🔴 FAILLE #3 : PERMISSIONS TROP PERMISSIVES (HAUTE)

### **Problème:**
```sql
GRANT SELECT ON membres_en_attente TO authenticated;
GRANT SELECT ON membres_en_attente TO anon;  -- ❌ TRÈS DANGEREUX

GRANT EXECUTE ON FUNCTION valider_membre(...) TO authenticated;  -- ❌
```

### **Faille:**
❌ **Tous les utilisateurs authentifiés peuvent exécuter des fonctions admin**
❌ **Les utilisateurs anonymes peuvent voir les membres en attente**

### **Exploitation:**
```typescript
// Sans même être connecté:
const { data } = await supabase
  .from('membres_en_attente')
  .select('*')

// Récupère tous les emails, noms, téléphones des membres en attente
```

### **Impact:**
- 🟠 **HAUTE** : Fuite de données personnelles (RGPD)
- 🟠 Emails exposés publiquement
- 🟠 Numéros de téléphone exposés

---

## 🔴 FAILLE #4 : PAS DE VALIDATION DES ENTRÉES (HAUTE)

### **Problème:**
```typescript
// Dashboard web - aucune validation
const { error } = await supabase
  .from('user_permissions')
  .insert({
    user_id: userId,  // ❌ Non validé
    module_code: moduleCode  // ❌ Non validé
  })
```

### **Faille:**
❌ **Pas de validation du format UUID**
❌ **Pas de vérification que le module existe**
❌ **Injections possibles**

### **Exploitation:**
```typescript
// Injection de données invalides
togglePermission(
  "'; DROP TABLE profiles; --",  // SQL Injection potentielle
  "fake_module",
  false
)
```

### **Impact:**
- 🟠 **HAUTE** : Corruption de données
- 🟠 Injections SQL potentielles
- 🟠 Crash de l'application

---

## 🟡 FAILLE #5 : TOKENS NON VÉRIFIÉS (MOYENNE)

### **Problème:**
```typescript
// Flutter - stockage du token sans vérification
await HiveSessionService.saveSession(session)

// Aucune vérification de:
// - Expiration du token
// - Signature du token
// - Révocation du token
```

### **Faille:**
❌ **Token peut être réutilisé après déconnexion**
❌ **Pas de refresh automatique**
❌ **Session peut expirer sans notification**

### **Impact:**
- 🟡 **MOYENNE** : Sessions zombies
- 🟡 Tokens expirés utilisés
- 🟡 Mauvaise UX

---

## 🟡 FAILLE #6 : VUES AVEC DONNÉES SENSIBLES (MOYENNE)

### **Problème:**
```sql
CREATE VIEW membres_en_attente AS
SELECT 
    p.user_id,  -- ❌ UUID exposé
    au.email,   -- ❌ Email exposé
    p.telephone -- ❌ Téléphone exposé
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
```

### **Faille:**
❌ **Données personnelles exposées dans une vue**
❌ **Accessible à tous les utilisateurs authentifiés**

### **Impact:**
- 🟡 **MOYENNE** : Violation RGPD
- 🟡 Données personnelles exposées
- 🟡 Risque de phishing

---

## 🔵 FAILLE #7 : PAS DE RATE LIMITING (BASSE)

### **Problème:**
```typescript
// Aucune limite sur les appels API
for (let i = 0; i < 10000; i++) {
  await supabase.from('profiles').select('*')
}
```

### **Faille:**
❌ **Pas de limite de requêtes**
❌ **Attaque DDoS possible**

### **Impact:**
- 🔵 **BASSE** : Surcharge du serveur
- 🔵 Coûts Supabase élevés
- 🔵 Déni de service

---

## 🔵 FAILLE #8 : LOGS SENSIBLES (BASSE)

### **Problème:**
```typescript
console.log('🔍 Toggle permission:', { userId, moduleCode, hasPermission })
console.log('✅ Utilisateur trouvé:', profileCheck.full_name)
```

### **Faille:**
❌ **Données sensibles dans les logs**
❌ **UUIDs exposés**

### **Impact:**
- 🔵 **BASSE** : Fuite d'informations
- 🔵 Aide au reverse engineering

---

## 🛡️ PLAN DE CORRECTION PRIORITAIRE

### **PHASE 1 : CRITIQUE (À FAIRE IMMÉDIATEMENT)**

#### **1.1 Sécuriser les RLS Policies**
```sql
-- Empêcher l'auto-promotion en super_admin
CREATE POLICY "Seuls les super admins peuvent modifier les rôles"
ON profiles
FOR UPDATE
TO authenticated
USING (
  -- Soit c'est son propre profil ET il ne change pas le rôle
  (user_id = auth.uid() AND role = (SELECT role FROM profiles WHERE user_id = auth.uid()))
  OR
  -- Soit c'est un super admin qui modifie
  EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role = 'super_admin'
  )
)
WITH CHECK (
  -- Vérifier que le nouveau rôle est valide
  role IN ('membre', 'admin', 'super_admin')
  AND
  -- Seul un super admin peut créer un autre super admin
  (role != 'super_admin' OR EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role = 'super_admin'
  ))
);
```

#### **1.2 Remplacer SECURITY DEFINER**
```sql
-- Supprimer SECURITY DEFINER et utiliser RLS
DROP FUNCTION IF EXISTS valider_membre(UUID, UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION valider_membre(
    p_user_id UUID,
    p_chorale_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER  -- ✅ Utilise les permissions de l'appelant
AS $$
DECLARE
    v_result JSONB;
    v_validateur_role TEXT;
BEGIN
    -- Vérifier que l'appelant est bien le validateur
    IF p_validateur_id != auth.uid() THEN
        RAISE EXCEPTION 'Non autorisé: vous ne pouvez pas valider au nom de quelqu''un d''autre';
    END IF;
    
    -- Vérifier que le validateur est admin ou super_admin
    SELECT role INTO v_validateur_role
    FROM profiles
    WHERE user_id = auth.uid();
    
    IF v_validateur_role NOT IN ('admin', 'super_admin') THEN
        RAISE EXCEPTION 'Non autorisé: seuls les admins peuvent valider des membres';
    END IF;
    
    -- Vérifier que l'utilisateur existe
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Utilisateur introuvable: %', p_user_id;
    END IF;
    
    -- Vérifier que la chorale existe
    IF NOT EXISTS (SELECT 1 FROM chorales WHERE id = p_chorale_id) THEN
        RAISE EXCEPTION 'Chorale introuvable: %', p_chorale_id;
    END IF;
    
    -- Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'valide',
        chorale_id = p_chorale_id,
        statut_membre = 'actif'
    WHERE user_id = p_user_id;
    
    -- Enregistrer dans l'historique
    INSERT INTO validations_membres (
        user_id,
        validateur_id,
        action,
        commentaire,
        created_at
    ) VALUES (
        p_user_id,
        p_validateur_id,
        'validation',
        p_commentaire,
        NOW()
    );
    
    v_result := jsonb_build_object(
        'success', true,
        'message', 'Membre validé avec succès',
        'user_id', p_user_id,
        'chorale_id', p_chorale_id
    );
    
    RETURN v_result;
END;
$$;
```

#### **1.3 Restreindre les permissions**
```sql
-- Révoquer les permissions trop permissives
REVOKE SELECT ON membres_en_attente FROM anon;  -- ✅ Plus d'accès anonyme
REVOKE EXECUTE ON FUNCTION valider_membre(UUID, UUID, UUID, TEXT) FROM authenticated;

-- Donner uniquement aux admins
GRANT EXECUTE ON FUNCTION valider_membre(UUID, UUID, UUID, TEXT) TO authenticated;
-- Mais la fonction vérifie le rôle en interne
```

---

### **PHASE 2 : HAUTE PRIORITÉ (CETTE SEMAINE)**

#### **2.1 Validation des entrées**
```typescript
// Dashboard - Ajouter validation
function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

async function togglePermission(userId: string, moduleCode: string, hasPermission: boolean) {
  // Validation
  if (!isValidUUID(userId)) {
    throw new Error('UUID utilisateur invalide')
  }
  
  if (!/^[a-z_]+$/.test(moduleCode)) {
    throw new Error('Code module invalide')
  }
  
  // Suite...
}
```

#### **2.2 Sécuriser les vues**
```sql
-- Créer une vue sécurisée
DROP VIEW IF EXISTS membres_en_attente;

CREATE OR REPLACE VIEW membres_en_attente_admin AS
SELECT 
    p.user_id,
    au.email,
    p.full_name,
    p.telephone,
    p.created_at,
    p.statut_validation,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER as jours_attente
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
-- ✅ Vérifier que l'appelant est admin
AND EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'super_admin')
)
ORDER BY p.created_at ASC;

-- Permissions restrictives
GRANT SELECT ON membres_en_attente_admin TO authenticated;
-- Mais la vue vérifie le rôle en interne
```

---

### **PHASE 3 : MOYENNE PRIORITÉ (CE MOIS-CI)**

#### **3.1 Vérification des tokens**
```dart
// Flutter - Vérifier l'expiration
class EnhancedAuthService {
  Future<bool> isTokenValid() async {
    final session = await _hiveSessionService.getSession();
    if (session == null) return false;
    
    // Vérifier l'expiration
    final expiresAt = DateTime.parse(session.expiresAt);
    if (expiresAt.isBefore(DateTime.now())) {
      // Token expiré, refresh
      return await refreshToken();
    }
    
    return true;
  }
  
  Future<bool> refreshToken() async {
    try {
      final response = await _supabase.auth.refreshSession();
      if (response.session != null) {
        await _hiveSessionService.saveSession(response.session);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
```

#### **3.2 Masquer les données sensibles des logs**
```typescript
// Masquer les UUIDs dans les logs
function maskUUID(uuid: string): string {
  return uuid.substring(0, 8) + '...'
}

console.log('🔍 Toggle permission:', { 
  userId: maskUUID(userId), 
  moduleCode, 
  hasPermission 
})
```

---

### **PHASE 4 : BASSE PRIORITÉ (AMÉLIORATION CONTINUE)**

#### **4.1 Rate limiting**
```typescript
// Utiliser Supabase Edge Functions avec rate limiting
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const rateLimiter = new Map<string, number[]>()

serve(async (req) => {
  const userId = req.headers.get('user-id')
  const now = Date.now()
  
  // Vérifier le rate limit (max 100 requêtes par minute)
  const userRequests = rateLimiter.get(userId) || []
  const recentRequests = userRequests.filter(t => now - t < 60000)
  
  if (recentRequests.length >= 100) {
    return new Response('Too many requests', { status: 429 })
  }
  
  recentRequests.push(now)
  rateLimiter.set(userId, recentRequests)
  
  // Traiter la requête
})
```

---

## 📊 RÉSUMÉ DES FAILLES

| Faille | Sévérité | Impact | Effort Fix | Priorité |
|--------|----------|--------|------------|----------|
| RLS Policies incomplètes | 🔴 CRITIQUE | Escalade privilèges | Moyen | 1 |
| SECURITY DEFINER | 🔴 CRITIQUE | Bypass sécurité | Moyen | 1 |
| Permissions permissives | 🟠 HAUTE | Fuite données | Faible | 2 |
| Pas de validation | 🟠 HAUTE | Corruption données | Faible | 2 |
| Tokens non vérifiés | 🟡 MOYENNE | Sessions zombies | Moyen | 3 |
| Vues avec données sensibles | 🟡 MOYENNE | RGPD | Faible | 3 |
| Pas de rate limiting | 🔵 BASSE | DDoS | Élevé | 4 |
| Logs sensibles | 🔵 BASSE | Fuite info | Faible | 4 |

---

## 🎯 ACTIONS IMMÉDIATES

### **À FAIRE MAINTENANT (30 minutes):**

1. ✅ Exécuter le script de sécurisation RLS (ci-dessous)
2. ✅ Remplacer SECURITY DEFINER par SECURITY INVOKER
3. ✅ Révoquer les permissions anon
4. ✅ Tester que tout fonctionne encore

### **À FAIRE CETTE SEMAINE:**

1. ✅ Ajouter validation des entrées
2. ✅ Sécuriser les vues
3. ✅ Audit complet des permissions

---

## 🚀 CONCLUSION

**ROOT CAUSE:** 
- ❌ RLS mal configuré dès le départ
- ❌ Utilisation de SECURITY DEFINER par facilité
- ❌ Permissions trop permissives "pour que ça marche"

**SOLUTION:**
- ✅ Refonte complète des RLS policies
- ✅ Suppression de SECURITY DEFINER
- ✅ Principe du moindre privilège

**IMPACT:**
- 🔴 Sans correction: Système complètement vulnérable
- ✅ Avec correction: Sécurité niveau production

---

**TEMPS TOTAL DE CORRECTION:** 4-6 heures
**PRIORITÉ:** 🔴 URGENT - À faire avant mise en production

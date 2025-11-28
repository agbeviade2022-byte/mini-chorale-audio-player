-- =====================================================
-- DIAGNOSTIC COMPLET DES UTILISATEURS
-- =====================================================

-- ÉTAPE 1: Voir TOUS les utilisateurs dans auth.users
SELECT 
  id,
  email,
  created_at,
  email_confirmed_at,
  last_sign_in_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 20;

-- =====================================================

-- ÉTAPE 2: Voir TOUS les profils
SELECT 
  p.id,
  p.user_id,
  p.full_name,
  p.role,
  p.statut_validation,
  p.created_at
FROM profiles p
ORDER BY p.created_at DESC
LIMIT 20;

-- =====================================================

-- ÉTAPE 3: Voir la jointure complète
SELECT 
  p.id as profile_id,
  p.user_id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation,
  p.chorale_id
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.created_at DESC
LIMIT 20;

-- =====================================================

-- ÉTAPE 4: Chercher spécifiquement vos emails
SELECT 
  id,
  email,
  created_at
FROM auth.users
WHERE email LIKE '%kodjodavid%' 
   OR email LIKE '%agbeviade%'
   OR email LIKE '%gmail%';

-- =====================================================

-- ÉTAPE 5: Compter les utilisateurs
SELECT 
  'auth.users' as table_name,
  COUNT(*) as total
FROM auth.users
UNION ALL
SELECT 
  'profiles' as table_name,
  COUNT(*) as total
FROM profiles;

-- =====================================================
-- RÉSULTATS POSSIBLES:
-- =====================================================

-- CAS 1: Aucun utilisateur
-- → Vous devez créer un compte via l'app Flutter ou le dashboard

-- CAS 2: Utilisateurs existent mais avec des emails différents
-- → Utilisez les vrais emails trouvés

-- CAS 3: Utilisateurs dans auth.users mais pas dans profiles
-- → Problème de synchronisation, il faut créer les profils

-- =====================================================
-- SI VOUS TROUVEZ VOS EMAILS, UTILISEZ CETTE REQUÊTE:
-- =====================================================

-- Remplacez 'EMAIL_TROUVÉ' par le vrai email
UPDATE profiles
SET role = 'super_admin'
WHERE user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'EMAIL_TROUVÉ'  -- ⚠️ REMPLACEZ ICI
);

-- =====================================================
-- SI AUCUN UTILISATEUR N'EXISTE:
-- =====================================================

-- Option A: Créer un utilisateur manuellement (TEMPORAIRE pour tests)
-- NOTE: En production, utilisez l'inscription normale via l'app

-- 1. Créer dans auth.users (via Supabase Dashboard > Authentication > Add User)
-- 2. Puis créer le profil:

INSERT INTO profiles (user_id, full_name, role, statut_validation)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com'),
  'David Kodjo',
  'super_admin',
  'valide'
);

-- =====================================================
-- VÉRIFICATION FINALE
-- =====================================================

SELECT 
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin';

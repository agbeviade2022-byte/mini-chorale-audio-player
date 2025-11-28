-- =====================================================
-- CORRIGER LES EMAILS NULL - LIER PROFILES À AUTH.USERS
-- =====================================================

-- ÉTAPE 1: Voir tous les utilisateurs dans auth.users
SELECT 
  id as auth_user_id,
  email,
  created_at,
  email_confirmed_at
FROM auth.users
ORDER BY created_at DESC;

-- =====================================================

-- ÉTAPE 2: Voir les profils avec leurs user_id actuels
SELECT 
  p.id as profile_id,
  p.user_id,
  p.full_name,
  p.role,
  au.email
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.created_at DESC;

-- =====================================================

-- ÉTAPE 3: Identifier les correspondances
-- Vous devez matcher manuellement les profils avec les emails

-- Exemple de correspondance probable:
-- Profile: David Kodjo (fec9ae76-52a9-43ac-814a-f1e44eb02397)
-- Auth.users: kodjodavid2025@gmail.com

-- Profile: Kodjo David (0e595ee6-bdee-47d4-b7a9-4a693f54f1e7)
-- Auth.users: agbeviade2017@gmail.com (ou autre)

-- =====================================================

-- ÉTAPE 4: Mettre à jour les liens (APRÈS avoir identifié les correspondances)

-- Exemple 1: Lier David Kodjo à kodjodavid2025@gmail.com
UPDATE profiles
SET user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'kodjodavid2025@gmail.com'  -- ⚠️ REMPLACEZ par le vrai email
)
WHERE id = 'fec9ae76-52a9-43ac-814a-f1e44eb02397';  -- David Kodjo

-- =====================================================

-- Exemple 2: Lier Kodjo David à agbeviade2017@gmail.com
UPDATE profiles
SET user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'agbeviade2017@gmail.com'  -- ⚠️ REMPLACEZ par le vrai email
)
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';  -- Kodjo David

-- =====================================================

-- ÉTAPE 5: Vérifier que les liens sont corrects
SELECT 
  p.id as profile_id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.full_name;

-- Résultat attendu:
-- profile_id                           | full_name   | email                      | role  | statut_validation
-- -------------------------------------+-------------+----------------------------+-------+------------------
-- fec9ae76-52a9-43ac-814a-f1e44eb02397 | David Kodjo | kodjodavid2025@gmail.com   | admin | valide
-- 0e595ee6-bdee-47d4-b7a9-4a693f54f1e7 | Kodjo David | agbeviade2017@gmail.com    | user  | valide

-- =====================================================

-- ÉTAPE 6: Mettre David Kodjo en Super Admin
UPDATE profiles
SET role = 'super_admin'
WHERE id = 'fec9ae76-52a9-43ac-814a-f1e44eb02397';

-- =====================================================

-- ÉTAPE 7: Vérification finale
SELECT 
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin';

-- Résultat attendu:
-- full_name   | email                      | role        | statut_validation
-- ------------+----------------------------+-------------+------------------
-- David Kodjo | kodjodavid2025@gmail.com   | super_admin | valide

-- =====================================================
-- SI AUCUN EMAIL N'EXISTE DANS AUTH.USERS
-- =====================================================

-- CAS: Si auth.users est vide ou ne contient pas vos emails
-- Vous devez créer les utilisateurs via Supabase Dashboard:
-- 1. Aller sur Supabase Dashboard
-- 2. Authentication > Users > Add User
-- 3. Créer les utilisateurs avec les bons emails
-- 4. Puis revenir exécuter les UPDATE ci-dessus

-- =====================================================
-- ALTERNATIVE: Créer les utilisateurs en SQL (si droits suffisants)
-- =====================================================

-- NOTE: Cette méthode peut ne pas fonctionner selon vos permissions
-- Préférez la création via Supabase Dashboard

-- Créer kodjodavid2025@gmail.com
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'kodjodavid2025@gmail.com',
  crypt('MotDePasseTemporaire123!', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
);

-- Puis lier au profil
UPDATE profiles
SET user_id = (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com')
WHERE id = 'fec9ae76-52a9-43ac-814a-f1e44eb02397';

-- =====================================================
-- RÉSUMÉ DES ÉTAPES
-- =====================================================

-- 1. Exécuter ÉTAPE 1 pour voir les emails dans auth.users
-- 2. Identifier quels emails correspondent à quels profils
-- 3. Exécuter les UPDATE de l'ÉTAPE 4 avec les bons emails
-- 4. Vérifier avec ÉTAPE 5
-- 5. Mettre en Super Admin avec ÉTAPE 6
-- 6. Vérification finale avec ÉTAPE 7

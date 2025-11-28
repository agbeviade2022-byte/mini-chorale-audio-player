-- =====================================================
-- CRÉER LE SUPER ADMIN - ÉTAPE PAR ÉTAPE
-- =====================================================

-- ÉTAPE 1: Vérifier que agbeviade2017@gmail.com existe dans auth.users
SELECT 
  id,
  email,
  email_confirmed_at
FROM auth.users
WHERE email = 'agbeviade2017@gmail.com';

-- Si vous voyez l'email, passez à l'ÉTAPE 2
-- Si "No rows returned", retournez dans Supabase Dashboard pour créer l'utilisateur

-- =====================================================

-- ÉTAPE 2: Vérifier le profil existant
SELECT 
  id,
  user_id,
  full_name,
  role
FROM profiles
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu:
-- id                                   | user_id | full_name   | role
-- -------------------------------------+---------+-------------+------
-- 0e595ee6-bdee-47d4-b7a9-4a693f54f1e7 | NULL    | Kodjo David | user

-- =====================================================

-- ÉTAPE 3: Lier le profil à l'utilisateur auth.users
UPDATE profiles
SET user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'agbeviade2017@gmail.com'
)
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu: UPDATE 1

-- =====================================================

-- ÉTAPE 4: Vérifier que le lien a fonctionné
SELECT 
  p.id,
  p.user_id,
  p.full_name,
  au.email,
  p.role
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu:
-- id                                   | user_id      | full_name   | email                    | role
-- -------------------------------------+--------------+-------------+--------------------------+------
-- 0e595ee6-bdee-47d4-b7a9-4a693f54f1e7 | uuid-here    | Kodjo David | agbeviade2017@gmail.com  | user

-- ⚠️ Si email est toujours NULL, l'UPDATE de l'ÉTAPE 3 n'a pas fonctionné
-- Vérifiez que l'utilisateur existe bien dans auth.users (retour ÉTAPE 1)

-- =====================================================

-- ÉTAPE 5: Mettre le profil en Super Admin
UPDATE profiles
SET role = 'super_admin'
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu: UPDATE 1

-- =====================================================

-- ÉTAPE 6: VÉRIFICATION FINALE
SELECT 
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin'
ORDER BY au.email;

-- Résultat attendu:
-- full_name   | email                    | role        | statut_validation
-- ------------+--------------------------+-------------+------------------
-- Kodjo David | agbeviade2017@gmail.com  | super_admin | valide

-- =====================================================

-- ÉTAPE 7: Voir TOUS les profils pour diagnostic
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.role,
  p.user_id
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.full_name;

-- =====================================================
-- SI AUCUN RÉSULTAT À L'ÉTAPE 6
-- =====================================================

-- Diagnostic: Vérifier si le rôle a bien été mis à jour
SELECT 
  id,
  full_name,
  role,
  user_id
FROM profiles
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Si role = 'user' au lieu de 'super_admin', réexécutez l'ÉTAPE 5

-- =====================================================
-- ALTERNATIVE: Utiliser David Kodjo (qui est déjà admin)
-- =====================================================

-- Si agbeviade2017@gmail.com pose problème, utilisez David Kodjo:

-- 1. Créer kodjodavid2025@gmail.com dans Supabase Dashboard
-- 2. Puis exécuter:

UPDATE profiles
SET 
  user_id = (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com'),
  role = 'super_admin'
WHERE id = 'fec9ae76-52a9-43ac-814a-f1e44eb02397';

-- Vérifier:
SELECT 
  p.full_name,
  au.email,
  p.role
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.id = 'fec9ae76-52a9-43ac-814a-f1e44eb02397';

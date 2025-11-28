-- =====================================================
-- CRÉER LE PROFIL POUR agbeviade2017@gmail.com
-- =====================================================
-- User ID: c051d34a-bdc9-4ba2-893d-e17e3c0e19a8
-- Email: agbeviade2017@gmail.com
-- =====================================================

-- ÉTAPE 1: Vérifier que l'utilisateur existe dans auth.users
SELECT 
  id,
  email,
  email_confirmed_at
FROM auth.users
WHERE id = 'c051d34a-bdc9-4ba2-893d-e17e3c0e19a8';

-- Résultat attendu:
-- id                                   | email                    | email_confirmed_at
-- -------------------------------------+--------------------------+-------------------------
-- c051d34a-bdc9-4ba2-893d-e17e3c0e19a8 | agbeviade2017@gmail.com  | 2025-11-20 14:08:00

-- =====================================================

-- ÉTAPE 2: Vérifier si un profil existe déjà pour cet user_id
SELECT 
  id,
  user_id,
  full_name,
  role
FROM profiles
WHERE user_id = 'c051d34a-bdc9-4ba2-893d-e17e3c0e19a8';

-- Si "No rows returned", passez à l'ÉTAPE 3
-- Si un profil existe, passez directement à l'ÉTAPE 4

-- =====================================================

-- ÉTAPE 3: Créer le profil pour agbeviade2017@gmail.com
INSERT INTO profiles (
  user_id,
  full_name,
  role,
  statut_validation
) VALUES (
  'c051d34a-bdc9-4ba2-893d-e17e3c0e19a8',
  'Agbeviade',  -- ⚠️ Modifiez le nom si nécessaire
  'super_admin',
  'valide'
);

-- Résultat attendu: INSERT 0 1

-- =====================================================

-- ÉTAPE 4: Vérifier que le profil a été créé
SELECT 
  p.id as profile_id,
  p.user_id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.user_id = 'c051d34a-bdc9-4ba2-893d-e17e3c0e19a8';

-- Résultat attendu:
-- profile_id                           | user_id                              | full_name  | email                    | role        | statut_validation
-- -------------------------------------+--------------------------------------+------------+--------------------------+-------------+------------------
-- uuid-nouveau                         | c051d34a-bdc9-4ba2-893d-e17e3c0e19a8 | Agbeviade  | agbeviade2017@gmail.com  | super_admin | valide

-- =====================================================

-- ÉTAPE 5: Vérifier tous les Super Admins
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
-- full_name  | email                    | role        | statut_validation
-- -----------+--------------------------+-------------+------------------
-- Agbeviade  | agbeviade2017@gmail.com  | super_admin | valide

-- =====================================================

-- ÉTAPE 6: Voir tous les profils
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.role,
  p.user_id
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.role DESC, p.full_name;

-- =====================================================

-- ÉTAPE 7: Tester la création d'un Maître de Chœur
-- Vérifier les chorales disponibles
SELECT id, nom FROM chorales ORDER BY nom;

-- =====================================================

-- ÉTAPE 8: Créer un Maître de Chœur
SELECT creer_maitre_choeur(
  p_email := 'maitre.test@example.com',
  p_full_name := 'Maître Test',
  p_chorale_id := (SELECT id FROM chorales LIMIT 1),
  p_super_admin_id := (SELECT id FROM profiles WHERE user_id = 'c051d34a-bdc9-4ba2-893d-e17e3c0e19a8')
);

-- Résultat attendu:
-- {
--   "success": true,
--   "profile_id": "uuid-here",
--   "affiliation_code": "MC-A3F8B2E1",
--   "lien_affiliation": "/register?ref=MC-A3F8B2E1",
--   "email": "maitre.test@example.com"
-- }

-- =====================================================
-- ALTERNATIVE: Utiliser David Kodjo existant
-- =====================================================

-- Si vous préférez utiliser David Kodjo qui existe déjà:
UPDATE profiles
SET role = 'super_admin'
WHERE id = 'fec9ae76-52a9-43ac-814a-f1e44eb02397';

-- Vérifier:
SELECT 
  p.full_name,
  p.role
FROM profiles p
WHERE id = 'fec9ae76-52a9-43ac-814a-f1e44eb02397';

-- =====================================================
-- RÉSUMÉ
-- =====================================================

-- Problème: Le compte existe dans auth.users mais pas de profil dans profiles
-- Solution: Créer le profil manuellement avec INSERT INTO profiles
-- Résultat: Super Admin opérationnel et prêt à créer des Maîtres de Chœur

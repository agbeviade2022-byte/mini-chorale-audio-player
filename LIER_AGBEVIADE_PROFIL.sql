-- =====================================================
-- LIER agbeviade2017@gmail.com AU PROFIL EXISTANT
-- =====================================================

-- PRÉREQUIS: Avoir créé l'utilisateur via Supabase Dashboard
-- Email: agbeviade2017@gmail.com
-- ✅ Auto Confirm User coché

-- =====================================================

-- ÉTAPE 1: Vérifier que l'utilisateur a été créé dans auth.users
SELECT 
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users
WHERE email = 'agbeviade2017@gmail.com';

-- Résultat attendu:
-- id                                   | email                    | email_confirmed_at      | created_at
-- -------------------------------------+--------------------------+-------------------------+-------------------------
-- uuid-here                            | agbeviade2017@gmail.com  | 2025-11-20 13:54:00     | 2025-11-20 13:54:00

-- =====================================================

-- ÉTAPE 2: Lier le profil existant à cet utilisateur
UPDATE profiles
SET user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'agbeviade2017@gmail.com'
)
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu: UPDATE 1

-- =====================================================

-- ÉTAPE 3: Vérifier que le lien est correct
SELECT 
  p.id as profile_id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation,
  p.user_id
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu:
-- profile_id                           | full_name   | email                    | role | statut_validation | user_id
-- -------------------------------------+-------------+--------------------------+------+-------------------+----------
-- 0e595ee6-bdee-47d4-b7a9-4a693f54f1e7 | Kodjo David | agbeviade2017@gmail.com  | user | valide            | uuid-here

-- =====================================================

-- ÉTAPE 4 (OPTIONNEL): Mettre en Super Admin
UPDATE profiles
SET role = 'super_admin'
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

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
-- full_name   | email                      | role        | statut_validation
-- ------------+----------------------------+-------------+------------------
-- Kodjo David | agbeviade2017@gmail.com    | super_admin | valide
-- David Kodjo | kodjodavid2025@gmail.com   | super_admin | valide (si créé)

-- =====================================================

-- ÉTAPE 6: Voir tous les profils avec leurs emails
SELECT 
  p.id as profile_id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.full_name;

-- =====================================================
-- MAINTENANT VOUS POUVEZ CRÉER DES MAÎTRES DE CHŒUR
-- =====================================================

-- Vérifier les chorales disponibles
SELECT id, nom FROM chorales ORDER BY nom;

-- Créer un Maître de Chœur
SELECT creer_maitre_choeur(
  p_email := 'maitre.test@example.com',
  p_full_name := 'Maître Test',
  p_chorale_id := (SELECT id FROM chorales LIMIT 1),
  p_super_admin_id := '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7'  -- Kodjo David
);

-- Résultat attendu:
-- {
--   "success": true,
--   "profile_id": "uuid-here",
--   "affiliation_code": "MC-A3F8B2E1",
--   "lien_affiliation": "/register?ref=MC-A3F8B2E1",
--   "email": "maitre.test@example.com"
-- }

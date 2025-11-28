-- =====================================================
-- CRÉER kodjodavid2025@gmail.com COMME SUPER ADMIN
-- =====================================================

-- ÉTAPE 1: Vérifier si kodjodavid2025@gmail.com existe dans auth.users
SELECT 
  id,
  email,
  email_confirmed_at
FROM auth.users
WHERE email = 'kodjodavid2025@gmail.com';

-- Si "No rows returned", vous devez créer l'utilisateur dans Supabase Dashboard:
-- 1. Authentication > Users > Add User
-- 2. Email: kodjodavid2025@gmail.com
-- 3. Password: VotreMotDePasse123!
-- 4. ✅ Cocher "Auto Confirm User"
-- 5. Cliquer "Create User"

-- Si vous voyez l'email, notez l'ID et passez à l'ÉTAPE 2

-- =====================================================

-- ÉTAPE 2: Vérifier si un profil existe pour kodjodavid2025@gmail.com
SELECT 
  p.id,
  p.user_id,
  p.full_name,
  au.email,
  p.role
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE au.email = 'kodjodavid2025@gmail.com';

-- Si "No rows returned", passez à l'ÉTAPE 3
-- Si un profil existe, passez à l'ÉTAPE 4

-- =====================================================

-- ÉTAPE 3: Créer le profil pour kodjodavid2025@gmail.com
-- ⚠️ REMPLACEZ 'USER_ID_ICI' par l'ID trouvé à l'ÉTAPE 1

INSERT INTO profiles (
  user_id,
  full_name,
  role,
  statut_validation
) VALUES (
  (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com'),
  'David Kodjo',
  'super_admin',
  'valide'
);

-- Résultat attendu: INSERT 0 1

-- =====================================================

-- ÉTAPE 4: Si le profil existe déjà, le mettre en Super Admin
UPDATE profiles
SET role = 'super_admin'
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com');

-- Résultat attendu: UPDATE 1

-- =====================================================

-- ÉTAPE 5: VÉRIFICATION FINALE
SELECT 
  p.id as profile_id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE au.email = 'kodjodavid2025@gmail.com';

-- Résultat attendu:
-- profile_id                           | full_name   | email                      | role        | statut_validation
-- -------------------------------------+-------------+----------------------------+-------------+------------------
-- uuid-here                            | David Kodjo | kodjodavid2025@gmail.com   | super_admin | valide

-- =====================================================

-- ÉTAPE 6: Vérifier tous les Super Admins
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
-- Agbeviade   | agbeviade2017@gmail.com    | super_admin | valide (si créé)
-- David Kodjo | kodjodavid2025@gmail.com   | super_admin | valide

-- =====================================================

-- ÉTAPE 7: Voir tous les profils
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.role,
  p.est_maitre_choeur
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY 
  CASE p.role 
    WHEN 'super_admin' THEN 1
    WHEN 'admin' THEN 2
    ELSE 3
  END,
  p.full_name;

-- =====================================================

-- ÉTAPE 8: Tester la création d'un Maître de Chœur
-- Vérifier les chorales disponibles
SELECT id, nom, description FROM chorales ORDER BY nom;

-- =====================================================

-- ÉTAPE 9: Créer un Maître de Chœur de test
SELECT creer_maitre_choeur(
  p_email := 'maitre.test@example.com',
  p_full_name := 'Maître Test',
  p_chorale_id := (SELECT id FROM chorales LIMIT 1),
  p_super_admin_id := (SELECT id FROM profiles WHERE user_id = (SELECT id FROM auth.users WHERE email = 'kodjodavid2025@gmail.com'))
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

-- ÉTAPE 10: Vérifier les Maîtres de Chœur créés
SELECT 
  p.full_name,
  au.email,
  p.role,
  p.est_maitre_choeur,
  p.affiliation_code,
  p.lien_affiliation,
  c.nom as chorale
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
LEFT JOIN chorales c ON p.chorale_id = c.id
WHERE p.est_maitre_choeur = true;

-- =====================================================

-- ÉTAPE 11: Vérifier les permissions du MC
SELECT get_user_permissions(
  (SELECT id FROM profiles WHERE est_maitre_choeur = true LIMIT 1)
);

-- Résultat attendu: JSON avec les permissions du MC

-- =====================================================
-- RÉSUMÉ
-- =====================================================

-- 1. Créer kodjodavid2025@gmail.com dans Supabase Dashboard (si pas déjà fait)
-- 2. Créer ou mettre à jour le profil en super_admin
-- 3. Tester la création d'un Maître de Chœur
-- 4. Vérifier les permissions

-- =====================================================
-- FINALISER LA CRÉATION DU SUPER ADMIN
-- =====================================================
-- User ID: c051d34a-bdc9-4ba2-893d-e17e3c0e19a8
-- Email: agbeviade2017@gmail.com
-- Profile ID: 0e595ee6-bdee-47d4-b7a9-4a693f54f1e7
-- =====================================================

-- ÉTAPE 1: Lier le profil à l'utilisateur auth.users
UPDATE profiles
SET user_id = 'c051d34a-bdc9-4ba2-893d-e17e3c0e19a8'
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu: UPDATE 1

-- =====================================================

-- ÉTAPE 2: Vérifier que le lien a fonctionné
SELECT 
  p.id as profile_id,
  p.user_id,
  p.full_name,
  au.email,
  p.role
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu:
-- profile_id                           | user_id                              | full_name   | email                    | role
-- -------------------------------------+--------------------------------------+-------------+--------------------------+------
-- 0e595ee6-bdee-47d4-b7a9-4a693f54f1e7 | c051d34a-bdc9-4ba2-893d-e17e3c0e19a8 | Kodjo David | agbeviade2017@gmail.com  | user

-- =====================================================

-- ÉTAPE 3: Mettre en Super Admin
UPDATE profiles
SET role = 'super_admin'
WHERE id = '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7';

-- Résultat attendu: UPDATE 1

-- =====================================================

-- ÉTAPE 4: VÉRIFICATION FINALE
SELECT 
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin';

-- Résultat attendu:
-- full_name   | email                    | role        | statut_validation
-- ------------+--------------------------+-------------+------------------
-- Kodjo David | agbeviade2017@gmail.com  | super_admin | valide

-- =====================================================

-- ÉTAPE 5: Tester la création d'un Maître de Chœur
-- Vérifier d'abord les chorales disponibles
SELECT id, nom FROM chorales ORDER BY nom;

-- =====================================================

-- ÉTAPE 6: Créer un Maître de Chœur de test
SELECT creer_maitre_choeur(
  p_email := 'maitre.test@example.com',
  p_full_name := 'Maître Test',
  p_chorale_id := (SELECT id FROM chorales LIMIT 1),
  p_super_admin_id := '0e595ee6-bdee-47d4-b7a9-4a693f54f1e7'
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

-- ÉTAPE 7: Vérifier le Maître de Chœur créé
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

-- ÉTAPE 8: Vérifier les permissions du MC
SELECT get_user_permissions(
  (SELECT id FROM profiles WHERE est_maitre_choeur = true LIMIT 1)
);

-- Résultat attendu: JSON avec les permissions du MC

-- =====================================================
-- RÉSUMÉ FINAL
-- =====================================================

-- Voir tous les utilisateurs avec leurs rôles
SELECT 
  p.full_name,
  au.email,
  p.role,
  p.est_maitre_choeur,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY 
  CASE p.role 
    WHEN 'super_admin' THEN 1
    WHEN 'admin' THEN 2
    ELSE 3
  END,
  p.full_name;

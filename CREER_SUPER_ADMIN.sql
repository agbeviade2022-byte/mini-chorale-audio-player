-- =====================================================
-- CRÉER LE SUPER ADMIN
-- =====================================================

-- Étape 1: Vérifier les utilisateurs existants
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.created_at DESC;

-- =====================================================

-- Étape 2: Mettre à jour votre profil en Super Admin
-- REMPLACEZ 'votre-email@example.com' par votre vrai email

UPDATE profiles
SET role = 'super_admin'
WHERE user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'agbeviade2017@gmail.com'  -- ⚠️ REMPLACEZ PAR VOTRE EMAIL
);

-- =====================================================

-- Étape 3: Vérifier que le Super Admin a été créé
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin';

-- Résultat attendu:
-- id                                   | full_name  | email                    | role        | statut_validation
-- -------------------------------------+------------+--------------------------+-------------+------------------
-- uuid-here                            | Agbeviade  | agbeviade2017@gmail.com  | super_admin | valide

-- =====================================================

-- Étape 4: Vérifier les chorales existantes
SELECT id, nom, description 
FROM chorales 
ORDER BY nom;

-- =====================================================

-- Étape 5: Créer un Maître de Chœur (APRÈS avoir créé le SA)
-- Cette requête ne fonctionnera QUE si vous avez exécuté l'étape 2

SELECT creer_maitre_choeur(
  p_email := 'maitre.test@example.com',  -- Email du futur MC
  p_full_name := 'Jean Dupont',          -- Nom du MC
  p_chorale_id := (SELECT id FROM chorales WHERE nom = 'Chorale St Camille'),
  p_super_admin_id := (SELECT id FROM profiles WHERE role = 'super_admin' LIMIT 1)
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

-- Étape 6: Vérifier les Maîtres de Chœur créés
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

-- Étape 7: Vérifier les permissions d'un Maître de Chœur
SELECT get_user_permissions(
  (SELECT id FROM profiles WHERE est_maitre_choeur = true LIMIT 1)
);

-- Résultat attendu: JSON avec les permissions du MC

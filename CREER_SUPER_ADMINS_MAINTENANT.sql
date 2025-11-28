-- =====================================================
-- CRÉER LES SUPER ADMINS MAINTENANT
-- =====================================================

-- ÉTAPE 1: Vérifier que les comptes existent
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE au.email IN ('kodjodavid2025@gmail.com', 'agbeviade2017@gmail.com')
ORDER BY au.email;

-- =====================================================

-- ÉTAPE 2: Créer DEUX Super Admins (RECOMMANDÉ)
UPDATE profiles
SET role = 'super_admin'
WHERE user_id IN (
  SELECT id FROM auth.users 
  WHERE email IN ('kodjodavid2025@gmail.com', 'agbeviade2017@gmail.com')
);

-- =====================================================

-- ÉTAPE 3: Vérifier que ça a fonctionné
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin'
ORDER BY au.email;

-- Résultat attendu:
-- id                                   | full_name  | email                      | role        | statut_validation
-- -------------------------------------+------------+----------------------------+-------------+------------------
-- uuid-1                               | Agbeviade  | agbeviade2017@gmail.com    | super_admin | valide
-- uuid-2                               | David      | kodjodavid2025@gmail.com   | super_admin | valide

-- =====================================================

-- ÉTAPE 4: Maintenant vous pouvez créer un Maître de Chœur
-- Vérifier d'abord les chorales disponibles
SELECT id, nom, description 
FROM chorales 
ORDER BY nom;

-- =====================================================

-- ÉTAPE 5: Créer un Maître de Chœur
-- REMPLACEZ les valeurs selon vos besoins

SELECT creer_maitre_choeur(
  p_email := 'maitre.test@example.com',  -- ⚠️ Email du futur MC
  p_full_name := 'Maître de Chœur Test', -- ⚠️ Nom du MC
  p_chorale_id := (SELECT id FROM chorales LIMIT 1), -- ⚠️ Ou spécifiez le nom
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

-- ÉTAPE 6: Vérifier le Maître de Chœur créé
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

-- ÉTAPE 7: Vérifier les permissions du MC
SELECT get_user_permissions(
  (SELECT id FROM profiles WHERE est_maitre_choeur = true LIMIT 1)
);

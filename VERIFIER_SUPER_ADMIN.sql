-- =====================================================
-- VÉRIFIER QUI EST SUPER ADMIN
-- =====================================================

-- Étape 1: Vérifier tous les Super Admins actuels
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.role,
  p.statut_validation,
  p.created_at
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin'
ORDER BY p.created_at;

-- =====================================================

-- Étape 2: Vérifier les deux comptes spécifiques
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

-- Étape 3: Vérifier tous les admins (super_admin + admin)
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.role,
  p.est_maitre_choeur,
  p.statut_validation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role IN ('super_admin', 'admin')
ORDER BY p.role, au.email;

-- =====================================================
-- RÉSULTATS POSSIBLES:
-- =====================================================

-- CAS 1: kodjodavid2025@gmail.com est toujours Super Admin
-- → Utilisez ce compte pour créer les MC

-- CAS 2: Aucun Super Admin
-- → Il faut en créer un avec l'UPDATE ci-dessous

-- CAS 3: agbeviade2017@gmail.com est déjà Super Admin
-- → Vous pouvez créer des MC directement

-- =====================================================
-- SI BESOIN: Remettre kodjodavid2025@gmail.com en Super Admin
-- =====================================================

-- Option A: Remettre kodjodavid2025@gmail.com en Super Admin
UPDATE profiles
SET role = 'super_admin'
WHERE user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'kodjodavid2025@gmail.com'
);

-- =====================================================

-- Option B: Mettre agbeviade2017@gmail.com en Super Admin
UPDATE profiles
SET role = 'super_admin'
WHERE user_id = (
  SELECT id FROM auth.users 
  WHERE email = 'agbeviade2017@gmail.com'
);

-- =====================================================

-- Option C: Avoir DEUX Super Admins (recommandé pour backup)
UPDATE profiles
SET role = 'super_admin'
WHERE user_id IN (
  SELECT id FROM auth.users 
  WHERE email IN ('kodjodavid2025@gmail.com', 'agbeviade2017@gmail.com')
);

-- =====================================================

-- Vérification finale
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.role
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.role = 'super_admin'
ORDER BY au.email;

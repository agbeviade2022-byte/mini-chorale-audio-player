-- =====================================================
-- REQUÊTES UTILES POUR LA GESTION DE LA VALIDATION
-- =====================================================

-- =====================================================
-- 1. VOIR TOUS LES UTILISATEURS AVEC LEUR EMAIL
-- =====================================================

SELECT 
  p.id,
  p.full_name,
  au.email,
  p.statut_validation,
  p.role,
  p.created_at
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
ORDER BY p.created_at DESC;

-- =====================================================
-- 2. VOIR UNIQUEMENT LES UTILISATEURS NON VALIDÉS
-- =====================================================

SELECT 
  p.id,
  p.full_name,
  au.email,
  p.statut_validation,
  p.created_at
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.statut_validation = 'en_attente'
ORDER BY p.created_at DESC;

-- =====================================================
-- 3. VALIDER UN UTILISATEUR PAR SON NOM
-- =====================================================

-- Remplacez 'Azerty13' par le nom de l'utilisateur
UPDATE profiles
SET statut_validation = 'valide'
WHERE full_name = 'Azerty13';

-- =====================================================
-- 4. VALIDER UN UTILISATEUR PAR SON EMAIL
-- =====================================================

-- Remplacez 'email@example.com' par l'email de l'utilisateur
UPDATE profiles
SET statut_validation = 'valide'
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'email@example.com'
);

-- =====================================================
-- 5. VALIDER UN UTILISATEUR ET LE RENDRE ADMIN
-- =====================================================

-- Remplacez 'email@example.com' par l'email de l'utilisateur
UPDATE profiles
SET 
  statut_validation = 'valide',
  role = 'admin'
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'email@example.com'
);

-- =====================================================
-- 6. REFUSER UN UTILISATEUR
-- =====================================================

-- Remplacez 'Azerty13' par le nom de l'utilisateur
UPDATE profiles
SET statut_validation = 'refuse'
WHERE full_name = 'Azerty13';

-- =====================================================
-- 7. VOIR LES SESSIONS ACTIVES DES NON-VALIDÉS
-- =====================================================

SELECT 
  p.full_name,
  au.email,
  p.statut_validation,
  usl.connected_at,
  usl.device_info
FROM user_sessions_log usl
JOIN profiles p ON usl.user_id = p.id
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.statut_validation != 'valide'
  AND usl.disconnected_at IS NULL
ORDER BY usl.connected_at DESC;

-- =====================================================
-- 8. DÉCONNECTER MANUELLEMENT UN UTILISATEUR
-- =====================================================

-- Remplacez 'Azerty13' par le nom de l'utilisateur
UPDATE user_sessions_log
SET 
  disconnected_at = NOW(),
  disconnected_reason = 'admin_disconnect'
WHERE user_id = (
  SELECT id FROM profiles WHERE full_name = 'Azerty13'
)
AND disconnected_at IS NULL;

-- =====================================================
-- 9. STATISTIQUES DE VALIDATION
-- =====================================================

SELECT 
  statut_validation,
  COUNT(*) as nombre_utilisateurs
FROM profiles
GROUP BY statut_validation
ORDER BY nombre_utilisateurs DESC;

-- =====================================================
-- 10. VOIR LES TENTATIVES DE CONNEXION ÉCHOUÉES
-- =====================================================

SELECT 
  p.full_name,
  au.email,
  fla.attempt_time,
  fla.error_message
FROM failed_login_attempts fla
LEFT JOIN auth.users au ON fla.identifier = au.email
LEFT JOIN profiles p ON au.id = p.id
ORDER BY fla.attempt_time DESC
LIMIT 20;

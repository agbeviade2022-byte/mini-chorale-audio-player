-- =====================================================
-- CORRIGER LA FONCTION creer_maitre_choeur
-- Problème: Permet de créer plusieurs MC avec le même email
-- Cause: La fonction ne crée pas l'utilisateur dans auth.users
-- =====================================================

-- Supprimer l'ancienne version
DROP FUNCTION IF EXISTS creer_maitre_choeur(TEXT, TEXT, UUID, UUID, TEXT);

-- Créer la nouvelle version corrigée
CREATE OR REPLACE FUNCTION creer_maitre_choeur(
  p_email TEXT,
  p_full_name TEXT,
  p_chorale_id UUID,
  p_super_admin_id UUID,
  p_telephone TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_profile_id UUID;
  v_code_affiliation VARCHAR(20);
  v_lien_affiliation VARCHAR(100);
  v_result JSON;
  v_auth_user_id UUID;
BEGIN
  -- Vérifier que l'appelant est super admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = p_super_admin_id 
    AND role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Seuls les super admins peuvent créer des maîtres de chœur';
  END IF;

  -- ⚠️ NOUVEAU: Vérifier si l'email existe déjà dans auth.users
  SELECT id INTO v_auth_user_id
  FROM auth.users
  WHERE email = p_email;

  IF v_auth_user_id IS NULL THEN
    RAISE EXCEPTION 'L''utilisateur avec l''email % n''existe pas. Créez-le d''abord dans Supabase Dashboard (Authentication > Users > Add User)', p_email;
  END IF;

  -- ⚠️ NOUVEAU: Vérifier si un profil existe déjà pour cet utilisateur
  IF EXISTS (
    SELECT 1 FROM profiles 
    WHERE user_id = v_auth_user_id
  ) THEN
    RAISE EXCEPTION 'Un profil existe déjà pour l''email %', p_email;
  END IF;

  -- ⚠️ NOUVEAU: Vérifier si l'utilisateur est déjà maître de chœur
  IF EXISTS (
    SELECT 1 FROM profiles 
    WHERE user_id = v_auth_user_id 
    AND est_maitre_choeur = true
  ) THEN
    RAISE EXCEPTION 'L''utilisateur % est déjà maître de chœur', p_email;
  END IF;

  -- Générer le code d'affiliation unique
  v_code_affiliation := 'MC-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
  v_lien_affiliation := '/register?ref=' || v_code_affiliation;

  -- Créer le profil
  INSERT INTO profiles (
    user_id,
    full_name,
    role,
    chorale_id,
    est_maitre_choeur,
    affiliation_code,
    lien_affiliation,
    cree_par,
    date_activation,
    statut_validation,
    telephone
  ) VALUES (
    v_auth_user_id,
    p_full_name,
    'admin',
    p_chorale_id,
    true,
    v_code_affiliation,
    v_lien_affiliation,
    p_super_admin_id,
    NOW(),
    'valide',
    p_telephone
  )
  RETURNING id INTO v_profile_id;

  -- Attribuer les permissions de base du maître de chœur
  INSERT INTO user_permissions (user_id, module_code, attribue_par)
  SELECT 
    v_profile_id,
    code,
    p_super_admin_id
  FROM modules_permissions
  WHERE code IN (
    'view_dashboard',
    'view_members',
    'validate_members',
    'edit_members',
    'view_chants',
    'add_chants',
    'edit_chants',
    'delete_chants',
    'add_chants_pupitre',
    'view_stats',
    'assign_permissions'
  );

  -- Construire le résultat JSON
  v_result := json_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'affiliation_code', v_code_affiliation,
    'lien_affiliation', v_lien_affiliation,
    'email', p_email
  );

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION creer_maitre_choeur IS 
'Créer un maître de chœur avec son lien d''affiliation unique. L''utilisateur doit d''abord exister dans auth.users.';

-- =====================================================
-- NETTOYER LES DOUBLONS EXISTANTS
-- =====================================================

-- Voir les doublons
SELECT 
  p.id,
  p.full_name,
  au.email,
  p.affiliation_code,
  p.created_at
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.est_maitre_choeur = true
ORDER BY p.full_name, p.created_at;

-- =====================================================

-- Supprimer les doublons (garder le plus ancien)
-- ⚠️ ATTENTION: Vérifiez bien avant de supprimer

-- Exemple: Supprimer "Maitre Test" (le plus récent)
-- DELETE FROM profiles WHERE id = 'uuid-du-doublon';

-- Ou supprimer tous les MC sans email (NULL)
DELETE FROM profiles 
WHERE est_maitre_choeur = true 
AND user_id IS NULL;

-- =====================================================
-- TESTER LA NOUVELLE FONCTION
-- =====================================================

-- ÉTAPE 1: Créer l'utilisateur dans Supabase Dashboard
-- Authentication > Users > Add User
-- Email: maitre.reel@example.com
-- Password: MotDePasse123!
-- ✅ Auto Confirm User

-- ÉTAPE 2: Créer le MC avec la fonction corrigée
SELECT creer_maitre_choeur(
  p_email := 'maitre.reel@example.com',  -- ⚠️ Doit exister dans auth.users
  p_full_name := 'Maître Réel',
  p_chorale_id := (SELECT id FROM chorales LIMIT 1),
  p_super_admin_id := (SELECT id FROM profiles WHERE role = 'super_admin' LIMIT 1)
);

-- Si l'email n'existe pas, vous aurez:
-- ERROR: L'utilisateur avec l'email maitre.reel@example.com n'existe pas. 
-- Créez-le d'abord dans Supabase Dashboard

-- =====================================================

-- ÉTAPE 3: Vérifier que le MC a été créé avec l'email
SELECT 
  p.full_name,
  au.email,
  p.role,
  p.est_maitre_choeur,
  p.affiliation_code,
  p.lien_affiliation
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.est_maitre_choeur = true
ORDER BY p.created_at DESC;

-- Résultat attendu: L'email ne doit plus être NULL

-- =====================================================

-- ÉTAPE 4: Tester qu'on ne peut pas créer de doublon
SELECT creer_maitre_choeur(
  p_email := 'maitre.reel@example.com',  -- Même email
  p_full_name := 'Doublon Test',
  p_chorale_id := (SELECT id FROM chorales LIMIT 1),
  p_super_admin_id := (SELECT id FROM profiles WHERE role = 'super_admin' LIMIT 1)
);

-- Résultat attendu:
-- ERROR: Un profil existe déjà pour l'email maitre.reel@example.com

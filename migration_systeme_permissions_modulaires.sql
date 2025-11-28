-- =====================================================
-- SYSTÈME DE PERMISSIONS MODULAIRES
-- Architecture: Super Admin → Maître de Chœur → Membres
-- =====================================================

-- =====================================================
-- 1. TABLE DES MODULES (Permissions disponibles)
-- =====================================================

CREATE TABLE IF NOT EXISTS modules_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR(50) UNIQUE NOT NULL,
  nom VARCHAR(100) NOT NULL,
  description TEXT,
  categorie VARCHAR(50) NOT NULL, -- 'gestion', 'contenu', 'administration'
  icone VARCHAR(50),
  ordre INTEGER DEFAULT 0,
  actif BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE modules_permissions IS 
'Liste des modules/permissions disponibles dans le système';

-- Insérer les modules de base
INSERT INTO modules_permissions (code, nom, description, categorie, icone, ordre) VALUES
-- Gestion des membres
('view_members', 'Voir les membres', 'Consulter la liste des membres', 'gestion', 'Users', 1),
('validate_members', 'Valider les membres', 'Valider ou refuser les inscriptions', 'gestion', 'UserCheck', 2),
('edit_members', 'Modifier les membres', 'Modifier les informations des membres', 'gestion', 'UserCog', 3),
('delete_members', 'Supprimer les membres', 'Supprimer des membres', 'gestion', 'UserX', 4),
('assign_permissions', 'Attribuer des permissions', 'Donner des accès à d''autres membres', 'gestion', 'Shield', 5),

-- Gestion des chants
('view_chants', 'Voir les chants', 'Consulter la bibliothèque de chants', 'contenu', 'Music', 10),
('add_chants', 'Ajouter des chants', 'Ajouter de nouveaux chants', 'contenu', 'Plus', 11),
('edit_chants', 'Modifier les chants', 'Modifier les chants existants', 'contenu', 'Edit', 12),
('delete_chants', 'Supprimer les chants', 'Supprimer des chants', 'contenu', 'Trash', 13),
('add_chants_pupitre', 'Ajouter chants par pupitre', 'Ajouter des chants avec pistes par pupitre', 'contenu', 'Layers', 14),

-- Gestion des chorales
('view_chorales', 'Voir les chorales', 'Consulter les chorales', 'administration', 'Building2', 20),
('manage_chorales', 'Gérer les chorales', 'Créer, modifier, supprimer des chorales', 'administration', 'Settings', 21),

-- Statistiques et rapports
('view_stats', 'Voir les statistiques', 'Accéder aux statistiques', 'administration', 'BarChart', 30),
('view_logs', 'Voir les logs', 'Consulter l''historique des actions', 'administration', 'FileText', 31),

-- Administration système
('manage_system', 'Administration système', 'Accès complet au système', 'administration', 'Shield', 40),
('view_dashboard', 'Accès au dashboard', 'Accéder au dashboard admin', 'administration', 'LayoutDashboard', 41)

ON CONFLICT (code) DO NOTHING;

-- =====================================================
-- 2. TABLE DES PERMISSIONS UTILISATEURS
-- =====================================================

CREATE TABLE IF NOT EXISTS user_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  module_code VARCHAR(50) NOT NULL REFERENCES modules_permissions(code) ON DELETE CASCADE,
  attribue_par UUID REFERENCES profiles(id), -- Qui a donné cette permission
  attribue_le TIMESTAMP DEFAULT NOW(),
  expire_le TIMESTAMP, -- Optionnel: permission temporaire
  actif BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, module_code)
);

COMMENT ON TABLE user_permissions IS 
'Permissions attribuées aux utilisateurs';

CREATE INDEX idx_user_permissions_user ON user_permissions(user_id);
CREATE INDEX idx_user_permissions_module ON user_permissions(module_code);

-- =====================================================
-- 3. MODIFIER LA TABLE PROFILES
-- =====================================================

-- Ajouter les nouveaux champs
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS est_maitre_choeur BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS lien_affiliation VARCHAR(100) UNIQUE,
ADD COLUMN IF NOT EXISTS affiliation_code VARCHAR(20) UNIQUE,
ADD COLUMN IF NOT EXISTS cree_par UUID REFERENCES profiles(id), -- Super Admin qui l'a créé
ADD COLUMN IF NOT EXISTS date_activation TIMESTAMP;

COMMENT ON COLUMN profiles.est_maitre_choeur IS 
'Indique si l''utilisateur est un maître de chœur (admin de chorale)';

COMMENT ON COLUMN profiles.lien_affiliation IS 
'Lien unique pour que les membres s''inscrivent via ce maître de chœur';

COMMENT ON COLUMN profiles.affiliation_code IS 
'Code court d''affiliation (ex: MC-PARIS-2024)';

-- =====================================================
-- 4. TABLE DES AFFILIATIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS affiliations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  membre_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  maitre_choeur_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  code_affiliation VARCHAR(20) NOT NULL,
  date_inscription TIMESTAMP DEFAULT NOW(),
  statut VARCHAR(20) DEFAULT 'en_attente', -- en_attente, valide, refuse
  valide_le TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE affiliations IS 
'Historique des inscriptions via liens d''affiliation';

CREATE INDEX idx_affiliations_membre ON affiliations(membre_id);
CREATE INDEX idx_affiliations_maitre ON affiliations(maitre_choeur_id);

-- =====================================================
-- 5. FONCTION: Créer un maître de chœur
-- =====================================================

-- Supprimer l'ancienne version si elle existe
DROP FUNCTION IF EXISTS creer_maitre_choeur(TEXT, TEXT, UUID, UUID, TEXT);

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
  v_user_id UUID;
  v_profile_id UUID;
  v_code_affiliation VARCHAR(20);
  v_lien_affiliation VARCHAR(100);
  v_result JSON;
BEGIN
  -- Vérifier que l'appelant est super admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = p_super_admin_id 
    AND role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Seuls les super admins peuvent créer des maîtres de chœur';
  END IF;

  -- Générer un code d'affiliation unique
  v_code_affiliation := 'MC-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
  v_lien_affiliation := '/register?ref=' || v_code_affiliation;

  -- Créer l'utilisateur dans auth.users (via Supabase Admin API)
  -- Note: Cette partie doit être gérée côté application
  -- Pour l'instant, on suppose que l'utilisateur existe déjà

  -- Créer le profil
  INSERT INTO profiles (
    full_name,
    chorale_id,
    role,
    statut_validation,
    est_maitre_choeur,
    affiliation_code,
    lien_affiliation,
    cree_par,
    date_activation,
    telephone
  ) VALUES (
    p_full_name,
    p_chorale_id,
    'admin',
    'valide',
    true,
    v_code_affiliation,
    v_lien_affiliation,
    p_super_admin_id,
    NOW(),
    p_telephone
  )
  RETURNING id INTO v_profile_id;

  -- Attribuer les permissions de base du maître de chœur
  INSERT INTO user_permissions (user_id, module_code, attribue_par)
  SELECT v_profile_id, code, p_super_admin_id
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

  -- Construire le résultat
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
'Créer un maître de chœur avec son lien d''affiliation unique';

-- =====================================================
-- 6. FONCTION: Vérifier les permissions d'un utilisateur
-- =====================================================

-- Supprimer l'ancienne version si elle existe
DROP FUNCTION IF EXISTS has_permission(UUID, VARCHAR);

CREATE OR REPLACE FUNCTION has_permission(
  p_user_id UUID,
  p_module_code VARCHAR(50)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_has_permission BOOLEAN;
  v_is_super_admin BOOLEAN;
BEGIN
  -- Les super admins ont toutes les permissions
  SELECT role = 'super_admin' INTO v_is_super_admin
  FROM profiles
  WHERE id = p_user_id;

  IF v_is_super_admin THEN
    RETURN true;
  END IF;

  -- Vérifier la permission spécifique
  SELECT EXISTS (
    SELECT 1 
    FROM user_permissions 
    WHERE user_id = p_user_id 
      AND module_code = p_module_code
      AND actif = true
      AND (expire_le IS NULL OR expire_le > NOW())
  ) INTO v_has_permission;

  RETURN v_has_permission;
END;
$$;

COMMENT ON FUNCTION has_permission IS 
'Vérifie si un utilisateur a une permission spécifique';

-- =====================================================
-- 7. FONCTION: Obtenir toutes les permissions d'un utilisateur
-- =====================================================

-- Supprimer l'ancienne version si elle existe
DROP FUNCTION IF EXISTS get_user_permissions(UUID);

CREATE OR REPLACE FUNCTION get_user_permissions(p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_is_super_admin BOOLEAN;
  v_permissions JSON;
BEGIN
  -- Vérifier si super admin
  SELECT role = 'super_admin' INTO v_is_super_admin
  FROM profiles
  WHERE id = p_user_id;

  -- Si super admin, retourner tous les modules
  IF v_is_super_admin THEN
    SELECT json_agg(
      json_build_object(
        'code', code,
        'nom', nom,
        'description', description,
        'categorie', categorie,
        'icone', icone,
        'actif', true,
        'source', 'super_admin'
      )
    )
    INTO v_permissions
    FROM modules_permissions
    WHERE actif = true;
  ELSE
    -- Sinon, retourner uniquement les permissions attribuées
    SELECT json_agg(
      json_build_object(
        'code', mp.code,
        'nom', mp.nom,
        'description', mp.description,
        'categorie', mp.categorie,
        'icone', mp.icone,
        'actif', up.actif,
        'attribue_par', p.full_name,
        'attribue_le', up.attribue_le,
        'expire_le', up.expire_le
      )
    )
    INTO v_permissions
    FROM user_permissions up
    JOIN modules_permissions mp ON up.module_code = mp.code
    LEFT JOIN profiles p ON up.attribue_par = p.id
    WHERE up.user_id = p_user_id
      AND up.actif = true
      AND (up.expire_le IS NULL OR up.expire_le > NOW());
  END IF;

  RETURN COALESCE(v_permissions, '[]'::json);
END;
$$;

COMMENT ON FUNCTION get_user_permissions IS 
'Retourne toutes les permissions d''un utilisateur au format JSON';

-- =====================================================
-- 8. FONCTION: Attribuer une permission
-- =====================================================

-- Supprimer l'ancienne version si elle existe
DROP FUNCTION IF EXISTS attribuer_permission(UUID, VARCHAR, UUID, TIMESTAMP);

CREATE OR REPLACE FUNCTION attribuer_permission(
  p_user_id UUID,
  p_module_code VARCHAR(50),
  p_attribue_par UUID,
  p_expire_le TIMESTAMP DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Vérifier que l'attributeur a la permission 'assign_permissions' ou est super admin
  IF NOT (
    has_permission(p_attribue_par, 'assign_permissions') OR
    EXISTS (SELECT 1 FROM profiles WHERE id = p_attribue_par AND role = 'super_admin')
  ) THEN
    RAISE EXCEPTION 'Vous n''avez pas la permission d''attribuer des permissions';
  END IF;

  -- Vérifier que le module existe
  IF NOT EXISTS (SELECT 1 FROM modules_permissions WHERE code = p_module_code) THEN
    RAISE EXCEPTION 'Module % n''existe pas', p_module_code;
  END IF;

  -- Insérer ou mettre à jour la permission
  INSERT INTO user_permissions (user_id, module_code, attribue_par, expire_le)
  VALUES (p_user_id, p_module_code, p_attribue_par, p_expire_le)
  ON CONFLICT (user_id, module_code) 
  DO UPDATE SET 
    actif = true,
    attribue_par = p_attribue_par,
    attribue_le = NOW(),
    expire_le = p_expire_le;

  RETURN true;
END;
$$;

COMMENT ON FUNCTION attribuer_permission IS 
'Attribue une permission à un utilisateur';

-- =====================================================
-- 9. FONCTION: Révoquer une permission
-- =====================================================

-- Supprimer l'ancienne version si elle existe
DROP FUNCTION IF EXISTS revoquer_permission(UUID, VARCHAR, UUID);

CREATE OR REPLACE FUNCTION revoquer_permission(
  p_user_id UUID,
  p_module_code VARCHAR(50),
  p_revoque_par UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Vérifier que le révocateur a la permission ou est super admin
  IF NOT (
    has_permission(p_revoque_par, 'assign_permissions') OR
    EXISTS (SELECT 1 FROM profiles WHERE id = p_revoque_par AND role = 'super_admin')
  ) THEN
    RAISE EXCEPTION 'Vous n''avez pas la permission de révoquer des permissions';
  END IF;

  -- Désactiver la permission
  UPDATE user_permissions
  SET actif = false
  WHERE user_id = p_user_id 
    AND module_code = p_module_code;

  RETURN true;
END;
$$;

COMMENT ON FUNCTION revoquer_permission IS 
'Révoque une permission d''un utilisateur';

-- =====================================================
-- 10. VUE: Permissions par utilisateur
-- =====================================================

CREATE OR REPLACE VIEW v_user_permissions AS
SELECT 
  p.id as user_id,
  p.full_name,
  au.email,
  p.role,
  p.est_maitre_choeur,
  c.nom as chorale,
  mp.code as permission_code,
  mp.nom as permission_nom,
  mp.categorie as permission_categorie,
  up.actif as permission_active,
  up.attribue_le,
  up.expire_le,
  attrib.full_name as attribue_par_nom
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
LEFT JOIN user_permissions up ON p.id = up.user_id
LEFT JOIN modules_permissions mp ON up.module_code = mp.code
LEFT JOIN profiles attrib ON up.attribue_par = attrib.id
LEFT JOIN chorales c ON p.chorale_id = c.id
WHERE p.statut_validation = 'valide';

COMMENT ON VIEW v_user_permissions IS 
'Vue complète des permissions par utilisateur';

-- =====================================================
-- 11. RLS POLICIES
-- =====================================================

-- Activer RLS
ALTER TABLE modules_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE affiliations ENABLE ROW LEVEL SECURITY;

-- Policy: Tout le monde peut voir les modules disponibles
CREATE POLICY modules_read_all ON modules_permissions
  FOR SELECT
  TO authenticated
  USING (actif = true);

-- Policy: Voir ses propres permissions
CREATE POLICY user_permissions_read_own ON user_permissions
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Policy: Super admin et ceux avec assign_permissions peuvent voir toutes les permissions
CREATE POLICY user_permissions_read_admin ON user_permissions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND (role = 'super_admin' OR has_permission(auth.uid(), 'assign_permissions'))
    )
  );

-- Policy: Voir ses propres affiliations
CREATE POLICY affiliations_read_own ON affiliations
  FOR SELECT
  TO authenticated
  USING (
    membre_id = auth.uid() OR 
    maitre_choeur_id = auth.uid()
  );

-- =====================================================
-- 12. STATISTIQUES
-- =====================================================

DO $$
DECLARE
  v_total_modules INTEGER;
  v_total_permissions INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total_modules FROM modules_permissions;
  SELECT COUNT(*) INTO v_total_permissions FROM user_permissions;

  RAISE NOTICE '==============================================';
  RAISE NOTICE '✅ SYSTÈME DE PERMISSIONS MODULAIRES CRÉÉ';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE '📊 STATISTIQUES:';
  RAISE NOTICE '  - Modules disponibles: %', v_total_modules;
  RAISE NOTICE '  - Permissions attribuées: %', v_total_permissions;
  RAISE NOTICE '';
  RAISE NOTICE '🔧 FONCTIONS CRÉÉES:';
  RAISE NOTICE '  - creer_maitre_choeur()';
  RAISE NOTICE '  - has_permission()';
  RAISE NOTICE '  - get_user_permissions()';
  RAISE NOTICE '  - attribuer_permission()';
  RAISE NOTICE '  - revoquer_permission()';
  RAISE NOTICE '';
  RAISE NOTICE '📋 MODULES DISPONIBLES:';
  RAISE NOTICE '  - Gestion membres: 5 modules';
  RAISE NOTICE '  - Gestion chants: 5 modules';
  RAISE NOTICE '  - Administration: 6 modules';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Migration terminée avec succès!';
  RAISE NOTICE '==============================================';
END $$;

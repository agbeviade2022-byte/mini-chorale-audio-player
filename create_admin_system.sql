-- =====================================================
-- SYSTÈME D'ADMINISTRATION COMPLET
-- =====================================================
-- Ce script crée les tables pour gérer les admins système
-- et les permissions multi-niveaux

-- =====================================================
-- 1. TABLE DES ADMINS SYSTÈME (SUPER ADMINS)
-- =====================================================

CREATE TABLE IF NOT EXISTS system_admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'super_admin' CHECK (role IN ('super_admin', 'admin', 'support')),
    permissions JSONB DEFAULT '[]'::jsonb,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 2. TABLE DES LOGS D'ADMINISTRATION
-- =====================================================

CREATE TABLE IF NOT EXISTS admin_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES system_admins(id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id UUID,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 3. TABLE DES PERMISSIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    module VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 4. TABLE DE LIAISON ADMIN-PERMISSIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS admin_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES system_admins(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(admin_id, permission_id)
);

-- =====================================================
-- 5. MODIFIER LA TABLE MEMBRES POUR AJOUTER LES RÔLES
-- =====================================================

-- Ajouter une colonne pour distinguer les admins de chorale
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'membres') THEN
        -- Vérifier si la colonne permissions existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'membres' AND column_name = 'permissions'
        ) THEN
            ALTER TABLE membres ADD COLUMN permissions JSONB DEFAULT '[]'::jsonb;
        END IF;
    END IF;
END $$;

-- =====================================================
-- 6. CRÉER LES INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_system_admins_user ON system_admins(user_id);
CREATE INDEX IF NOT EXISTS idx_system_admins_email ON system_admins(email);
CREATE INDEX IF NOT EXISTS idx_admin_logs_admin ON admin_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_action ON admin_logs(action);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created ON admin_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_admin_permissions_admin ON admin_permissions(admin_id);

-- =====================================================
-- 7. DÉSACTIVER RLS
-- =====================================================

ALTER TABLE system_admins DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE permissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_permissions DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 8. INSÉRER LES PERMISSIONS PAR DÉFAUT
-- =====================================================

INSERT INTO permissions (nom, description, module)
VALUES 
    -- Gestion des chorales
    ('chorales.view', 'Voir toutes les chorales', 'chorales'),
    ('chorales.create', 'Créer des chorales', 'chorales'),
    ('chorales.edit', 'Modifier des chorales', 'chorales'),
    ('chorales.delete', 'Supprimer des chorales', 'chorales'),
    ('chorales.suspend', 'Suspendre des chorales', 'chorales'),
    
    -- Gestion des utilisateurs
    ('users.view', 'Voir tous les utilisateurs', 'users'),
    ('users.edit', 'Modifier des utilisateurs', 'users'),
    ('users.delete', 'Supprimer des utilisateurs', 'users'),
    ('users.ban', 'Bannir des utilisateurs', 'users'),
    
    -- Gestion des plans
    ('plans.view', 'Voir les plans', 'plans'),
    ('plans.create', 'Créer des plans', 'plans'),
    ('plans.edit', 'Modifier des plans', 'plans'),
    ('plans.delete', 'Supprimer des plans', 'plans'),
    
    -- Gestion des chants
    ('chants.view_all', 'Voir tous les chants', 'chants'),
    ('chants.edit_all', 'Modifier tous les chants', 'chants'),
    ('chants.delete_all', 'Supprimer tous les chants', 'chants'),
    
    -- Gestion du système
    ('system.logs', 'Voir les logs système', 'system'),
    ('system.settings', 'Modifier les paramètres système', 'system'),
    ('system.backup', 'Gérer les sauvegardes', 'system'),
    
    -- Support
    ('support.tickets', 'Gérer les tickets support', 'support'),
    ('support.chat', 'Accès au chat support', 'support')
ON CONFLICT (nom) DO NOTHING;

-- =====================================================
-- 9. CRÉER UN SUPER ADMIN PAR DÉFAUT
-- =====================================================

-- ⚠️ IMPORTANT: Remplacez 'VOTRE_EMAIL@example.com' par votre vrai email
-- et 'VOTRE_USER_ID' par votre ID utilisateur Supabase

-- Pour obtenir votre user_id, exécutez d'abord:
-- SELECT id, email FROM auth.users WHERE email = 'votre_email@example.com';

-- Puis décommentez et modifiez cette ligne:
/*
INSERT INTO system_admins (user_id, email, role, permissions)
VALUES (
    'VOTRE_USER_ID'::uuid,
    'VOTRE_EMAIL@example.com',
    'super_admin',
    '["all"]'::jsonb
)
ON CONFLICT (user_id) DO NOTHING;
*/

-- =====================================================
-- 10. FONCTION POUR VÉRIFIER SI UN USER EST ADMIN SYSTÈME
-- =====================================================

CREATE OR REPLACE FUNCTION is_system_admin(check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM system_admins 
        WHERE user_id = check_user_id 
        AND actif = true
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 11. FONCTION POUR VÉRIFIER UNE PERMISSION
-- =====================================================

CREATE OR REPLACE FUNCTION has_permission(check_user_id UUID, permission_name VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    -- Super admin a toutes les permissions
    IF EXISTS (
        SELECT 1 FROM system_admins 
        WHERE user_id = check_user_id 
        AND role = 'super_admin' 
        AND actif = true
    ) THEN
        RETURN true;
    END IF;
    
    -- Vérifier la permission spécifique
    RETURN EXISTS (
        SELECT 1 
        FROM system_admins sa
        JOIN admin_permissions ap ON sa.id = ap.admin_id
        JOIN permissions p ON ap.permission_id = p.id
        WHERE sa.user_id = check_user_id 
        AND p.nom = permission_name
        AND sa.actif = true
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 12. FONCTION POUR LOGGER UNE ACTION ADMIN
-- =====================================================

CREATE OR REPLACE FUNCTION log_admin_action(
    p_user_id UUID,
    p_action VARCHAR,
    p_table_name VARCHAR DEFAULT NULL,
    p_record_id UUID DEFAULT NULL,
    p_details JSONB DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_admin_id UUID;
BEGIN
    -- Récupérer l'ID de l'admin
    SELECT id INTO v_admin_id
    FROM system_admins
    WHERE user_id = p_user_id;
    
    -- Insérer le log
    IF v_admin_id IS NOT NULL THEN
        INSERT INTO admin_logs (admin_id, action, table_name, record_id, details)
        VALUES (v_admin_id, p_action, p_table_name, p_record_id, p_details);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 13. VUE POUR FACILITER LA GESTION DES ADMINS
-- =====================================================

CREATE OR REPLACE VIEW v_system_admins AS
SELECT 
    sa.id,
    sa.user_id,
    sa.email,
    sa.role,
    sa.actif,
    sa.created_at,
    COUNT(ap.id) as nb_permissions,
    ARRAY_AGG(p.nom) FILTER (WHERE p.nom IS NOT NULL) as permissions_list
FROM system_admins sa
LEFT JOIN admin_permissions ap ON sa.id = ap.admin_id
LEFT JOIN permissions p ON ap.permission_id = p.id
GROUP BY sa.id, sa.user_id, sa.email, sa.role, sa.actif, sa.created_at;

-- =====================================================
-- 14. VÉRIFICATION
-- =====================================================

-- Lister les tables d'administration
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '⚠️ RLS Activé'
        ELSE '✅ RLS Désactivé'
    END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('system_admins', 'admin_logs', 'permissions', 'admin_permissions')
ORDER BY tablename;

-- Compter les permissions
SELECT 'PERMISSIONS' as table_name, COUNT(*) as nombre FROM permissions;

-- Lister les fonctions créées
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('is_system_admin', 'has_permission', 'log_admin_action')
ORDER BY routine_name;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ 4 tables créées (system_admins, admin_logs, permissions, admin_permissions)
-- ✅ RLS désactivé
-- ✅ 21 permissions créées
-- ✅ 3 fonctions créées
-- ✅ 1 vue créée

-- =====================================================
-- PROCHAINES ÉTAPES
-- =====================================================
/*
1. Obtenir votre user_id:
   SELECT id, email FROM auth.users WHERE email = 'votre_email@example.com';

2. Créer votre compte super admin:
   INSERT INTO system_admins (user_id, email, role)
   VALUES ('VOTRE_USER_ID'::uuid, 'votre_email@example.com', 'super_admin');

3. Dans votre app Flutter, vérifier si l'utilisateur est admin:
   SELECT is_system_admin('USER_ID'::uuid);

4. Vérifier une permission:
   SELECT has_permission('USER_ID'::uuid, 'chorales.delete');

5. Logger une action:
   SELECT log_admin_action('USER_ID'::uuid, 'DELETE_CHORALE', 'chorales', 'CHORALE_ID'::uuid);
*/

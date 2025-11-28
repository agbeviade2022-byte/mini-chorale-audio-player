-- =====================================================
-- FIX SÉCURITÉ URGENT : Correction des failles critiques
-- =====================================================
-- À exécuter IMMÉDIATEMENT
-- =====================================================

-- ============================================
-- PHASE 1 : SÉCURISER LES RLS POLICIES
-- ============================================

-- 1.1 Empêcher l'auto-promotion en super_admin
SELECT '🔒 PHASE 1.1 : Sécurisation du rôle super_admin' as info;

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Seuls les super admins peuvent modifier les rôles" ON profiles;

-- Policy pour mise à jour du profil (SANS changement de rôle)
CREATE POLICY "Users can update own profile without role change"
ON profiles
FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
  AND role = (SELECT role FROM profiles WHERE user_id = auth.uid())
)
WITH CHECK (
  user_id = auth.uid()
  AND role = (SELECT role FROM profiles WHERE user_id = auth.uid())
);

-- Policy pour les super admins (peuvent tout modifier)
CREATE POLICY "Super admins can update any profile"
ON profiles
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role = 'super_admin'
  )
)
WITH CHECK (
  -- Vérifier que le nouveau rôle est valide
  role IN ('membre', 'admin', 'super_admin', 'maitre_choeur')
  AND
  -- Seul un super admin peut créer un autre super admin
  (role != 'super_admin' OR EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role = 'super_admin'
  ))
);

-- ============================================
-- PHASE 1.2 : REMPLACER SECURITY DEFINER
-- ============================================

SELECT '🔒 PHASE 1.2 : Remplacement de SECURITY DEFINER' as info;

-- Supprimer les anciennes fonctions dangereuses
DROP FUNCTION IF EXISTS valider_membre(UUID, UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS refuser_membre(UUID, UUID, TEXT);

-- Nouvelle fonction valider_membre SÉCURISÉE
CREATE OR REPLACE FUNCTION valider_membre(
    p_user_id UUID,
    p_chorale_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER  -- ✅ Utilise les permissions de l'appelant
AS $$
DECLARE
    v_result JSONB;
    v_validateur_role TEXT;
BEGIN
    -- Vérifier que l'appelant est bien le validateur
    IF p_validateur_id != auth.uid() THEN
        RAISE EXCEPTION 'Non autorisé: vous ne pouvez pas valider au nom de quelqu''un d''autre';
    END IF;
    
    -- Vérifier que le validateur est admin ou super_admin
    SELECT role INTO v_validateur_role
    FROM profiles
    WHERE user_id = auth.uid();
    
    IF v_validateur_role NOT IN ('admin', 'super_admin') THEN
        RAISE EXCEPTION 'Non autorisé: seuls les admins peuvent valider des membres';
    END IF;
    
    -- Vérifier que l'utilisateur existe
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Utilisateur introuvable: %', p_user_id;
    END IF;
    
    -- Vérifier que la chorale existe
    IF NOT EXISTS (SELECT 1 FROM chorales WHERE id = p_chorale_id) THEN
        RAISE EXCEPTION 'Chorale introuvable: %', p_chorale_id;
    END IF;
    
    -- Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'valide',
        chorale_id = p_chorale_id,
        statut_membre = 'actif'
    WHERE user_id = p_user_id;
    
    -- Enregistrer dans l'historique
    INSERT INTO validations_membres (
        user_id,
        validateur_id,
        action,
        commentaire,
        created_at
    ) VALUES (
        p_user_id,
        p_validateur_id,
        'validation',
        p_commentaire,
        NOW()
    );
    
    v_result := jsonb_build_object(
        'success', true,
        'message', 'Membre validé avec succès',
        'user_id', p_user_id,
        'chorale_id', p_chorale_id
    );
    
    RETURN v_result;
END;
$$;

-- Nouvelle fonction refuser_membre SÉCURISÉE
CREATE OR REPLACE FUNCTION refuser_membre(
    p_user_id UUID,
    p_validateur_id UUID,
    p_motif TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER  -- ✅ Utilise les permissions de l'appelant
AS $$
DECLARE
    v_result JSONB;
    v_validateur_role TEXT;
BEGIN
    -- Vérifier que l'appelant est bien le validateur
    IF p_validateur_id != auth.uid() THEN
        RAISE EXCEPTION 'Non autorisé: vous ne pouvez pas refuser au nom de quelqu''un d''autre';
    END IF;
    
    -- Vérifier que le validateur est admin ou super_admin
    SELECT role INTO v_validateur_role
    FROM profiles
    WHERE user_id = auth.uid();
    
    IF v_validateur_role NOT IN ('admin', 'super_admin') THEN
        RAISE EXCEPTION 'Non autorisé: seuls les admins peuvent refuser des membres';
    END IF;
    
    -- Vérifier que l'utilisateur existe
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Utilisateur introuvable: %', p_user_id;
    END IF;
    
    -- Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'refuse',
        statut_membre = 'inactif'
    WHERE user_id = p_user_id;
    
    -- Enregistrer dans l'historique
    INSERT INTO validations_membres (
        user_id,
        validateur_id,
        action,
        commentaire,
        created_at
    ) VALUES (
        p_user_id,
        p_validateur_id,
        'refus',
        p_motif,
        NOW()
    );
    
    v_result := jsonb_build_object(
        'success', true,
        'message', 'Membre refusé',
        'user_id', p_user_id
    );
    
    RETURN v_result;
END;
$$;

-- Permissions
GRANT EXECUTE ON FUNCTION valider_membre(UUID, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION refuser_membre(UUID, UUID, TEXT) TO authenticated;

-- ============================================
-- PHASE 1.3 : RESTREINDRE LES PERMISSIONS
-- ============================================

SELECT '🔒 PHASE 1.3 : Restriction des permissions' as info;

-- Révoquer les permissions trop permissives
REVOKE SELECT ON membres_en_attente FROM anon;

-- Recréer la vue avec vérification de rôle
DROP VIEW IF EXISTS membres_en_attente;

CREATE OR REPLACE VIEW membres_en_attente AS
SELECT 
    p.user_id,
    COALESCE(au.email::TEXT, 'email@manquant.com') as email,
    COALESCE(NULLIF(p.full_name, ''), 'Utilisateur_' || SUBSTRING(p.user_id::TEXT, 1, 8)) as full_name,
    p.telephone,
    p.created_at,
    p.statut_validation,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER as jours_attente
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
-- ✅ Vérifier que l'appelant est admin
AND EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'super_admin')
)
ORDER BY p.created_at ASC;

-- Permissions restrictives
GRANT SELECT ON membres_en_attente TO authenticated;

-- ============================================
-- PHASE 1.4 : SÉCURISER user_permissions
-- ============================================

SELECT '🔒 PHASE 1.4 : Sécurisation de user_permissions' as info;

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Super admins peuvent tout faire sur user_permissions" ON user_permissions;
DROP POLICY IF EXISTS "Maitres de choeur peuvent gérer permissions" ON user_permissions;
DROP POLICY IF EXISTS "Users peuvent voir leurs permissions" ON user_permissions;

-- Policy SELECT : Tous peuvent voir leurs propres permissions
CREATE POLICY "Users can view own permissions"
ON user_permissions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy SELECT : Admins peuvent voir toutes les permissions
CREATE POLICY "Admins can view all permissions"
ON user_permissions
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'super_admin')
  )
);

-- Policy INSERT : Seuls les super admins peuvent attribuer des permissions
CREATE POLICY "Super admins can insert permissions"
ON user_permissions
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role = 'super_admin'
  )
);

-- Policy UPDATE : Seuls les super admins peuvent modifier des permissions
CREATE POLICY "Super admins can update permissions"
ON user_permissions
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role = 'super_admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role = 'super_admin'
  )
);

-- Policy DELETE : Seuls les super admins peuvent révoquer des permissions
CREATE POLICY "Super admins can delete permissions"
ON user_permissions
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role = 'super_admin'
  )
);

-- ============================================
-- VÉRIFICATION FINALE
-- ============================================

SELECT '✅ VÉRIFICATION FINALE' as info;

-- Vérifier les policies sur profiles
SELECT 
    'Policies sur profiles' as table_name,
    COUNT(*) as nombre_policies
FROM pg_policies
WHERE tablename = 'profiles';

-- Vérifier les policies sur user_permissions
SELECT 
    'Policies sur user_permissions' as table_name,
    COUNT(*) as nombre_policies
FROM pg_policies
WHERE tablename = 'user_permissions';

-- Vérifier les fonctions
SELECT 
    'Fonctions sécurisées' as info,
    routine_name,
    security_type
FROM information_schema.routines
WHERE routine_name IN ('valider_membre', 'refuser_membre')
AND routine_schema = 'public';

-- Vérifier les permissions sur la vue
SELECT 
    'Permissions sur membres_en_attente' as info,
    grantee,
    privilege_type
FROM information_schema.table_privileges
WHERE table_name = 'membres_en_attente';

SELECT '✅ Correction de sécurité terminée avec succès !' as status;
SELECT '⚠️ IMPORTANT : Testez toutes les fonctionnalités' as avertissement;
SELECT '📝 Lisez AUDIT_SECURITE_COMPLET.md pour les détails' as documentation;

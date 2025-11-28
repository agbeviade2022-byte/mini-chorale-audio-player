-- =====================================================
-- CORRECTION: Fonction valider_membre
-- Problème: La fonction utilise user_id au lieu de id
-- =====================================================

-- =====================================================
-- 1. CORRIGER LA FONCTION valider_membre
-- =====================================================

CREATE OR REPLACE FUNCTION valider_membre(
    p_user_id UUID,
    p_chorale_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_ancien_statut VARCHAR(20);
BEGIN
    -- Vérifier que le validateur est admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = p_validateur_id 
        AND role IN ('admin', 'super_admin')
    ) THEN
        RAISE EXCEPTION 'Seuls les admins peuvent valider des membres';
    END IF;

    -- Récupérer l'ancien statut
    SELECT statut_validation INTO v_ancien_statut
    FROM profiles
    WHERE id = p_user_id;  -- ← CORRECTION: id au lieu de user_id

    -- Mettre à jour le profil
    UPDATE profiles
    SET 
        chorale_id = p_chorale_id,
        statut_validation = 'valide',
        updated_at = NOW()
    WHERE id = p_user_id;  -- ← CORRECTION: id au lieu de user_id

    -- Enregistrer dans l'historique
    INSERT INTO validations_membres (
        user_id,
        validateur_id,
        chorale_id,
        ancien_statut,
        nouveau_statut,
        action,
        commentaire
    ) VALUES (
        p_user_id,
        p_validateur_id,
        p_chorale_id,
        v_ancien_statut,
        'valide',
        'validation',
        p_commentaire
    );

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors de la validation: %', SQLERRM;
        RETURN FALSE;
END;
$$;

COMMENT ON FUNCTION valider_membre IS 
'Valide un membre et lui assigne une chorale. Utilise id (clé primaire) au lieu de user_id.';

-- =====================================================
-- 2. CORRIGER LA FONCTION refuser_membre
-- =====================================================

CREATE OR REPLACE FUNCTION refuser_membre(
    p_user_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_ancien_statut VARCHAR(20);
BEGIN
    -- Vérifier que le validateur est admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = p_validateur_id 
        AND role IN ('admin', 'super_admin')
    ) THEN
        RAISE EXCEPTION 'Seuls les admins peuvent refuser des membres';
    END IF;

    -- Récupérer l'ancien statut
    SELECT statut_validation INTO v_ancien_statut
    FROM profiles
    WHERE id = p_user_id;  -- ← CORRECTION: id au lieu de user_id

    -- Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'refuse',
        updated_at = NOW()
    WHERE id = p_user_id;  -- ← CORRECTION: id au lieu de user_id

    -- Enregistrer dans l'historique
    INSERT INTO validations_membres (
        user_id,
        validateur_id,
        ancien_statut,
        nouveau_statut,
        action,
        commentaire
    ) VALUES (
        p_user_id,
        p_validateur_id,
        v_ancien_statut,
        'refuse',
        'refus',
        p_commentaire
    );

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors du refus: %', SQLERRM;
        RETURN FALSE;
END;
$$;

COMMENT ON FUNCTION refuser_membre IS 
'Refuse un membre. Utilise id (clé primaire) au lieu de user_id.';

-- =====================================================
-- 3. VÉRIFICATION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE '✅ FONCTIONS CORRIGÉES';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ valider_membre() - Utilise maintenant id';
    RAISE NOTICE '✅ refuser_membre() - Utilise maintenant id';
    RAISE NOTICE '';
    RAISE NOTICE '📋 STRUCTURE profiles:';
    RAISE NOTICE '  - id (UUID) - Clé primaire ← Utilisé par les fonctions';
    RAISE NOTICE '  - user_id (UUID) - Référence auth.users';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ IMPORTANT:';
    RAISE NOTICE '  Le dashboard Flutter passe member[''user_id'']';
    RAISE NOTICE '  qui correspond à profiles.id (pas profiles.user_id)';
    RAISE NOTICE '==============================================';
END $$;

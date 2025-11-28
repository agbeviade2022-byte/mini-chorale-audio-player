-- =====================================================
-- FIX : Validation des membres - ID manquant
-- =====================================================

-- 1. Vérifier si la vue membres_en_attente existe
SELECT 
    '🔍 Vérification de la vue membres_en_attente' as info;

SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE viewname = 'membres_en_attente';

-- 2. Recréer la vue avec les bons champs
DROP VIEW IF EXISTS membres_en_attente;

CREATE OR REPLACE VIEW membres_en_attente AS
SELECT 
    p.user_id,
    COALESCE(au.email, 'email@manquant.com')::TEXT as email,
    COALESCE(NULLIF(p.full_name, ''), 'Utilisateur')::TEXT as full_name,
    p.telephone,
    p.created_at,
    p.statut_validation,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER as jours_attente
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
ORDER BY p.created_at ASC;

-- 3. Permissions sur la vue
GRANT SELECT ON membres_en_attente TO authenticated;
GRANT SELECT ON membres_en_attente TO anon;

-- 4. Test de la vue
SELECT 
    '🧪 Test de la vue membres_en_attente' as info;

SELECT 
    user_id,
    email,
    full_name,
    telephone,
    jours_attente,
    statut_validation
FROM membres_en_attente
LIMIT 5;

-- 5. Vérifier la fonction valider_membre
SELECT 
    '🔍 Vérification de la fonction valider_membre' as info;

SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines
WHERE routine_name = 'valider_membre'
AND routine_schema = 'public';

-- 6. Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS valider_membre(UUID, UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS valider_membre(UUID, UUID, UUID);

-- Créer la nouvelle fonction
CREATE OR REPLACE FUNCTION valider_membre(
    p_user_id UUID,
    p_chorale_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Vérifier que l''utilisateur existe
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
    
    -- Enregistrer dans l''historique
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
    
    -- Retourner le résultat
    v_result := jsonb_build_object(
        'success', true,
        'message', 'Membre validé avec succès',
        'user_id', p_user_id,
        'chorale_id', p_chorale_id
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erreur lors de la validation: %', SQLERRM;
END;
$$;

-- 7. Permissions sur la fonction
GRANT EXECUTE ON FUNCTION valider_membre(UUID, UUID, UUID, TEXT) TO authenticated;

-- 8. Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS refuser_membre(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS refuser_membre(UUID, UUID);

-- Créer la nouvelle fonction
CREATE OR REPLACE FUNCTION refuser_membre(
    p_user_id UUID,
    p_validateur_id UUID,
    p_motif TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Vérifier que l''utilisateur existe
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Utilisateur introuvable: %', p_user_id;
    END IF;
    
    -- Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'refuse',
        statut_membre = 'inactif'
    WHERE user_id = p_user_id;
    
    -- Enregistrer dans l''historique
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
    
    -- Retourner le résultat
    v_result := jsonb_build_object(
        'success', true,
        'message', 'Membre refusé',
        'user_id', p_user_id
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erreur lors du refus: %', SQLERRM;
END;
$$;

-- 9. Permissions sur la fonction
GRANT EXECUTE ON FUNCTION refuser_membre(UUID, UUID, TEXT) TO authenticated;

-- 10. Test complet
SELECT 
    '✅ VÉRIFICATION FINALE' as info;

-- Tester la vue
SELECT 
    'Vue membres_en_attente' as test,
    COUNT(*) as nombre_membres
FROM membres_en_attente;

-- Lister les fonctions
SELECT 
    'Fonctions disponibles' as test,
    routine_name
FROM information_schema.routines
WHERE routine_name IN ('valider_membre', 'refuser_membre')
AND routine_schema = 'public';

SELECT '✅ Configuration terminée avec succès !' as status;
SELECT '📝 Rechargez le dashboard et réessayez de valider un membre' as conseil;

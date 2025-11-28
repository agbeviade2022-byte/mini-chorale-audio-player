-- =====================================================
-- CORRECTION COMPLÈTE : Inscription → Validation
-- =====================================================
-- Corrige toutes les failles de sécurité identifiées
-- dans le flux d'inscription jusqu'à la validation
-- =====================================================

-- ============================================
-- CORRECTION 1 : Trigger avec validation
-- ============================================

SELECT '🔧 CORRECTION 1 : Trigger sécurisé avec validation' as info;

-- Supprimer l'ancien trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Créer une fonction de validation
CREATE OR REPLACE FUNCTION validate_user_metadata(metadata JSONB)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_full_name TEXT;
    v_cleaned_name TEXT;
BEGIN
    -- Récupérer le nom
    v_full_name := metadata->>'full_name';
    
    -- Validation et nettoyage
    IF v_full_name IS NULL OR LENGTH(TRIM(v_full_name)) = 0 THEN
        -- Pas de nom fourni
        RETURN jsonb_build_object('full_name', NULL, 'valid', false);
    END IF;
    
    -- Nettoyer le nom (supprimer HTML/JS)
    v_cleaned_name := TRIM(v_full_name);
    
    -- Supprimer les balises HTML
    v_cleaned_name := REGEXP_REPLACE(v_cleaned_name, '<[^>]*>', '', 'g');
    
    -- Supprimer les caractères dangereux
    v_cleaned_name := REGEXP_REPLACE(v_cleaned_name, '[<>\"''`]', '', 'g');
    
    -- Limiter la longueur
    v_cleaned_name := SUBSTRING(v_cleaned_name, 1, 100);
    
    -- Vérifier qu'il reste quelque chose
    IF LENGTH(TRIM(v_cleaned_name)) = 0 THEN
        RETURN jsonb_build_object('full_name', NULL, 'valid', false);
    END IF;
    
    RETURN jsonb_build_object('full_name', v_cleaned_name, 'valid', true);
END;
$$;

-- Nouvelle fonction trigger SÉCURISÉE
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER  -- ✅ Utilise permissions de l'appelant
AS $$
DECLARE
    v_validated_metadata JSONB;
    v_full_name TEXT;
    v_email_username TEXT;
BEGIN
    -- Valider les métadonnées
    v_validated_metadata := validate_user_metadata(NEW.raw_user_meta_data);
    
    -- Récupérer le nom validé
    v_full_name := v_validated_metadata->>'full_name';
    
    -- Si pas de nom valide, utiliser la partie email
    IF v_full_name IS NULL THEN
        v_email_username := SPLIT_PART(NEW.email, '@', 1);
        v_full_name := 'Utilisateur_' || SUBSTRING(v_email_username, 1, 20);
    END IF;
    
    -- Créer le profil avec ON CONFLICT
    INSERT INTO public.profiles (
        user_id,
        full_name,
        role,
        statut_validation,
        statut_membre,
        created_at
    ) VALUES (
        NEW.id,
        v_full_name,              -- ✅ Nom validé et nettoyé
        'membre',                 -- ✅ Rôle forcé
        'en_attente',            -- ✅ Validation requise
        'inactif',               -- ✅ Inactif par défaut
        NEW.created_at
    )
    ON CONFLICT (user_id) DO NOTHING;  -- ✅ Évite les doublons
    
    RETURN NEW;
END;
$$;

-- Recréer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

SELECT '✅ Trigger sécurisé créé' as status;

-- ============================================
-- CORRECTION 2 : Vue membres_en_attente sécurisée
-- ============================================

SELECT '🔧 CORRECTION 2 : Vue avec masquage données sensibles' as info;

DROP VIEW IF EXISTS membres_en_attente;

-- Vue avec données masquées pour les admins normaux
CREATE OR REPLACE VIEW membres_en_attente AS
SELECT 
    p.user_id,
    -- Masquer partiellement l'email pour les admins normaux
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM profiles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin'
        ) THEN au.email::TEXT  -- ✅ Super admin voit tout
        ELSE 
            SUBSTRING(au.email, 1, 3) || '***@' || 
            SPLIT_PART(au.email, '@', 2)  -- ⚠️ Admin voit partiel
    END as email,
    p.full_name,
    -- Masquer le téléphone
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM profiles 
            WHERE user_id = auth.uid() 
            AND role = 'super_admin'
        ) THEN p.telephone  -- ✅ Super admin voit tout
        ELSE 
            CASE 
                WHEN p.telephone IS NOT NULL 
                THEN '***' || RIGHT(p.telephone, 4)  -- ⚠️ Admin voit 4 derniers chiffres
                ELSE NULL
            END
    END as telephone,
    p.created_at,
    p.statut_validation,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER as jours_attente
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
-- Vérifier que l'appelant est admin
AND EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'super_admin')
)
ORDER BY p.created_at ASC;

GRANT SELECT ON membres_en_attente TO authenticated;

SELECT '✅ Vue sécurisée créée avec masquage données' as status;

-- ============================================
-- CORRECTION 3 : Fonction valider_membre renforcée
-- ============================================

SELECT '🔧 CORRECTION 3 : Fonction valider_membre avec validations' as info;

DROP FUNCTION IF EXISTS valider_membre(UUID, UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION valider_membre(
    p_user_id UUID,
    p_chorale_id UUID,
    p_validateur_id UUID,
    p_commentaire TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER  -- ✅ Utilise permissions appelant
AS $$
DECLARE
    v_result JSONB;
    v_validateur_role TEXT;
    v_user_exists BOOLEAN;
    v_chorale_exists BOOLEAN;
    v_user_email TEXT;
BEGIN
    -- 1. Vérifier que l'appelant est bien le validateur
    IF p_validateur_id != auth.uid() THEN
        RAISE EXCEPTION 'Non autorisé: vous ne pouvez pas valider au nom de quelqu''un d''autre';
    END IF;
    
    -- 2. Vérifier le rôle du validateur
    SELECT role INTO v_validateur_role
    FROM profiles
    WHERE user_id = auth.uid();
    
    IF v_validateur_role NOT IN ('admin', 'super_admin') THEN
        RAISE EXCEPTION 'Non autorisé: seuls les admins peuvent valider des membres';
    END IF;
    
    -- 3. ✅ NOUVEAU: Vérifier que l'utilisateur existe
    SELECT EXISTS (
        SELECT 1 FROM profiles WHERE user_id = p_user_id
    ) INTO v_user_exists;
    
    IF NOT v_user_exists THEN
        RAISE EXCEPTION 'Utilisateur introuvable: %', p_user_id;
    END IF;
    
    -- 4. ✅ NOUVEAU: Vérifier que la chorale existe
    SELECT EXISTS (
        SELECT 1 FROM chorales WHERE id = p_chorale_id
    ) INTO v_chorale_exists;
    
    IF NOT v_chorale_exists THEN
        RAISE EXCEPTION 'Chorale introuvable: %', p_chorale_id;
    END IF;
    
    -- 5. ✅ NOUVEAU: Vérifier que l'utilisateur est bien en attente
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = p_user_id 
        AND statut_validation = 'en_attente'
    ) THEN
        RAISE EXCEPTION 'Utilisateur déjà validé ou refusé';
    END IF;
    
    -- 6. ✅ NOUVEAU: Nettoyer le commentaire
    p_commentaire := SUBSTRING(TRIM(COALESCE(p_commentaire, '')), 1, 500);
    
    -- 7. Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'valide',
        chorale_id = p_chorale_id,
        statut_membre = 'actif',
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- 8. Enregistrer dans l'historique
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
    
    -- 9. ✅ NOUVEAU: Logger l'action
    INSERT INTO admin_logs (
        admin_id,
        action,
        table_name,
        record_id,
        details,
        created_at
    ) VALUES (
        p_validateur_id,
        'VALIDATION_MEMBRE',
        'profiles',
        p_user_id::TEXT,
        jsonb_build_object(
            'chorale_id', p_chorale_id,
            'commentaire', p_commentaire
        ),
        NOW()
    );
    
    -- 10. Récupérer l'email pour le résultat
    SELECT au.email INTO v_user_email
    FROM auth.users au
    WHERE au.id = p_user_id;
    
    v_result := jsonb_build_object(
        'success', true,
        'message', 'Membre validé avec succès',
        'user_id', p_user_id,
        'email', v_user_email,
        'chorale_id', p_chorale_id
    );
    
    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION valider_membre(UUID, UUID, UUID, TEXT) TO authenticated;

SELECT '✅ Fonction valider_membre renforcée' as status;

-- ============================================
-- CORRECTION 4 : Fonction refuser_membre renforcée
-- ============================================

SELECT '🔧 CORRECTION 4 : Fonction refuser_membre avec validations' as info;

DROP FUNCTION IF EXISTS refuser_membre(UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION refuser_membre(
    p_user_id UUID,
    p_validateur_id UUID,
    p_motif TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_result JSONB;
    v_validateur_role TEXT;
    v_user_exists BOOLEAN;
    v_user_email TEXT;
BEGIN
    -- 1. Vérifier que l'appelant est bien le validateur
    IF p_validateur_id != auth.uid() THEN
        RAISE EXCEPTION 'Non autorisé';
    END IF;
    
    -- 2. Vérifier le rôle
    SELECT role INTO v_validateur_role
    FROM profiles
    WHERE user_id = auth.uid();
    
    IF v_validateur_role NOT IN ('admin', 'super_admin') THEN
        RAISE EXCEPTION 'Non autorisé: seuls les admins peuvent refuser des membres';
    END IF;
    
    -- 3. ✅ NOUVEAU: Vérifier que l'utilisateur existe
    SELECT EXISTS (
        SELECT 1 FROM profiles WHERE user_id = p_user_id
    ) INTO v_user_exists;
    
    IF NOT v_user_exists THEN
        RAISE EXCEPTION 'Utilisateur introuvable: %', p_user_id;
    END IF;
    
    -- 4. ✅ NOUVEAU: Vérifier le motif
    IF p_motif IS NULL OR LENGTH(TRIM(p_motif)) < 10 THEN
        RAISE EXCEPTION 'Motif de refus requis (minimum 10 caractères)';
    END IF;
    
    -- 5. ✅ NOUVEAU: Nettoyer le motif
    p_motif := SUBSTRING(TRIM(p_motif), 1, 500);
    
    -- 6. Mettre à jour le profil
    UPDATE profiles
    SET 
        statut_validation = 'refuse',
        statut_membre = 'inactif',
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- 7. Enregistrer dans l'historique
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
    
    -- 8. ✅ NOUVEAU: Logger l'action
    INSERT INTO admin_logs (
        admin_id,
        action,
        table_name,
        record_id,
        details,
        created_at
    ) VALUES (
        p_validateur_id,
        'REFUS_MEMBRE',
        'profiles',
        p_user_id::TEXT,
        jsonb_build_object('motif', p_motif),
        NOW()
    );
    
    -- 9. Récupérer l'email
    SELECT au.email INTO v_user_email
    FROM auth.users au
    WHERE au.id = p_user_id;
    
    v_result := jsonb_build_object(
        'success', true,
        'message', 'Membre refusé',
        'user_id', p_user_id,
        'email', v_user_email
    );
    
    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION refuser_membre(UUID, UUID, TEXT) TO authenticated;

SELECT '✅ Fonction refuser_membre renforcée' as status;

-- ============================================
-- CORRECTION 5 : Table admin_logs (si n'existe pas)
-- ============================================

SELECT '🔧 CORRECTION 5 : Création table admin_logs' as info;

CREATE TABLE IF NOT EXISTS admin_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id TEXT,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_admin_logs_admin_id ON admin_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created_at ON admin_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_logs_action ON admin_logs(action);

-- RLS sur admin_logs
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Super admins peuvent voir tous les logs" ON admin_logs;
CREATE POLICY "Super admins peuvent voir tous les logs"
ON admin_logs
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    )
);

DROP POLICY IF EXISTS "Admins peuvent voir leurs propres logs" ON admin_logs;
CREATE POLICY "Admins peuvent voir leurs propres logs"
ON admin_logs
FOR SELECT
TO authenticated
USING (admin_id = auth.uid());

SELECT '✅ Table admin_logs créée avec RLS' as status;

-- ============================================
-- CORRECTION 6 : RLS renforcé sur profiles
-- ============================================

SELECT '🔧 CORRECTION 6 : RLS renforcé sur profiles' as info;

-- Supprimer les anciennes policies
DROP POLICY IF EXISTS "Users can update own profile without role change" ON profiles;
DROP POLICY IF EXISTS "Super admins can update any profile" ON profiles;

-- Policy: Utilisateur peut voir son propre profil
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
ON profiles
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy: Admins peuvent voir tous les profils
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles"
ON profiles
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'super_admin')
    )
);

-- Policy: Utilisateur peut modifier son profil (SAUF rôle et statut)
CREATE POLICY "Users can update own profile limited"
ON profiles
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (
    user_id = auth.uid()
    -- ✅ Vérifier que le rôle n'a pas changé
    AND role = (SELECT role FROM profiles WHERE user_id = auth.uid())
    -- ✅ Vérifier que le statut n'a pas changé
    AND statut_validation = (SELECT statut_validation FROM profiles WHERE user_id = auth.uid())
    -- ✅ Vérifier que la chorale n'a pas changé (sauf si NULL)
    AND (
        chorale_id = (SELECT chorale_id FROM profiles WHERE user_id = auth.uid())
        OR (SELECT chorale_id FROM profiles WHERE user_id = auth.uid()) IS NULL
    )
);

-- Policy: Super admins peuvent tout modifier
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
    -- ✅ Vérifier que le rôle est valide
    role IN ('membre', 'admin', 'super_admin', 'maitre_choeur')
    AND
    -- ✅ Seul un super admin peut créer un autre super admin
    (role != 'super_admin' OR EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
    ))
);

SELECT '✅ RLS renforcé sur profiles' as status;

-- ============================================
-- VÉRIFICATION FINALE
-- ============================================

SELECT '✅ VÉRIFICATION FINALE' as info;

-- Vérifier le trigger
SELECT 
    'Trigger on_auth_user_created' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgname = 'on_auth_user_created'
        ) THEN '✅ Existe'
        ELSE '❌ Manquant'
    END as statut;

-- Vérifier les fonctions
SELECT 
    routine_name,
    security_type,
    CASE 
        WHEN security_type = 'INVOKER' THEN '✅ Sécurisé'
        WHEN security_type = 'DEFINER' THEN '⚠️ À surveiller'
        ELSE '❓ Inconnu'
    END as statut
FROM information_schema.routines
WHERE routine_name IN ('handle_new_user', 'valider_membre', 'refuser_membre', 'validate_user_metadata')
AND routine_schema = 'public';

-- Vérifier la table admin_logs
SELECT 
    'Table admin_logs' as element,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'admin_logs'
        ) THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as statut;

-- Vérifier les RLS policies sur profiles
SELECT 
    'RLS Policies sur profiles' as element,
    COUNT(*) as nombre,
    CASE 
        WHEN COUNT(*) >= 4 THEN '✅ OK'
        ELSE '⚠️ Insuffisant'
    END as statut
FROM pg_policies
WHERE tablename = 'profiles';

SELECT '✅ Correction et renforcement terminés avec succès !' as status;
SELECT '📝 Consultez GUIDE_CORRECTIONS_APPLIQUEES.md pour les détails' as documentation;
SELECT '🧪 Exécutez TEST_SECURITE_RAPIDE.sql pour vérifier' as next_step;

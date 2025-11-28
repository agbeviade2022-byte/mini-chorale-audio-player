-- =====================================================
-- DIAGNOSTIC : Identifier le problème d'inscription
-- =====================================================

-- 1. Vérifier la structure de profiles
SELECT 
    '1. Structure de la table profiles' as etape;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN is_nullable = 'NO' AND column_default IS NULL 
        THEN '⚠️ Obligatoire sans défaut'
        ELSE '✅ OK'
    END as statut
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes
SELECT 
    '2. Contraintes sur profiles' as etape;
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'profiles';

-- 3. Vérifier le trigger actuel
SELECT 
    '3. Trigger actuel' as etape;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users'
AND trigger_schema = 'auth';

-- 4. Vérifier la fonction actuelle
SELECT 
    '4. Fonction create_profile_on_signup' as etape;
SELECT 
    proname as nom_fonction,
    prosrc as code_source
FROM pg_proc
WHERE proname = 'create_profile_on_signup';

-- 5. Tester manuellement l'insertion
SELECT 
    '5. Test d''insertion manuelle' as etape;

-- Simuler ce que fait le trigger
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
BEGIN
    -- Essayer d'insérer un profil test
    INSERT INTO profiles (
        user_id,
        full_name,
        role
    ) VALUES (
        test_user_id,
        'Test User',
        'membre'
    );
    
    -- Si ça marche, supprimer le test
    DELETE FROM profiles WHERE user_id = test_user_id;
    
    RAISE NOTICE '✅ Insertion manuelle fonctionne';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur insertion: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;

-- 6. Vérifier les policies RLS
SELECT 
    '6. Policies RLS sur profiles' as etape;
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'profiles';

SELECT '✅ Diagnostic terminé - Vérifiez les résultats ci-dessus' as status;

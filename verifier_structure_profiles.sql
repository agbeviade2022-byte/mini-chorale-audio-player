-- =====================================================
-- SCRIPT : Vérifier la structure de la table profiles
-- =====================================================
-- Exécutez ce script AVANT d'exécuter migration_validation_membres.sql
-- pour vérifier que votre table profiles est compatible
-- =====================================================

-- Vérifier toutes les colonnes de la table profiles
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- Vérifier si les colonnes nécessaires existent
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'user_id') 
        THEN '✅ user_id existe'
        ELSE '❌ user_id manquant'
    END as user_id_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'full_name') 
        THEN '✅ full_name existe'
        ELSE '❌ full_name manquant'
    END as full_name_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'role') 
        THEN '✅ role existe'
        ELSE '❌ role manquant'
    END as role_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'chorale_id') 
        THEN '✅ chorale_id existe'
        ELSE '❌ chorale_id manquant'
    END as chorale_id_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'statut_membre') 
        THEN '✅ statut_membre existe'
        ELSE '⚠️ statut_membre manquant (sera créé)'
    END as statut_membre_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'statut_validation') 
        THEN '⚠️ statut_validation existe déjà'
        ELSE '✅ statut_validation sera créé'
    END as statut_validation_check;

-- Vérifier si la table profiles existe
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') 
        THEN '✅ Table profiles existe'
        ELSE '❌ Table profiles n''existe pas - Créez-la d''abord !'
    END as table_check;

-- Vérifier si la table chorales existe
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chorales') 
        THEN '✅ Table chorales existe'
        ELSE '❌ Table chorales n''existe pas - Exécutez migration_chorale_obligatoire.sql d''abord !'
    END as chorales_check;

-- Vérifier si la table chants existe
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chants') 
        THEN '✅ Table chants existe'
        ELSE '❌ Table chants n''existe pas'
    END as chants_check;

-- Compter les utilisateurs actuels
SELECT 
    COUNT(*) as total_profiles,
    COUNT(*) FILTER (WHERE chorale_id IS NOT NULL) as avec_chorale,
    COUNT(*) FILTER (WHERE chorale_id IS NULL) as sans_chorale
FROM profiles;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
/*
Si tout est OK, vous devriez voir :
- ✅ Table profiles existe
- ✅ Table chorales existe
- ✅ Table chants existe
- ✅ user_id existe
- ✅ full_name existe
- ✅ role existe
- ✅ chorale_id existe
- ✅ statut_validation sera créé (ou existe déjà)

Si vous voyez des ❌, corrigez d'abord ces problèmes avant d'exécuter
migration_validation_membres.sql
*/

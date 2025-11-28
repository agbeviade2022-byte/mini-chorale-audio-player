-- =====================================================
-- DEBUG : Utilisateur spécifique Lebron13
-- =====================================================
-- user_id: 9d30bbbb-12cd-4764-afdb-01f5d3377426
-- =====================================================

-- 1. Vérifier dans auth.users
SELECT 
    '🔍 Vérification dans auth.users' as info;

SELECT 
    id,
    email,
    created_at,
    '✅ Existe dans auth.users' as status
FROM auth.users
WHERE id = '9d30bbbb-12cd-4764-afdb-01f5d3377426';

-- 2. Vérifier dans profiles
SELECT 
    '🔍 Vérification dans profiles' as info;

SELECT 
    user_id,
    full_name,
    role,
    created_at,
    '✅ Existe dans profiles' as status
FROM profiles
WHERE user_id = '9d30bbbb-12cd-4764-afdb-01f5d3377426';

-- 3. Vérifier les permissions existantes
SELECT 
    '🔍 Permissions actuelles de Lebron13' as info;

SELECT 
    up.user_id,
    mp.code,
    mp.nom,
    up.created_at
FROM user_permissions up
JOIN modules_permissions mp ON up.module_code = mp.code
WHERE up.user_id = '9d30bbbb-12cd-4764-afdb-01f5d3377426'
ORDER BY mp.categorie, mp.nom;

-- 4. Vérifier la contrainte de clé étrangère
SELECT 
    '🔍 Vérification de la contrainte FK' as info;

SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'user_permissions'
AND kcu.column_name = 'user_id';

-- 5. Test d'insertion manuelle
SELECT 
    '🧪 Test d''insertion manuelle' as info;

-- Essayer d'insérer une permission de test
INSERT INTO user_permissions (user_id, module_code)
VALUES ('9d30bbbb-12cd-4764-afdb-01f5d3377426', 'view_stats')
ON CONFLICT (user_id, module_code) DO NOTHING
RETURNING *;

-- 6. Vérifier si l'insertion a fonctionné
SELECT 
    '✅ Vérification après insertion' as info;

SELECT 
    user_id,
    module_code,
    created_at
FROM user_permissions
WHERE user_id = '9d30bbbb-12cd-4764-afdb-01f5d3377426'
AND module_code = 'view_stats';

-- 7. Nettoyer le test
DELETE FROM user_permissions
WHERE user_id = '9d30bbbb-12cd-4764-afdb-01f5d3377426'
AND module_code = 'view_stats';

-- 8. Diagnostic complet
SELECT 
    '📊 DIAGNOSTIC COMPLET' as info;

SELECT 
    'Dans auth.users' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM auth.users WHERE id = '9d30bbbb-12cd-4764-afdb-01f5d3377426') 
        THEN '✅ OUI' 
        ELSE '❌ NON' 
    END as existe
UNION ALL
SELECT 
    'Dans profiles' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM profiles WHERE user_id = '9d30bbbb-12cd-4764-afdb-01f5d3377426') 
        THEN '✅ OUI' 
        ELSE '❌ NON' 
    END as existe
UNION ALL
SELECT 
    'A des permissions' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM user_permissions WHERE user_id = '9d30bbbb-12cd-4764-afdb-01f5d3377426') 
        THEN '✅ OUI (' || COUNT(*)::TEXT || ')' 
        ELSE '❌ NON' 
    END as existe
FROM user_permissions
WHERE user_id = '9d30bbbb-12cd-4764-afdb-01f5d3377426';

SELECT '✅ Diagnostic terminé' as status;

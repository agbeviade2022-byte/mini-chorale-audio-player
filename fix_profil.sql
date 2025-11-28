-- =====================================================
-- CORRIGER LE PROFIL POUR kodjodavid2025@gmail.com
-- =====================================================

-- 1. Vérifier si le profil existe déjà
SELECT 
    '🔍 VÉRIFICATION PROFIL' as info,
    COUNT(*) as nb_profils
FROM profiles p
JOIN auth.users au ON p.id = au.id
WHERE au.email = 'kodjodavid2025@gmail.com';

-- 2. Créer ou mettre à jour le profil
DO $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer le user_id
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = 'kodjodavid2025@gmail.com';
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur kodjodavid2025@gmail.com non trouvé dans auth.users';
    END IF;
    
    -- Créer ou mettre à jour le profil
    INSERT INTO profiles (id, full_name, role)
    VALUES (
        v_user_id,
        'David Kodjo',
        'admin'
    )
    ON CONFLICT (id) DO UPDATE
    SET 
        full_name = 'David Kodjo',
        role = 'admin';
    
    RAISE NOTICE '✅ Profil créé/mis à jour pour kodjodavid2025@gmail.com';
END $$;

-- 3. Vérifier que le profil est bien créé
SELECT 
    '✅ PROFIL CRÉÉ' as statut,
    p.id,
    au.email,
    p.full_name,
    p.role,
    p.created_at
FROM profiles p
JOIN auth.users au ON p.id = au.id
WHERE au.email = 'kodjodavid2025@gmail.com';

-- 4. Vérifier la correspondance auth.users <-> profiles
SELECT 
    '🔗 CORRESPONDANCE' as info,
    au.id as user_id,
    au.email,
    p.full_name,
    p.role,
    CASE 
        WHEN p.id IS NOT NULL THEN '✅ Profil existe'
        ELSE '❌ Profil manquant'
    END as statut
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
WHERE au.email = 'kodjodavid2025@gmail.com';

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Profil créé/mis à jour
-- id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
-- email: kodjodavid2025@gmail.com
-- full_name: David Kodjo
-- role: admin

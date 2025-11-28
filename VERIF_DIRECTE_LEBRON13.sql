-- =====================================================
-- VÉRIFICATION DIRECTE : Lebron13 existe-t-il vraiment ?
-- =====================================================

-- Vérification 1: Dans profiles
SELECT 
    '1️⃣ Recherche dans profiles' as etape;

SELECT 
    user_id,
    full_name,
    role,
    created_at
FROM profiles
WHERE user_id = '9d30bbbb-12cd-4764-afdb-01f5d3377426';

-- Si aucun résultat, l'utilisateur N'EXISTE PAS dans profiles

-- Vérification 2: Dans auth.users
SELECT 
    '2️⃣ Recherche dans auth.users' as etape;

SELECT 
    id,
    email,
    created_at
FROM auth.users
WHERE id = '9d30bbbb-12cd-4764-afdb-01f5d3377426';

-- Vérification 3: Chercher par nom
SELECT 
    '3️⃣ Recherche par nom "Lebron13"' as etape;

SELECT 
    user_id,
    full_name,
    role
FROM profiles
WHERE full_name ILIKE '%lebron%';

-- Vérification 4: Lister TOUS les profiles
SELECT 
    '4️⃣ Liste de TOUS les profiles' as etape;

SELECT 
    user_id,
    full_name,
    role,
    created_at
FROM profiles
ORDER BY created_at DESC;

-- SOLUTION: Créer le profil manquant
SELECT 
    '🔧 SOLUTION: Créer le profil pour Lebron13' as etape;

-- D'abord, vérifier si l'utilisateur existe dans auth.users
DO $$
DECLARE
    v_email TEXT;
BEGIN
    -- Récupérer l'email depuis auth.users
    SELECT email INTO v_email
    FROM auth.users
    WHERE id = '9d30bbbb-12cd-4764-afdb-01f5d3377426';
    
    IF v_email IS NOT NULL THEN
        -- Créer le profil
        INSERT INTO profiles (user_id, full_name, role, created_at)
        VALUES (
            '9d30bbbb-12cd-4764-afdb-01f5d3377426',
            'Lebron13',
            'membre',
            NOW()
        )
        ON CONFLICT (user_id) DO UPDATE
        SET full_name = 'Lebron13',
            role = 'membre';
        
        RAISE NOTICE '✅ Profil créé pour Lebron13 (%)' , v_email;
    ELSE
        RAISE NOTICE '❌ Utilisateur introuvable dans auth.users';
    END IF;
END $$;

-- Vérification finale
SELECT 
    '✅ VÉRIFICATION FINALE' as etape;

SELECT 
    user_id,
    full_name,
    role,
    created_at
FROM profiles
WHERE user_id = '9d30bbbb-12cd-4764-afdb-01f5d3377426';

SELECT '✅ Script terminé' as status;

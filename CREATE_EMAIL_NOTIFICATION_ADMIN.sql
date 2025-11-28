-- =====================================================
-- NOTIFICATION EMAIL : Super admin quand email confirmé
-- =====================================================

SELECT '🔧 CRÉATION : Notification email pour super admin' as info;

-- ============================================
-- ÉTAPE 1 : Créer une fonction pour notifier le super admin
-- ============================================

SELECT '📋 ÉTAPE 1 : Fonction de notification' as etape;

-- Fonction appelée quand un utilisateur confirme son email
CREATE OR REPLACE FUNCTION notify_admin_email_confirmed()
RETURNS TRIGGER AS $$
DECLARE
    admin_email TEXT;
    user_full_name TEXT;
    user_email TEXT;
BEGIN
    -- Vérifier si l'email vient d'être confirmé
    IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
        
        -- Récupérer le nom complet de l'utilisateur depuis profiles
        SELECT full_name INTO user_full_name
        FROM profiles
        WHERE user_id = NEW.id;
        
        user_email := NEW.email;
        
        -- Récupérer l'email du super admin
        SELECT au.email INTO admin_email
        FROM auth.users au
        INNER JOIN profiles p ON au.id = p.user_id
        WHERE p.role = 'super_admin'
        LIMIT 1;
        
        -- Si un super admin existe, créer une notification
        IF admin_email IS NOT NULL THEN
            -- Insérer dans une table de notifications (à créer)
            INSERT INTO admin_notifications (
                type,
                titre,
                message,
                user_id,
                created_at
            ) VALUES (
                'email_confirmed',
                'Nouvel utilisateur - Email confirmé',
                'L''utilisateur ' || COALESCE(user_full_name, user_email) || ' (' || user_email || ') a confirmé son email et est en attente de validation.',
                NEW.id,
                NOW()
            );
            
            -- Log pour debug
            RAISE NOTICE 'Notification créée pour super admin: % - Utilisateur: %', admin_email, user_email;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ÉTAPE 2 : Créer la table des notifications admin
-- ============================================

SELECT '📋 ÉTAPE 2 : Table notifications' as etape;

-- Table pour stocker les notifications admin
CREATE TABLE IF NOT EXISTS admin_notifications (
    id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,  -- 'email_confirmed', 'new_signup', 'member_validated', etc.
    titre VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    lu BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_admin_notifications_created_at ON admin_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_lu ON admin_notifications(lu);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_type ON admin_notifications(type);

-- ============================================
-- ÉTAPE 3 : Créer le trigger
-- ============================================

SELECT '📋 ÉTAPE 3 : Trigger sur auth.users' as etape;

-- Supprimer le trigger s'il existe
DROP TRIGGER IF EXISTS trigger_notify_admin_email_confirmed ON auth.users;

-- Créer le trigger
CREATE TRIGGER trigger_notify_admin_email_confirmed
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION notify_admin_email_confirmed();

-- ============================================
-- ÉTAPE 4 : Fonction pour récupérer les notifications
-- ============================================

SELECT '📋 ÉTAPE 4 : Fonction RPC pour dashboard' as etape;

-- Fonction pour récupérer les notifications non lues
CREATE OR REPLACE FUNCTION get_admin_notifications(
    p_limit INTEGER DEFAULT 50,
    p_only_unread BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    id INTEGER,
    type VARCHAR(50),
    titre VARCHAR(255),
    message TEXT,
    user_id UUID,
    user_email TEXT,
    user_full_name TEXT,
    lu BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        an.id,
        an.type,
        an.titre,
        an.message,
        an.user_id,
        au.email as user_email,
        p.full_name as user_full_name,
        an.lu,
        an.created_at
    FROM admin_notifications an
    LEFT JOIN auth.users au ON an.user_id = au.id
    LEFT JOIN profiles p ON au.id = p.user_id
    WHERE (p_only_unread = FALSE OR an.lu = FALSE)
    ORDER BY an.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour marquer une notification comme lue
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE admin_notifications
    SET lu = TRUE
    WHERE id = p_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour marquer toutes les notifications comme lues
CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS VOID AS $$
BEGIN
    UPDATE admin_notifications
    SET lu = TRUE
    WHERE lu = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ÉTAPE 5 : Politiques RLS
-- ============================================

SELECT '📋 ÉTAPE 5 : Politiques RLS' as etape;

-- Activer RLS
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;

-- Supprimer TOUTES les anciennes politiques
DROP POLICY IF EXISTS "Super admins peuvent voir toutes les notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Super admins peuvent créer des notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Super admins peuvent mettre à jour les notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Système peut créer des notifications" ON admin_notifications;

-- Politique SELECT : Super admins voient tout
CREATE POLICY "Super admins peuvent voir toutes les notifications"
ON admin_notifications
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.role = 'super_admin'
    )
);

-- Politique INSERT : Système peut créer
CREATE POLICY "Système peut créer des notifications"
ON admin_notifications
FOR INSERT
WITH CHECK (TRUE);  -- Le trigger peut insérer

-- Politique UPDATE : Super admins peuvent mettre à jour
CREATE POLICY "Super admins peuvent mettre à jour les notifications"
ON admin_notifications
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.role = 'super_admin'
    )
);

-- ============================================
-- ÉTAPE 6 : Créer aussi une notification à l'inscription
-- ============================================

SELECT '📋 ÉTAPE 6 : Notification à l''inscription' as etape;

-- Fonction appelée quand un nouvel utilisateur s'inscrit
CREATE OR REPLACE FUNCTION notify_admin_new_signup()
RETURNS TRIGGER AS $$
DECLARE
    user_full_name TEXT;
BEGIN
    -- Récupérer le nom complet depuis profiles
    SELECT full_name INTO user_full_name
    FROM profiles
    WHERE user_id = NEW.id;
    
    -- Créer une notification
    INSERT INTO admin_notifications (
        type,
        titre,
        message,
        user_id,
        created_at
    ) VALUES (
        'new_signup',
        'Nouvelle inscription',
        'Nouvel utilisateur inscrit : ' || COALESCE(user_full_name, NEW.email) || ' (' || NEW.email || '). En attente de confirmation d''email.',
        NEW.id,
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer le trigger s'il existe
DROP TRIGGER IF EXISTS trigger_notify_admin_new_signup ON auth.users;

-- Créer le trigger sur INSERT
CREATE TRIGGER trigger_notify_admin_new_signup
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION notify_admin_new_signup();

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ SYSTÈME DE NOTIFICATION CRÉÉ ✅✅✅' as resultat;
SELECT 'Le super admin recevra des notifications pour :' as note;
SELECT '  - Nouvelle inscription (email non confirmé)' as notification_1;
SELECT '  - Email confirmé (prêt pour validation)' as notification_2;
SELECT 'Utilisez get_admin_notifications() dans le dashboard' as utilisation;

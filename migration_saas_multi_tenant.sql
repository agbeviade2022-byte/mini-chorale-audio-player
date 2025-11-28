-- =====================================================
-- MIGRATION VERS SAAS MULTI-TENANT
-- Mini Chorale Audio Player
-- =====================================================
-- Ce script transforme l'application en plateforme SaaS
-- où chaque chorale a son espace privé
-- =====================================================

-- =====================================================
-- ÉTAPE 1 : CRÉER LES NOUVELLES TABLES
-- =====================================================

-- Table Chorales (Organisations)
CREATE TABLE IF NOT EXISTS chorales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Informations de base
  nom TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL, -- pour URL personnalisée (ex: chorale-st-camille)
  description TEXT,
  pays TEXT DEFAULT 'CI',
  ville TEXT,
  
  -- Contact
  email_contact TEXT NOT NULL,
  telephone TEXT,
  site_web TEXT,
  
  -- Branding
  logo_url TEXT,
  couleur_principale TEXT DEFAULT '#1976D2',
  
  -- Admin principal
  admin_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Abonnement
  abonnement_actif BOOLEAN DEFAULT false,
  plan TEXT CHECK (plan IN ('trial', 'basic', 'standard', 'pro')) DEFAULT 'trial',
  date_debut_abonnement TIMESTAMPTZ,
  date_fin_abonnement TIMESTAMPTZ,
  
  -- Limites par plan
  max_chants INTEGER DEFAULT 10, -- trial: 10, basic: 40, standard/pro: -1 (illimité)
  max_membres INTEGER DEFAULT 20, -- trial: 20, basic: 50, standard: 100, pro: -1
  stockage_utilise_mb DECIMAL(10,2) DEFAULT 0,
  stockage_max_mb INTEGER DEFAULT 500, -- trial: 500, basic: 1000, standard: 5000, pro: 20000
  
  -- Paiement (Stripe)
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  
  -- Paiement (CinetPay / Mobile Money)
  cinetpay_customer_id TEXT,
  
  -- Statistiques
  total_chants INTEGER DEFAULT 0,
  total_membres INTEGER DEFAULT 0,
  total_ecoutes INTEGER DEFAULT 0,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  statut TEXT CHECK (statut IN ('actif', 'suspendu', 'archive')) DEFAULT 'actif'
);

-- Index pour performance
CREATE INDEX idx_chorales_slug ON chorales(slug);
CREATE INDEX idx_chorales_admin ON chorales(admin_user_id);
CREATE INDEX idx_chorales_abonnement ON chorales(abonnement_actif, date_fin_abonnement);

-- =====================================================

-- Table Membres (Lien entre utilisateurs et chorales)
CREATE TABLE IF NOT EXISTS membres (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Relations
  chorale_id UUID NOT NULL REFERENCES chorales(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Informations (dupliquées pour performance)
  nom_complet TEXT NOT NULL,
  email TEXT NOT NULL,
  telephone TEXT,
  photo_url TEXT,
  
  -- Rôle dans la chorale
  role TEXT CHECK (role IN ('chef', 'assistant', 'choriste')) DEFAULT 'choriste',
  
  -- Pupitre (pour chants pupitre)
  pupitre TEXT CHECK (pupitre IN ('soprano', 'alto', 'tenor', 'basse', 'autre', 'non_defini')) DEFAULT 'non_defini',
  
  -- Statut
  statut TEXT CHECK (statut IN ('actif', 'suspendu', 'invite')) DEFAULT 'invite',
  date_invitation TIMESTAMPTZ DEFAULT NOW(),
  date_acceptation TIMESTAMPTZ,
  
  -- Permissions spécifiques
  peut_uploader BOOLEAN DEFAULT false,
  peut_supprimer BOOLEAN DEFAULT false,
  peut_inviter BOOLEAN DEFAULT false,
  
  -- Statistiques
  total_ecoutes INTEGER DEFAULT 0,
  derniere_activite TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Contraintes
  UNIQUE(chorale_id, user_id),
  UNIQUE(chorale_id, email)
);

-- Index pour performance
CREATE INDEX idx_membres_chorale ON membres(chorale_id);
CREATE INDEX idx_membres_user ON membres(user_id);
CREATE INDEX idx_membres_role ON membres(chorale_id, role);
CREATE INDEX idx_membres_statut ON membres(chorale_id, statut);

-- =====================================================

-- Table Invitations
CREATE TABLE IF NOT EXISTS invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Relations
  chorale_id UUID NOT NULL REFERENCES chorales(id) ON DELETE CASCADE,
  invite_par UUID REFERENCES membres(id) ON DELETE SET NULL,
  
  -- Destinataire
  email TEXT NOT NULL,
  nom_complet TEXT,
  
  -- Rôle proposé
  role TEXT CHECK (role IN ('chef', 'assistant', 'choriste')) DEFAULT 'choriste',
  pupitre TEXT,
  
  -- Token sécurisé
  token TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  
  -- Validité
  expire_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  
  -- Statut
  statut TEXT CHECK (statut IN ('en_attente', 'accepte', 'refuse', 'expire')) DEFAULT 'en_attente',
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  
  -- Message personnalisé
  message TEXT
);

-- Index
CREATE INDEX idx_invitations_chorale ON invitations(chorale_id);
CREATE INDEX idx_invitations_email ON invitations(email);
CREATE INDEX idx_invitations_token ON invitations(token);
CREATE INDEX idx_invitations_statut ON invitations(statut, expire_at);

-- =====================================================

-- Table Abonnements (Historique des paiements)
CREATE TABLE IF NOT EXISTS abonnements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Relation
  chorale_id UUID NOT NULL REFERENCES chorales(id) ON DELETE CASCADE,
  
  -- Plan
  plan TEXT NOT NULL CHECK (plan IN ('trial', 'basic', 'standard', 'pro')),
  prix_cfa INTEGER NOT NULL,
  periode TEXT CHECK (periode IN ('mensuel', 'annuel', 'trial')) DEFAULT 'mensuel',
  
  -- Dates
  date_debut TIMESTAMPTZ NOT NULL,
  date_fin TIMESTAMPTZ NOT NULL,
  
  -- Paiement
  methode_paiement TEXT CHECK (methode_paiement IN ('stripe', 'cinetpay', 'mobile_money', 'virement', 'gratuit')),
  transaction_id TEXT,
  reference_paiement TEXT,
  
  -- Statut
  statut TEXT CHECK (statut IN ('actif', 'expire', 'annule', 'en_attente', 'echoue')) DEFAULT 'en_attente',
  
  -- Stripe
  stripe_subscription_id TEXT,
  stripe_invoice_id TEXT,
  stripe_payment_intent_id TEXT,
  
  -- CinetPay
  cinetpay_transaction_id TEXT,
  cinetpay_payment_token TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Notes
  notes TEXT
);

-- Index
CREATE INDEX idx_abonnements_chorale ON abonnements(chorale_id);
CREATE INDEX idx_abonnements_statut ON abonnements(statut, date_fin);
CREATE INDEX idx_abonnements_stripe ON abonnements(stripe_subscription_id);

-- =====================================================

-- Table Statistiques d'écoute
CREATE TABLE IF NOT EXISTS ecoutes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Relations
  chant_id UUID NOT NULL REFERENCES chants(id) ON DELETE CASCADE,
  membre_id UUID REFERENCES membres(id) ON DELETE SET NULL,
  chorale_id UUID NOT NULL REFERENCES chorales(id) ON DELETE CASCADE,
  
  -- Détails écoute
  duree_ecoute_secondes INTEGER NOT NULL DEFAULT 0,
  pourcentage_ecoute INTEGER CHECK (pourcentage_ecoute >= 0 AND pourcentage_ecoute <= 100),
  complete BOOLEAN DEFAULT false,
  
  -- Context
  date_ecoute TIMESTAMPTZ DEFAULT NOW(),
  appareil TEXT CHECK (appareil IN ('android', 'ios', 'web', 'autre')),
  version_app TEXT,
  
  -- Localisation (optionnel)
  pays TEXT,
  ville TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour analytics
CREATE INDEX idx_ecoutes_chant ON ecoutes(chant_id, date_ecoute DESC);
CREATE INDEX idx_ecoutes_membre ON ecoutes(membre_id, date_ecoute DESC);
CREATE INDEX idx_ecoutes_chorale ON ecoutes(chorale_id, date_ecoute DESC);
CREATE INDEX idx_ecoutes_date ON ecoutes(date_ecoute DESC);

-- =====================================================
-- ÉTAPE 2 : MODIFIER LES TABLES EXISTANTES
-- =====================================================

-- Ajouter chorale_id à la table chants
ALTER TABLE chants ADD COLUMN IF NOT EXISTS chorale_id UUID REFERENCES chorales(id) ON DELETE CASCADE;
ALTER TABLE chants ADD COLUMN IF NOT EXISTS uploaded_by UUID REFERENCES membres(id) ON DELETE SET NULL;
ALTER TABLE chants ADD COLUMN IF NOT EXISTS taille_mb DECIMAL(10,2);
ALTER TABLE chants ADD COLUMN IF NOT EXISTS visibilite TEXT CHECK (visibilite IN ('tous', 'pupitre_specifique')) DEFAULT 'tous';
ALTER TABLE chants ADD COLUMN IF NOT EXISTS pupitre_cible TEXT; -- si visibilite = pupitre_specifique
ALTER TABLE chants ADD COLUMN IF NOT EXISTS nombre_ecoutes INTEGER DEFAULT 0;
ALTER TABLE chants ADD COLUMN IF NOT EXISTS derniere_ecoute TIMESTAMPTZ;

-- Index
CREATE INDEX IF NOT EXISTS idx_chants_chorale ON chants(chorale_id);
CREATE INDEX IF NOT EXISTS idx_chants_uploaded_by ON chants(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_chants_type_chorale ON chants(type, chorale_id);

-- Modifier la table profiles pour ajouter chorale_id (optionnel, pour compatibilité)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS chorale_actuelle_id UUID REFERENCES chorales(id) ON DELETE SET NULL;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS derniere_chorale_visitee UUID;

-- =====================================================
-- ÉTAPE 3 : ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Activer RLS sur toutes les tables
ALTER TABLE chorales ENABLE ROW LEVEL SECURITY;
ALTER TABLE membres ENABLE ROW LEVEL SECURITY;
ALTER TABLE chants ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE abonnements ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecoutes ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- Politiques RLS pour CHORALES
-- =====================================================

-- Les utilisateurs voient les chorales dont ils sont membres
CREATE POLICY "Utilisateurs voient leurs chorales"
ON chorales FOR SELECT
USING (
  id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid()
  )
);

-- Seuls les chefs peuvent modifier leur chorale
CREATE POLICY "Chefs modifient leur chorale"
ON chorales FOR UPDATE
USING (
  id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() AND role = 'chef'
  )
);

-- Tout utilisateur authentifié peut créer une chorale
CREATE POLICY "Utilisateurs créent des chorales"
ON chorales FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- =====================================================
-- Politiques RLS pour MEMBRES
-- =====================================================

-- Les membres voient les autres membres de leur chorale
CREATE POLICY "Membres voient leur chorale"
ON membres FOR SELECT
USING (
  chorale_id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() AND statut = 'actif'
  )
);

-- Seuls les chefs et assistants peuvent ajouter des membres
CREATE POLICY "Chefs ajoutent des membres"
ON membres FOR INSERT
WITH CHECK (
  chorale_id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() AND role IN ('chef', 'assistant')
  )
);

-- Seuls les chefs peuvent modifier les membres
CREATE POLICY "Chefs modifient les membres"
ON membres FOR UPDATE
USING (
  chorale_id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() AND role = 'chef'
  )
);

-- =====================================================
-- Politiques RLS pour CHANTS
-- =====================================================

-- Les membres actifs voient les chants de leur chorale (si abonnement actif)
CREATE POLICY "Membres voient chants de leur chorale"
ON chants FOR SELECT
USING (
  chorale_id IN (
    SELECT m.chorale_id FROM membres m
    JOIN chorales c ON c.id = m.chorale_id
    WHERE m.user_id = auth.uid() 
    AND m.statut = 'actif'
    AND c.abonnement_actif = true
    AND c.date_fin_abonnement > NOW()
  )
);

-- Seuls les membres autorisés peuvent uploader
CREATE POLICY "Membres autorisés uploadent"
ON chants FOR INSERT
WITH CHECK (
  chorale_id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() 
    AND statut = 'actif'
    AND (role IN ('chef', 'assistant') OR peut_uploader = true)
  )
);

-- Seuls les chefs et ceux qui ont uploadé peuvent modifier
CREATE POLICY "Chefs et uploaders modifient"
ON chants FOR UPDATE
USING (
  uploaded_by IN (
    SELECT id FROM membres WHERE user_id = auth.uid()
  )
  OR
  chorale_id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() AND role = 'chef'
  )
);

-- Seuls les chefs et ceux autorisés peuvent supprimer
CREATE POLICY "Chefs et autorisés suppriment"
ON chants FOR DELETE
USING (
  uploaded_by IN (
    SELECT id FROM membres WHERE user_id = auth.uid()
  )
  OR
  chorale_id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() 
    AND (role = 'chef' OR peut_supprimer = true)
  )
);

-- =====================================================
-- Politiques RLS pour INVITATIONS
-- =====================================================

-- Les chefs voient les invitations de leur chorale
CREATE POLICY "Chefs voient invitations"
ON invitations FOR SELECT
USING (
  chorale_id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() AND role IN ('chef', 'assistant')
  )
);

-- Les chefs et membres autorisés peuvent inviter
CREATE POLICY "Chefs invitent"
ON invitations FOR INSERT
WITH CHECK (
  chorale_id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() 
    AND (role IN ('chef', 'assistant') OR peut_inviter = true)
  )
);

-- =====================================================
-- Politiques RLS pour ABONNEMENTS
-- =====================================================

-- Les chefs voient l'historique des abonnements
CREATE POLICY "Chefs voient abonnements"
ON abonnements FOR SELECT
USING (
  chorale_id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() AND role = 'chef'
  )
);

-- =====================================================
-- Politiques RLS pour ECOUTES
-- =====================================================

-- Les membres voient leurs propres écoutes
CREATE POLICY "Membres voient leurs écoutes"
ON ecoutes FOR SELECT
USING (
  membre_id IN (
    SELECT id FROM membres WHERE user_id = auth.uid()
  )
);

-- Les chefs voient toutes les écoutes de leur chorale
CREATE POLICY "Chefs voient écoutes chorale"
ON ecoutes FOR SELECT
USING (
  chorale_id IN (
    SELECT chorale_id FROM membres 
    WHERE user_id = auth.uid() AND role = 'chef'
  )
);

-- Tout membre actif peut créer une écoute
CREATE POLICY "Membres créent écoutes"
ON ecoutes FOR INSERT
WITH CHECK (
  membre_id IN (
    SELECT id FROM membres 
    WHERE user_id = auth.uid() AND statut = 'actif'
  )
);

-- =====================================================
-- ÉTAPE 4 : FONCTIONS ET TRIGGERS
-- =====================================================

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers pour updated_at
CREATE TRIGGER update_chorales_updated_at BEFORE UPDATE ON chorales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_membres_updated_at BEFORE UPDATE ON membres
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_abonnements_updated_at BEFORE UPDATE ON abonnements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================

-- Fonction pour vérifier les limites du plan
CREATE OR REPLACE FUNCTION check_plan_limits()
RETURNS TRIGGER AS $$
DECLARE
    v_chorale RECORD;
    v_count INTEGER;
BEGIN
    -- Récupérer les infos de la chorale
    SELECT * INTO v_chorale FROM chorales WHERE id = NEW.chorale_id;
    
    -- Vérifier si l'abonnement est actif
    IF NOT v_chorale.abonnement_actif OR v_chorale.date_fin_abonnement < NOW() THEN
        RAISE EXCEPTION 'Abonnement inactif ou expiré';
    END IF;
    
    -- Vérifier la limite de chants (si pas illimité)
    IF TG_TABLE_NAME = 'chants' AND v_chorale.max_chants > 0 THEN
        SELECT COUNT(*) INTO v_count FROM chants WHERE chorale_id = NEW.chorale_id;
        IF v_count >= v_chorale.max_chants THEN
            RAISE EXCEPTION 'Limite de chants atteinte pour le plan %', v_chorale.plan;
        END IF;
    END IF;
    
    -- Vérifier la limite de membres (si pas illimité)
    IF TG_TABLE_NAME = 'membres' AND v_chorale.max_membres > 0 THEN
        SELECT COUNT(*) INTO v_count FROM membres WHERE chorale_id = NEW.chorale_id AND statut = 'actif';
        IF v_count >= v_chorale.max_membres THEN
            RAISE EXCEPTION 'Limite de membres atteinte pour le plan %', v_chorale.plan;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers pour vérifier les limites
CREATE TRIGGER check_chants_limit BEFORE INSERT ON chants
    FOR EACH ROW EXECUTE FUNCTION check_plan_limits();

CREATE TRIGGER check_membres_limit BEFORE INSERT ON membres
    FOR EACH ROW EXECUTE FUNCTION check_plan_limits();

-- =====================================================

-- Fonction pour mettre à jour les statistiques de la chorale
CREATE OR REPLACE FUNCTION update_chorale_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF TG_TABLE_NAME = 'chants' THEN
            UPDATE chorales SET 
                total_chants = total_chants + 1,
                stockage_utilise_mb = stockage_utilise_mb + COALESCE(NEW.taille_mb, 0)
            WHERE id = NEW.chorale_id;
        ELSIF TG_TABLE_NAME = 'membres' AND NEW.statut = 'actif' THEN
            UPDATE chorales SET total_membres = total_membres + 1
            WHERE id = NEW.chorale_id;
        ELSIF TG_TABLE_NAME = 'ecoutes' THEN
            UPDATE chorales SET total_ecoutes = total_ecoutes + 1
            WHERE id = NEW.chorale_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF TG_TABLE_NAME = 'chants' THEN
            UPDATE chorales SET 
                total_chants = GREATEST(0, total_chants - 1),
                stockage_utilise_mb = GREATEST(0, stockage_utilise_mb - COALESCE(OLD.taille_mb, 0))
            WHERE id = OLD.chorale_id;
        ELSIF TG_TABLE_NAME = 'membres' AND OLD.statut = 'actif' THEN
            UPDATE chorales SET total_membres = GREATEST(0, total_membres - 1)
            WHERE id = OLD.chorale_id;
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF TG_TABLE_NAME = 'membres' THEN
            IF OLD.statut != 'actif' AND NEW.statut = 'actif' THEN
                UPDATE chorales SET total_membres = total_membres + 1
                WHERE id = NEW.chorale_id;
            ELSIF OLD.statut = 'actif' AND NEW.statut != 'actif' THEN
                UPDATE chorales SET total_membres = GREATEST(0, total_membres - 1)
                WHERE id = NEW.chorale_id;
            END IF;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Triggers pour les statistiques
CREATE TRIGGER update_stats_chants AFTER INSERT OR DELETE ON chants
    FOR EACH ROW EXECUTE FUNCTION update_chorale_stats();

CREATE TRIGGER update_stats_membres AFTER INSERT OR UPDATE OR DELETE ON membres
    FOR EACH ROW EXECUTE FUNCTION update_chorale_stats();

CREATE TRIGGER update_stats_ecoutes AFTER INSERT ON ecoutes
    FOR EACH ROW EXECUTE FUNCTION update_chorale_stats();

-- =====================================================

-- Fonction pour créer automatiquement un membre chef lors de la création d'une chorale
CREATE OR REPLACE FUNCTION create_chef_membre()
RETURNS TRIGGER AS $$
DECLARE
    v_user RECORD;
BEGIN
    -- Récupérer les infos de l'utilisateur
    SELECT * INTO v_user FROM auth.users WHERE id = NEW.admin_user_id;
    
    -- Créer le membre chef
    INSERT INTO membres (
        chorale_id,
        user_id,
        nom_complet,
        email,
        role,
        statut,
        peut_uploader,
        peut_supprimer,
        peut_inviter,
        date_acceptation
    ) VALUES (
        NEW.id,
        NEW.admin_user_id,
        COALESCE(v_user.raw_user_meta_data->>'full_name', v_user.email),
        v_user.email,
        'chef',
        'actif',
        true,
        true,
        true,
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour créer le chef automatiquement
CREATE TRIGGER create_chef_on_chorale_creation AFTER INSERT ON chorales
    FOR EACH ROW EXECUTE FUNCTION create_chef_membre();

-- =====================================================
-- ÉTAPE 5 : VUES UTILES
-- =====================================================

-- Vue pour les statistiques des chorales
CREATE OR REPLACE VIEW v_chorales_stats AS
SELECT 
    c.id,
    c.nom,
    c.plan,
    c.abonnement_actif,
    c.date_fin_abonnement,
    c.total_chants,
    c.total_membres,
    c.total_ecoutes,
    c.stockage_utilise_mb,
    c.stockage_max_mb,
    ROUND((c.stockage_utilise_mb::DECIMAL / NULLIF(c.stockage_max_mb, 0)) * 100, 2) as pourcentage_stockage,
    COUNT(DISTINCT m.id) FILTER (WHERE m.statut = 'actif') as membres_actifs,
    COUNT(DISTINCT ch.id) as chants_count,
    COUNT(DISTINCT e.id) as ecoutes_count,
    MAX(e.date_ecoute) as derniere_ecoute
FROM chorales c
LEFT JOIN membres m ON m.chorale_id = c.id
LEFT JOIN chants ch ON ch.chorale_id = c.id
LEFT JOIN ecoutes e ON e.chorale_id = c.id
GROUP BY c.id;

-- Vue pour les chants populaires par chorale
CREATE OR REPLACE VIEW v_chants_populaires AS
SELECT 
    ch.id,
    ch.titre,
    ch.auteur,
    ch.chorale_id,
    ch.nombre_ecoutes,
    COUNT(e.id) as ecoutes_30j,
    ch.derniere_ecoute
FROM chants ch
LEFT JOIN ecoutes e ON e.chant_id = ch.id AND e.date_ecoute > NOW() - INTERVAL '30 days'
GROUP BY ch.id
ORDER BY ecoutes_30j DESC, ch.nombre_ecoutes DESC;

-- =====================================================
-- ÉTAPE 6 : DONNÉES DE TEST (OPTIONNEL)
-- =====================================================

-- Créer une chorale de test (décommenter si besoin)
/*
INSERT INTO chorales (
    nom,
    slug,
    description,
    email_contact,
    admin_user_id,
    abonnement_actif,
    plan,
    date_debut_abonnement,
    date_fin_abonnement
) VALUES (
    'Chorale St Camille',
    'chorale-st-camille',
    'Chorale de test pour développement',
    'admin@chorale-st-camille.com',
    (SELECT id FROM auth.users LIMIT 1), -- Remplacer par un vrai user_id
    true,
    'pro',
    NOW(),
    NOW() + INTERVAL '1 year'
);
*/

-- =====================================================
-- FIN DE LA MIGRATION
-- =====================================================

-- Afficher un résumé
DO $$
BEGIN
    RAISE NOTICE '✅ Migration SaaS Multi-Tenant terminée avec succès !';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Tables créées :';
    RAISE NOTICE '   - chorales';
    RAISE NOTICE '   - membres';
    RAISE NOTICE '   - invitations';
    RAISE NOTICE '   - abonnements';
    RAISE NOTICE '   - ecoutes';
    RAISE NOTICE '';
    RAISE NOTICE '🔐 Row Level Security activé sur toutes les tables';
    RAISE NOTICE '⚡ Triggers et fonctions créés';
    RAISE NOTICE '📈 Vues de statistiques créées';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Prochaines étapes :';
    RAISE NOTICE '   1. Tester les politiques RLS';
    RAISE NOTICE '   2. Créer les Edge Functions Supabase';
    RAISE NOTICE '   3. Adapter le code Flutter';
    RAISE NOTICE '   4. Implémenter les paiements';
END $$;

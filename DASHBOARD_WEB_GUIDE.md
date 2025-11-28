# 🖥️ Dashboard Web Admin - Guide complet

## 🎯 Objectif

Créer une plateforme web d'administration pour gérer tout votre SaaS musical.

**URL finale:** `admin.votre-domaine.com`

---

## 📋 Prérequis

- Node.js 18+ installé
- Compte Vercel (gratuit) pour le déploiement
- Votre projet Supabase configuré ✅

---

## 🚀 Étape 1: Créer le projet Next.js

### 1.1 Créer le projet

```bash
# Dans un nouveau dossier (PAS dans le dossier Flutter)
cd d:/Projet\ Flutter/
npx create-next-app@latest admin-chorale-dashboard

# Répondre aux questions:
✔ Would you like to use TypeScript? Yes
✔ Would you like to use ESLint? Yes
✔ Would you like to use Tailwind CSS? Yes
✔ Would you like to use `src/` directory? No
✔ Would you like to use App Router? Yes
✔ Would you like to customize the default import alias? No
```

### 1.2 Installer les dépendances

```bash
cd admin-chorale-dashboard
npm install @supabase/supabase-js
npm install @supabase/auth-helpers-nextjs
npm install recharts
npm install lucide-react
```

---

## 📁 Étape 2: Structure du projet

```
admin-chorale-dashboard/
├── app/
│   ├── layout.tsx              # Layout principal
│   ├── page.tsx                # Redirection vers login
│   ├── login/
│   │   └── page.tsx            # Page de connexion
│   ├── dashboard/
│   │   ├── layout.tsx          # Layout avec sidebar
│   │   ├── page.tsx            # Vue d'ensemble
│   │   ├── chorales/
│   │   │   └── page.tsx        # Gestion des chorales
│   │   ├── users/
│   │   │   └── page.tsx        # Gestion des utilisateurs
│   │   ├── chants/
│   │   │   └── page.tsx        # Gestion des chants
│   │   ├── stats/
│   │   │   └── page.tsx        # Statistiques avancées
│   │   └── logs/
│   │       └── page.tsx        # Logs système
│   └── api/
│       └── auth/
│           └── callback/
│               └── route.ts    # Callback auth
├── components/
│   ├── Sidebar.tsx             # Menu latéral
│   ├── StatsCard.tsx           # Carte de statistique
│   ├── ChoraleTable.tsx        # Tableau des chorales
│   └── ProtectedRoute.tsx      # Protection des routes
├── lib/
│   ├── supabase.ts             # Client Supabase
│   └── utils.ts                # Fonctions utilitaires
└── .env.local                  # Variables d'environnement
```

---

## 🔧 Étape 3: Configuration

### 3.1 Variables d'environnement

Créer `.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=https://milzcdtfblwhblstwuzh.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=votre_anon_key_ici
```

### 3.2 Client Supabase

Créer `lib/supabase.ts`:

```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Vérifier si l'utilisateur est admin système
export async function isSystemAdmin(): Promise<boolean> {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return false

    const { data, error } = await supabase.rpc('is_system_admin', {
      check_user_id: user.id
    })

    if (error) {
      console.error('Erreur is_system_admin:', error)
      return false
    }

    return data as boolean
  } catch (error) {
    console.error('Erreur:', error)
    return false
  }
}

// Logger une action admin
export async function logAdminAction(
  action: string,
  tableName?: string,
  recordId?: string,
  details?: any
) {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    await supabase.rpc('log_admin_action', {
      p_user_id: user.id,
      p_action: action,
      p_table_name: tableName,
      p_record_id: recordId,
      p_details: details
    })
  } catch (error) {
    console.error('Erreur log:', error)
  }
}
```

---

## 🎨 Étape 4: Créer les composants

### 4.1 Sidebar

Créer `components/Sidebar.tsx`:

```typescript
'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { 
  LayoutDashboard, 
  Music, 
  Users, 
  Building2, 
  BarChart3, 
  FileText,
  LogOut 
} from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

const menuItems = [
  { href: '/dashboard', label: 'Vue d\'ensemble', icon: LayoutDashboard },
  { href: '/dashboard/chorales', label: 'Chorales', icon: Building2 },
  { href: '/dashboard/users', label: 'Utilisateurs', icon: Users },
  { href: '/dashboard/chants', label: 'Chants', icon: Music },
  { href: '/dashboard/stats', label: 'Statistiques', icon: BarChart3 },
  { href: '/dashboard/logs', label: 'Logs', icon: FileText },
]

export default function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()

  async function handleLogout() {
    await supabase.auth.signOut()
    router.push('/login')
  }

  return (
    <div className="w-64 bg-gray-900 text-white min-h-screen p-4">
      <div className="mb-8">
        <h1 className="text-2xl font-bold">🎵 Admin Dashboard</h1>
        <p className="text-sm text-gray-400">Chorale SaaS</p>
      </div>

      <nav className="space-y-2">
        {menuItems.map((item) => {
          const Icon = item.icon
          const isActive = pathname === item.href
          
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                isActive 
                  ? 'bg-blue-600 text-white' 
                  : 'text-gray-300 hover:bg-gray-800'
              }`}
            >
              <Icon size={20} />
              <span>{item.label}</span>
            </Link>
          )
        })}
      </nav>

      <button
        onClick={handleLogout}
        className="flex items-center gap-3 px-4 py-3 rounded-lg text-gray-300 hover:bg-gray-800 w-full mt-8"
      >
        <LogOut size={20} />
        <span>Déconnexion</span>
      </button>
    </div>
  )
}
```

### 4.2 StatsCard

Créer `components/StatsCard.tsx`:

```typescript
import { LucideIcon } from 'lucide-react'

interface StatsCardProps {
  title: string
  value: number | string
  icon: LucideIcon
  color: 'blue' | 'green' | 'purple' | 'orange'
}

const colorClasses = {
  blue: 'bg-blue-100 text-blue-600',
  green: 'bg-green-100 text-green-600',
  purple: 'bg-purple-100 text-purple-600',
  orange: 'bg-orange-100 text-orange-600',
}

export default function StatsCard({ title, value, icon: Icon, color }: StatsCardProps) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-600">{title}</p>
          <p className="text-3xl font-bold mt-2">{value}</p>
        </div>
        <div className={`p-3 rounded-full ${colorClasses[color]}`}>
          <Icon size={24} />
        </div>
      </div>
    </div>
  )
}
```

---

## 📄 Étape 5: Créer les pages

### 5.1 Page de connexion

Créer `app/login/page.tsx`:

```typescript
'use client'
import { useState } from 'react'
import { supabase, isSystemAdmin } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const router = useRouter()

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      // Connexion
      const { error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (authError) {
        setError(authError.message)
        setLoading(false)
        return
      }

      // Vérifier si admin
      const isAdmin = await isSystemAdmin()

      if (!isAdmin) {
        setError('Accès refusé: Vous n\'êtes pas administrateur système')
        await supabase.auth.signOut()
        setLoading(false)
        return
      }

      // Rediriger vers le dashboard
      router.push('/dashboard')
    } catch (err) {
      setError('Une erreur est survenue')
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-500 to-purple-600">
      <div className="bg-white p-8 rounded-2xl shadow-2xl w-96">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-800">🎵 Admin Dashboard</h1>
          <p className="text-gray-600 mt-2">Chorale SaaS</p>
        </div>

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="admin@example.com"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Mot de passe
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="••••••••"
              required
            />
          </div>

          {error && (
            <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition-colors disabled:opacity-50"
          >
            {loading ? 'Connexion...' : 'Se connecter'}
          </button>
        </form>
      </div>
    </div>
  )
}
```

### 5.2 Layout du dashboard

Créer `app/dashboard/layout.tsx`:

```typescript
import Sidebar from '@/components/Sidebar'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="flex">
      <Sidebar />
      <main className="flex-1 bg-gray-100 min-h-screen">
        {children}
      </main>
    </div>
  )
}
```

### 5.3 Dashboard principal

Créer `app/dashboard/page.tsx`:

```typescript
'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import StatsCard from '@/components/StatsCard'
import { Building2, Users, Music, Activity } from 'lucide-react'

export default function DashboardPage() {
  const [stats, setStats] = useState({
    chorales: 0,
    users: 0,
    chants: 0,
    activeChorales: 0,
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadStats()
  }, [])

  async function loadStats() {
    try {
      // Compter les chorales
      const { count: choralesCount } = await supabase
        .from('chorales')
        .select('*', { count: 'exact', head: true })

      // Compter les chorales actives
      const { count: activeChoralesCount } = await supabase
        .from('chorales')
        .select('*', { count: 'exact', head: true })
        .eq('statut', 'actif')

      // Compter les utilisateurs
      const { count: usersCount } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true })

      // Compter les chants
      const { count: chantsCount } = await supabase
        .from('chants')
        .select('*', { count: 'exact', head: true })

      setStats({
        chorales: choralesCount || 0,
        users: usersCount || 0,
        chants: chantsCount || 0,
        activeChorales: activeChoralesCount || 0,
      })
    } catch (error) {
      console.error('Erreur:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-xl">Chargement...</div>
      </div>
    )
  }

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-800">Vue d'ensemble</h1>
        <p className="text-gray-600 mt-2">Statistiques globales de votre SaaS</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatsCard
          title="Chorales"
          value={stats.chorales}
          icon={Building2}
          color="blue"
        />
        <StatsCard
          title="Chorales actives"
          value={stats.activeChorales}
          icon={Activity}
          color="green"
        />
        <StatsCard
          title="Utilisateurs"
          value={stats.users}
          icon={Users}
          color="purple"
        />
        <StatsCard
          title="Chants"
          value={stats.chants}
          icon={Music}
          color="orange"
        />
      </div>

      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-bold mb-4">Activité récente</h2>
        <p className="text-gray-600">Les dernières actions seront affichées ici</p>
      </div>
    </div>
  )
}
```

---

## 🚀 Étape 6: Lancer le projet

```bash
npm run dev
```

Ouvrir: `http://localhost:3000`

**Se connecter avec:**
- Email: `kodjodavid2025@gmail.com`
- Mot de passe: `votre_mot_de_passe`

---

## 📦 Étape 7: Déploiement sur Vercel

### 7.1 Créer un compte Vercel

1. Aller sur https://vercel.com
2. S'inscrire avec GitHub

### 7.2 Déployer

```bash
npm install -g vercel
vercel login
vercel
```

Suivre les instructions.

### 7.3 Configurer les variables d'environnement

Dans Vercel Dashboard:
1. Project Settings
2. Environment Variables
3. Ajouter:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`

---

## ✅ Résultat final

Vous aurez:
- ✅ Dashboard web professionnel
- ✅ Connexion sécurisée (admin uniquement)
- ✅ Vue d'ensemble avec statistiques
- ✅ Gestion des chorales
- ✅ Gestion des utilisateurs
- ✅ Logs système
- ✅ Déployé sur `votre-projet.vercel.app`

**Voulez-vous que je crée les pages de gestion des chorales et utilisateurs ?** 🚀

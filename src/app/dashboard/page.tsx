'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'

interface Site {
  id: string
  name: string
  status: 'draft' | 'published'
  updated_at: string
  template_id: string | null
}

export default function DashboardPage() {
  const { user, loading: authLoading } = useAuth()
  const router = useRouter()
  const [sites, setSites] = useState<Site[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!authLoading && !user) {
      router.push('/auth/login')
    }
  }, [user, authLoading, router])

  useEffect(() => {
    if (user) {
      fetchSites()
    }
  }, [user])

  const fetchSites = async () => {
    try {
      const { data, error } = await supabase
        .from('sites')
        .select('*')
        .eq('user_id', user!.id)
        .order('updated_at', { ascending: false })

      if (error) throw error
      setSites(data || [])
    } catch (error) {
      console.error('Error fetching sites:', error)
    } finally {
      setLoading(false)
    }
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  }

  if (authLoading || loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-purple-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-slate-400">Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950">
      {/* Navbar */}
      <nav className="border-b border-slate-800 bg-slate-900/50 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-8 py-6 flex items-center justify-between">
          <h1 className="text-4xl font-bold bg-gradient-to-r from-purple-500 to-blue-500 bg-clip-text text-transparent">
            DragSite
          </h1>
          <div className="flex items-center gap-6">
            <span className="text-slate-300 text-lg">Welcome, {user?.user_metadata?.full_name || user?.email}</span>
            <button
              onClick={() => {
                // Sign out logic will be handled by auth context
                window.location.href = '/auth/login'
              }}
              className="px-6 py-3 text-slate-400 hover:text-white transition-colors text-base font-medium"
            >
              Sign Out
            </button>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-8 py-12">
        <div className="mb-12">
          <h2 className="text-5xl font-bold text-white mb-3">Your Sites</h2>
          <p className="text-slate-400 text-xl">Manage and edit your websites</p>
        </div>

        {sites.length === 0 ? (
          <div className="bg-slate-900/50 backdrop-blur-xl rounded-3xl p-16 border border-slate-800 text-center">
            <div className="mb-8">
              <div className="w-24 h-24 bg-gradient-to-br from-purple-500/20 to-blue-500/20 rounded-full flex items-center justify-center mx-auto mb-6">
                <svg className="w-12 h-12 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
              </div>
              <h3 className="text-3xl font-semibold text-white mb-3">No sites yet</h3>
              <p className="text-slate-400 text-lg mb-8">Create your first website and start building</p>
            </div>
            <button
              onClick={() => router.push('/templates')}
              className="px-10 py-5 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 text-white font-bold text-lg rounded-2xl transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98] shadow-xl shadow-purple-500/25"
            >
              Create Your First Site
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Create New Site Card */}
            <button
              onClick={() => router.push('/templates')}
              className="bg-slate-900/50 backdrop-blur-xl rounded-3xl p-10 border-2 border-dashed border-slate-700 hover:border-purple-500 transition-all duration-200 group flex flex-col items-center justify-center min-h-[360px]"
            >
              <div className="w-20 h-20 bg-gradient-to-br from-purple-500/20 to-blue-500/20 rounded-full flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-200">
                <svg className="w-10 h-10 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
              </div>
              <span className="text-2xl font-semibold text-white mb-2">Create New Site</span>
              <span className="text-slate-400 text-base">Choose a template to get started</span>
            </button>

            {/* Site Cards */}
            {sites.map((site) => (
              <div
                key={site.id}
                className="bg-slate-900/50 backdrop-blur-xl rounded-3xl p-8 border border-slate-800 hover:border-slate-700 transition-all duration-200 group hover:-translate-y-1 hover:shadow-xl"
              >
                <div className="aspect-video bg-gradient-to-br from-slate-800 to-slate-900 rounded-2xl mb-6 flex items-center justify-center overflow-hidden">
                  <div className="text-slate-600 text-lg">Preview</div>
                </div>
                <h3 className="text-2xl font-semibold text-white mb-3">{site.name}</h3>
                <div className="flex items-center justify-between mb-6">
                  <span
                    className={`px-4 py-2 rounded-full text-sm font-medium ${
                      site.status === 'published'
                        ? 'bg-green-500/20 text-green-400'
                        : 'bg-yellow-500/20 text-yellow-400'
                    }`}
                  >
                    {site.status === 'published' ? 'Published' : 'Draft'}
                  </span>
                  <span className="text-slate-500 text-base">{formatDate(site.updated_at)}</span>
                </div>
                <div className="flex gap-3">
                  <button
                    onClick={() => router.push(`/editor/${site.id}`)}
                    className="flex-1 py-3 px-6 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 text-white font-semibold rounded-xl transition-all duration-200 text-base"
                  >
                    Edit
                  </button>
                  <button
                    className="py-3 px-6 bg-slate-800 hover:bg-slate-700 text-white font-semibold rounded-xl transition-all duration-200 text-base"
                  >
                    {site.status === 'published' ? 'View' : 'Publish'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

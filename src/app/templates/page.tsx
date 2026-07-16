'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'

interface Template {
  id: string
  name: string
  category: string
  description: string
  thumbnail_url: string | null
  page_data: any
}

const CATEGORIES = ['All', 'Portfolio', 'Business', 'Landing Page', 'Restaurant', 'Blog', 'Agency', 'Event', 'Nonprofit', 'Coming Soon']

export default function TemplatesPage() {
  const { user, loading: authLoading } = useAuth()
  const router = useRouter()
  const [templates, setTemplates] = useState<Template[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedCategory, setSelectedCategory] = useState('All')
  const [searchQuery, setSearchQuery] = useState('')
  const [creating, setCreating] = useState<string | null>(null)

  useEffect(() => {
    if (!authLoading && !user) {
      router.push('/auth/login')
    }
  }, [user, authLoading, router])

  useEffect(() => {
    if (user) {
      fetchTemplates()
    }
  }, [user])

  const fetchTemplates = async () => {
    try {
      console.log('Fetching templates from database...')
      const { data, error } = await supabase
        .from('templates')
        .select('*')
        .order('name', { ascending: true })

      if (error) throw error

      console.log('Templates fetched:', data)
      console.log('Number of templates:', data?.length || 0)
      console.log('Template categories:', data?.map(t => t.category))

      setTemplates(data || [])
    } catch (error) {
      console.error('Error fetching templates:', error)
    } finally {
      setLoading(false)
    }
  }

  const filteredTemplates = templates.filter(template => {
    const matchesCategory = selectedCategory === 'All' || template.category === selectedCategory
    const matchesSearch = template.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         template.description.toLowerCase().includes(searchQuery.toLowerCase())
    return matchesCategory && matchesSearch
  })

  const handleSelectTemplate = async (template: Template) => {
    setCreating(template.id)
    try {
      // Create default page structure if template has empty page_data
      const defaultPageData = {
        sections: [
          {
            id: `section_${Date.now()}`,
            style: { backgroundColor: '#ffffff', padding: '60px 20px' },
            rows: [
              {
                id: `row_${Date.now()}`,
                style: {},
                columns: [
                  {
                    id: `column_${Date.now()}`,
                    style: {},
                    widgets: [
                      {
                        id: `widget_${Date.now()}`,
                        type: 'heading',
                        content: { text: template.name, level: 1 },
                        style: { color: '#000000', textAlign: 'center' }
                      },
                      {
                        id: `widget_${Date.now() + 1}`,
                        type: 'text',
                        content: { text: template.description },
                        style: { color: '#666666', textAlign: 'center' }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }

      // Use template page_data if available, otherwise use default
      const pageDataToUse = template.page_data && template.page_data.sections && template.page_data.sections.length > 0
        ? template.page_data
        : defaultPageData

      // Create new site from template
      const siteName = `${template.name} - Copy`
      const slug = siteName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')

      console.log('Creating site with data:', {
        user_id: user!.id,
        name: siteName,
        slug: slug,
        page_data: pageDataToUse,
        template_id: template.id,
        status: 'draft',
      })

      const { data: siteData, error: siteError } = await supabase
        .from('sites')
        .insert({
          user_id: user!.id,
          name: siteName,
          slug: slug,
          page_data: pageDataToUse,
          template_id: template.id,
          status: 'draft',
        })
        .select()
        .single()

      if (siteError) {
        console.error('Supabase error details:', siteError)
        throw siteError
      }

      console.log('Site created successfully:', siteData)

      // Redirect to editor with the new site
      router.push(`/editor/${siteData.id}`)
    } catch (error) {
      console.error('Error creating site from template:', error)
      console.error('Error details:', JSON.stringify(error, null, 2))
      setCreating(null)
    }
  }

  const getTemplatePreview = (template: Template) => {
    // Return a simplified preview based on category
    const previews: Record<string, React.ReactNode> = {
      'Portfolio': (
        <div className="space-y-2">
          <div className="h-8 bg-purple-500/30 rounded"></div>
          <div className="h-4 bg-slate-700 rounded w-3/4"></div>
          <div className="grid grid-cols-2 gap-2 mt-4">
            <div className="h-16 bg-slate-700 rounded"></div>
            <div className="h-16 bg-slate-700 rounded"></div>
          </div>
        </div>
      ),
      'Business': (
        <div className="space-y-2">
          <div className="h-6 bg-blue-500/30 rounded"></div>
          <div className="h-3 bg-slate-700 rounded w-1/2"></div>
          <div className="flex gap-2 mt-4">
            <div className="h-8 bg-slate-700 rounded flex-1"></div>
            <div className="h-8 bg-slate-700 rounded flex-1"></div>
            <div className="h-8 bg-slate-700 rounded flex-1"></div>
          </div>
        </div>
      ),
      'Landing Page': (
        <div className="space-y-2">
          <div className="h-10 bg-gradient-to-r from-purple-500/30 to-blue-500/30 rounded"></div>
          <div className="h-4 bg-slate-700 rounded w-full"></div>
          <div className="h-8 bg-purple-500/40 rounded mt-4"></div>
        </div>
      ),
      'Restaurant': (
        <div className="space-y-2">
          <div className="h-6 bg-orange-500/30 rounded"></div>
          <div className="space-y-1 mt-3">
            <div className="h-3 bg-slate-700 rounded w-full"></div>
            <div className="h-3 bg-slate-700 rounded w-2/3"></div>
          </div>
          <div className="space-y-1 mt-2">
            <div className="h-3 bg-slate-700 rounded w-full"></div>
            <div className="h-3 bg-slate-700 rounded w-1/2"></div>
          </div>
        </div>
      ),
      'Blog': (
        <div className="space-y-2">
          <div className="h-6 bg-green-500/30 rounded"></div>
          <div className="h-3 bg-slate-700 rounded w-3/4"></div>
          <div className="space-y-2 mt-3">
            <div className="h-2 bg-slate-700 rounded"></div>
            <div className="h-2 bg-slate-700 rounded"></div>
            <div className="h-2 bg-slate-700 rounded w-2/3"></div>
          </div>
        </div>
      ),
      'Agency': (
        <div className="space-y-2">
          <div className="h-8 bg-pink-500/30 rounded"></div>
          <div className="grid grid-cols-3 gap-2 mt-3">
            <div className="h-12 bg-slate-700 rounded"></div>
            <div className="h-12 bg-slate-700 rounded"></div>
            <div className="h-12 bg-slate-700 rounded"></div>
          </div>
        </div>
      ),
      'Event': (
        <div className="space-y-2">
          <div className="h-8 bg-yellow-500/30 rounded"></div>
          <div className="h-4 bg-slate-700 rounded w-full"></div>
          <div className="h-6 bg-yellow-500/40 rounded mt-4"></div>
        </div>
      ),
      'Nonprofit': (
        <div className="space-y-2">
          <div className="h-6 bg-teal-500/30 rounded"></div>
          <div className="h-3 bg-slate-700 rounded w-2/3"></div>
          <div className="h-8 bg-teal-500/40 rounded mt-4"></div>
        </div>
      ),
      'Coming Soon': (
        <div className="space-y-2">
          <div className="h-12 bg-indigo-500/30 rounded"></div>
          <div className="h-4 bg-slate-700 rounded w-full text-center"></div>
          <div className="h-8 bg-indigo-500/40 rounded mt-4"></div>
        </div>
      ),
    }
    return previews[template.category] || previews['Business']
  }

  if (authLoading || loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-purple-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-slate-400">Loading templates...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950">
      {/* Navbar */}
      <nav className="border-b border-slate-800 bg-slate-900/50 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <button
            onClick={() => router.push('/dashboard')}
            className="text-2xl font-bold bg-gradient-to-r from-purple-500 to-blue-500 bg-clip-text text-transparent"
          >
            DragSite
          </button>
          <div className="flex items-center gap-4">
            <span className="text-slate-300">Welcome, {user?.user_metadata?.full_name || user?.email}</span>
            <button
              onClick={() => router.push('/dashboard')}
              className="px-4 py-2 text-slate-400 hover:text-white transition-colors"
            >
              Dashboard
            </button>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-6 py-8">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-white mb-2">Choose a Template</h1>
          <p className="text-slate-400 text-lg">Beautiful templates for every kind of site</p>
        </div>

        {/* Search Bar */}
        <div className="mb-6">
          <input
            type="text"
            placeholder="Search templates..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full max-w-md px-4 py-3 bg-slate-800/50 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all duration-200"
          />
        </div>

        {/* Category Filter Tabs */}
        <div className="flex flex-wrap gap-2 mb-8">
          {CATEGORIES.map((category) => (
            <button
              key={category}
              onClick={() => setSelectedCategory(category)}
              className={`px-5 py-2.5 rounded-xl font-medium transition-all duration-200 ${
                selectedCategory === category
                  ? 'bg-gradient-to-r from-purple-600 to-blue-600 text-white shadow-lg shadow-purple-500/25'
                  : 'bg-slate-800/50 text-slate-400 hover:text-white hover:bg-slate-800'
              }`}
            >
              {category}
            </button>
          ))}
        </div>

        {/* Templates Grid */}
        {filteredTemplates.length === 0 ? (
          <div className="bg-slate-900/50 backdrop-blur-xl rounded-2xl p-12 border border-slate-800 text-center">
            <p className="text-slate-400 text-lg">No templates found matching your criteria</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {filteredTemplates.map((template) => (
              <div
                key={template.id}
                className="bg-slate-900/50 backdrop-blur-xl rounded-2xl overflow-hidden border border-slate-800 hover:border-slate-700 transition-all duration-200 group hover:-translate-y-1 hover:shadow-xl"
              >
                {/* Preview */}
                <div className="aspect-video bg-slate-800/50 p-4 flex items-center justify-center overflow-hidden">
                  <div className="w-full h-full scale-90 opacity-80">
                    {getTemplatePreview(template)}
                  </div>
                </div>

                {/* Content */}
                <div className="p-6">
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <h3 className="text-xl font-semibold text-white mb-1">{template.name}</h3>
                      <span className="inline-block px-3 py-1 rounded-full text-xs font-medium bg-purple-500/20 text-purple-400">
                        {template.category}
                      </span>
                    </div>
                  </div>
                  <p className="text-slate-400 text-sm mb-6 line-clamp-2">{template.description}</p>

                  <button
                    onClick={() => handleSelectTemplate(template)}
                    disabled={creating === template.id}
                    className="w-full py-3 px-6 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 text-white font-semibold rounded-xl transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none shadow-lg shadow-purple-500/25"
                  >
                    {creating === template.id ? 'Creating...' : 'Start with this template'}
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

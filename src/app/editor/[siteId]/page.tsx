'use client'

import { useEffect, useState } from 'react'
import { useRouter, useParams } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { useEditorStore } from '@/store/editorStore'
import EditablePageRenderer from '@/components/EditablePageRenderer'
import { PageData, Widget } from '@/components/PageRenderer'
import WidgetPalette from '@/components/WidgetPalette'
import StylePanel from '@/components/StylePanel'
import { DndContext, DragEndEvent, DragOverlay, DragStartEvent, closestCorners } from '@dnd-kit/core'

export default function EditorPage() {
  const { user, loading: authLoading } = useAuth()
  const router = useRouter()
  const params = useParams()
  const siteId = params.siteId as string

  const { pageData, setPageData, selectedWidget, setSelectedWidget, undo, redo, canUndo, canRedo, addWidget } = useEditorStore()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [siteName, setSiteName] = useState('')
  const [activeDrag, setActiveDrag] = useState<string | null>(null)

  useEffect(() => {
    if (!authLoading && !user) {
      router.push('/auth/login')
    }
  }, [user, authLoading, router])

  useEffect(() => {
    if (user && siteId) {
      loadSite()
    }
  }, [user, siteId])

  const loadSite = async () => {
    try {
      console.log('Loading site with ID:', siteId)
      const { data, error } = await supabase
        .from('sites')
        .select('*')
        .eq('id', siteId)
        .eq('user_id', user!.id)
        .single()

      if (error) {
        console.error('Error loading site:', error)
        throw error
      }

      console.log('Site data loaded:', data)
      setSiteName(data.name)
      
      // Parse page_data if it's a string, otherwise use as-is
      const parsedPageData = typeof data.page_data === 'string' 
        ? JSON.parse(data.page_data) 
        : data.page_data
      
      setPageData(parsedPageData || { sections: [] })
    } catch (error: any) {
      console.error('Error in loadSite:', error)
      setError(error.message || 'Failed to load site')
    } finally {
      setLoading(false)
    }
  }

  const handleSave = async () => {
    if (!pageData) return

    setSaving(true)
    setError('')

    try {
      const { error } = await supabase
        .from('sites')
        .update({
          page_data: pageData,
          updated_at: new Date().toISOString()
        })
        .eq('id', siteId)
        .eq('user_id', user!.id)

      if (error) throw error

      // Show success feedback
      console.log('Site saved successfully')
    } catch (error: any) {
      console.error('Error saving site:', error)
      setError(error.message || 'Failed to save site')
    } finally {
      setSaving(false)
    }
  }

  const handlePublish = async () => {
    if (!pageData) return

    setSaving(true)
    setError('')

    try {
      // First save the current state
      await handleSave()

      // Get the session token
      const { data: { session } } = await supabase.auth.getSession()
      const token = session?.access_token

      // Then call the publish API with auth token
      const response = await fetch(`/api/publish/${siteId}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to publish site')
      }

      // Show success message and redirect to published URL
      alert(`Site published successfully! Your site is now live at: ${data.publishedUrl}`)
      window.open(data.publishedUrl, '_blank')
    } catch (error: any) {
      console.error('Error publishing site:', error)
      setError(error.message || 'Failed to publish site')
      alert(`Failed to publish: ${error.message || 'Unknown error'}`)
    } finally {
      setSaving(false)
    }
  }

  const handleDragStart = (event: DragStartEvent) => {
    console.log('Drag started:', event.active.id)
    setActiveDrag(event.active.id as string)
  }

  const handleDragEnd = (event: DragEndEvent) => {
    console.log('Drag ended:', event)
    const { active, over } = event
    setActiveDrag(null)

    if (!over) return

    const activeId = active.id as string
    const overId = over.id as string

    // Check if dragging from palette (widget type) vs reordering (widget id)
    const isFromPalette = WIDGET_TYPES.some(w => w.type === activeId)

    if (isFromPalette) {
      // Dragging new widget from palette
      console.log('Adding new widget:', activeId, 'to column:', overId)
      console.log('Page data structure:', JSON.stringify(pageData, null, 2))
      console.log('Page data sections:', pageData?.sections)
      // Find the column by ID and add the widget
      if (pageData && pageData.sections && Array.isArray(pageData.sections) && pageData.sections.length > 0) {
        // Search through all sections, rows, and columns to find the matching column
        let foundSection, foundRow, foundColumn
        for (const section of pageData.sections) {
          if (!section || !section.rows || !Array.isArray(section.rows)) {
            console.log('Section has no rows or is invalid:', section?.id)
            continue
          }
          for (const row of section.rows) {
            if (!row.columns || !Array.isArray(row.columns)) {
              console.log('Row has no columns:', row.id)
              continue
            }
            for (const column of row.columns) {
              if (column.id === overId) {
                foundSection = section
                foundRow = row
                foundColumn = column
                break
              }
            }
            if (foundColumn) break
          }
          if (foundColumn) break
        }

        if (foundSection && foundRow && foundColumn) {
          const newWidget: Widget = {
            id: `widget_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            type: activeId as any,
            content: getDefaultContent(activeId),
            style: {}
          }

          addWidget(foundSection.id, foundRow.id, foundColumn.id, newWidget)
          console.log('Widget added successfully')
        } else {
          console.log('Could not find target column:', overId)
        }
      }
    } else {
      // Reordering existing widgets - this would need more complex logic
      console.log('Reordering widget:', activeId, 'to position:', overId)
    }
  }

  const getDefaultContent = (type: string) => {
    switch (type) {
      case 'heading':
        return { text: 'Heading', level: 2 }
      case 'text':
        return { text: 'Add your text here' }
      case 'image':
        return { url: 'https://via.placeholder.com/400x300', alt: 'Placeholder image' }
      case 'button':
        return { text: 'Click me' }
      case 'spacer':
        return { height: '20px' }
      case 'divider':
        return { color: '#e5e7eb' }
      case 'video':
        return { url: '' }
      case 'gallery':
        return { images: [] }
      case 'form':
        return {}
      case 'icon':
        return {}
      case 'list':
        return { items: ['Item 1', 'Item 2', 'Item 3'] }
      default:
        return {}
    }
  }

  const WIDGET_TYPES = [
    { type: 'heading', label: 'Heading', icon: 'H' },
    { type: 'text', label: 'Text', icon: 'T' },
    { type: 'image', label: 'Image', icon: '🖼️' },
    { type: 'button', label: 'Button', icon: '⬛' },
    { type: 'spacer', label: 'Spacer', icon: '↕️' },
    { type: 'divider', label: 'Divider', icon: '―' },
    { type: 'video', label: 'Video', icon: '🎬' },
    { type: 'gallery', label: 'Gallery', icon: '🖼️' },
    { type: 'form', label: 'Form', icon: '📝' },
    { type: 'icon', label: 'Icon', icon: '★' },
    { type: 'list', label: 'List', icon: '☰' },
  ]

  // Auto-save every 30 seconds
  useEffect(() => {
    const autoSaveInterval = setInterval(() => {
      if (pageData && !loading) {
        handleSave()
      }
    }, 30000)

    return () => clearInterval(autoSaveInterval)
  }, [pageData, loading])

  if (authLoading || loading) {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-purple-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-slate-600">Loading editor...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center">
        <div className="bg-white rounded-xl p-8 shadow-lg max-w-md">
          <h2 className="text-2xl font-bold text-red-600 mb-4">Error</h2>
          <p className="text-slate-600 mb-6">{error}</p>
          <button
            onClick={() => router.push('/dashboard')}
            className="px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700"
          >
            Back to Dashboard
          </button>
        </div>
      </div>
    )
  }

  return (
    <DndContext onDragStart={handleDragStart} onDragEnd={handleDragEnd} collisionDetection={closestCorners}>
      <div className="min-h-screen bg-slate-100 flex flex-col">
        {/* Top Toolbar */}
        <div className="bg-slate-900 border-b border-slate-700 px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-6">
            <button
              onClick={() => router.push('/dashboard')}
              className="text-slate-400 hover:text-white transition-colors text-base font-medium"
            >
              ← Back
            </button>
            <div className="h-8 w-px bg-slate-700"></div>
            <h1 className="text-white font-semibold text-xl">{siteName || 'Untitled Site'}</h1>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={undo}
              disabled={!canUndo()}
              className="px-5 py-3 bg-slate-800 text-slate-300 rounded-xl hover:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-base font-medium"
            >
              Undo
            </button>
            <button
              onClick={redo}
              disabled={!canRedo()}
              className="px-5 py-3 bg-slate-800 text-slate-300 rounded-xl hover:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-base font-medium"
            >
              Redo
            </button>
            <div className="h-8 w-px bg-slate-700"></div>
            <button
              onClick={handleSave}
              disabled={saving}
              className="px-6 py-3 bg-slate-800 text-slate-300 rounded-xl hover:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-base font-medium"
            >
              {saving ? 'Saving...' : 'Save'}
            </button>
            <button
              onClick={handlePublish}
              disabled={saving}
              className="px-6 py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-xl hover:from-purple-500 hover:to-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-base font-bold shadow-lg shadow-purple-500/25"
            >
              {saving ? 'Publishing...' : 'Publish'}
            </button>
          </div>
        </div>

        {/* Editor Layout */}
        <div className="flex-1 flex overflow-hidden">
          {/* Left Sidebar - Widget Palette */}
          <div className="w-80 bg-slate-900 border-r border-slate-700 overflow-y-auto">
            <WidgetPalette />
          </div>

          {/* Main Canvas */}
          <div className="flex-1 overflow-y-auto bg-slate-200 p-12" style={{ backgroundImage: 'radial-gradient(circle, #cbd5e1 1px, transparent 1px)', backgroundSize: '20px 20px' }}>
            <div className="max-w-6xl mx-auto" style={{ width: '100%' }}>
              <div className="bg-white rounded-2xl shadow-xl overflow-hidden" style={{ minHeight: '900px', width: '100%', fontSize: '18px' }}>
                {pageData && pageData.sections.length > 0 ? (
                  <EditablePageRenderer pageData={pageData} />
                ) : (
                  <div className="flex items-center justify-center h-96" style={{ fontSize: '18px' }}>
                    <div className="text-center">
                      <p className="text-slate-400 text-2xl mb-4">Your page is empty</p>
                      <p className="text-slate-500 text-lg">Drag widgets from the left panel to start building</p>
                    </div>
                  </div>
                )}
              </div>

              {/* Add Section Button */}
              <button
                onClick={() => {
                  const newSection = {
                    id: `section_${Date.now()}`,
                    rows: [{
                      id: `row_${Date.now()}`,
                      columns: [{
                        id: `column_${Date.now()}`,
                        widgets: [],
                        style: {}
                      }],
                      style: {}
                    }],
                    style: { backgroundColor: '#ffffff', padding: '60px 20px' }
                  }
                  useEditorStore.getState().addSection(newSection)
                }}
                className="mt-6 w-full py-5 bg-white border-2 border-dashed border-slate-300 rounded-2xl text-slate-500 hover:border-purple-500 hover:text-purple-500 transition-colors text-lg font-medium"
              >
                + Add Section
              </button>
            </div>
          </div>

          {/* Right Sidebar - Style Panel */}
          <div className="w-96 bg-slate-900 border-l border-slate-700 overflow-y-auto">
            <StylePanel />
          </div>
        </div>
      </div>
    </DndContext>
  )
}

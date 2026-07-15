import { create } from 'zustand'
import { Widget, Column, Row, Section, PageData } from '@/components/PageRenderer'

interface EditorState {
  pageData: PageData | null
  selectedWidget: Widget | null
  selectedSection: Section | null
  history: PageData[]
  historyIndex: number
  setPageData: (data: PageData) => void
  setSelectedWidget: (widget: Widget | null) => void
  setSelectedSection: (section: Section | null) => void
  updateWidget: (widgetId: string, updates: Partial<Widget>) => void
  addWidget: (sectionId: string, rowId: string, columnId: string, widget: Widget) => void
  removeWidget: (widgetId: string) => void
  duplicateWidget: (widgetId: string) => void
  addSection: (section: Section) => void
  removeSection: (sectionId: string) => void
  undo: () => void
  redo: () => void
  canUndo: () => boolean
  canRedo: () => boolean
  saveToHistory: () => void
}

const generateId = () => `id_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

export const useEditorStore = create<EditorState>((set, get) => ({
  pageData: { sections: [] },
  selectedWidget: null,
  selectedSection: null,
  history: [],
  historyIndex: -1,

  setPageData: (data) => {
    set({ pageData: data })
    get().saveToHistory()
  },

  setSelectedWidget: (widget) => set({ selectedWidget: widget }),
  setSelectedSection: (section) => set({ selectedSection: section }),

  updateWidget: (widgetId, updates) => {
    const { pageData } = get()
    if (!pageData) return

    const updatedSections = pageData.sections.map(section => ({
      ...section,
      rows: section.rows.map(row => ({
        ...row,
        columns: row.columns.map(column => ({
          ...column,
          widgets: column.widgets.map(widget =>
            widget.id === widgetId ? { ...widget, ...updates } : widget
          )
        }))
      }))
    }))

    set({ pageData: { sections: updatedSections } })
    get().saveToHistory()
  },

  addWidget: (sectionId, rowId, columnId, widget) => {
    const { pageData } = get()
    if (!pageData) return

    const updatedSections = pageData.sections.map(section => {
      if (section.id !== sectionId) return section

      return {
        ...section,
        rows: section.rows.map(row => {
          if (row.id !== rowId) return row

          return {
            ...row,
            columns: row.columns.map(column => {
              if (column.id !== columnId) return column

              return {
                ...column,
                widgets: [...column.widgets, widget]
              }
            })
          }
        })
      }
    })

    set({ pageData: { sections: updatedSections } })
    get().saveToHistory()
  },

  removeWidget: (widgetId) => {
    const { pageData } = get()
    if (!pageData) return

    const updatedSections = pageData.sections.map(section => ({
      ...section,
      rows: section.rows.map(row => ({
        ...row,
        columns: row.columns.map(column => ({
          ...column,
          widgets: column.widgets.filter(widget => widget.id !== widgetId)
        }))
      }))
    }))

    set({ pageData: { sections: updatedSections } })
    get().saveToHistory()
  },

  duplicateWidget: (widgetId) => {
    const { pageData } = get()
    if (!pageData) return

    let found = false
    const updatedSections = pageData.sections.map(section => ({
      ...section,
      rows: section.rows.map(row => ({
        ...row,
        columns: row.columns.map(column => {
          if (found) return column

          const widgetIndex = column.widgets.findIndex(w => w.id === widgetId)
          if (widgetIndex === -1) return column

          found = true
          const widget = column.widgets[widgetIndex]
          const duplicatedWidget = {
            ...widget,
            id: generateId()
          }

          return {
            ...column,
            widgets: [
              ...column.widgets.slice(0, widgetIndex + 1),
              duplicatedWidget,
              ...column.widgets.slice(widgetIndex + 1)
            ]
          }
        })
      }))
    }))

    set({ pageData: { sections: updatedSections } })
    get().saveToHistory()
  },

  addSection: (section) => {
    const { pageData } = get()
    if (!pageData) return

    set({
      pageData: {
        sections: [...pageData.sections, section]
      }
    })
    get().saveToHistory()
  },

  removeSection: (sectionId) => {
    const { pageData } = get()
    if (!pageData) return

    set({
      pageData: {
        sections: pageData.sections.filter(section => section.id !== sectionId)
      }
    })
    get().saveToHistory()
  },

  undo: () => {
    const { history, historyIndex } = get()
    if (historyIndex <= 0) return

    const newIndex = historyIndex - 1
    set({
      pageData: history[newIndex],
      historyIndex: newIndex
    })
  },

  redo: () => {
    const { history, historyIndex } = get()
    if (historyIndex >= history.length - 1) return

    const newIndex = historyIndex + 1
    set({
      pageData: history[newIndex],
      historyIndex: newIndex
    })
  },

  canUndo: () => {
    const { historyIndex } = get()
    return historyIndex > 0
  },

  canRedo: () => {
    const { history, historyIndex } = get()
    return historyIndex < history.length - 1
  },

  saveToHistory: () => {
    const { pageData, history, historyIndex } = get()
    if (!pageData) return

    // Remove any future history if we're not at the end
    const newHistory = history.slice(0, historyIndex + 1)
    
    // Add current state
    newHistory.push(JSON.parse(JSON.stringify(pageData)))
    
    // Keep only last 50 states
    if (newHistory.length > 50) {
      newHistory.shift()
    }

    set({
      history: newHistory,
      historyIndex: newHistory.length - 1
    })
  }
}))

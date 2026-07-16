'use client'

import React from 'react'
import { useDroppable } from '@dnd-kit/core'
import { SortableContext, verticalListSortingStrategy, useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { Widget, Column, Row, Section, PageData } from './PageRenderer'
import { useEditorStore } from '@/store/editorStore'

interface EditablePageRendererProps {
  pageData: PageData | null
}

const generateId = () => `id_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

// Sortable Widget Component
const SortableWidget: React.FC<{ widget: Widget; columnId: string; rowId: string; sectionId: string }> = ({ 
  widget, columnId, rowId, sectionId 
}) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: widget.id })

  const { setSelectedWidget, selectedWidget } = useEditorStore()

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  }

  const isSelected = selectedWidget?.id === widget.id

  const renderWidgetContent = () => {
    const { type, content, style: widgetStyle } = widget
    const baseStyle = { ...widgetStyle }

    switch (type) {
      case 'heading':
        const headingLevel = content.level || 2
        const headingStyles = {
          h1: { fontSize: '48px', fontWeight: 'bold' },
          h2: { fontSize: '36px', fontWeight: 'bold' },
          h3: { fontSize: '28px', fontWeight: 'bold' },
          h4: { fontSize: '24px', fontWeight: 'bold' },
          h5: { fontSize: '20px', fontWeight: 'bold' },
          h6: { fontSize: '16px', fontWeight: 'bold' },
        }
        const headingStyle = { ...baseStyle, ...headingStyles[`h${headingLevel}` as keyof typeof headingStyles] }
        
        if (headingLevel === 1) return <h1 style={headingStyle} className="font-bold">{content.text || ''}</h1>
        if (headingLevel === 2) return <h2 style={headingStyle} className="font-bold">{content.text || ''}</h2>
        if (headingLevel === 3) return <h3 style={headingStyle} className="font-bold">{content.text || ''}</h3>
        if (headingLevel === 4) return <h4 style={headingStyle} className="font-bold">{content.text || ''}</h4>
        if (headingLevel === 5) return <h5 style={headingStyle} className="font-bold">{content.text || ''}</h5>
        return <h6 style={headingStyle} className="font-bold">{content.text || ''}</h6>

      case 'text':
        const textStyle = { fontSize: '16px', ...baseStyle }
        return <p style={textStyle} className="leading-relaxed">{content.text || ''}</p>

      case 'image':
        return (
          <img
            src={content.url || 'https://via.placeholder.com/400x300'}
            alt={content.alt || ''}
            style={baseStyle}
            className="max-w-full h-auto"
          />
        )

      case 'button':
        return (
          <button
            style={baseStyle}
            className="px-6 py-3 rounded-lg font-medium transition-all duration-200 hover:opacity-90"
          >
            {content.text || 'Button'}
          </button>
        )

      case 'spacer':
        return <div style={{ height: content.height || '20px', ...baseStyle }} />

      case 'divider':
        return (
          <hr
            style={{
              border: 'none',
              borderTop: `2px solid ${content.color || '#e5e7eb'}`,
              ...baseStyle,
            }}
          />
        )

      case 'video':
        return (
          <div style={baseStyle} className="aspect-video bg-slate-900 rounded-lg flex items-center justify-center">
            <p className="text-slate-400">Video: {content.url || 'No video URL'}</p>
          </div>
        )

      case 'gallery':
        return (
          <div style={baseStyle} className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {(content.images || []).map((img: any, idx: number) => (
              <img
                key={idx}
                src={img.url || 'https://via.placeholder.com/200x200'}
                alt={img.alt || ''}
                className="rounded-lg w-full h-32 object-cover"
              />
            ))}
          </div>
        )

      case 'form':
        return (
          <form style={baseStyle} className="space-y-4">
            <input type="text" placeholder="Name" className="w-full px-4 py-2 border border-slate-300 rounded-lg" />
            <input type="email" placeholder="Email" className="w-full px-4 py-2 border border-slate-300 rounded-lg" />
            <textarea placeholder="Message" rows={4} className="w-full px-4 py-2 border border-slate-300 rounded-lg" />
            <button type="submit" className="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700">
              Submit
            </button>
          </form>
        )

      case 'icon':
        return (
          <div style={baseStyle} className="flex items-center justify-center">
            <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
          </div>
        )

      case 'list':
        return (
          <ul style={baseStyle} className="list-disc list-inside space-y-2">
            {(content.items || []).map((item: string, idx: number) => (
              <li key={idx}>{item}</li>
            ))}
          </ul>
        )

      default:
        return <div style={baseStyle}>Unknown widget type: {type}</div>
    }
  }

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      onClick={(e) => {
        e.stopPropagation()
        console.log('Widget clicked:', widget.id, widget.type)
        setSelectedWidget(widget)
      }}
      className={`
        relative p-2 rounded-lg transition-all duration-200 cursor-move
        ${isSelected ? 'ring-2 ring-purple-500 ring-offset-2' : 'hover:ring-2 hover:ring-purple-300 hover:ring-offset-1'}
      `}
    >
      {renderWidgetContent()}
    </div>
  )
}

// Droppable Column Component
const DroppableColumn: React.FC<{ column: Column; rowId: string; sectionId: string }> = ({ 
  column, rowId, sectionId 
}) => {
  const { setNodeRef, isOver } = useDroppable({ id: column.id })
  const { addWidget } = useEditorStore()

  return (
    <div
      ref={setNodeRef}
      className={`flex-1 min-w-0 p-4 border-2 border-dashed transition-colors ${
        isOver ? 'border-purple-500 bg-purple-50' : 'border-transparent hover:border-purple-300'
      }`}
    >
      {column.widgets.length === 0 ? (
        <div className="text-center text-slate-400 py-8">
          <p className="text-base">Drag elements here</p>
        </div>
      ) : (
        <SortableContext items={column.widgets.map(w => w.id)} strategy={verticalListSortingStrategy}>
          {column.widgets.map((widget) => (
            <SortableWidget
              key={widget.id}
              widget={widget}
              columnId={column.id}
              rowId={rowId}
              sectionId={sectionId}
            />
          ))}
        </SortableContext>
      )}
    </div>
  )
}

// Row Component
const RowComponent: React.FC<{ row: Row; sectionId: string }> = ({ row, sectionId }) => {
  const { columns, style } = row

  return (
    <div style={style} className="flex flex-wrap gap-4">
      {columns && columns.length > 0 ? (
        columns.map((column) => (
          <DroppableColumn
            key={column.id}
            column={column}
            rowId={row.id}
            sectionId={sectionId}
          />
        ))
      ) : (
        <div className="text-center text-slate-400 py-4 w-full">
          <p className="text-sm">No columns in this row</p>
        </div>
      )}
    </div>
  )
}

// Section Component
const SectionComponent: React.FC<{ section: Section }> = ({ section }) => {
  const { rows, style } = section

  const sectionStyle = {
    fontSize: '16px',
    ...style
  }

  return (
    <section style={sectionStyle} className="py-12 px-4 border-b border-slate-200">
      <div className="max-w-6xl mx-auto">
        {rows && rows.length > 0 ? (
          rows.map((row) => (
            <RowComponent key={row.id} row={row} sectionId={section.id} />
          ))
        ) : (
          <div className="text-center text-slate-400 py-8">
            <p className="text-sm">No rows in this section</p>
          </div>
        )}
      </div>
    </section>
  )
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

const EditablePageRenderer: React.FC<EditablePageRendererProps> = ({ pageData }) => {
  const { setSelectedWidget } = useEditorStore()

  const handleCanvasClick = () => {
    setSelectedWidget(null)
  }

  if (!pageData || !pageData.sections || pageData.sections.length === 0) {
    return (
      <div 
        onClick={handleCanvasClick}
        className="min-h-[400px] flex items-center justify-center bg-slate-50"
      >
        <div className="text-center">
          <p className="text-slate-400 text-lg">No content yet. Start adding sections to build your page.</p>
        </div>
      </div>
    )
  }

  return (
    <div onClick={handleCanvasClick} className="min-h-screen bg-white" style={{ fontSize: '16px' }}>
      {pageData.sections.map((section) => (
        <SectionComponent key={section.id} section={section} />
      ))}
    </div>
  )
}

export default EditablePageRenderer

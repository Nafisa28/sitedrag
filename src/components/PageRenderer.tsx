'use client'

import React from 'react'

// Type definitions for the page data structure
export interface Widget {
  id: string
  type: 'heading' | 'text' | 'image' | 'button' | 'spacer' | 'divider' | 'video' | 'gallery' | 'form' | 'icon' | 'list'
  content: any
  style: Record<string, any>
}

export interface Column {
  id: string
  widgets: Widget[]
  style: Record<string, any>
}

export interface Row {
  id: string
  columns: Column[]
  style: Record<string, any>
}

export interface Section {
  id: string
  rows: Row[]
  style: Record<string, any>
}

export interface PageData {
  sections: Section[]
}

interface PageRendererProps {
  pageData: PageData | null
}

const WidgetComponent: React.FC<{ widget: Widget }> = ({ widget }) => {
  const { type, content, style } = widget

  const baseStyle = {
    ...style,
  }

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
      
      if (headingLevel === 1) {
        return <h1 style={headingStyle} className="font-bold">{content.text || ''}</h1>
      } else if (headingLevel === 2) {
        return <h2 style={headingStyle} className="font-bold">{content.text || ''}</h2>
      } else if (headingLevel === 3) {
        return <h3 style={headingStyle} className="font-bold">{content.text || ''}</h3>
      } else if (headingLevel === 4) {
        return <h4 style={headingStyle} className="font-bold">{content.text || ''}</h4>
      } else if (headingLevel === 5) {
        return <h5 style={headingStyle} className="font-bold">{content.text || ''}</h5>
      } else {
        return <h6 style={headingStyle} className="font-bold">{content.text || ''}</h6>
      }

    case 'text':
      return (
        <p style={baseStyle} className="leading-relaxed">
          {content.text || ''}
        </p>
      )

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
          <input
            type="text"
            placeholder="Name"
            className="w-full px-4 py-2 border border-slate-300 rounded-lg"
          />
          <input
            type="email"
            placeholder="Email"
            className="w-full px-4 py-2 border border-slate-300 rounded-lg"
          />
          <textarea
            placeholder="Message"
            rows={4}
            className="w-full px-4 py-2 border border-slate-300 rounded-lg"
          />
          <button
            type="submit"
            className="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700"
          >
            Submit
          </button>
        </form>
      )

    case 'icon':
      return (
        <div style={baseStyle} className="flex items-center justify-center">
          <svg
            className="w-8 h-8"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
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

const ColumnComponent: React.FC<{ column: Column }> = ({ column }) => {
  const { widgets, style } = column

  return (
    <div
      style={style}
      className="flex-1 min-w-0"
    >
      {widgets.map((widget) => (
        <WidgetComponent key={widget.id} widget={widget} />
      ))}
    </div>
  )
}

const RowComponent: React.FC<{ row: Row }> = ({ row }) => {
  const { columns, style } = row

  return (
    <div
      style={style}
      className="flex flex-wrap gap-4"
    >
      {columns.map((column) => (
        <ColumnComponent key={column.id} column={column} />
      ))}
    </div>
  )
}

const SectionComponent: React.FC<{ section: Section }> = ({ section }) => {
  const { rows, style } = section

  return (
    <section
      style={style}
      className="py-12 px-4"
    >
      <div className="max-w-6xl mx-auto">
        {rows.map((row) => (
          <RowComponent key={row.id} row={row} />
        ))}
      </div>
    </section>
  )
}

const PageRenderer: React.FC<PageRendererProps> = ({ pageData }) => {
  if (!pageData || !pageData.sections || pageData.sections.length === 0) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <div className="text-center">
          <p className="text-slate-400 text-lg">No content yet. Start adding sections to build your page.</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-white">
      {pageData.sections.map((section) => (
        <SectionComponent key={section.id} section={section} />
      ))}
    </div>
  )
}

export default PageRenderer

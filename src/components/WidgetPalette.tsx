'use client'

import { useDraggable } from '@dnd-kit/core'

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

interface DraggableWidgetProps {
  widgetType: string
  label: string
  icon: string
}

const DraggableWidget: React.FC<DraggableWidgetProps> = ({ widgetType, label, icon }) => {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: widgetType,
    data: { widgetType }
  })

  return (
    <div
      ref={setNodeRef}
      {...attributes}
      {...listeners}
      className={`flex items-center gap-4 p-4 rounded-xl cursor-grab active:cursor-grabbing transition-all duration-200 hover:bg-slate-800 hover:scale-[1.02] ${
        isDragging ? 'opacity-50' : ''
      }`}
    >
      <div className="w-12 h-12 bg-slate-800 rounded-xl flex items-center justify-center text-2xl">
        {icon}
      </div>
      <span className="text-slate-300 font-medium text-base">{label}</span>
    </div>
  )
}

export default function WidgetPalette() {
  return (
    <div className="p-6">
      <h2 className="text-white font-semibold mb-6 text-2xl">Widgets</h2>
      <div className="space-y-3">
        {WIDGET_TYPES.map((widget) => (
          <DraggableWidget
            key={widget.type}
            widgetType={widget.type}
            label={widget.label}
            icon={widget.icon}
          />
        ))}
      </div>
    </div>
  )
}

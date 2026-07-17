'use client'

import { useState, useEffect } from 'react'
import { useEditorStore } from '@/store/editorStore'
import { Widget } from './PageRenderer'

export default function StylePanel() {
  const { selectedWidget, updateWidget, removeWidget, duplicateWidget } = useEditorStore()

  // Local state for input values to prevent focus loss on every keystroke
  const [localContent, setLocalContent] = useState<Record<string, any>>({})
  const [localStyle, setLocalStyle] = useState<Record<string, any>>({})

  // Sync local state when selected widget changes
  useEffect(() => {
    if (selectedWidget) {
      setLocalContent(selectedWidget.content)
      setLocalStyle(selectedWidget.style)
    }
  }, [selectedWidget])

  console.log('StylePanel render - selectedWidget:', selectedWidget)

  if (!selectedWidget) {
    return (
      <div className="p-6">
        <h2 className="text-white font-semibold mb-6 text-2xl">Style Panel</h2>
        <p className="text-slate-400 text-base">
          Select a widget on the canvas to edit its properties
        </p>
      </div>
    )
  }

  const { type } = selectedWidget

  const handleContentChange = (key: string, value: any) => {
    setLocalContent(prev => ({ ...prev, [key]: value }))
  }

  const handleContentBlur = () => {
    updateWidget(selectedWidget.id, {
      content: localContent
    })
  }

  const handleStyleChange = (key: string, value: any) => {
    setLocalStyle(prev => ({ ...prev, [key]: value }))
    // Update style immediately (no blur needed for style changes)
    updateWidget(selectedWidget.id, {
      style: { ...localStyle, [key]: value }
    })
  }

  return (
    <div className="p-6">
      <h2 className="text-white font-semibold mb-6 text-2xl">Style Panel</h2>
      
      <div className="mb-8">
        <span className="text-purple-400 text-base font-medium uppercase tracking-wide">
          {type}
        </span>
      </div>

      {/* Content Properties */}
      <div className="mb-8">
        <h3 className="text-slate-300 font-medium mb-4 text-lg">Content</h3>
        
        {type === 'heading' && (
          <div className="space-y-4">
            <div>
              <label className="block text-slate-400 text-base mb-2">Text</label>
              <input
                type="text"
                value={localContent.text || ''}
                onChange={(e) => handleContentChange('text', e.target.value)}
                onBlur={handleContentBlur}
                className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
            </div>
            <div>
              <label className="block text-slate-400 text-base mb-2">Level</label>
              <select
                value={localContent.level || 2}
                onChange={(e) => handleContentChange('level', parseInt(e.target.value))}
                onBlur={handleContentBlur}
                className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
              >
                <option value={1}>H1</option>
                <option value={2}>H2</option>
                <option value={3}>H3</option>
                <option value={4}>H4</option>
                <option value={5}>H5</option>
                <option value={6}>H6</option>
              </select>
            </div>
          </div>
        )}

        {type === 'text' && (
          <div>
            <label className="block text-slate-400 text-base mb-2">Text</label>
            <textarea
              value={localContent.text || ''}
              onChange={(e) => handleContentChange('text', e.target.value)}
              onBlur={handleContentBlur}
              rows={4}
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
          </div>
        )}

        {type === 'button' && (
          <div>
            <label className="block text-slate-400 text-base mb-2">Button Text</label>
            <input
              type="text"
              value={localContent.text || 'Button'}
              onChange={(e) => handleContentChange('text', e.target.value)}
              onBlur={handleContentBlur}
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
          </div>
        )}

        {type === 'image' && (
          <div className="space-y-4">
            <div>
              <label className="block text-slate-400 text-base mb-2">Image URL</label>
              <input
                type="text"
                value={localContent.src || ''}
                onChange={(e) => handleContentChange('src', e.target.value)}
                onBlur={handleContentBlur}
                className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
            </div>
            <div>
              <label className="block text-slate-400 text-base mb-2">Alt Text</label>
              <input
                type="text"
                value={localContent.alt || ''}
                onChange={(e) => handleContentChange('alt', e.target.value)}
                onBlur={handleContentBlur}
                className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
            </div>
          </div>
        )}

        {type === 'spacer' && (
          <div>
            <label className="block text-slate-400 text-base mb-2">Height (px)</label>
            <input
              type="number"
              value={parseInt(localContent.height) || 20}
              onChange={(e) => handleContentChange('height', `${e.target.value}px`)}
              onBlur={handleContentBlur}
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
          </div>
        )}

        {type === 'list' && (
          <div>
            <label className="block text-slate-400 text-base mb-2">Items (one per line)</label>
            <textarea
              value={(localContent.items || []).join('\n')}
              onChange={(e) => handleContentChange('items', e.target.value.split('\n').filter(i => i.trim()))}
              onBlur={handleContentBlur}
              rows={4}
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
          </div>
        )}
      </div>

      {/* Style Properties */}
      <div className="mb-8">
        <h3 className="text-slate-300 font-medium mb-4 text-lg">Style</h3>

        <div className="space-y-4">
          <div>
            <label className="block text-slate-400 text-base mb-2">Color</label>
            <input
              type="color"
              value={localStyle.color || '#000000'}
              onChange={(e) => handleStyleChange('color', e.target.value)}
              className="w-full h-12 bg-slate-800 border border-slate-700 rounded-xl cursor-pointer"
            />
          </div>

          <div>
            <label className="block text-slate-400 text-base mb-2">Background Color</label>
            <input
              type="color"
              value={localStyle.backgroundColor || '#ffffff'}
              onChange={(e) => handleStyleChange('backgroundColor', e.target.value)}
              className="w-full h-12 bg-slate-800 border border-slate-700 rounded-xl cursor-pointer"
            />
          </div>

          <div>
            <label className="block text-slate-400 text-base mb-2">Font Size (px)</label>
            <input
              type="number"
              value={parseInt(localStyle.fontSize) || 16}
              onChange={(e) => handleStyleChange('fontSize', `${e.target.value}px`)}
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
          </div>

          <div>
            <label className="block text-slate-400 text-base mb-2">Alignment</label>
            <select
              value={localStyle.textAlign || 'left'}
              onChange={(e) => handleStyleChange('textAlign', e.target.value)}
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
            >
              <option value="left">Left</option>
              <option value="center">Center</option>
              <option value="right">Right</option>
            </select>
          </div>

          <div>
            <label className="block text-slate-400 text-base mb-2">Padding (px)</label>
            <input
              type="number"
              value={parseInt(localStyle.padding) || 0}
              onChange={(e) => handleStyleChange('padding', `${e.target.value}px`)}
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
          </div>

          <div>
            <label className="block text-slate-400 text-base mb-2">Margin (px)</label>
            <input
              type="number"
              value={parseInt(localStyle.margin) || 0}
              onChange={(e) => handleStyleChange('margin', `${e.target.value}px`)}
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white text-base focus:outline-none focus:ring-2 focus:ring-purple-500"
            />
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-3">
        <button
          onClick={() => duplicateWidget(selectedWidget.id)}
          className="flex-1 py-3 px-6 bg-slate-800 text-slate-300 rounded-xl hover:bg-slate-700 transition-colors text-base font-medium"
        >
          Duplicate
        </button>
        <button
          onClick={() => removeWidget(selectedWidget.id)}
          className="flex-1 py-3 px-6 bg-red-600/20 text-red-400 rounded-xl hover:bg-red-600/30 transition-colors text-base font-medium"
        >
          Delete
        </button>
      </div>
    </div>
  )
}

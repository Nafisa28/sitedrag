import { PageData, Widget, Column, Row, Section } from '@/components/PageRenderer'

// Convert page data JSON to static HTML
export function renderToHTML(pageData: PageData): string {
  if (!pageData || !pageData.sections || pageData.sections.length === 0) {
    return '<html><body><p>No content</p></body></html>'
  }

  const sectionsHTML = pageData.sections.map(section => renderSection(section)).join('\n')

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Website</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      line-height: 1.6;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 20px;
    }
    img {
      max-width: 100%;
      height: auto;
    }
  </style>
</head>
<body>
  ${sectionsHTML}
</body>
</html>`
}

function renderSection(section: Section): string {
  const style = section.style || {}
  const styleString = Object.entries(style)
    .map(([key, value]) => `${camelToKebab(key)}: ${value}`)
    .join('; ')

  const rowsHTML = section.rows.map(row => renderRow(row)).join('\n')

  return `<section style="${styleString}" class="py-12 px-4">
  <div class="container">
    ${rowsHTML}
  </div>
</section>`
}

function renderRow(row: Row): string {
  const style = row.style || {}
  const styleString = Object.entries(style)
    .map(([key, value]) => `${camelToKebab(key)}: ${value}`)
    .join('; ')

  const columnsHTML = row.columns.map(column => renderColumn(column)).join('\n')

  return `<div style="${styleString}" class="flex flex-wrap gap-4">
  ${columnsHTML}
</div>`
}

function renderColumn(column: Column): string {
  const style = column.style || {}
  const styleString = Object.entries(style)
    .map(([key, value]) => `${camelToKebab(key)}: ${value}`)
    .join('; ')

  const widgetsHTML = column.widgets.map(widget => renderWidget(widget)).join('\n')

  return `<div style="${styleString}" class="flex-1 min-w-0 p-4">
  ${widgetsHTML}
</div>`
}

function renderWidget(widget: Widget): string {
  const { type, content, style } = widget
  const styleString = Object.entries(style || {})
    .map(([key, value]) => `${camelToKebab(key)}: ${value}`)
    .join('; ')

  switch (type) {
    case 'heading':
      const level = content.level || 2
      const text = content.text || ''
      return `<h${level} style="${styleString}" class="font-bold">${text}</h${level}>`

    case 'text':
      return `<p style="${styleString}" class="leading-relaxed">${content.text || ''}</p>`

    case 'image':
      return `<img src="${content.url || 'https://via.placeholder.com/400x300'}" alt="${content.alt || ''}" style="${styleString}" />`

    case 'button':
      return `<button style="${styleString}" class="px-6 py-3 rounded-lg font-medium">${content.text || 'Button'}</button>`

    case 'spacer':
      return `<div style="height: ${content.height || '20px'}; ${styleString}"></div>`

    case 'divider':
      return `<hr style="border: none; border-top: 2px solid ${content.color || '#e5e7eb'}; ${styleString}" />`

    case 'video':
      return `<div style="${styleString}" class="aspect-video bg-slate-900 rounded-lg flex items-center justify-center">
  <p style="color: #94a3b8">Video: ${content.url || 'No video URL'}</p>
</div>`

    case 'gallery':
      const imagesHTML = (content.images || []).map((img: any) => 
        `<img src="${img.url || 'https://via.placeholder.com/200x200'}" alt="${img.alt || ''}" class="rounded-lg w-full h-32 object-cover" />`
      ).join('\n')
      return `<div style="${styleString}" class="grid grid-cols-2 md:grid-cols-3 gap-4">
  ${imagesHTML}
</div>`

    case 'form':
      return `<form style="${styleString}" class="space-y-4">
  <input type="text" placeholder="Name" class="w-full px-4 py-2 border border-slate-300 rounded-lg" />
  <input type="email" placeholder="Email" class="w-full px-4 py-2 border border-slate-300 rounded-lg" />
  <textarea placeholder="Message" rows="4" class="w-full px-4 py-2 border border-slate-300 rounded-lg"></textarea>
  <button type="submit" class="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700">Submit</button>
</form>`

    case 'icon':
      return `<div style="${styleString}" class="flex items-center justify-center">
  <svg style="width: 32px; height: 32px" fill="currentColor" viewBox="0 0 20 20">
    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
  </svg>
</div>`

    case 'list':
      const itemsHTML = (content.items || []).map((item: string) => `<li>${item}</li>`).join('\n')
      return `<ul style="${styleString}" class="list-disc list-inside space-y-2">
  ${itemsHTML}
</ul>`

    default:
      return `<div style="${styleString}">Unknown widget type: ${type}</div>`
  }
}

function camelToKebab(str: string): string {
  return str.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase()
}

// Generate CSS file
export function renderToCSS(pageData: PageData): string {
  let css = `/* Generated CSS for your website */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  line-height: 1.6;
  color: #333;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

img {
  max-width: 100%;
  height: auto;
}

button {
  cursor: pointer;
  border: none;
  font-family: inherit;
}

input, textarea {
  font-family: inherit;
}
`

  // Add custom styles from sections if needed
  if (pageData && pageData.sections) {
    pageData.sections.forEach((section, index) => {
      if (section.style && Object.keys(section.style).length > 0) {
        css += `\n/* Section ${index + 1} */\n`
        Object.entries(section.style).forEach(([key, value]) => {
          css += `section:nth-child(${index + 1}) { ${camelToKebab(key)}: ${value}; }\n`
        })
      }
    })
  }

  return css
}

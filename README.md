# DragSite

A modern SaaS platform for building websites with a drag-and-drop editor. Users can sign up, choose from professionally designed templates, customize their page visually, and publish or export their finished website.

## Features

- **Authentication**: Email/password signup and login with Supabase Auth
- **Template Gallery**: Browse and select from categorized templates with search and filtering
- **Drag-and-Drop Editor**: Visual page builder with widget palette, canvas, and style panel
- **Real-time Editing**: Live preview with undo/redo support
- **Auto-save**: Automatic saving every 30 seconds
- **Publish/Export**: Generate static HTML/CSS or export as downloadable files
- **Professional Design**: Consistent dark theme with purple-to-blue gradient accents

## Tech Stack

- **Frontend**: Next.js 16 (React) + TypeScript + Tailwind CSS
- **Drag-and-Drop**: HTML5 Drag and Drop API
- **State Management**: Zustand
- **Backend/Database**: Supabase (Postgres + Auth + Storage)
- **Page Data Storage**: JSONB column for structured page data

## Getting Started

### Prerequisites

- Node.js 18+ installed
- A Supabase project (create one at [supabase.com](https://supabase.com))

### Setup

1. **Clone and install dependencies**:
```bash
npm install
```

2. **Configure environment variables**:
Create a `.env.local` file in the root directory:
```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

3. **Set up the database**:
Run the SQL script in `supabase-setup.sql` in your Supabase SQL editor to create the required tables:
- `profiles` - User profiles
- `sites` - User-created websites
- `templates` - Available templates

4. **Run the development server**:
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the application.

## Project Structure

```
src/
├── app/
│   ├── api/
│   │   └── publish/[siteId]/route.ts    # Publish API endpoint
│   ├── auth/
│   │   ├── login/page.tsx              # Login page
│   │   ├── signup/page.tsx             # Signup page
│   │   └── reset-password/page.tsx     # Password reset
│   ├── dashboard/page.tsx              # User dashboard
│   ├── editor/[siteId]/page.tsx        # Drag-and-drop editor
│   ├── templates/page.tsx              # Template gallery
│   ├── layout.tsx                      # Root layout with AuthProvider
│   ├── page.tsx                        # Landing page
│   └── globals.css                     # Global styles
├── components/
│   ├── EditablePageRenderer.tsx        # Editor canvas with drag-drop
│   ├── PageRenderer.tsx                # Read-only page renderer
│   ├── StylePanel.tsx                  # Widget style editor
│   └── WidgetPalette.tsx               # Draggable widget palette
├── contexts/
│   └── AuthContext.tsx                 # Authentication context
├── lib/
│   ├── pageExporter.ts                 # HTML/CSS export functions
│   └── supabase.ts                     # Supabase client
└── store/
    └── editorStore.ts                  # Editor state management
```

## Database Schema

### profiles
- `id` (UUID, primary key, references auth.users)
- `email` (TEXT)
- `full_name` (TEXT, nullable)
- `created_at` (TIMESTAMP)

### sites
- `id` (UUID, primary key)
- `user_id` (UUID, foreign key to profiles)
- `name` (TEXT)
- `page_data` (JSONB) - Structured page content
- `template_id` (UUID, foreign key to templates, nullable)
- `status` (TEXT: 'draft' | 'published')
- `published_url` (TEXT, nullable)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### templates
- `id` (UUID, primary key)
- `name` (TEXT)
- `category` (TEXT)
- `description` (TEXT)
- `thumbnail_url` (TEXT, nullable)
- `page_data` (JSONB) - Template page structure
- `created_at` (TIMESTAMP)

## Page Data Structure

Pages are stored as structured JSON:

```json
{
  "sections": [
    {
      "id": "section_1",
      "style": { "backgroundColor": "#ffffff", "padding": "60px 20px" },
      "rows": [
        {
          "id": "row_1",
          "style": {},
          "columns": [
            {
              "id": "column_1",
              "style": {},
              "widgets": [
                {
                  "id": "widget_1",
                  "type": "heading",
                  "content": { "text": "Hello World", "level": 2 },
                  "style": { "color": "#000000", "fontSize": "36px" }
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

## Supported Widget Types

- **Heading** - H1-H6 headings with text content
- **Text** - Paragraph text blocks
- **Image** - Images with URL and alt text
- **Button** - Clickable buttons
- **Spacer** - Vertical spacing
- **Divider** - Horizontal lines
- **Video** - Video embeds
- **Gallery** - Image grids
- **Form** - Contact forms
- **Icon** - SVG icons
- **List** - Bulleted/numbered lists

## Design System

- **Theme**: Dark slate background with purple-to-blue gradient accents
- **Typography**: 16px minimum body text, 64px hero headings
- **Spacing**: 24-32px card padding, 20-32px grid gaps
- **Border Radius**: 12-16px for buttons, cards, and inputs
- **Transitions**: 200-250ms ease for all interactive elements

## Deployment

The easiest way to deploy is using [Vercel](https://vercel.com):

1. Push your code to GitHub
2. Import the project in Vercel
3. Add environment variables in Vercel dashboard
4. Deploy

## Known Issues & Future Improvements

- Add Google OAuth authentication option
- Implement ZIP export functionality
- Add more template categories and templates
- Implement responsive breakpoint editing
- Add collaboration features
- Add custom domain support for published sites

## License

MIT

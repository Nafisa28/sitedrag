import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          email: string
          full_name: string | null
          created_at: string
        }
        Insert: {
          id: string
          email: string
          full_name?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          email?: string
          full_name?: string | null
          created_at?: string
        }
      }
      sites: {
        Row: {
          id: string
          user_id: string
          name: string
          page_data: any
          template_id: string | null
          status: 'draft' | 'published'
          published_url: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          name: string
          page_data: any
          template_id?: string | null
          status?: 'draft' | 'published'
          published_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          name?: string
          page_data?: any
          template_id?: string | null
          status?: 'draft' | 'published'
          published_url?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      templates: {
        Row: {
          id: string
          name: string
          category: string
          description: string
          thumbnail_url: string | null
          page_data: any
          created_at: string
        }
        Insert: {
          id?: string
          name: string
          category: string
          description: string
          thumbnail_url?: string | null
          page_data: any
          created_at?: string
        }
        Update: {
          id?: string
          name?: string
          category?: string
          description?: string
          thumbnail_url?: string | null
          page_data?: any
          created_at?: string
        }
      }
    }
  }
}

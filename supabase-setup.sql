-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- Sites table
CREATE TABLE IF NOT EXISTS sites (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  page_data JSONB NOT NULL DEFAULT '[]'::jsonb,
  template_id UUID REFERENCES templates(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
  published_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- Templates table
CREATE TABLE IF NOT EXISTS templates (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  thumbnail_url TEXT,
  page_data JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_sites_user_id ON sites(user_id);
CREATE INDEX IF NOT EXISTS idx_sites_status ON sites(status);
CREATE INDEX IF NOT EXISTS idx_templates_category ON templates(category);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- RLS Policies for sites
DROP POLICY IF EXISTS "Users can view own sites" ON sites;
CREATE POLICY "Users can view own sites"
  ON sites FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own sites" ON sites;
CREATE POLICY "Users can insert own sites"
  ON sites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own sites" ON sites;
CREATE POLICY "Users can update own sites"
  ON sites FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own sites" ON sites;
CREATE POLICY "Users can delete own sites"
  ON sites FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for templates (public read, authenticated insert/update)
DROP POLICY IF EXISTS "Anyone can view templates" ON templates;
CREATE POLICY "Anyone can view templates"
  ON templates FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert templates" ON templates;
CREATE POLICY "Authenticated users can insert templates"
  ON templates FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can update templates" ON templates;
CREATE POLICY "Authenticated users can update templates"
  ON templates FOR UPDATE
  USING (auth.role() = 'authenticated');

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at on sites
DROP TRIGGER IF EXISTS update_sites_updated_at ON sites;

CREATE TRIGGER update_sites_updated_at
  BEFORE UPDATE ON sites
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert sample templates with real page_data
INSERT INTO templates (name, category, description, page_data) VALUES
('Portfolio Pro', 'Portfolio', 'A clean, modern portfolio template for creative professionals', '{
  "sections": [
    {
      "id": "section_hero",
      "style": {"backgroundColor": "#1a1a2e", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Creative Portfolio", "level": 1}, "style": {"color": "#ffffff", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "Showcasing my best work and creative projects"}, "style": {"color": "#a0a0a0", "textAlign": "center", "fontSize": "18px"}},
                {"id": "w_button", "type": "button", "content": {"text": "View My Work"}, "style": {"backgroundColor": "#6366f1", "color": "#ffffff"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_about",
      "style": {"backgroundColor": "#ffffff", "padding": "60px 20px"},
      "rows": [
        {
          "id": "row_about",
          "style": {},
          "columns": [
            {
              "id": "col_about",
              "style": {},
              "widgets": [
                {"id": "w_about_heading", "type": "heading", "content": {"text": "About Me", "level": 2}, "style": {"color": "#1a1a2e", "textAlign": "center"}},
                {"id": "w_about_text", "type": "text", "content": {"text": "I am a passionate designer and developer with 5+ years of experience creating beautiful digital experiences."}, "style": {"color": "#4a4a4a", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}'),
('Business Starter', 'Business', 'Professional business site with services and contact sections', '{
  "sections": [
    {
      "id": "section_hero",
      "style": {"backgroundColor": "#0f172a", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Grow Your Business", "level": 1}, "style": {"color": "#ffffff", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "Professional solutions for modern businesses"}, "style": {"color": "#94a3b8", "textAlign": "center", "fontSize": "20px"}},
                {"id": "w_button", "type": "button", "content": {"text": "Get Started"}, "style": {"backgroundColor": "#3b82f6", "color": "#ffffff"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_services",
      "style": {"backgroundColor": "#ffffff", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_services",
          "style": {},
          "columns": [
            {
              "id": "col_services",
              "style": {},
              "widgets": [
                {"id": "w_services_heading", "type": "heading", "content": {"text": "Our Services", "level": 2}, "style": {"color": "#0f172a", "textAlign": "center"}},
                {"id": "w_services_text", "type": "text", "content": {"text": "We offer comprehensive business solutions tailored to your needs."}, "style": {"color": "#475569", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}'),
('Landing Page', 'Landing Page', 'High-converting landing page for products or services', '{
  "sections": [
    {
      "id": "section_hero",
      "style": {"backgroundColor": "#7c3aed", "padding": "120px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Launch Your Product", "level": 1}, "style": {"color": "#ffffff", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "The fastest way to bring your ideas to life"}, "style": {"color": "#e9d5ff", "textAlign": "center", "fontSize": "22px"}},
                {"id": "w_button", "type": "button", "content": {"text": "Start Free Trial"}, "style": {"backgroundColor": "#ffffff", "color": "#7c3aed"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_features",
      "style": {"backgroundColor": "#f5f3ff", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_features",
          "style": {},
          "columns": [
            {
              "id": "col_features",
              "style": {},
              "widgets": [
                {"id": "w_features_heading", "type": "heading", "content": {"text": "Powerful Features", "level": 2}, "style": {"color": "#5b21b6", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}'),
('Restaurant Menu', 'Restaurant', 'Elegant restaurant template with menu and reservation features', '{
  "sections": [
    {
      "id": "section_hero",
      "style": {"backgroundColor": "#78350f", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Fine Dining Experience", "level": 1}, "style": {"color": "#fef3c7", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "Exquisite cuisine in an elegant atmosphere"}, "style": {"color": "#fde68a", "textAlign": "center", "fontSize": "20px"}},
                {"id": "w_button", "type": "button", "content": {"text": "Reserve a Table"}, "style": {"backgroundColor": "#f59e0b", "color": "#78350f"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_menu",
      "style": {"backgroundColor": "#fffbeb", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_menu",
          "style": {},
          "columns": [
            {
              "id": "col_menu",
              "style": {},
              "widgets": [
                {"id": "w_menu_heading", "type": "heading", "content": {"text": "Our Menu", "level": 2}, "style": {"color": "#78350f", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}'),
('Personal Blog', 'Blog', 'Clean blog template perfect for writers and content creators', '{
  "sections": [
    {
      "id": "section_hero",
      "style": {"backgroundColor": "#f8fafc", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "My Blog", "level": 1}, "style": {"color": "#1e293b", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "Thoughts, stories, and ideas from my journey"}, "style": {"color": "#64748b", "textAlign": "center", "fontSize": "18px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_posts",
      "style": {"backgroundColor": "#ffffff", "padding": "60px 20px"},
      "rows": [
        {
          "id": "row_posts",
          "style": {},
          "columns": [
            {
              "id": "col_posts",
              "style": {},
              "widgets": [
                {"id": "w_posts_heading", "type": "heading", "content": {"text": "Latest Posts", "level": 2}, "style": {"color": "#1e293b", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}'),
('Agency Portfolio', 'Agency', 'Showcase your agency work with this bold, modern template', '{
  "sections": [
    {
      "id": "section_hero",
      "style": {"backgroundColor": "#000000", "padding": "120px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Creative Agency", "level": 1}, "style": {"color": "#ffffff", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "We create digital experiences that matter"}, "style": {"color": "#a1a1aa", "textAlign": "center", "fontSize": "22px"}},
                {"id": "w_button", "type": "button", "content": {"text": "View Our Work"}, "style": {"backgroundColor": "#ec4899", "color": "#ffffff"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_work",
      "style": {"backgroundColor": "#18181b", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_work",
          "style": {},
          "columns": [
            {
              "id": "col_work",
              "style": {},
              "widgets": [
                {"id": "w_work_heading", "type": "heading", "content": {"text": "Selected Work", "level": 2}, "style": {"color": "#ffffff", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}'),
('Event Landing', 'Event', 'Promote your event with this attention-grabbing template', '{
  "sections": [
    {
      "id": "section_hero",
      "style": {"backgroundColor": "#dc2626", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Annual Conference 2024", "level": 1}, "style": {"color": "#ffffff", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "Join us for the biggest event of the year"}, "style": {"color": "#fecaca", "textAlign": "center", "fontSize": "20px"}},
                {"id": "w_button", "type": "button", "content": {"text": "Register Now"}, "style": {"backgroundColor": "#ffffff", "color": "#dc2626"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_details",
      "style": {"backgroundColor": "#fef2f2", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_details",
          "style": {},
          "columns": [
            {
              "id": "col_details",
              "style": {},
              "widgets": [
                {"id": "w_details_heading", "type": "heading", "content": {"text": "Event Details", "level": 2}, "style": {"color": "#991b1b", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}'),
('Nonprofit', 'Nonprofit', 'Heartfelt template for nonprofits and charitable organizations', '{
  "sections": [
    {
      "id": "section_hero",
      "style": {"backgroundColor": "#059669", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Making a Difference", "level": 1}, "style": {"color": "#ffffff", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "Together we can change lives"}, "style": {"color": "#d1fae5", "textAlign": "center", "fontSize": "20px"}},
                {"id": "w_button", "type": "button", "content": {"text": "Donate Now"}, "style": {"backgroundColor": "#ffffff", "color": "#059669"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_mission",
      "style": {"backgroundColor": "#ecfdf5", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_mission",
          "style": {},
          "columns": [
            {
              "id": "col_mission",
              "style": {},
              "widgets": [
                {"id": "w_mission_heading", "type": "heading", "content": {"text": "Our Mission", "level": 2}, "style": {"color": "#065f46", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}'),
('Coming Soon', 'Coming Soon', 'Build anticipation with this coming soon page template', '{
  "sections": [
    {
      "id": "section_hero",
      "style": {"backgroundColor": "#4f46e5", "padding": "150px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Coming Soon", "level": 1}, "style": {"color": "#ffffff", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "Something amazing is on the way"}, "style": {"color": "#c7d2fe", "textAlign": "center", "fontSize": "24px"}},
                {"id": "w_button", "type": "button", "content": {"text": "Get Notified"}, "style": {"backgroundColor": "#ffffff", "color": "#4f46e5"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}'),
('E-commerce Store', 'Business', 'Simple e-commerce template to showcase products', '{
  "sections": [
    {
      "id": "section_hero",
      "style": {"backgroundColor": "#1e293b", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Premium Products", "level": 1}, "style": {"color": "#ffffff", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "Quality products at great prices"}, "style": {"color": "#94a3b8", "textAlign": "center", "fontSize": "18px"}},
                {"id": "w_button", "type": "button", "content": {"text": "Shop Now"}, "style": {"backgroundColor": "#f97316", "color": "#ffffff"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_products",
      "style": {"backgroundColor": "#f8fafc", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_products",
          "style": {},
          "columns": [
            {
              "id": "col_products",
              "style": {},
              "widgets": [
                {"id": "w_products_heading", "type": "heading", "content": {"text": "Featured Products", "level": 2}, "style": {"color": "#1e293b", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}')
ON CONFLICT DO NOTHING;

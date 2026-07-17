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
      "style": {"backgroundColor": "#0f172a", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero_left",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Alex Morgan", "level": 1}, "style": {"color": "#ffffff", "fontSize": "48px", "fontWeight": "bold"}},
                {"id": "w_text", "type": "text", "content": {"text": "Full-Stack Developer & UI Designer"}, "style": {"color": "#94a3b8", "fontSize": "20px", "marginBottom": "20px"}},
                {"id": "w_button", "type": "button", "content": {"text": "View My Work"}, "style": {"backgroundColor": "#6366f1", "color": "#ffffff", "padding": "12px 24px", "borderRadius": "8px"}}
              ]
            },
            {
              "id": "col_hero_right",
              "style": {},
              "widgets": [
                {"id": "w_image", "type": "image", "content": {"src": "https://via.placeholder.com/400x400/6366f1/ffffff?text=Profile+Photo", "alt": "Professional headshot"}, "style": {"borderRadius": "50%", "maxWidth": "300px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_about",
      "style": {"backgroundColor": "#ffffff", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_about",
          "style": {},
          "columns": [
            {
              "id": "col_about",
              "style": {},
              "widgets": [
                {"id": "w_about_heading", "type": "heading", "content": {"text": "About Me", "level": 2}, "style": {"color": "#0f172a", "fontSize": "32px", "marginBottom": "20px"}},
                {"id": "w_about_text", "type": "text", "content": {"text": "I am a passionate designer and developer with 5+ years of experience creating beautiful digital experiences. I specialize in building responsive web applications and crafting intuitive user interfaces that solve real problems."}, "style": {"color": "#475569", "fontSize": "16px", "lineHeight": "1.6"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_skills",
      "style": {"backgroundColor": "#f8fafc", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_skills",
          "style": {},
          "columns": [
            {
              "id": "col_skills",
              "style": {},
              "widgets": [
                {"id": "w_skills_heading", "type": "heading", "content": {"text": "Skills & Tools", "level": 2}, "style": {"color": "#0f172a", "fontSize": "32px", "marginBottom": "30px", "textAlign": "center"}},
                {"id": "w_skills_text", "type": "text", "content": {"text": "React • TypeScript • Node.js • Figma • Python • PostgreSQL • Tailwind CSS • Next.js"}, "style": {"color": "#475569", "fontSize": "18px", "textAlign": "center", "fontWeight": "500"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_projects",
      "style": {"backgroundColor": "#ffffff", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_projects_heading",
          "style": {},
          "columns": [
            {
              "id": "col_projects_heading",
              "style": {},
              "widgets": [
                {"id": "w_projects_heading", "type": "heading", "content": {"text": "My Projects", "level": 2}, "style": {"color": "#0f172a", "fontSize": "32px", "marginBottom": "40px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_projects_grid",
          "style": {},
          "columns": [
            {
              "id": "col_project_1",
              "style": {},
              "widgets": [
                {"id": "w_project_1_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x300/6366f1/ffffff?text=Project+1", "alt": "Project thumbnail"}, "style": {"borderRadius": "12px", "marginBottom": "16px"}},
                {"id": "w_project_1_title", "type": "heading", "content": {"text": "E-Commerce Dashboard", "level": 3}, "style": {"color": "#0f172a", "fontSize": "20px", "marginBottom": "8px"}},
                {"id": "w_project_1_desc", "type": "text", "content": {"text": "A comprehensive admin dashboard for online stores"}, "style": {"color": "#64748b", "fontSize": "14px", "marginBottom": "12px"}},
                {"id": "w_project_1_link", "type": "button", "content": {"text": "View Project"}, "style": {"backgroundColor": "#6366f1", "color": "#ffffff", "padding": "8px 16px", "borderRadius": "6px"}}
              ]
            },
            {
              "id": "col_project_2",
              "style": {},
              "widgets": [
                {"id": "w_project_2_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x300/8b5cf6/ffffff?text=Project+2", "alt": "Project thumbnail"}, "style": {"borderRadius": "12px", "marginBottom": "16px"}},
                {"id": "w_project_2_title", "type": "heading", "content": {"text": "Mobile Banking App", "level": 3}, "style": {"color": "#0f172a", "fontSize": "20px", "marginBottom": "8px"}},
                {"id": "w_project_2_desc", "type": "text", "content": {"text": "Secure and intuitive mobile banking experience"}, "style": {"color": "#64748b", "fontSize": "14px", "marginBottom": "12px"}},
                {"id": "w_project_2_link", "type": "button", "content": {"text": "View Project"}, "style": {"backgroundColor": "#8b5cf6", "color": "#ffffff", "padding": "8px 16px", "borderRadius": "6px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_contact",
      "style": {"backgroundColor": "#f8fafc", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_contact",
          "style": {},
          "columns": [
            {
              "id": "col_contact",
              "style": {},
              "widgets": [
                {"id": "w_contact_heading", "type": "heading", "content": {"text": "Get In Touch", "level": 2}, "style": {"color": "#0f172a", "fontSize": "32px", "marginBottom": "30px", "textAlign": "center"}},
                {"id": "w_contact_text", "type": "text", "content": {"text": "Feel free to reach out for collaborations or just a friendly hello"}, "style": {"color": "#64748b", "fontSize": "16px", "textAlign": "center", "marginBottom": "30px"}},
                {"id": "w_contact_button", "type": "button", "content": {"text": "Send Message"}, "style": {"backgroundColor": "#6366f1", "color": "#ffffff", "padding": "12px 24px", "borderRadius": "8px"}}
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
      "style": {"backgroundColor": "#1e3a8a", "padding": "120px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero_left",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Grow Your Business Today", "level": 1}, "style": {"color": "#ffffff", "fontSize": "48px", "fontWeight": "bold", "marginBottom": "20px"}},
                {"id": "w_text", "type": "text", "content": {"text": "Transform your operations with our proven business solutions and expert consulting services"}, "style": {"color": "#bfdbfe", "fontSize": "18px", "marginBottom": "30px", "lineHeight": "1.6"}},
                {"id": "w_button", "type": "button", "content": {"text": "Get Started"}, "style": {"backgroundColor": "#3b82f6", "color": "#ffffff", "padding": "14px 28px", "borderRadius": "8px", "fontSize": "16px"}}
              ]
            },
            {
              "id": "col_hero_right",
              "style": {},
              "widgets": [
                {"id": "w_image", "type": "image", "content": {"src": "https://via.placeholder.com/500x400/3b82f6/ffffff?text=Business+Growth", "alt": "Business growth illustration"}, "style": {"borderRadius": "12px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_services",
      "style": {"backgroundColor": "#ffffff", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_services_heading",
          "style": {},
          "columns": [
            {
              "id": "col_services_heading",
              "style": {},
              "widgets": [
                {"id": "w_services_heading", "type": "heading", "content": {"text": "Our Services", "level": 2}, "style": {"color": "#1e3a8a", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_services_grid",
          "style": {},
          "columns": [
            {
              "id": "col_service_1",
              "style": {},
              "widgets": [
                {"id": "w_service_1_icon", "type": "text", "content": {"text": "📊"}, "style": {"fontSize": "48px", "textAlign": "center", "marginBottom": "16px"}},
                {"id": "w_service_1_title", "type": "heading", "content": {"text": "Strategic Consulting", "level": 3}, "style": {"color": "#1e3a8a", "fontSize": "20px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_service_1_desc", "type": "text", "content": {"text": "Data-driven strategies to optimize your business performance"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            },
            {
              "id": "col_service_2",
              "style": {},
              "widgets": [
                {"id": "w_service_2_icon", "type": "text", "content": {"text": "🚀"}, "style": {"fontSize": "48px", "textAlign": "center", "marginBottom": "16px"}},
                {"id": "w_service_2_title", "type": "heading", "content": {"text": "Digital Transformation", "level": 3}, "style": {"color": "#1e3a8a", "fontSize": "20px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_service_2_desc", "type": "text", "content": {"text": "Modernize your operations with cutting-edge technology"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            },
            {
              "id": "col_service_3",
              "style": {},
              "widgets": [
                {"id": "w_service_3_icon", "type": "text", "content": {"text": "💼"}, "style": {"fontSize": "48px", "textAlign": "center", "marginBottom": "16px"}},
                {"id": "w_service_3_title", "type": "heading", "content": {"text": "Financial Planning", "level": 3}, "style": {"color": "#1e3a8a", "fontSize": "20px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_service_3_desc", "type": "text", "content": {"text": "Expert financial guidance for sustainable growth"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_stats",
      "style": {"backgroundColor": "#f8fafc", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_stats",
          "style": {},
          "columns": [
            {
              "id": "col_stat_1",
              "style": {},
              "widgets": [
                {"id": "w_stat_1_number", "type": "heading", "content": {"text": "500+", "level": 2}, "style": {"color": "#1e3a8a", "fontSize": "48px", "fontWeight": "bold", "textAlign": "center"}},
                {"id": "w_stat_1_label", "type": "text", "content": {"text": "Clients Served"}, "style": {"color": "#64748b", "fontSize": "16px", "textAlign": "center"}}
              ]
            },
            {
              "id": "col_stat_2",
              "style": {},
              "widgets": [
                {"id": "w_stat_2_number", "type": "heading", "content": {"text": "10+", "level": 2}, "style": {"color": "#1e3a8a", "fontSize": "48px", "fontWeight": "bold", "textAlign": "center"}},
                {"id": "w_stat_2_label", "type": "text", "content": {"text": "Years Experience"}, "style": {"color": "#64748b", "fontSize": "16px", "textAlign": "center"}}
              ]
            },
            {
              "id": "col_stat_3",
              "style": {},
              "widgets": [
                {"id": "w_stat_3_number", "type": "heading", "content": {"text": "98%", "level": 2}, "style": {"color": "#1e3a8a", "fontSize": "48px", "fontWeight": "bold", "textAlign": "center"}},
                {"id": "w_stat_3_label", "type": "text", "content": {"text": "Client Satisfaction"}, "style": {"color": "#64748b", "fontSize": "16px", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_testimonials",
      "style": {"backgroundColor": "#ffffff", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_testimonials_heading",
          "style": {},
          "columns": [
            {
              "id": "col_testimonials_heading",
              "style": {},
              "widgets": [
                {"id": "w_testimonials_heading", "type": "heading", "content": {"text": "What Our Clients Say", "level": 2}, "style": {"color": "#1e3a8a", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_testimonials_grid",
          "style": {},
          "columns": [
            {
              "id": "col_testimonial_1",
              "style": {},
              "widgets": [
                {"id": "w_testimonial_1_quote", "type": "text", "content": {"text": "\"Working with this team transformed our operations. Their strategic insights helped us increase revenue by 40% in just six months.\""}, "style": {"color": "#475569", "fontSize": "15px", "lineHeight": "1.6", "marginBottom": "16px", "fontStyle": "italic"}},
                {"id": "w_testimonial_1_name", "type": "text", "content": {"text": "— Sarah Johnson, CEO, TechStart Inc."}, "style": {"color": "#1e3a8a", "fontSize": "14px", "fontWeight": "600"}}
              ]
            },
            {
              "id": "col_testimonial_2",
              "style": {},
              "widgets": [
                {"id": "w_testimonial_2_quote", "type": "text", "content": {"text": "\"Exceptional service and expertise. They understood our unique challenges and delivered solutions that exceeded our expectations.\""}, "style": {"color": "#475569", "fontSize": "15px", "lineHeight": "1.6", "marginBottom": "16px", "fontStyle": "italic"}},
                {"id": "w_testimonial_2_name", "type": "text", "content": {"text": "— Michael Chen, Director, Global Solutions"}, "style": {"color": "#1e3a8a", "fontSize": "14px", "fontWeight": "600"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_contact",
      "style": {"backgroundColor": "#1e3a8a", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_contact",
          "style": {},
          "columns": [
            {
              "id": "col_contact",
              "style": {},
              "widgets": [
                {"id": "w_contact_heading", "type": "heading", "content": {"text": "Ready to Transform Your Business?", "level": 2}, "style": {"color": "#ffffff", "fontSize": "36px", "marginBottom": "20px", "textAlign": "center"}},
                {"id": "w_contact_text", "type": "text", "content": {"text": "Contact us today for a free consultation"}, "style": {"color": "#bfdbfe", "fontSize": "18px", "textAlign": "center", "marginBottom": "30px"}},
                {"id": "w_contact_button", "type": "button", "content": {"text": "Contact Us"}, "style": {"backgroundColor": "#3b82f6", "color": "#ffffff", "padding": "14px 28px", "borderRadius": "8px", "fontSize": "16px"}}
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
              "id": "col_hero_left",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Build Better Products, Faster", "level": 1}, "style": {"color": "#ffffff", "fontSize": "52px", "fontWeight": "bold", "marginBottom": "20px"}},
                {"id": "w_text", "type": "text", "content": {"text": "The all-in-one platform for teams who ship. Streamline your workflow, collaborate seamlessly, and deliver exceptional results."}, "style": {"color": "#e9d5ff", "fontSize": "20px", "marginBottom": "30px", "lineHeight": "1.6"}},
                {"id": "w_button_1", "type": "button", "content": {"text": "Start Free Trial"}, "style": {"backgroundColor": "#ffffff", "color": "#7c3aed", "padding": "14px 28px", "borderRadius": "8px", "fontSize": "16px", "marginRight": "12px"}},
                {"id": "w_button_2", "type": "button", "content": {"text": "Watch Demo"}, "style": {"backgroundColor": "transparent", "color": "#ffffff", "padding": "14px 28px", "borderRadius": "8px", "fontSize": "16px", "border": "2px solid #ffffff"}}
              ]
            },
            {
              "id": "col_hero_right",
              "style": {},
              "widgets": [
                {"id": "w_image", "type": "image", "content": {"src": "https://via.placeholder.com/600x400/8b5cf6/ffffff?text=Product+Dashboard", "alt": "Product dashboard screenshot"}, "style": {"borderRadius": "12px", "boxShadow": "0 20px 40px rgba(0,0,0,0.2)"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_social_proof",
      "style": {"backgroundColor": "#ffffff", "padding": "60px 20px"},
      "rows": [
        {
          "id": "row_social_proof",
          "style": {},
          "columns": [
            {
              "id": "col_social_proof",
              "style": {},
              "widgets": [
                {"id": "w_social_heading", "type": "heading", "content": {"text": "Trusted By Teams Worldwide", "level": 2}, "style": {"color": "#5b21b6", "fontSize": "28px", "marginBottom": "30px", "textAlign": "center"}},
                {"id": "w_social_logos", "type": "text", "content": {"text": "⬜ ⬜ ⬜ ⬜ ⬜ ⬜"}, "style": {"fontSize": "32px", "textAlign": "center", "letterSpacing": "20px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_features",
      "style": {"backgroundColor": "#f5f3ff", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_features_heading",
          "style": {},
          "columns": [
            {
              "id": "col_features_heading",
              "style": {},
              "widgets": [
                {"id": "w_features_heading", "type": "heading", "content": {"text": "Why Teams Choose Us", "level": 2}, "style": {"color": "#5b21b6", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_features_grid",
          "style": {},
          "columns": [
            {
              "id": "col_feature_1",
              "style": {},
              "widgets": [
                {"id": "w_feature_1_icon", "type": "text", "content": {"text": "⚡"}, "style": {"fontSize": "48px", "textAlign": "center", "marginBottom": "16px"}},
                {"id": "w_feature_1_title", "type": "heading", "content": {"text": "Lightning Fast", "level": 3}, "style": {"color": "#5b21b6", "fontSize": "20px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_feature_1_desc", "type": "text", "content": {"text": "Deploy in seconds, not hours. Our optimized infrastructure ensures maximum performance."}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            },
            {
              "id": "col_feature_2",
              "style": {},
              "widgets": [
                {"id": "w_feature_2_icon", "type": "text", "content": {"text": "🔒"}, "style": {"fontSize": "48px", "textAlign": "center", "marginBottom": "16px"}},
                {"id": "w_feature_2_title", "type": "heading", "content": {"text": "Enterprise Security", "level": 3}, "style": {"color": "#5b21b6", "fontSize": "20px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_feature_2_desc", "type": "text", "content": {"text": "Bank-level encryption and compliance with industry security standards."}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            },
            {
              "id": "col_feature_3",
              "style": {},
              "widgets": [
                {"id": "w_feature_3_icon", "type": "text", "content": {"text": "🔄"}, "style": {"fontSize": "48px", "textAlign": "center", "marginBottom": "16px"}},
                {"id": "w_feature_3_title", "type": "heading", "content": {"text": "Real-time Sync", "level": 3}, "style": {"color": "#5b21b6", "fontSize": "20px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_feature_3_desc", "type": "text", "content": {"text": "Collaborate seamlessly with instant updates across all team members."}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            },
            {
              "id": "col_feature_4",
              "style": {},
              "widgets": [
                {"id": "w_feature_4_icon", "type": "text", "content": {"text": "📊"}, "style": {"fontSize": "48px", "textAlign": "center", "marginBottom": "16px"}},
                {"id": "w_feature_4_title", "type": "heading", "content": {"text": "Advanced Analytics", "level": 3}, "style": {"color": "#5b21b6", "fontSize": "20px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_feature_4_desc", "type": "text", "content": {"text": "Gain insights with powerful analytics and customizable dashboards."}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_pricing",
      "style": {"backgroundColor": "#ffffff", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_pricing_heading",
          "style": {},
          "columns": [
            {
              "id": "col_pricing_heading",
              "style": {},
              "widgets": [
                {"id": "w_pricing_heading", "type": "heading", "content": {"text": "Simple, Transparent Pricing", "level": 2}, "style": {"color": "#5b21b6", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_pricing_grid",
          "style": {},
          "columns": [
            {
              "id": "col_pricing_1",
              "style": {},
              "widgets": [
                {"id": "w_pricing_1_title", "type": "heading", "content": {"text": "Starter", "level": 3}, "style": {"color": "#5b21b6", "fontSize": "24px", "marginBottom": "8px", "textAlign": "center"}},
                {"id": "w_pricing_1_price", "type": "heading", "content": {"text": "$29", "level": 2}, "style": {"color": "#7c3aed", "fontSize": "48px", "fontWeight": "bold", "textAlign": "center", "marginBottom": "20px"}},
                {"id": "w_pricing_1_features", "type": "text", "content": {"text": "✓ 5 team members\n✓ 10 projects\n✓ Basic analytics\n✓ Email support"}, "style": {"color": "#64748b", "fontSize": "14px", "lineHeight": "2", "marginBottom": "20px"}},
                {"id": "w_pricing_1_button", "type": "button", "content": {"text": "Choose Plan"}, "style": {"backgroundColor": "#7c3aed", "color": "#ffffff", "padding": "12px 24px", "borderRadius": "8px", "width": "100%"}}
              ]
            },
            {
              "id": "col_pricing_2",
              "style": {},
              "widgets": [
                {"id": "w_pricing_2_title", "type": "heading", "content": {"text": "Professional", "level": 3}, "style": {"color": "#5b21b6", "fontSize": "24px", "marginBottom": "8px", "textAlign": "center"}},
                {"id": "w_pricing_2_price", "type": "heading", "content": {"text": "$79", "level": 2}, "style": {"color": "#7c3aed", "fontSize": "48px", "fontWeight": "bold", "textAlign": "center", "marginBottom": "20px"}},
                {"id": "w_pricing_2_features", "type": "text", "content": {"text": "✓ 20 team members\n✓ Unlimited projects\n✓ Advanced analytics\n✓ Priority support\n✓ Custom integrations"}, "style": {"color": "#64748b", "fontSize": "14px", "lineHeight": "2", "marginBottom": "20px"}},
                {"id": "w_pricing_2_button", "type": "button", "content": {"text": "Choose Plan"}, "style": {"backgroundColor": "#7c3aed", "color": "#ffffff", "padding": "12px 24px", "borderRadius": "8px", "width": "100%"}}
              ]
            },
            {
              "id": "col_pricing_3",
              "style": {},
              "widgets": [
                {"id": "w_pricing_3_title", "type": "heading", "content": {"text": "Enterprise", "level": 3}, "style": {"color": "#5b21b6", "fontSize": "24px", "marginBottom": "8px", "textAlign": "center"}},
                {"id": "w_pricing_3_price", "type": "heading", "content": {"text": "Custom", "level": 2}, "style": {"color": "#7c3aed", "fontSize": "48px", "fontWeight": "bold", "textAlign": "center", "marginBottom": "20px"}},
                {"id": "w_pricing_3_features", "type": "text", "content": {"text": "✓ Unlimited team members\n✓ Unlimited projects\n✓ Enterprise analytics\n✓ 24/7 support\n✓ Dedicated account manager"}, "style": {"color": "#64748b", "fontSize": "14px", "lineHeight": "2", "marginBottom": "20px"}},
                {"id": "w_pricing_3_button", "type": "button", "content": {"text": "Contact Sales"}, "style": {"backgroundColor": "#7c3aed", "color": "#ffffff", "padding": "12px 24px", "borderRadius": "8px", "width": "100%"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_cta",
      "style": {"backgroundColor": "#7c3aed", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_cta",
          "style": {},
          "columns": [
            {
              "id": "col_cta",
              "style": {},
              "widgets": [
                {"id": "w_cta_heading", "type": "heading", "content": {"text": "Ready to Get Started?", "level": 2}, "style": {"color": "#ffffff", "fontSize": "40px", "marginBottom": "20px", "textAlign": "center"}},
                {"id": "w_cta_text", "type": "text", "content": {"text": "Join thousands of teams already using our platform"}, "style": {"color": "#e9d5ff", "fontSize": "18px", "textAlign": "center", "marginBottom": "30px"}},
                {"id": "w_cta_button", "type": "button", "content": {"text": "Sign Up Free"}, "style": {"backgroundColor": "#ffffff", "color": "#7c3aed", "padding": "16px 32px", "borderRadius": "8px", "fontSize": "18px"}}
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
      "style": {"backgroundColor": "#78350f", "padding": "120px 20px", "backgroundImage": "url(https://via.placeholder.com/1920x600/78350f/ffffff?text=Restaurant+Ambience)", "backgroundSize": "cover", "backgroundPosition": "center"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "The Golden Fork", "level": 1}, "style": {"color": "#fef3c7", "fontSize": "56px", "fontWeight": "bold", "marginBottom": "16px", "textAlign": "center", "textShadow": "2px 2px 4px rgba(0,0,0,0.5)"}},
                {"id": "w_text", "type": "text", "content": {"text": "Where culinary artistry meets timeless elegance"}, "style": {"color": "#fde68a", "fontSize": "22px", "marginBottom": "32px", "textAlign": "center", "textShadow": "1px 1px 2px rgba(0,0,0,0.5)"}},
                {"id": "w_button", "type": "button", "content": {"text": "Reserve a Table"}, "style": {"backgroundColor": "#f59e0b", "color": "#78350f", "padding": "16px 32px", "borderRadius": "8px", "fontSize": "18px", "fontWeight": "bold"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_menu_highlights",
      "style": {"backgroundColor": "#fffbeb", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_menu_heading",
          "style": {},
          "columns": [
            {
              "id": "col_menu_heading",
              "style": {},
              "widgets": [
                {"id": "w_menu_heading", "type": "heading", "content": {"text": "Our Menu Highlights", "level": 2}, "style": {"color": "#78350f", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_menu_grid",
          "style": {},
          "columns": [
            {
              "id": "col_dish_1",
              "style": {},
              "widgets": [
                {"id": "w_dish_1_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x300/f59e0b/ffffff?text=Dish+1", "alt": "Dish photo"}, "style": {"borderRadius": "12px", "marginBottom": "16px"}},
                {"id": "w_dish_1_name", "type": "heading", "content": {"text": "Grilled Salmon", "level": 3}, "style": {"color": "#78350f", "fontSize": "20px", "marginBottom": "8px"}},
                {"id": "w_dish_1_desc", "type": "text", "content": {"text": "Fresh Atlantic salmon with lemon butter sauce"}, "style": {"color": "#92400e", "fontSize": "14px", "marginBottom": "8px"}},
                {"id": "w_dish_1_price", "type": "text", "content": {"text": "$32"}, "style": {"color": "#f59e0b", "fontSize": "18px", "fontWeight": "bold"}}
              ]
            },
            {
              "id": "col_dish_2",
              "style": {},
              "widgets": [
                {"id": "w_dish_2_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x300/d97706/ffffff?text=Dish+2", "alt": "Dish photo"}, "style": {"borderRadius": "12px", "marginBottom": "16px"}},
                {"id": "w_dish_2_name", "type": "heading", "content": {"text": "Filet Mignon", "level": 3}, "style": {"color": "#78350f", "fontSize": "20px", "marginBottom": "8px"}},
                {"id": "w_dish_2_desc", "type": "text", "content": {"text": "Prime cut with truffle mashed potatoes"}, "style": {"color": "#92400e", "fontSize": "14px", "marginBottom": "8px"}},
                {"id": "w_dish_2_price", "type": "text", "content": {"text": "$45"}, "style": {"color": "#f59e0b", "fontSize": "18px", "fontWeight": "bold"}}
              ]
            },
            {
              "id": "col_dish_3",
              "style": {},
              "widgets": [
                {"id": "w_dish_3_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x300/b45309/ffffff?text=Dish+3", "alt": "Dish photo"}, "style": {"borderRadius": "12px", "marginBottom": "16px"}},
                {"id": "w_dish_3_name", "type": "heading", "content": {"text": "Lobster Thermidor", "level": 3}, "style": {"color": "#78350f", "fontSize": "20px", "marginBottom": "8px"}},
                {"id": "w_dish_3_desc", "type": "text", "content": {"text": "Classic French preparation with herbs"}, "style": {"color": "#92400e", "fontSize": "14px", "marginBottom": "8px"}},
                {"id": "w_dish_3_price", "type": "text", "content": {"text": "$58"}, "style": {"color": "#f59e0b", "fontSize": "18px", "fontWeight": "bold"}}
              ]
            },
            {
              "id": "col_dish_4",
              "style": {},
              "widgets": [
                {"id": "w_dish_4_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x300/92400e/ffffff?text=Dish+4", "alt": "Dish photo"}, "style": {"borderRadius": "12px", "marginBottom": "16px"}},
                {"id": "w_dish_4_name", "type": "heading", "content": {"text": "Chocolate Soufflé", "level": 3}, "style": {"color": "#78350f", "fontSize": "20px", "marginBottom": "8px"}},
                {"id": "w_dish_4_desc", "type": "text", "content": {"text": "Warm dessert with vanilla ice cream"}, "style": {"color": "#92400e", "fontSize": "14px", "marginBottom": "8px"}},
                {"id": "w_dish_4_price", "type": "text", "content": {"text": "$18"}, "style": {"color": "#f59e0b", "fontSize": "18px", "fontWeight": "bold"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_story",
      "style": {"backgroundColor": "#ffffff", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_story",
          "style": {},
          "columns": [
            {
              "id": "col_story_left",
              "style": {},
              "widgets": [
                {"id": "w_story_img", "type": "image", "content": {"src": "https://via.placeholder.com/500x400/78350f/ffffff?text=Our+Story", "alt": "Restaurant interior"}, "style": {"borderRadius": "12px"}}
              ]
            },
            {
              "id": "col_story_right",
              "style": {},
              "widgets": [
                {"id": "w_story_heading", "type": "heading", "content": {"text": "Our Story", "level": 2}, "style": {"color": "#78350f", "fontSize": "32px", "marginBottom": "20px"}},
                {"id": "w_story_text", "type": "text", "content": {"text": "Founded in 1985, The Golden Fork has been a cornerstone of fine dining for over three decades. Our commitment to using only the freshest, locally-sourced ingredients has made us a beloved destination for food enthusiasts from around the world."}, "style": {"color": "#92400e", "fontSize": "16px", "lineHeight": "1.6"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_gallery",
      "style": {"backgroundColor": "#fffbeb", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_gallery_heading",
          "style": {},
          "columns": [
            {
              "id": "col_gallery_heading",
              "style": {},
              "widgets": [
                {"id": "w_gallery_heading", "type": "heading", "content": {"text": "Gallery", "level": 2}, "style": {"color": "#78350f", "fontSize": "36px", "marginBottom": "40px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_gallery_grid",
          "style": {},
          "columns": [
            {
              "id": "col_gallery_1",
              "style": {},
              "widgets": [
                {"id": "w_gallery_1", "type": "image", "content": {"src": "https://via.placeholder.com/300x300/f59e0b/ffffff?text=Gallery+1", "alt": "Gallery photo"}, "style": {"borderRadius": "8px"}}
              ]
            },
            {
              "id": "col_gallery_2",
              "style": {},
              "widgets": [
                {"id": "w_gallery_2", "type": "image", "content": {"src": "https://via.placeholder.com/300x300/d97706/ffffff?text=Gallery+2", "alt": "Gallery photo"}, "style": {"borderRadius": "8px"}}
              ]
            },
            {
              "id": "col_gallery_3",
              "style": {},
              "widgets": [
                {"id": "w_gallery_3", "type": "image", "content": {"src": "https://via.placeholder.com/300x300/b45309/ffffff?text=Gallery+3", "alt": "Gallery photo"}, "style": {"borderRadius": "8px"}}
              ]
            },
            {
              "id": "col_gallery_4",
              "style": {},
              "widgets": [
                {"id": "w_gallery_4", "type": "image", "content": {"src": "https://via.placeholder.com/300x300/92400e/ffffff?text=Gallery+4", "alt": "Gallery photo"}, "style": {"borderRadius": "8px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_reservation",
      "style": {"backgroundColor": "#78350f", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_reservation",
          "style": {},
          "columns": [
            {
              "id": "col_reservation",
              "style": {},
              "widgets": [
                {"id": "w_reservation_heading", "type": "heading", "content": {"text": "Book Your Table", "level": 2}, "style": {"color": "#fef3c7", "fontSize": "36px", "marginBottom": "20px", "textAlign": "center"}},
                {"id": "w_reservation_text", "type": "text", "content": {"text": "Open Tuesday - Sunday, 6PM - 11PM"}, "style": {"color": "#fde68a", "fontSize": "16px", "textAlign": "center", "marginBottom": "30px"}},
                {"id": "w_reservation_button", "type": "button", "content": {"text": "Reserve Now"}, "style": {"backgroundColor": "#f59e0b", "color": "#78350f", "padding": "16px 32px", "borderRadius": "8px", "fontSize": "18px"}}
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
      "id": "section_header",
      "style": {"backgroundColor": "#ffffff", "padding": "60px 20px", "borderBottom": "1px solid #e5e7eb"},
      "rows": [
        {
          "id": "row_header",
          "style": {},
          "columns": [
            {
              "id": "col_header",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "The Daily Perspective", "level": 1}, "style": {"color": "#1e293b", "fontSize": "42px", "fontWeight": "bold", "marginBottom": "12px"}},
                {"id": "w_text", "type": "text", "content": {"text": "Thoughts on technology, design, and the future of work"}, "style": {"color": "#64748b", "fontSize": "18px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_featured",
      "style": {"backgroundColor": "#f8fafc", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_featured",
          "style": {},
          "columns": [
            {
              "id": "col_featured_left",
              "style": {},
              "widgets": [
                {"id": "w_featured_img", "type": "image", "content": {"src": "https://via.placeholder.com/600x400/3b82f6/ffffff?text=Featured+Article", "alt": "Featured article image"}, "style": {"borderRadius": "12px"}}
              ]
            },
            {
              "id": "col_featured_right",
              "style": {},
              "widgets": [
                {"id": "w_featured_tag", "type": "text", "content": {"text": "FEATURED"}, "style": {"color": "#3b82f6", "fontSize": "12px", "fontWeight": "bold", "letterSpacing": "1px", "marginBottom": "12px"}},
                {"id": "w_featured_title", "type": "heading", "content": {"text": "The Future of Remote Work: What We Learned in 2024", "level": 2}, "style": {"color": "#1e293b", "fontSize": "28px", "marginBottom": "16px"}},
                {"id": "w_featured_excerpt", "type": "text", "content": {"text": "An in-depth analysis of how distributed teams are reshaping the modern workplace and what it means for the future of collaboration."}, "style": {"color": "#64748b", "fontSize": "16px", "lineHeight": "1.6", "marginBottom": "20px"}},
                {"id": "w_featured_button", "type": "button", "content": {"text": "Read More"}, "style": {"backgroundColor": "#3b82f6", "color": "#ffffff", "padding": "12px 24px", "borderRadius": "6px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_recent",
      "style": {"backgroundColor": "#ffffff", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_recent_heading",
          "style": {},
          "columns": [
            {
              "id": "col_recent_heading",
              "style": {},
              "widgets": [
                {"id": "w_recent_heading", "type": "heading", "content": {"text": "Recent Articles", "level": 2}, "style": {"color": "#1e293b", "fontSize": "32px", "marginBottom": "40px"}}
              ]
            }
          ]
        },
        {
          "id": "row_recent_grid",
          "style": {},
          "columns": [
            {
              "id": "col_article_1",
              "style": {},
              "widgets": [
                {"id": "w_article_1_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x250/8b5cf6/ffffff?text=Article+1", "alt": "Article thumbnail"}, "style": {"borderRadius": "8px", "marginBottom": "16px"}},
                {"id": "w_article_1_tag", "type": "text", "content": {"text": "TECHNOLOGY"}, "style": {"color": "#8b5cf6", "fontSize": "11px", "fontWeight": "bold", "letterSpacing": "1px", "marginBottom": "8px"}},
                {"id": "w_article_1_title", "type": "heading", "content": {"text": "Building Scalable Systems", "level": 3}, "style": {"color": "#1e293b", "fontSize": "20px", "marginBottom": "8px"}},
                {"id": "w_article_1_excerpt", "type": "text", "content": {"text": "Lessons from scaling a startup to millions of users"}, "style": {"color": "#64748b", "fontSize": "14px", "marginBottom": "12px"}},
                {"id": "w_article_1_link", "type": "button", "content": {"text": "Read More"}, "style": {"backgroundColor": "transparent", "color": "#3b82f6", "padding": "8px 0", "borderRadius": "4px", "fontSize": "14px"}}
              ]
            },
            {
              "id": "col_article_2",
              "style": {},
              "widgets": [
                {"id": "w_article_2_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x256/10b981/ffffff?text=Article+2", "alt": "Article thumbnail"}, "style": {"borderRadius": "8px", "marginBottom": "16px"}},
                {"id": "w_article_2_tag", "type": "text", "content": {"text": "DESIGN"}, "style": {"color": "#10b981", "fontSize": "11px", "fontWeight": "bold", "letterSpacing": "1px", "marginBottom": "8px"}},
                {"id": "w_article_2_title", "type": "heading", "content": {"text": "The Psychology of Color", "level": 3}, "style": {"color": "#1e293b", "fontSize": "20px", "marginBottom": "8px"}},
                {"id": "w_article_2_excerpt", "type": "text", "content": {"text": "How color choices affect user behavior and conversion"}, "style": {"color": "#64748b", "fontSize": "14px", "marginBottom": "12px"}},
                {"id": "w_article_2_link", "type": "button", "content": {"text": "Read More"}, "style": {"backgroundColor": "transparent", "color": "#3b82f6", "padding": "8px 0", "borderRadius": "4px", "fontSize": "14px"}}
              ]
            },
            {
              "id": "col_article_3",
              "style": {},
              "widgets": [
                {"id": "w_article_3_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x250/f59e0b/ffffff?text=Article+3", "alt": "Article thumbnail"}, "style": {"borderRadius": "8px", "marginBottom": "16px"}},
                {"id": "w_article_3_tag", "type": "text", "content": {"text": "PRODUCTIVITY"}, "style": {"color": "#f59e0b", "fontSize": "11px", "fontWeight": "bold", "letterSpacing": "1px", "marginBottom": "8px"}},
                {"id": "w_article_3_title", "type": "heading", "content": {"text": "Deep Work in a Distracted World", "level": 3}, "style": {"color": "#1e293b", "fontSize": "20px", "marginBottom": "8px"}},
                {"id": "w_article_3_excerpt", "type": "text", "content": {"text": "Strategies for maintaining focus in the age of notifications"}, "style": {"color": "#64748b", "fontSize": "14px", "marginBottom": "12px"}},
                {"id": "w_article_3_link", "type": "button", "content": {"text": "Read More"}, "style": {"backgroundColor": "transparent", "color": "#3b82f6", "padding": "8px 0", "borderRadius": "4px", "fontSize": "14px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_author",
      "style": {"backgroundColor": "#f8fafc", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_author",
          "style": {},
          "columns": [
            {
              "id": "col_author_left",
              "style": {},
              "widgets": [
                {"id": "w_author_img", "type": "image", "content": {"src": "https://via.placeholder.com/200x200/3b82f6/ffffff?text=Author", "alt": "Author avatar"}, "style": {"borderRadius": "50%"}}
              ]
            },
            {
              "id": "col_author_right",
              "style": {},
              "widgets": [
                {"id": "w_author_heading", "type": "heading", "content": {"text": "About the Author", "level": 2}, "style": {"color": "#1e293b", "fontSize": "24px", "marginBottom": "12px"}},
                {"id": "w_author_name", "type": "text", "content": {"text": "Written by Alex Thompson"}, "style": {"color": "#64748b", "fontSize": "16px", "marginBottom": "12px"}},
                {"id": "w_author_bio", "type": "text", "content": {"text": "Alex is a product designer and writer based in San Francisco. With over 10 years of experience in tech, he shares insights on design, productivity, and the future of work."}, "style": {"color": "#475569", "fontSize": "14px", "lineHeight": "1.6"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_newsletter",
      "style": {"backgroundColor": "#1e293b", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_newsletter",
          "style": {},
          "columns": [
            {
              "id": "col_newsletter",
              "style": {},
              "widgets": [
                {"id": "w_newsletter_heading", "type": "heading", "content": {"text": "Subscribe to Our Newsletter", "level": 2}, "style": {"color": "#ffffff", "fontSize": "32px", "marginBottom": "16px", "textAlign": "center"}},
                {"id": "w_newsletter_text", "type": "text", "content": {"text": "Get the latest articles delivered straight to your inbox"}, "style": {"color": "#94a3b8", "fontSize": "16px", "textAlign": "center", "marginBottom": "30px"}},
                {"id": "w_newsletter_button", "type": "button", "content": {"text": "Subscribe"}, "style": {"backgroundColor": "#3b82f6", "color": "#ffffff", "padding": "14px 28px", "borderRadius": "8px", "fontSize": "16px"}}
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
                {"id": "w_heading", "type": "heading", "content": {"text": "We Create Digital Experiences That Matter", "level": 1}, "style": {"color": "#ffffff", "fontSize": "56px", "fontWeight": "bold", "marginBottom": "20px", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "Bold design. Strategic thinking. Results that speak for themselves."}, "style": {"color": "#a1a1aa", "fontSize": "20px", "marginBottom": "32px", "textAlign": "center"}},
                {"id": "w_button", "type": "button", "content": {"text": "See Our Work"}, "style": {"backgroundColor": "#ec4899", "color": "#ffffff", "padding": "16px 32px", "borderRadius": "8px", "fontSize": "18px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_services",
      "style": {"backgroundColor": "#ffffff", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_services_heading",
          "style": {},
          "columns": [
            {
              "id": "col_services_heading",
              "style": {},
              "widgets": [
                {"id": "w_services_heading", "type": "heading", "content": {"text": "What We Do", "level": 2}, "style": {"color": "#000000", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_services_grid",
          "style": {},
          "columns": [
            {
              "id": "col_service_1",
              "style": {},
              "widgets": [
                {"id": "w_service_1_title", "type": "heading", "content": {"text": "Branding", "level": 3}, "style": {"color": "#000000", "fontSize": "24px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_service_1_desc", "type": "text", "content": {"text": "Identity systems that tell your story"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            },
            {
              "id": "col_service_2",
              "style": {},
              "widgets": [
                {"id": "w_service_2_title", "type": "heading", "content": {"text": "Web Design", "level": 3}, "style": {"color": "#000000", "fontSize": "24px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_service_2_desc", "type": "text", "content": {"text": "Digital experiences that convert"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            },
            {
              "id": "col_service_3",
              "style": {},
              "widgets": [
                {"id": "w_service_3_title", "type": "heading", "content": {"text": "Marketing", "level": 3}, "style": {"color": "#000000", "fontSize": "24px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_service_3_desc", "type": "text", "content": {"text": "Campaigns that drive growth"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            },
            {
              "id": "col_service_4",
              "style": {},
              "widgets": [
                {"id": "w_service_4_title", "type": "heading", "content": {"text": "Strategy", "level": 3}, "style": {"color": "#000000", "fontSize": "24px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_service_4_desc", "type": "text", "content": {"text": "Data-driven insights for success"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_work",
      "style": {"backgroundColor": "#18181b", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_work_heading",
          "style": {},
          "columns": [
            {
              "id": "col_work_heading",
              "style": {},
              "widgets": [
                {"id": "w_work_heading", "type": "heading", "content": {"text": "Our Work", "level": 2}, "style": {"color": "#ffffff", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_work_grid",
          "style": {},
          "columns": [
            {
              "id": "col_project_1",
              "style": {},
              "widgets": [
                {"id": "w_project_1_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x300/ec4899/ffffff?text=Project+1", "alt": "Project thumbnail"}, "style": {"borderRadius": "12px", "marginBottom": "16px"}},
                {"id": "w_project_1_client", "type": "text", "content": {"text": "TechCorp"}, "style": {"color": "#a1a1aa", "fontSize": "12px", "marginBottom": "8px"}},
                {"id": "w_project_1_type", "type": "heading", "content": {"text": "Brand Identity", "level": 3}, "style": {"color": "#ffffff", "fontSize": "18px"}}
              ]
            },
            {
              "id": "col_project_2",
              "style": {},
              "widgets": [
                {"id": "w_project_2_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x300/8b5cf6/ffffff?text=Project+2", "alt": "Project thumbnail"}, "style": {"borderRadius": "12px", "marginBottom": "16px"}},
                {"id": "w_project_2_client", "type": "text", "content": {"text": "StartupXYZ"}, "style": {"color": "#a1a1aa", "fontSize": "12px", "marginBottom": "8px"}},
                {"id": "w_project_2_type", "type": "heading", "content": {"text": "Web Design", "level": 3}, "style": {"color": "#ffffff", "fontSize": "18px"}}
              ]
            },
            {
              "id": "col_project_3",
              "style": {},
              "widgets": [
                {"id": "w_project_3_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x300/3b82f6/ffffff?text=Project+3", "alt": "Project thumbnail"}, "style": {"borderRadius": "12px", "marginBottom": "16px"}},
                {"id": "w_project_3_client", "type": "text", "content": {"text": "RetailPlus"}, "style": {"color": "#a1a1aa", "fontSize": "12px", "marginBottom": "8px"}},
                {"id": "w_project_3_type", "type": "heading", "content": {"text": "Marketing Campaign", "level": 3}, "style": {"color": "#ffffff", "fontSize": "18px"}}
              ]
            },
            {
              "id": "col_project_4",
              "style": {},
              "widgets": [
                {"id": "w_project_4_img", "type": "image", "content": {"src": "https://via.placeholder.com/400x300/10b981/ffffff?text=Project+4", "alt": "Project thumbnail"}, "style": {"borderRadius": "12px", "marginBottom": "16px"}},
                {"id": "w_project_4_client", "type": "text", "content": {"text": "FinanceHub"}, "style": {"color": "#a1a1aa", "fontSize": "12px", "marginBottom": "8px"}},
                {"id": "w_project_4_type", "type": "heading", "content": {"text": "Digital Strategy", "level": 3}, "style": {"color": "#ffffff", "fontSize": "18px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_team",
      "style": {"backgroundColor": "#ffffff", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_team_heading",
          "style": {},
          "columns": [
            {
              "id": "col_team_heading",
              "style": {},
              "widgets": [
                {"id": "w_team_heading", "type": "heading", "content": {"text": "Meet the Team", "level": 2}, "style": {"color": "#000000", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_team_grid",
          "style": {},
          "columns": [
            {
              "id": "col_team_1",
              "style": {},
              "widgets": [
                {"id": "w_team_1_img", "type": "image", "content": {"src": "https://via.placeholder.com/200x200/ec4899/ffffff?text=Team+1", "alt": "Team member photo"}, "style": {"borderRadius": "50%", "marginBottom": "16px"}},
                {"id": "w_team_1_name", "type": "heading", "content": {"text": "Jordan Lee", "level": 3}, "style": {"color": "#000000", "fontSize": "18px", "marginBottom": "4px", "textAlign": "center"}},
                {"id": "w_team_1_role", "type": "text", "content": {"text": "Creative Director"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center"}}
              ]
            },
            {
              "id": "col_team_2",
              "style": {},
              "widgets": [
                {"id": "w_team_2_img", "type": "image", "content": {"src": "https://via.placeholder.com/200x200/8b5cf6/ffffff?text=Team+2", "alt": "Team member photo"}, "style": {"borderRadius": "50%", "marginBottom": "16px"}},
                {"id": "w_team_2_name", "type": "heading", "content": {"text": "Sam Rivera", "level": 3}, "style": {"color": "#000000", "fontSize": "18px", "marginBottom": "4px", "textAlign": "center"}},
                {"id": "w_team_2_role", "type": "text", "content": {"text": "Lead Designer"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center"}}
              ]
            },
            {
              "id": "col_team_3",
              "style": {},
              "widgets": [
                {"id": "w_team_3_img", "type": "image", "content": {"src": "https://via.placeholder.com/200x200/3b82f6/ffffff?text=Team+3", "alt": "Team member photo"}, "style": {"borderRadius": "50%", "marginBottom": "16px"}},
                {"id": "w_team_3_name", "type": "heading", "content": {"text": "Taylor Kim", "level": 3}, "style": {"color": "#000000", "fontSize": "18px", "marginBottom": "4px", "textAlign": "center"}},
                {"id": "w_team_3_role", "type": "text", "content": {"text": "Strategy Lead"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center"}}
              ]
            },
            {
              "id": "col_team_4",
              "style": {},
              "widgets": [
                {"id": "w_team_4_img", "type": "image", "content": {"src": "https://via.placeholder.com/200x200/10b981/ffffff?text=Team+4", "alt": "Team member photo"}, "style": {"borderRadius": "50%", "marginBottom": "16px"}},
                {"id": "w_team_4_name", "type": "heading", "content": {"text": "Casey Morgan", "level": 3}, "style": {"color": "#000000", "fontSize": "18px", "marginBottom": "4px", "textAlign": "center"}},
                {"id": "w_team_4_role", "type": "text", "content": {"text": "Developer"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_contact",
      "style": {"backgroundColor": "#000000", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_contact",
          "style": {},
          "columns": [
            {
              "id": "col_contact",
              "style": {},
              "widgets": [
                {"id": "w_contact_heading", "type": "heading", "content": {"text": "Let's Create Something Great", "level": 2}, "style": {"color": "#ffffff", "fontSize": "40px", "marginBottom": "20px", "textAlign": "center"}},
                {"id": "w_contact_text", "type": "text", "content": {"text": "Ready to start your next project?"}, "style": {"color": "#a1a1aa", "fontSize": "18px", "textAlign": "center", "marginBottom": "30px"}},
                {"id": "w_contact_button", "type": "button", "content": {"text": "Start a Project"}, "style": {"backgroundColor": "#ec4899", "color": "#ffffff", "padding": "16px 32px", "borderRadius": "8px", "fontSize": "18px"}}
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
      "style": {"backgroundColor": "#dc2626", "padding": "120px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Tech Summit 2024", "level": 1}, "style": {"color": "#ffffff", "fontSize": "56px", "fontWeight": "bold", "marginBottom": "16px", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "November 15-17, 2024 • San Francisco Convention Center"}, "style": {"color": "#fecaca", "fontSize": "20px", "marginBottom": "32px", "textAlign": "center"}},
                {"id": "w_button", "type": "button", "content": {"text": "Register Now"}, "style": {"backgroundColor": "#ffffff", "color": "#dc2626", "padding": "16px 32px", "borderRadius": "8px", "fontSize": "18px", "fontWeight": "bold"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_about",
      "style": {"backgroundColor": "#ffffff", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_about",
          "style": {},
          "columns": [
            {
              "id": "col_about",
              "style": {},
              "widgets": [
                {"id": "w_about_heading", "type": "heading", "content": {"text": "About the Event", "level": 2}, "style": {"color": "#991b1b", "fontSize": "36px", "marginBottom": "20px", "textAlign": "center"}},
                {"id": "w_about_text", "type": "text", "content": {"text": "Join industry leaders, innovators, and enthusiasts for three days of inspiring talks, hands-on workshops, and networking opportunities. Discover the latest trends in technology and connect with like-minded professionals from around the world."}, "style": {"color": "#475569", "fontSize": "16px", "lineHeight": "1.6", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_schedule",
      "style": {"backgroundColor": "#fef2f2", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_schedule_heading",
          "style": {},
          "columns": [
            {
              "id": "col_schedule_heading",
              "style": {},
              "widgets": [
                {"id": "w_schedule_heading", "type": "heading", "content": {"text": "Event Schedule", "level": 2}, "style": {"color": "#991b1b", "fontSize": "36px", "marginBottom": "40px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_schedule_items",
          "style": {},
          "columns": [
            {
              "id": "col_schedule",
              "style": {},
              "widgets": [
                {"id": "w_schedule_item_1", "type": "text", "content": {"text": "9:00 AM - Opening Keynote: The Future of AI"}, "style": {"color": "#7f1d1d", "fontSize": "16px", "marginBottom": "12px"}},
                {"id": "w_schedule_item_2", "type": "text", "content": {"text": "11:00 AM - Workshop: Building Scalable Systems"}, "style": {"color": "#7f1d1d", "fontSize": "16px", "marginBottom": "12px"}},
                {"id": "w_schedule_item_3", "type": "text", "content": {"text": "1:00 PM - Lunch & Networking"}, "style": {"color": "#7f1d1d", "fontSize": "16px", "marginBottom": "12px"}},
                {"id": "w_schedule_item_4", "type": "text", "content": {"text": "2:30 PM - Panel: Women in Tech"}, "style": {"color": "#7f1d1d", "fontSize": "16px", "marginBottom": "12px"}},
                {"id": "w_schedule_item_5", "type": "text", "content": {"text": "4:00 PM - Closing Remarks & Awards"}, "style": {"color": "#7f1d1d", "fontSize": "16px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_speakers",
      "style": {"backgroundColor": "#ffffff", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_speakers_heading",
          "style": {},
          "columns": [
            {
              "id": "col_speakers_heading",
              "style": {},
              "widgets": [
                {"id": "w_speakers_heading", "type": "heading", "content": {"text": "Featured Speakers", "level": 2}, "style": {"color": "#991b1b", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_speakers_grid",
          "style": {},
          "columns": [
            {
              "id": "col_speaker_1",
              "style": {},
              "widgets": [
                {"id": "w_speaker_1_img", "type": "image", "content": {"src": "https://via.placeholder.com/200x200/dc2626/ffffff?text=Speaker+1", "alt": "Speaker photo"}, "style": {"borderRadius": "50%", "marginBottom": "16px"}},
                {"id": "w_speaker_1_name", "type": "heading", "content": {"text": "Dr. Sarah Chen", "level": 3}, "style": {"color": "#991b1b", "fontSize": "18px", "marginBottom": "4px", "textAlign": "center"}},
                {"id": "w_speaker_1_title", "type": "text", "content": {"text": "AI Research Lead, TechCorp"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center"}}
              ]
            },
            {
              "id": "col_speaker_2",
              "style": {},
              "widgets": [
                {"id": "w_speaker_2_img", "type": "image", "content": {"src": "https://via.placeholder.com/200x200/ef4444/ffffff?text=Speaker+2", "alt": "Speaker photo"}, "style": {"borderRadius": "50%", "marginBottom": "16px"}},
                {"id": "w_speaker_2_name", "type": "heading", "content": {"text": "Marcus Johnson", "level": 3}, "style": {"color": "#991b1b", "fontSize": "18px", "marginBottom": "4px", "textAlign": "center"}},
                {"id": "w_speaker_2_title", "type": "text", "content": {"text": "Founder, StartupXYZ"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center"}}
              ]
            },
            {
              "id": "col_speaker_3",
              "style": {},
              "widgets": [
                {"id": "w_speaker_3_img", "type": "image", "content": {"src": "https://via.placeholder.com/200x200/f97316/ffffff?text=Speaker+3", "alt": "Speaker photo"}, "style": {"borderRadius": "50%", "marginBottom": "16px"}},
                {"id": "w_speaker_3_name", "type": "heading", "content": {"text": "Elena Rodriguez", "level": 3}, "style": {"color": "#991b1b", "fontSize": "18px", "marginBottom": "4px", "textAlign": "center"}},
                {"id": "w_speaker_3_title", "type": "text", "content": {"text": "CTO, CloudScale"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center"}}
              ]
            },
            {
              "id": "col_speaker_4",
              "style": {},
              "widgets": [
                {"id": "w_speaker_4_img", "type": "image", "content": {"src": "https://via.placeholder.com/200x200/ea580c/ffffff?text=Speaker+4", "alt": "Speaker photo"}, "style": {"borderRadius": "50%", "marginBottom": "16px"}},
                {"id": "w_speaker_4_name", "type": "heading", "content": {"text": "David Park", "level": 3}, "style": {"color": "#991b1b", "fontSize": "18px", "marginBottom": "4px", "textAlign": "center"}},
                {"id": "w_speaker_4_title", "type": "text", "content": {"text": "VP Engineering, DataFlow"}, "style": {"color": "#64748b", "fontSize": "14px", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_registration",
      "style": {"backgroundColor": "#dc2626", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_registration",
          "style": {},
          "columns": [
            {
              "id": "col_registration",
              "style": {},
              "widgets": [
                {"id": "w_registration_heading", "type": "heading", "content": {"text": "Reserve Your Spot", "level": 2}, "style": {"color": "#ffffff", "fontSize": "40px", "marginBottom": "20px", "textAlign": "center"}},
                {"id": "w_registration_text", "type": "text", "content": {"text": "Early bird pricing available until September 30th"}, "style": {"color": "#fecaca", "fontSize": "18px", "textAlign": "center", "marginBottom": "30px"}},
                {"id": "w_registration_button", "type": "button", "content": {"text": "Register Now"}, "style": {"backgroundColor": "#ffffff", "color": "#dc2626", "padding": "16px 32px", "borderRadius": "8px", "fontSize": "18px", "fontWeight": "bold"}}
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
      "style": {"backgroundColor": "#059669", "padding": "120px 20px"},
      "rows": [
        {
          "id": "row_hero",
          "style": {},
          "columns": [
            {
              "id": "col_hero",
              "style": {},
              "widgets": [
                {"id": "w_heading", "type": "heading", "content": {"text": "Together, We Can Make a Difference", "level": 1}, "style": {"color": "#ffffff", "fontSize": "52px", "fontWeight": "bold", "marginBottom": "20px", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "Join us in our mission to provide clean water, education, and healthcare to communities in need around the world."}, "style": {"color": "#d1fae5", "fontSize": "18px", "marginBottom": "32px", "textAlign": "center", "lineHeight": "1.6"}},
                {"id": "w_button", "type": "button", "content": {"text": "Donate Now"}, "style": {"backgroundColor": "#ffffff", "color": "#059669", "padding": "16px 32px", "borderRadius": "8px", "fontSize": "18px", "fontWeight": "bold"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_mission",
      "style": {"backgroundColor": "#ecfdf5", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_mission",
          "style": {},
          "columns": [
            {
              "id": "col_mission_left",
              "style": {},
              "widgets": [
                {"id": "w_mission_img", "type": "image", "content": {"src": "https://via.placeholder.com/500x400/059669/ffffff?text=Our+Mission", "alt": "Mission illustration"}, "style": {"borderRadius": "12px"}}
              ]
            },
            {
              "id": "col_mission_right",
              "style": {},
              "widgets": [
                {"id": "w_mission_heading", "type": "heading", "content": {"text": "Our Mission", "level": 2}, "style": {"color": "#065f46", "fontSize": "32px", "marginBottom": "20px"}},
                {"id": "w_mission_text", "type": "text", "content": {"text": "For over 20 years, we've been working tirelessly to create sustainable change in underserved communities. Our focus is on long-term solutions that empower individuals and build stronger, more resilient communities."}, "style": {"color": "#047857", "fontSize": "16px", "lineHeight": "1.6"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_impact",
      "style": {"backgroundColor": "#ffffff", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_impact_heading",
          "style": {},
          "columns": [
            {
              "id": "col_impact_heading",
              "style": {},
              "widgets": [
                {"id": "w_impact_heading", "type": "heading", "content": {"text": "Our Impact", "level": 2}, "style": {"color": "#065f46", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_impact_stats",
          "style": {},
          "columns": [
            {
              "id": "col_stat_1",
              "style": {},
              "widgets": [
                {"id": "w_stat_1_number", "type": "heading", "content": {"text": "10,000+", "level": 2}, "style": {"color": "#059669", "fontSize": "48px", "fontWeight": "bold", "textAlign": "center"}},
                {"id": "w_stat_1_label", "type": "text", "content": {"text": "Meals Provided"}, "style": {"color": "#047857", "fontSize": "16px", "textAlign": "center"}}
              ]
            },
            {
              "id": "col_stat_2",
              "style": {},
              "widgets": [
                {"id": "w_stat_2_number", "type": "heading", "content": {"text": "500", "level": 2}, "style": {"color": "#059669", "fontSize": "48px", "fontWeight": "bold", "textAlign": "center"}},
                {"id": "w_stat_2_label", "type": "text", "content": {"text": "Volunteers"}, "style": {"color": "#047857", "fontSize": "16px", "textAlign": "center"}}
              ]
            },
            {
              "id": "col_stat_3",
              "style": {},
              "widgets": [
                {"id": "w_stat_3_number", "type": "heading", "content": {"text": "25", "level": 2}, "style": {"color": "#059669", "fontSize": "48px", "fontWeight": "bold", "textAlign": "center"}},
                {"id": "w_stat_3_label", "type": "text", "content": {"text": "Communities Served"}, "style": {"color": "#047857", "fontSize": "16px", "textAlign": "center"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_get_involved",
      "style": {"backgroundColor": "#ecfdf5", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_get_involved_heading",
          "style": {},
          "columns": [
            {
              "id": "col_get_involved_heading",
              "style": {},
              "widgets": [
                {"id": "w_get_involved_heading", "type": "heading", "content": {"text": "Get Involved", "level": 2}, "style": {"color": "#065f46", "fontSize": "36px", "marginBottom": "50px", "textAlign": "center"}}
              ]
            }
          ]
        },
        {
          "id": "row_get_involved_grid",
          "style": {},
          "columns": [
            {
              "id": "col_involve_1",
              "style": {},
              "widgets": [
                {"id": "w_involve_1_icon", "type": "text", "content": {"text": "🤝"}, "style": {"fontSize": "48px", "textAlign": "center", "marginBottom": "16px"}},
                {"id": "w_involve_1_title", "type": "heading", "content": {"text": "Volunteer", "level": 3}, "style": {"color": "#065f46", "fontSize": "20px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_involve_1_desc", "type": "text", "content": {"text": "Join our team of dedicated volunteers making a difference"}, "style": {"color": "#047857", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            },
            {
              "id": "col_involve_2",
              "style": {},
              "widgets": [
                {"id": "w_involve_2_icon", "type": "text", "content": {"text": "💝"}, "style": {"fontSize": "48px", "textAlign": "center", "marginBottom": "16px"}},
                {"id": "w_involve_2_title", "type": "heading", "content": {"text": "Donate", "level": 3}, "style": {"color": "#065f46", "fontSize": "20px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_involve_2_desc", "type": "text", "content": {"text": "Your contribution helps us reach more people in need"}, "style": {"color": "#047857", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            },
            {
              "id": "col_involve_3",
              "style": {},
              "widgets": [
                {"id": "w_involve_3_icon", "type": "text", "content": {"text": "🤝"}, "style": {"fontSize": "48px", "textAlign": "center", "marginBottom": "16px"}},
                {"id": "w_involve_3_title", "type": "heading", "content": {"text": "Partner", "level": 3}, "style": {"color": "#065f46", "fontSize": "20px", "marginBottom": "12px", "textAlign": "center"}},
                {"id": "w_involve_3_desc", "type": "text", "content": {"text": "Partner with us to create lasting change in communities"}, "style": {"color": "#047857", "fontSize": "14px", "textAlign": "center", "lineHeight": "1.5"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_donation",
      "style": {"backgroundColor": "#059669", "padding": "100px 20px"},
      "rows": [
        {
          "id": "row_donation",
          "style": {},
          "columns": [
            {
              "id": "col_donation",
              "style": {},
              "widgets": [
                {"id": "w_donation_heading", "type": "heading", "content": {"text": "Make a Donation Today", "level": 2}, "style": {"color": "#ffffff", "fontSize": "40px", "marginBottom": "20px", "textAlign": "center"}},
                {"id": "w_donation_text", "type": "text", "content": {"text": "Every dollar makes a difference in someone's life"}, "style": {"color": "#d1fae5", "fontSize": "18px", "textAlign": "center", "marginBottom": "30px"}},
                {"id": "w_donation_button", "type": "button", "content": {"text": "Donate Now"}, "style": {"backgroundColor": "#ffffff", "color": "#059669", "padding": "16px 32px", "borderRadius": "8px", "fontSize": "18px", "fontWeight": "bold"}}
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
                {"id": "w_heading", "type": "heading", "content": {"text": "Something Big Is Coming", "level": 1}, "style": {"color": "#ffffff", "fontSize": "64px", "fontWeight": "bold", "marginBottom": "20px", "textAlign": "center"}},
                {"id": "w_text", "type": "text", "content": {"text": "We're building something revolutionary. Be the first to know when we launch."}, "style": {"color": "#c7d2fe", "fontSize": "20px", "marginBottom": "40px", "textAlign": "center", "lineHeight": "1.6"}},
                {"id": "w_button", "type": "button", "content": {"text": "Notify Me"}, "style": {"backgroundColor": "#ffffff", "color": "#4f46e5", "padding": "16px 32px", "borderRadius": "8px", "fontSize": "18px", "fontWeight": "bold"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_countdown",
      "style": {"backgroundColor": "#4338ca", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_countdown",
          "style": {},
          "columns": [
            {
              "id": "col_countdown",
              "style": {},
              "widgets": [
                {"id": "w_countdown_text", "type": "text", "content": {"text": "Launching in Q4 2024"}, "style": {"color": "#e0e7ff", "fontSize": "24px", "textAlign": "center", "fontWeight": "500"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_social",
      "style": {"backgroundColor": "#4f46e5", "padding": "60px 20px"},
      "rows": [
        {
          "id": "row_social",
          "style": {},
          "columns": [
            {
              "id": "col_social",
              "style": {},
              "widgets": [
                {"id": "w_social_text", "type": "text", "content": {"text": "Follow us for updates"}, "style": {"color": "#c7d2fe", "fontSize": "16px", "textAlign": "center", "marginBottom": "20px"}},
                {"id": "w_social_icons", "type": "text", "content": {"text": "📧 🐦 📸 💼"}, "style": {"fontSize": "32px", "textAlign": "center", "letterSpacing": "16px"}}
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
      "id": "section_banner",
      "style": {"backgroundColor": "#1e293b", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_banner",
          "style": {},
          "columns": [
            {
              "id": "col_banner",
              "style": {},
              "widgets": [
                {"id": "w_banner_heading", "type": "heading", "content": {"text": "Summer Sale — Up to 50% Off", "level": 1}, "style": {"color": "#ffffff", "fontSize": "48px", "fontWeight": "bold", "marginBottom": "16px", "textAlign": "center"}},
                {"id": "w_banner_text", "type": "text", "content": {"text": "Limited time offer on selected items"}, "style": {"color": "#94a3b8", "fontSize": "18px", "marginBottom": "24px", "textAlign": "center"}},
                {"id": "w_banner_button", "type": "button", "content": {"text": "Shop Now"}, "style": {"backgroundColor": "#f97316", "color": "#ffffff", "padding": "14px 28px", "borderRadius": "8px", "fontSize": "16px", "fontWeight": "bold"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_categories",
      "style": {"backgroundColor": "#ffffff", "padding": "60px 20px"},
      "rows": [
        {
          "id": "row_categories",
          "style": {},
          "columns": [
            {
              "id": "col_cat_1",
              "style": {},
              "widgets": [
                {"id": "w_cat_1_icon", "type": "text", "content": {"text": "💻"}, "style": {"fontSize": "40px", "textAlign": "center", "marginBottom": "8px"}},
                {"id": "w_cat_1_name", "type": "text", "content": {"text": "Electronics"}, "style": {"color": "#1e293b", "fontSize": "14px", "textAlign": "center", "fontWeight": "500"}}
              ]
            },
            {
              "id": "col_cat_2",
              "style": {},
              "widgets": [
                {"id": "w_cat_2_icon", "type": "text", "content": {"text": "👕"}, "style": {"fontSize": "40px", "textAlign": "center", "marginBottom": "8px"}},
                {"id": "w_cat_2_name", "type": "text", "content": {"text": "Clothing"}, "style": {"color": "#1e293b", "fontSize": "14px", "textAlign": "center", "fontWeight": "500"}}
              ]
            },
            {
              "id": "col_cat_3",
              "style": {},
              "widgets": [
                {"id": "w_cat_3_icon", "type": "text", "content": {"text": "🏠"}, "style": {"fontSize": "40px", "textAlign": "center", "marginBottom": "8px"}},
                {"id": "w_cat_3_name", "type": "text", "content": {"text": "Home"}, "style": {"color": "#1e293b", "fontSize": "14px", "textAlign": "center", "fontWeight": "500"}}
              ]
            },
            {
              "id": "col_cat_4",
              "style": {},
              "widgets": [
                {"id": "w_cat_4_icon", "type": "text", "content": {"text": "⚽"}, "style": {"fontSize": "40px", "textAlign": "center", "marginBottom": "8px"}},
                {"id": "w_cat_4_name", "type": "text", "content": {"text": "Sports"}, "style": {"color": "#1e293b", "fontSize": "14px", "textAlign": "center", "fontWeight": "500"}}
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
          "id": "row_products_heading",
          "style": {},
          "columns": [
            {
              "id": "col_products_heading",
              "style": {},
              "widgets": [
                {"id": "w_products_heading", "type": "heading", "content": {"text": "Featured Products", "level": 2}, "style": {"color": "#1e293b", "fontSize": "36px", "marginBottom": "40px"}}
              ]
            }
          ]
        },
        {
          "id": "row_products_grid",
          "style": {},
          "columns": [
            {
              "id": "col_product_1",
              "style": {},
              "widgets": [
                {"id": "w_product_1_img", "type": "image", "content": {"src": "https://via.placeholder.com/300x300/3b82f6/ffffff?text=Product+1", "alt": "Product image"}, "style": {"borderRadius": "8px", "marginBottom": "12px"}},
                {"id": "w_product_1_name", "type": "heading", "content": {"text": "Wireless Headphones", "level": 3}, "style": {"color": "#1e293b", "fontSize": "16px", "marginBottom": "4px"}},
                {"id": "w_product_1_rating", "type": "text", "content": {"text": "⭐⭐⭐⭐⭐ (4.8)"}, "style": {"color": "#f97316", "fontSize": "12px", "marginBottom": "4px"}},
                {"id": "w_product_1_price", "type": "text", "content": {"text": "$79.99"}, "style": {"color": "#1e293b", "fontSize": "18px", "fontWeight": "bold", "marginBottom": "8px"}},
                {"id": "w_product_1_button", "type": "button", "content": {"text": "Add to Cart"}, "style": {"backgroundColor": "#f97316", "color": "#ffffff", "padding": "8px 16px", "borderRadius": "6px", "fontSize": "14px"}}
              ]
            },
            {
              "id": "col_product_2",
              "style": {},
              "widgets": [
                {"id": "w_product_2_img", "type": "image", "content": {"src": "https://via.placeholder.com/300x300/8b5cf6/ffffff?text=Product+2", "alt": "Product image"}, "style": {"borderRadius": "8px", "marginBottom": "12px"}},
                {"id": "w_product_2_name", "type": "heading", "content": {"text": "Smart Watch Pro", "level": 3}, "style": {"color": "#1e293b", "fontSize": "16px", "marginBottom": "4px"}},
                {"id": "w_product_2_rating", "type": "text", "content": {"text": "⭐⭐⭐⭐⭐ (4.6)"}, "style": {"color": "#f97316", "fontSize": "12px", "marginBottom": "4px"}},
                {"id": "w_product_2_price", "type": "text", "content": {"text": "$199.99"}, "style": {"color": "#1e293b", "fontSize": "18px", "fontWeight": "bold", "marginBottom": "8px"}},
                {"id": "w_product_2_button", "type": "button", "content": {"text": "Add to Cart"}, "style": {"backgroundColor": "#f97316", "color": "#ffffff", "padding": "8px 16px", "borderRadius": "6px", "fontSize": "14px"}}
              ]
            },
            {
              "id": "col_product_3",
              "style": {},
              "widgets": [
                {"id": "w_product_3_img", "type": "image", "content": {"src": "https://via.placeholder.com/300x300/10b981/ffffff?text=Product+3", "alt": "Product image"}, "style": {"borderRadius": "8px", "marginBottom": "12px"}},
                {"id": "w_product_3_name", "type": "heading", "content": {"text": "Portable Speaker", "level": 3}, "style": {"color": "#1e293b", "fontSize": "16px", "marginBottom": "4px"}},
                {"id": "w_product_3_rating", "type": "text", "content": {"text": "⭐⭐⭐⭐ (4.3)"}, "style": {"color": "#f97316", "fontSize": "12px", "marginBottom": "4px"}},
                {"id": "w_product_3_price", "type": "text", "content": {"text": "$49.99"}, "style": {"color": "#1e293b", "fontSize": "18px", "fontWeight": "bold", "marginBottom": "8px"}},
                {"id": "w_product_3_button", "type": "button", "content": {"text": "Add to Cart"}, "style": {"backgroundColor": "#f97316", "color": "#ffffff", "padding": "8px 16px", "borderRadius": "6px", "fontSize": "14px"}}
              ]
            },
            {
              "id": "col_product_4",
              "style": {},
              "widgets": [
                {"id": "w_product_4_img", "type": "image", "content": {"src": "https://via.placeholder.com/300x300/f59e0b/ffffff?text=Product+4", "alt": "Product image"}, "style": {"borderRadius": "8px", "marginBottom": "12px"}},
                {"id": "w_product_4_name", "type": "heading", "content": {"text": "Laptop Stand", "level": 3}, "style": {"color": "#1e293b", "fontSize": "16px", "marginBottom": "4px"}},
                {"id": "w_product_4_rating", "type": "text", "content": {"text": "⭐⭐⭐⭐⭐ (4.9)"}, "style": {"color": "#f97316", "fontSize": "12px", "marginBottom": "4px"}},
                {"id": "w_product_4_price", "type": "text", "content": {"text": "$34.99"}, "style": {"color": "#1e293b", "fontSize": "18px", "fontWeight": "bold", "marginBottom": "8px"}},
                {"id": "w_product_4_button", "type": "button", "content": {"text": "Add to Cart"}, "style": {"backgroundColor": "#f97316", "color": "#ffffff", "padding": "8px 16px", "borderRadius": "6px", "fontSize": "14px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_deals",
      "style": {"backgroundColor": "#ffffff", "padding": "80px 20px"},
      "rows": [
        {
          "id": "row_deals_heading",
          "style": {},
          "columns": [
            {
              "id": "col_deals_heading",
              "style": {},
              "widgets": [
                {"id": "w_deals_heading", "type": "heading", "content": {"text": "Today's Deals", "level": 2}, "style": {"color": "#1e293b", "fontSize": "36px", "marginBottom": "40px"}}
              ]
            }
          ]
        },
        {
          "id": "row_deals_grid",
          "style": {},
          "columns": [
            {
              "id": "col_deal_1",
              "style": {},
              "widgets": [
                {"id": "w_deal_1_img", "type": "image", "content": {"src": "https://via.placeholder.com/300x300/ef4444/ffffff?text=Deal+1", "alt": "Deal product"}, "style": {"borderRadius": "8px", "marginBottom": "12px"}},
                {"id": "w_deal_1_name", "type": "heading", "content": {"text": "Bluetooth Earbuds", "level": 3}, "style": {"color": "#1e293b", "fontSize": "16px", "marginBottom": "4px"}},
                {"id": "w_deal_1_rating", "type": "text", "content": {"text": "⭐⭐⭐⭐ (4.2)"}, "style": {"color": "#f97316", "fontSize": "12px", "marginBottom": "4px"}},
                {"id": "w_deal_1_price", "type": "text", "content": {"text": "$29.99 $59.99"}, "style": {"color": "#1e293b", "fontSize": "18px", "fontWeight": "bold", "marginBottom": "8px"}},
                {"id": "w_deal_1_button", "type": "button", "content": {"text": "Add to Cart"}, "style": {"backgroundColor": "#ef4444", "color": "#ffffff", "padding": "8px 16px", "borderRadius": "6px", "fontSize": "14px"}}
              ]
            },
            {
              "id": "col_deal_2",
              "style": {},
              "widgets": [
                {"id": "w_deal_2_img", "type": "image", "content": {"src": "https://via.placeholder.com/300x300/dc2626/ffffff?text=Deal+2", "alt": "Deal product"}, "style": {"borderRadius": "8px", "marginBottom": "12px"}},
                {"id": "w_deal_2_name", "type": "heading", "content": {"text": "Phone Case", "level": 3}, "style": {"color": "#1e293b", "fontSize": "16px", "marginBottom": "4px"}},
                {"id": "w_deal_2_rating", "type": "text", "content": {"text": "⭐⭐⭐⭐⭐ (4.7)"}, "style": {"color": "#f97316", "fontSize": "12px", "marginBottom": "4px"}},
                {"id": "w_deal_2_price", "type": "text", "content": {"text": "$19.99 $29.99"}, "style": {"color": "#1e293b", "fontSize": "18px", "fontWeight": "bold", "marginBottom": "8px"}},
                {"id": "w_deal_2_button", "type": "button", "content": {"text": "Add to Cart"}, "style": {"backgroundColor": "#ef4444", "color": "#ffffff", "padding": "8px 16px", "borderRadius": "6px", "fontSize": "14px"}}
              ]
            }
          ]
        }
      ]
    },
    {
      "id": "section_trust",
      "style": {"backgroundColor": "#f8fafc", "padding": "60px 20px"},
      "rows": [
        {
          "id": "row_trust",
          "style": {},
          "columns": [
            {
              "id": "col_trust_1",
              "style": {},
              "widgets": [
                {"id": "w_trust_1_icon", "type": "text", "content": {"text": "🚚"}, "style": {"fontSize": "32px", "textAlign": "center", "marginBottom": "8px"}},
                {"id": "w_trust_1_text", "type": "text", "content": {"text": "Free Shipping"}, "style": {"color": "#475569", "fontSize": "14px", "textAlign": "center", "fontWeight": "500"}}
              ]
            },
            {
              "id": "col_trust_2",
              "style": {},
              "widgets": [
                {"id": "w_trust_2_icon", "type": "text", "content": {"text": "🔒"}, "style": {"fontSize": "32px", "textAlign": "center", "marginBottom": "8px"}},
                {"id": "w_trust_2_text", "type": "text", "content": {"text": "Secure Checkout"}, "style": {"color": "#475569", "fontSize": "14px", "textAlign": "center", "fontWeight": "500"}}
              ]
            },
            {
              "id": "col_trust_3",
              "style": {},
              "widgets": [
                {"id": "w_trust_3_icon", "type": "text", "content": {"text": "↩️"}, "style": {"fontSize": "32px", "textAlign": "center", "marginBottom": "8px"}},
                {"id": "w_trust_3_text", "type": "text", "content": {"text": "Easy Returns"}, "style": {"color": "#475569", "fontSize": "14px", "textAlign": "center", "fontWeight": "500"}}
              ]
            },
            {
              "id": "col_trust_4",
              "style": {},
              "widgets": [
                {"id": "w_trust_4_icon", "type": "text", "content": {"text": "💬"}, "style": {"fontSize": "32px", "textAlign": "center", "marginBottom": "8px"}},
                {"id": "w_trust_4_text", "type": "text", "content": {"text": "24/7 Support"}, "style": {"color": "#475569", "fontSize": "14px", "textAlign": "center", "fontWeight": "500"}}
              ]
            }
          ]
        }
      ]
    }
  ]
}')
ON CONFLICT DO NOTHING;

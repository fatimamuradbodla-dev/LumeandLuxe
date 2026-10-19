-- =====================================================================
-- 🏛️ Lume & Luxe - Supabase Database Schema & Seed Data
-- Database: PostgreSQL (Supabase)
-- Description: Complete schema for products, orders, enquiries, and newsletter
-- =====================================================================

-- 1. CLEANUP (Drop tables if re-running)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS enquiries CASCADE;
DROP TABLE IF EXISTS newsletter_subscribers CASCADE;
DROP TABLE IF EXISTS products CASCADE;

-- =====================================================================
-- 2. TABLE DEFINITIONS
-- =====================================================================

-- Table: products (Store Catalogue)
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('furniture', 'lighting', 'rugs', 'accents', 'architectural')),
  price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
  rating NUMERIC(2, 1) DEFAULT 5.0 CHECK (rating BETWEEN 0.0 AND 5.0),
  image TEXT NOT NULL,
  material TEXT NOT NULL,
  dimensions TEXT NOT NULL,
  description TEXT NOT NULL,
  in_stock BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table: enquiries (Contact Us Form Submissions)
CREATE TABLE enquiries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  enquiry_type TEXT NOT NULL,
  budget TEXT,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'in_progress', 'resolved', 'archived')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table: orders (E-Commerce Customer Orders)
CREATE TABLE orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_reference TEXT UNIQUE NOT NULL,
  customer_name TEXT NOT NULL,
  customer_email TEXT NOT NULL,
  phone TEXT,
  shipping_address TEXT NOT NULL,
  city TEXT NOT NULL,
  country TEXT DEFAULT 'United Kingdom',
  postal_code TEXT NOT NULL,
  notes TEXT,
  subtotal NUMERIC(10, 2) NOT NULL,
  shipping_fee NUMERIC(10, 2) DEFAULT 0.00,
  total_amount NUMERIC(10, 2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table: order_items (Items within an order)
CREATE TABLE order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id TEXT REFERENCES products(id),
  product_title TEXT NOT NULL,
  unit_price NUMERIC(10, 2) NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  total_price NUMERIC(10, 2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table: newsletter_subscribers
CREATE TABLE newsletter_subscribers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  subscribed_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================
-- 3. INDEXES FOR HIGH-SPEED SEARCH & QUERYING
-- =====================================================================
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_enquiries_status ON enquiries(status);
CREATE INDEX idx_orders_reference ON orders(order_reference);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- =====================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================================
-- Enable RLS on all tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;

-- Products: Everyone (including public anonymous visitors) can view products
CREATE POLICY "Allow public read access to products" 
  ON products FOR SELECT 
  TO anon, authenticated 
  USING (true);

-- Enquiries: Anyone can submit a contact message
CREATE POLICY "Allow public to insert contact enquiries" 
  ON enquiries FOR INSERT 
  TO anon, authenticated 
  WITH CHECK (true);

-- Orders: Anyone can place an order and view their orders
CREATE POLICY "Allow public to create orders" 
  ON orders FOR INSERT 
  TO anon, authenticated 
  WITH CHECK (true);

CREATE POLICY "Allow public to read orders" 
  ON orders FOR SELECT 
  TO anon, authenticated 
  USING (true);

-- Order Items: Anyone can insert and read items for their order
CREATE POLICY "Allow public to insert order items" 
  ON order_items FOR INSERT 
  TO anon, authenticated 
  WITH CHECK (true);

CREATE POLICY "Allow public to read order items" 
  ON order_items FOR SELECT 
  TO anon, authenticated 
  USING (true);

-- Newsletter: Anyone can subscribe
CREATE POLICY "Allow public newsletter subscription" 
  ON newsletter_subscribers FOR INSERT 
  TO anon, authenticated 
  WITH CHECK (true);

-- =====================================================================
-- 5. SEED DATA - 14 CURATED LUME & LUXE PRODUCTS
-- =====================================================================
INSERT INTO products (id, title, category, price, rating, image, material, dimensions, description, in_stock) VALUES
(
  'prod-1',
  'The Aurelia Fluted White Oak Dining Table',
  'furniture',
  2450.00,
  4.9,
  'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=600&q=80',
  'Solid European White Oak & Beeswax Finish',
  '240cm (L) x 100cm (W) x 76cm (H)',
  'Handcrafted from slow-grown European white oak with dual fluted pillar plinths. Comfortably seats ten guests for banqueting.',
  true
),
(
  'prod-2',
  'The Mayfair Bouclé Curved Sectional Sofa',
  'furniture',
  3850.00,
  5.0,
  'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=600&q=80',
  'Heavy-Weight Belgian Wool Bouclé & Hardwood Frame',
  '340cm (W) x 145cm (D) x 74cm (H)',
  'An architectural low-slung silhouette featuring gentle organic curves. Upholstered in tactile, stain-resistant natural wool bouclé.',
  true
),
(
  'prod-3',
  'The Antiqued Brass Branch Chandelier',
  'lighting',
  1120.00,
  4.8,
  'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?auto=format&fit=crop&w=600&q=80',
  'Hand-Spun Unlacquered Brass & Frosted Mouth-Blown Glass',
  '120cm (Span) x 65cm (Drop, adjustable)',
  'Six asymmetrical arms of solid hand-rubbed brass holding warm-glow frosted glass globes. Dimmable to a warm 2200K amber glow.',
  true
),
(
  'prod-4',
  'The Nero Marquina Monolith Coffee Table',
  'furniture',
  1680.00,
  4.9,
  'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=600&q=80',
  'Authentic Nero Marquina Spanish Marble (Honed)',
  '120cm (L) x 60cm (W) x 32cm (H)',
  'Carved from a singular block of Spanish black marble with striking white calcite veins. Honed matte surface with chamfered edges.',
  true
),
(
  'prod-5',
  'The Calacatta Honed Marble Vessel Basin',
  'architectural',
  780.00,
  4.9,
  'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=600&q=80',
  'Solid Italian Calacatta Gold Marble',
  '42cm (Diameter) x 14cm (H)',
  'Monolithic bathroom cloakroom vessel basin with subtle caramel and grey veining. Treated with breathable mineral sealants.',
  true
),
(
  'prod-6',
  'The Alabaster Globe Pendant Light',
  'lighting',
  420.00,
  4.7,
  'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=600&q=80',
  'Natural Spanish Alabaster & Patinated Bronze Fitting',
  '25cm (Globe Diameter) x 150cm (Braided Cord)',
  'Carved from translucent genuine stone alabaster. Each sphere features organic cloud veining that radiates serene ambient light.',
  true
),
(
  'prod-7',
  'The Natural Sisal & Brass Stair Runner (Metre)',
  'rugs',
  320.00,
  4.8,
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=600&q=80',
  '100% Organic East African Sisal & Cotton Twill Border',
  '68cm (Width) x Sold per 5-Metre Roll',
  'Hard-wearing woven herringbone sisal runner with bound charcoal edges. Reduces stair footstep reverberation by up to 80%.',
  true
),
(
  'prod-8',
  'The Hand-Knotted Wool & Silk Area Rug (240x300cm)',
  'rugs',
  1950.00,
  5.0,
  'https://images.unsplash.com/photo-1579656381226-5fc0f0100c3b?auto=format&fit=crop&w=600&q=80',
  'Hand-Spun New Zealand Wool & Natural Mulberry Silk',
  '240cm x 300cm',
  'Hand-knotted with over 200,000 knots per square metre. Features an understated broken-line pattern in oatmeal and clotted cream.',
  true
),
(
  'prod-9',
  'The Sculptural Stoneware Urn Vase',
  'accents',
  185.00,
  4.9,
  'https://images.unsplash.com/photo-1581783342308-f792dbdd27c5?auto=format&fit=crop&w=600&q=80',
  'Coarse Sandy Stoneware with Raw Matte Slip',
  '32cm (Diameter) x 44cm (H)',
  'Hand-thrown pottery vase inspired by classical Cycladic forms. Ideal for tall dried magnolia branches or as a standalone plinth sculpture.',
  true
),
(
  'prod-10',
  'The Belgian Washed Linen Bedding Set (Super King)',
  'rugs',
  295.00,
  4.9,
  'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=600&q=80',
  '100% Pure Certified French & Belgian Flax (185 GSM)',
  'Duvet: 260x220cm + 2 Oxford Pillowcases',
  'Pre-washed with natural pumice stones for immediate softness. Highly breathable flax regulates body temperature across all British seasons.',
  true
),
(
  'prod-11',
  'The Aged Bronze Pivot Picture Wall Sconce',
  'lighting',
  240.00,
  4.7,
  'https://images.unsplash.com/photo-1540932239986-30128078f3c5?auto=format&fit=crop&w=600&q=80',
  'Cast Gunmetal Bronze with 2700K Warm LED Strip',
  '45cm (Width) x 18cm (Depth)',
  'Museum-grade 95+ CRI directional LED light designed to highlight framed artwork, bookcases, or powder room mirrors without UV heat.',
  true
),
(
  'prod-12',
  'The Smoked Glass & Brass Drinks Credenza',
  'furniture',
  2150.00,
  5.0,
  'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?auto=format&fit=crop&w=600&q=80',
  'European Walnut, Fluted Smoked Glass & Brass Hardware',
  '160cm (L) x 48cm (D) x 82cm (H)',
  'Features interior touch-sensor lighting, mirrored backings for crystal glassware, and silent soft-close reeded glass cupboard fronts.',
  true
),
(
  'prod-13',
  'The Honed Travertine Plinth Pedestal',
  'accents',
  690.00,
  4.8,
  'https://images.unsplash.com/photo-1533090161767-e6ffed986b88?auto=format&fit=crop&w=600&q=80',
  'Roman Honed Travertine with Natural Voids',
  '35cm (Square) x 75cm (H)',
  'Architectural monolithic pedestal displaying classical Roman open cavities and warm beige banding. Supports sculptures up to 120kg.',
  true
),
(
  'prod-14',
  'The Acoustic Fluted Wood Wall Slat Pack (4 Panes)',
  'architectural',
  480.00,
  4.9,
  'https://images.unsplash.com/photo-1585412727339-54e4bae3bbf9?auto=format&fit=crop&w=600&q=80',
  'Natural Oak Veneer over Recycled Black Acoustic Felt',
  '240cm (H) x 60cm (W) per panel (Covers 5.76 sqm)',
  'Class-A sound absorption panels that eliminate echo in home theatres, bedrooms, and studies while adding architectural depth.',
  true
);

-- Output verification notice
SELECT 'Lume & Luxe Supabase Database setup successfully completed! 14 products seeded.' AS status;

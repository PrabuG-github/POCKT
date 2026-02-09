-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. TABLES

-- Profiles: Cross-synced from Firebase/Supabase Auth
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'viewer' CHECK (role IN ('viewer', 'shop_owner')),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Shops: Managed by Shop Owners
CREATE TABLE IF NOT EXISTS shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  location GEOGRAPHY(POINT) NOT NULL,
  address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Global Product Catalog (Standardized names for search)
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  category TEXT,
  image_url TEXT
);

-- Mapping Products to Shops (Price & Stock)
CREATE TABLE IF NOT EXISTS shop_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  price DECIMAL(10, 2) NOT NULL,
  stock_status TEXT DEFAULT 'in_stock' CHECK (stock_status IN ('in_stock', 'low_stock', 'out_of_stock')),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(shop_id, product_id)
);

-- Reservations
CREATE TABLE IF NOT EXISTS reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  shop_product_id UUID REFERENCES shop_products(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'expired', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '60 minutes')
);

-- 3. INDEXES for Performance
CREATE INDEX IF NOT EXISTS idx_shops_location ON shops USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_shop_products_price ON shop_products (price ASC);
CREATE INDEX IF NOT EXISTS idx_reservations_expires_at ON reservations (expires_at);

-- 4. RLS POLICIES

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE shop_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read all profiles, but only edit their own
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Shops: Everyone can view shops, owner can manage
DROP POLICY IF EXISTS "Shops are viewable by everyone" ON shops;
CREATE POLICY "Shops are viewable by everyone" ON shops FOR SELECT USING (true);
DROP POLICY IF EXISTS "Owners can manage their shops" ON shops;
CREATE POLICY "Owners can manage their shops" ON shops FOR ALL USING (auth.uid() = owner_id);

-- Products: Viewable by everyone
DROP POLICY IF EXISTS "Products are viewable by everyone" ON products;
CREATE POLICY "Products are viewable by everyone" ON products FOR SELECT USING (true);

-- Shop Products: Viewable by everyone, owner can manage
DROP POLICY IF EXISTS "Shop products are viewable by everyone" ON shop_products;
CREATE POLICY "Shop products are viewable by everyone" ON shop_products FOR SELECT USING (true);
DROP POLICY IF EXISTS "Owners can manage their shop products" ON shop_products;
CREATE POLICY "Owners can manage their shop products" ON shop_products FOR ALL 
USING (EXISTS (SELECT 1 FROM shops WHERE id = shop_products.shop_id AND owner_id = auth.uid()));

-- Reservations: Users can see/create their own, Owners can see/update their shop's reservations
DROP POLICY IF EXISTS "Users can manage their own reservations" ON reservations;
CREATE POLICY "Users can manage their own reservations" ON reservations FOR ALL 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Owners can view shop reservations" ON reservations;
CREATE POLICY "Owners can view shop reservations" ON reservations FOR SELECT
USING (EXISTS (
  SELECT 1 FROM shop_products sp
  JOIN shops s ON sp.shop_id = s.id
  WHERE sp.id = reservations.shop_product_id AND s.owner_id = auth.uid()
));

-- 5. RPC FUNCTIONS

-- Geospatial Search Function
CREATE OR REPLACE FUNCTION get_shops_in_radius(
  user_lat FLOAT,
  user_long FLOAT,
  radius_meters FLOAT,
  search_product_name TEXT DEFAULT NULL
)
RETURNS TABLE (
  shop_id UUID,
  shop_name TEXT,
  distance FLOAT,
  product_id UUID,
  product_name TEXT,
  price DECIMAL,
  stock_status TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id as shop_id,
    s.name as shop_name,
    ST_Distance(s.location, ST_SetSRID(ST_MakePoint(user_long, user_lat), 4326)::geography) as distance,
    p.id as product_id,
    p.name as product_name,
    sp.price,
    sp.stock_status
  FROM shops s
  JOIN shop_products sp ON s.id = sp.shop_id
  JOIN products p ON sp.product_id = p.id
  WHERE 
    ST_DWithin(s.location, ST_SetSRID(ST_MakePoint(user_long, user_lat), 4326)::geography, radius_meters)
    AND (search_product_name IS NULL OR p.name ILIKE '%' || search_product_name || '%')
  ORDER BY sp.price ASC, distance ASC;
END;
$$;

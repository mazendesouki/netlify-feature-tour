-- ══════════════════════════════════════════════════
--  Wslha وصلها — Database Schema
--  Run this in: Supabase Dashboard → SQL Editor
-- ══════════════════════════════════════════════════

-- 1. PROFILES (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name   TEXT,
  phone       TEXT,
  role        TEXT DEFAULT 'customer' CHECK (role IN ('customer', 'driver', 'admin')),
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. STORES
CREATE TABLE IF NOT EXISTS stores (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name          TEXT NOT NULL,
  name_ar       TEXT NOT NULL,
  category      TEXT NOT NULL,
  image_emoji   TEXT DEFAULT '🏪',
  rating        DECIMAL(2,1) DEFAULT 4.5,
  delivery_time INTEGER DEFAULT 30,
  delivery_fee  DECIMAL(10,2) DEFAULT 5.00,
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 3. PRODUCTS
CREATE TABLE IF NOT EXISTS products (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  store_id     UUID REFERENCES stores(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  name_ar      TEXT NOT NULL,
  description  TEXT,
  price        DECIMAL(10,2) NOT NULL,
  image_emoji  TEXT DEFAULT '🍽️',
  is_available BOOLEAN DEFAULT TRUE
);

-- 4. DRIVERS
CREATE TABLE IF NOT EXISTS drivers (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          UUID REFERENCES profiles(id) ON DELETE CASCADE,
  vehicle_type     TEXT DEFAULT 'motorcycle',
  is_available     BOOLEAN DEFAULT TRUE,
  rating           DECIMAL(2,1) DEFAULT 4.8,
  total_deliveries INTEGER DEFAULT 0
);

-- 5. ORDERS
CREATE TABLE IF NOT EXISTS orders (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          UUID REFERENCES profiles(id) ON DELETE SET NULL,
  store_id         UUID REFERENCES stores(id) ON DELETE SET NULL,
  driver_id        UUID REFERENCES drivers(id) ON DELETE SET NULL,
  status           TEXT DEFAULT 'pending'
                   CHECK (status IN ('pending','confirmed','preparing','on_the_way','delivered','cancelled')),
  total_amount     DECIMAL(10,2) NOT NULL,
  delivery_fee     DECIMAL(10,2) DEFAULT 5.00,
  delivery_address TEXT,
  notes            TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  delivered_at     TIMESTAMPTZ
);

-- 6. ORDER ITEMS
CREATE TABLE IF NOT EXISTS order_items (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id   UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  name_ar    TEXT NOT NULL,
  quantity   INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL
);

-- 7. WALLET TRANSACTIONS
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  amount      DECIMAL(10,2) NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('credit','debit')),
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 8. RATINGS
CREATE TABLE IF NOT EXISTS ratings (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      UUID REFERENCES profiles(id) ON DELETE CASCADE,
  order_id     UUID REFERENCES orders(id) ON DELETE CASCADE UNIQUE,
  store_rating INTEGER CHECK (store_rating BETWEEN 1 AND 5),
  driver_rating INTEGER CHECK (driver_rating BETWEEN 1 AND 5),
  comment      TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════
--  ROW LEVEL SECURITY
-- ══════════════════════════════════════════════════
ALTER TABLE profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders             ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items        ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings            ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores             ENABLE ROW LEVEL SECURITY;
ALTER TABLE products           ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers            ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "profile_select" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profile_insert" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profile_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Stores & Products — public read
CREATE POLICY "stores_public"   ON stores   FOR SELECT USING (is_active = TRUE);
CREATE POLICY "products_public" ON products FOR SELECT USING (is_available = TRUE);
CREATE POLICY "drivers_public"  ON drivers  FOR SELECT USING (TRUE);

-- Orders
CREATE POLICY "orders_select" ON orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "orders_insert" ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "orders_update" ON orders FOR UPDATE USING (auth.uid() = user_id);

-- Order items
CREATE POLICY "items_select" ON order_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid())
);
CREATE POLICY "items_insert" ON order_items FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid())
);

-- Wallet
CREATE POLICY "wallet_select" ON wallet_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "wallet_insert" ON wallet_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Ratings
CREATE POLICY "ratings_select" ON ratings FOR SELECT USING (TRUE);
CREATE POLICY "ratings_insert" ON ratings FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ══════════════════════════════════════════════════
--  AUTO-CREATE PROFILE ON SIGN UP
-- ══════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', '')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ══════════════════════════════════════════════════
--  SAMPLE DATA
-- ══════════════════════════════════════════════════
INSERT INTO stores (name, name_ar, category, image_emoji, rating, delivery_time, delivery_fee) VALUES
  ('Burger House',     'برجر هاوس',        'restaurant',  '🍔', 4.8, 20, 5.00),
  ('Pizza Star',       'بيتزا ستار',        'restaurant',  '🍕', 4.5, 30, 0.00),
  ('Fresh Mart',       'فريش مارت',         'supermarket', '🛒', 4.9, 15, 3.00),
  ('Al-Shifa Pharmacy','صيدلية الشفاء',     'pharmacy',    '💊', 4.7, 10, 0.00),
  ('Sweet Corner',     'ركن الحلويات',      'sweets',      '🍰', 4.6, 25, 5.00),
  ('Koshary El-Tahrir','كشري التحرير',      'restaurant',  '🍝', 4.7, 15, 3.00)
ON CONFLICT DO NOTHING;

-- Products for Burger House
INSERT INTO products (store_id, name, name_ar, price, image_emoji)
SELECT id, 'Classic Burger',   'برجر كلاسيك',       25.00, '🍔' FROM stores WHERE name='Burger House'
UNION ALL
SELECT id, 'Double Burger',    'دبل برجر',           35.00, '🍔' FROM stores WHERE name='Burger House'
UNION ALL
SELECT id, 'Crispy Chicken',   'تشيكن كريسبي',       28.00, '🍗' FROM stores WHERE name='Burger House'
UNION ALL
SELECT id, 'French Fries',     'بطاطس مقلية',        12.00, '🍟' FROM stores WHERE name='Burger House'
UNION ALL
SELECT id, 'Cola',             'كولا',                8.00, '🥤' FROM stores WHERE name='Burger House';

-- Products for Pizza Star
INSERT INTO products (store_id, name, name_ar, price, image_emoji)
SELECT id, 'Margherita Pizza',  'بيتزا مارغريتا',   45.00, '🍕' FROM stores WHERE name='Pizza Star'
UNION ALL
SELECT id, 'Pepperoni Pizza',   'بيتزا بيبروني',    55.00, '🍕' FROM stores WHERE name='Pizza Star'
UNION ALL
SELECT id, 'Garlic Bread',      'خبز بالثوم',       15.00, '🥖' FROM stores WHERE name='Pizza Star';

-- Products for Fresh Mart
INSERT INTO products (store_id, name, name_ar, price, image_emoji)
SELECT id, 'Eggs (30 pcs)',     'بيض (30 حبة)',     25.00, '🥚' FROM stores WHERE name='Fresh Mart'
UNION ALL
SELECT id, 'Milk 1L',           'حليب 1 لتر',       12.00, '🥛' FROM stores WHERE name='Fresh Mart'
UNION ALL
SELECT id, 'Bread',             'عيش',               8.00, '🍞' FROM stores WHERE name='Fresh Mart'
UNION ALL
SELECT id, 'Water 6-pack',      'مياه 6 زجاجات',   18.00, '💧' FROM stores WHERE name='Fresh Mart';

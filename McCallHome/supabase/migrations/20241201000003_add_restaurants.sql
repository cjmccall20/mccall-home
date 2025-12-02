-- =====================================================
-- Add Restaurants and Orders Feature
-- =====================================================

-- Create restaurants table
CREATE TABLE IF NOT EXISTS restaurants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    cuisine_type TEXT DEFAULT 'other',
    address TEXT,
    phone_number TEXT,
    website TEXT,
    notes TEXT,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create restaurant_orders table
CREATE TABLE IF NOT EXISTS restaurant_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    items JSONB DEFAULT '[]'::jsonb,
    total_amount DECIMAL(10, 2),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_restaurants_household ON restaurants(household_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_cuisine ON restaurants(cuisine_type);
CREATE INDEX IF NOT EXISTS idx_restaurants_favorite ON restaurants(is_favorite) WHERE is_favorite = true;

CREATE INDEX IF NOT EXISTS idx_restaurant_orders_restaurant ON restaurant_orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_orders_household ON restaurant_orders(household_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_orders_date ON restaurant_orders(order_date DESC);

-- Enable RLS
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_orders ENABLE ROW LEVEL SECURITY;

-- Create permissive policies for development
DROP POLICY IF EXISTS "Allow all for restaurants" ON restaurants;
CREATE POLICY "Allow all for restaurants" ON restaurants FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all for restaurant_orders" ON restaurant_orders;
CREATE POLICY "Allow all for restaurant_orders" ON restaurant_orders FOR ALL USING (true) WITH CHECK (true);

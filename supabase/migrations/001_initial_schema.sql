-- 1. Staff Profiles & Roles (linked to Supabase Auth)
CREATE TABLE public.staff_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'manager', 'staff')) DEFAULT 'staff',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Book Categories
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Books Catalog
CREATE TABLE public.books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    isbn VARCHAR(13) NOT NULL UNIQUE,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    published_year INT CHECK (published_year >= 1450 AND published_year <= EXTRACT(YEAR FROM NOW()) + 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Inventory / Stock Levels
CREATE TABLE public.inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id UUID NOT NULL UNIQUE REFERENCES public.books(id) ON DELETE CASCADE,
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    reorder_threshold INT NOT NULL DEFAULT 5 CHECK (reorder_threshold >= 0),
    shelf_location TEXT,
    updated_by UUID REFERENCES public.staff_profiles(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX idx_books_category ON public.books(category_id);
CREATE INDEX idx_inventory_low_stock ON public.inventory(stock_quantity) WHERE stock_quantity <= 5;

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;


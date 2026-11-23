-- Enable Row-Level Security on all tables
ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;

-- Helper function to verify user is an active staff member (with pinned search_path)
CREATE OR REPLACE FUNCTION public.is_authenticated_staff()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.staff_profiles
    WHERE id = auth.uid()
  );
END;
$$;

-- READ POLICIES (Authenticated users can view catalog & stock)
CREATE POLICY "Authenticated users can read categories"
ON public.categories FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can read books"
ON public.books FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can read inventory"
ON public.inventory FOR SELECT TO authenticated USING (true);

CREATE POLICY "Staff can read own profile"
ON public.staff_profiles FOR SELECT TO authenticated USING (auth.uid() = id);

-- WRITE POLICIES: CATEGORIES (Split explicitly into INSERT, UPDATE, DELETE)
CREATE POLICY "Staff can insert categories"
ON public.categories FOR INSERT TO authenticated
WITH CHECK (public.is_authenticated_staff());

CREATE POLICY "Staff can update categories"
ON public.categories FOR UPDATE TO authenticated
USING (public.is_authenticated_staff())
WITH CHECK (public.is_authenticated_staff());

CREATE POLICY "Staff can delete categories"
ON public.categories FOR DELETE TO authenticated
USING (public.is_authenticated_staff());

-- WRITE POLICIES: BOOKS
CREATE POLICY "Staff can insert books"
ON public.books FOR INSERT TO authenticated
WITH CHECK (public.is_authenticated_staff());

CREATE POLICY "Staff can update books"
ON public.books FOR UPDATE TO authenticated
USING (public.is_authenticated_staff())
WITH CHECK (public.is_authenticated_staff());

CREATE POLICY "Staff can delete books"
ON public.books FOR DELETE TO authenticated
USING (public.is_authenticated_staff());

-- WRITE POLICIES: INVENTORY
CREATE POLICY "Staff can insert inventory"
ON public.inventory FOR INSERT TO authenticated
WITH CHECK (public.is_authenticated_staff());

CREATE POLICY "Staff can update inventory"
ON public.inventory FOR UPDATE TO authenticated
USING (public.is_authenticated_staff())
WITH CHECK (public.is_authenticated_staff());

CREATE POLICY "Staff can delete inventory"
ON public.inventory FOR DELETE TO authenticated
USING (public.is_authenticated_staff());

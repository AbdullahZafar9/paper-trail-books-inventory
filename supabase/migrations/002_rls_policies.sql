-- Enable Row-Level Security on all tables
ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;

-- Helper function to verify user is an active staff member
CREATE OR REPLACE FUNCTION public.is_authenticated_staff()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.staff_profiles
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- READ POLICIES (Authenticated users can view catalog & stock)
CREATE POLICY "Authenticated users can read categories"
ON public.categories FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can read books"
ON public.books FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can read inventory"
ON public.inventory FOR SELECT TO authenticated USING (true);

CREATE POLICY "Staff can read own profile"
ON public.staff_profiles FOR SELECT TO authenticated USING (auth.uid() = id);

-- WRITE POLICIES (Restricted strictly to verified authenticated staff)
CREATE POLICY "Only staff can insert/update/delete categories"
ON public.categories FOR ALL TO authenticated
USING (public.is_authenticated_staff())
WITH CHECK (public.is_authenticated_staff());

CREATE POLICY "Only staff can insert/update/delete books"
ON public.books FOR ALL TO authenticated
USING (public.is_authenticated_staff())
WITH CHECK (public.is_authenticated_staff());

CREATE POLICY "Only staff can modify inventory"
ON public.inventory FOR ALL TO authenticated
USING (public.is_authenticated_staff())
WITH CHECK (public.is_authenticated_staff());

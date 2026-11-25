CREATE OR REPLACE FUNCTION public.create_book_with_inventory(
  p_isbn text,
  p_title text,
  p_author text,
  p_category_id uuid,
  p_price numeric,
  p_published_year int DEFAULT NULL,
  p_stock_quantity int DEFAULT 0,
  p_reorder_threshold int DEFAULT 5,
  p_shelf_location text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_book public.books%ROWTYPE;
  v_inv public.inventory%ROWTYPE;
BEGIN
  INSERT INTO public.books (isbn, title, author, category_id, price, published_year)
  VALUES (p_isbn, p_title, p_author, p_category_id, p_price, p_published_year)
  RETURNING * INTO v_book;

  INSERT INTO public.inventory (book_id, stock_quantity, reorder_threshold, shelf_location, updated_by)
  VALUES (v_book.id, p_stock_quantity, p_reorder_threshold, p_shelf_location, auth.uid())
  RETURNING * INTO v_inv;

  RETURN to_jsonb(v_book) || jsonb_build_object('inventory', to_jsonb(v_inv));
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_book_with_inventory(text, text, text, uuid, numeric, int, int, int, text) TO authenticated;

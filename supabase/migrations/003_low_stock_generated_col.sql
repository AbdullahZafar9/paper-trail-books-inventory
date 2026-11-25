ALTER TABLE public.inventory
ADD COLUMN IF NOT EXISTS is_low_stock boolean
GENERATED ALWAYS AS (stock_quantity <= reorder_threshold) STORED;

DROP INDEX IF EXISTS idx_inventory_low_stock;
CREATE INDEX idx_inventory_low_stock
ON public.inventory (book_id)
WHERE is_low_stock = true;

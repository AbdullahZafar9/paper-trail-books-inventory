import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export async function GET(req: NextRequest) {
  const supabase = createSupabaseServerClient(req);

  const { data, error } = await supabase
    .from('inventory')
    .select(`
      id,
      stock_quantity,
      reorder_threshold,
      shelf_location,
      updated_at,
      books ( id, isbn, title, author, price )
    `)
    .order('stock_quantity', { ascending: true });

  if (error) {
    const status = error.code === '42501' ? 403 : 400;
    return NextResponse.json({ error: error.message }, { status });
  }

  const lowStockItems = (data ?? []).filter(
    (item) => item.stock_quantity <= item.reorder_threshold
  );

  return NextResponse.json({ data: lowStockItems }, { status: 200 });
}

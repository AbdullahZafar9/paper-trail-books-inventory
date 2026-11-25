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
      is_low_stock,
      shelf_location,
      updated_at,
      books ( id, isbn, title, author, price )
    `)
    .eq('is_low_stock', true)
    .order('stock_quantity', { ascending: true });

  if (error) {
    const status = error.code === '42501' ? 403 : 400;
    return NextResponse.json({ error: error.message }, { status });
  }

  return NextResponse.json({ data }, { status: 200 });
}

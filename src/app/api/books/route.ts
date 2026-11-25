import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { createBookSchema } from '@/lib/validations/inventory';

export async function GET(req: NextRequest) {
  const supabase = createSupabaseServerClient(req);
  const { searchParams } = new URL(req.url);
  const categoryId = searchParams.get('category_id');
  const search = searchParams.get('search')?.trim();
  const page = Math.max(1, Number(searchParams.get('page') || '1'));
  const limit = Math.min(50, Math.max(1, Number(searchParams.get('limit') || '8')));
  const from = (page - 1) * limit;
  const to = from + limit - 1;

  let query = supabase
    .from('books')
    .select(
      `
      id,
      isbn,
      title,
      author,
      price,
      published_year,
      created_at,
      categories ( id, name ),
      inventory ( id, stock_quantity, reorder_threshold, is_low_stock, shelf_location, updated_at )
    `,
      { count: 'exact' }
    )
    .order('created_at', { ascending: false })
    .range(from, to);

  if (categoryId) {
    query = query.eq('category_id', categoryId);
  }

  if (search) {
    query = query.or(`title.ilike.%${search}%,author.ilike.%${search}%,isbn.ilike.%${search}%`);
  }

  const { data, error, count } = await query;

  if (error) {
    const status = error.code === '42501' ? 403 : 400;
    return NextResponse.json({ error: error.message }, { status });
  }

  const total = count ?? 0;

  return NextResponse.json(
    {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    },
    { status: 200 }
  );
}

export async function POST(req: NextRequest) {
  const supabase = createSupabaseServerClient(req);

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) {
    return NextResponse.json({ error: 'Unauthorized: valid staff token required' }, { status: 401 });
  }

  const body = await req.json().catch(() => null);
  const parsed = createBookSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(
      { error: 'Validation failed', details: parsed.error.flatten() },
      { status: 400 }
    );
  }

  const { data, error } = await supabase.rpc('create_book_with_inventory', {
    p_isbn: parsed.data.isbn,
    p_title: parsed.data.title,
    p_author: parsed.data.author,
    p_category_id: parsed.data.category_id,
    p_price: parsed.data.price,
    p_published_year: parsed.data.published_year ?? null,
    p_stock_quantity: parsed.data.stock_quantity,
    p_reorder_threshold: parsed.data.reorder_threshold,
    p_shelf_location: parsed.data.shelf_location ?? null,
  });

  if (error) {
    const status = error.code === '42501' ? 403 : error.code === '23505' ? 409 : 400;
    return NextResponse.json({ error: error.message }, { status });
  }

  return NextResponse.json({ data }, { status: 201 });
}

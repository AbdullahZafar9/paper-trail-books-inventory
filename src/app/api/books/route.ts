import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { createBookSchema } from '@/lib/validations/inventory';

export async function GET(req: NextRequest) {
  const supabase = createSupabaseServerClient(req);
  const { searchParams } = new URL(req.url);
  const categoryId = searchParams.get('category_id');
  const search = searchParams.get('search');

  let query = supabase
    .from('books')
    .select(`
      id,
      isbn,
      title,
      author,
      price,
      published_year,
      created_at,
      categories ( id, name ),
      inventory ( id, stock_quantity, reorder_threshold, shelf_location, updated_at )
    `)
    .order('created_at', { ascending: false });

  if (categoryId) {
    query = query.eq('category_id', categoryId);
  }

  if (search) {
    query = query.or(`title.ilike.%${search}%,author.ilike.%${search}%,isbn.ilike.%${search}%`);
  }

  const { data, error } = await query;

  if (error) {
    const status = error.code === '42501' ? 403 : 400;
    return NextResponse.json({ error: error.message }, { status });
  }

  return NextResponse.json({ data }, { status: 200 });
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

  const { stock_quantity, reorder_threshold, shelf_location, ...bookFields } = parsed.data;

  const { data: book, error: bookError } = await supabase
    .from('books')
    .insert(bookFields)
    .select()
    .single();

  if (bookError) {
    const status = bookError.code === '42501' ? 403 : bookError.code === '23505' ? 409 : 400;
    return NextResponse.json({ error: bookError.message }, { status });
  }

  const { data: inventory, error: invError } = await supabase
    .from('inventory')
    .insert({
      book_id: book.id,
      stock_quantity,
      reorder_threshold,
      shelf_location: shelf_location ?? null,
      updated_by: user.id,
    })
    .select()
    .single();

  if (invError) {
    return NextResponse.json({ error: invError.message }, { status: 400 });
  }

  return NextResponse.json({ data: { ...book, inventory } }, { status: 201 });
}

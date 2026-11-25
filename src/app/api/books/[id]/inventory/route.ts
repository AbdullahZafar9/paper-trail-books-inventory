import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { updateInventorySchema } from '@/lib/validations/inventory';

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const supabase = createSupabaseServerClient(req);

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) {
    return NextResponse.json({ error: 'Unauthorized: valid staff token required' }, { status: 401 });
  }

  const body = await req.json().catch(() => null);
  const parsed = updateInventorySchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(
      { error: 'Validation failed', details: parsed.error.flatten() },
      { status: 400 }
    );
  }

  const { data, error } = await supabase
    .from('inventory')
    .update({
      ...parsed.data,
      updated_by: user.id,
      updated_at: new Date().toISOString(),
    })
    .eq('book_id', id)
    .select()
    .single();

  if (error) {
    const status = error.code === '42501' ? 403 : 400;
    return NextResponse.json({ error: error.message }, { status });
  }

  return NextResponse.json({ data }, { status: 200 });
}

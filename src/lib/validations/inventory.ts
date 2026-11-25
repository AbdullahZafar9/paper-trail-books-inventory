import { z } from 'zod';

export const createBookSchema = z.object({
  isbn: z.string().min(10, 'ISBN must be at least 10 characters').max(20),
  title: z.string().min(1, 'Title is required').max(255),
  author: z.string().min(1, 'Author is required').max(255),
  category_id: z.string().uuid('Invalid category UUID'),
  price: z.number().nonnegative('Price cannot be negative'),
  published_year: z.number().int().min(1450).max(new Date().getFullYear() + 1).optional(),
  stock_quantity: z.number().int().nonnegative('Stock cannot be negative').default(0),
  reorder_threshold: z.number().int().nonnegative().default(5),
  shelf_location: z.string().max(50).optional().nullable(),
});

export const updateInventorySchema = z.object({
  stock_quantity: z.number().int().nonnegative('Stock cannot be negative').optional(),
  reorder_threshold: z.number().int().nonnegative().optional(),
  shelf_location: z.string().max(50).optional().nullable(),
});

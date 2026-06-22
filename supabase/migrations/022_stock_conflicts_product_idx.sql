-- 022_stock_conflicts_product_idx.sql
-- Index the product_id FK on stock_conflicts so deleting/looking up a product
-- doesn't sequential-scan the table (the open partial index only covers
-- unresolved rows).

create index if not exists stock_conflicts_product_idx
  on stock_conflicts(product_id);

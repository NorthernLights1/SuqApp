-- ================================================================
-- Move RLS helper functions to private schema (not exposed by REST)
-- and move pg_trgm extension out of public schema.
-- ================================================================

-- 1. Fix pg_trgm location
ALTER EXTENSION pg_trgm SET SCHEMA extensions;

-- 2. Create private schema (PostgREST does not expose this)
CREATE SCHEMA IF NOT EXISTS private;
GRANT USAGE ON SCHEMA private TO authenticated;

-- 3. is_shop_member in private schema
CREATE OR REPLACE FUNCTION private.is_shop_member(p_shop_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM shop_users
    WHERE shop_id = p_shop_id
      AND user_id = auth.uid()
      AND status  = 'active'
  );
$$;

GRANT EXECUTE ON FUNCTION private.is_shop_member(uuid) TO authenticated;

-- 4. shop_id_from_branch in private schema
CREATE OR REPLACE FUNCTION private.shop_id_from_branch(p_branch_id uuid)
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT shop_id FROM branches WHERE id = p_branch_id;
$$;

GRANT EXECUTE ON FUNCTION private.shop_id_from_branch(uuid) TO authenticated;

-- 5. Rebuild every RLS policy that referenced the public functions
--    (drop old → create new with private.* prefix)

-- branches
DROP POLICY IF EXISTS branches_select ON public.branches;
CREATE POLICY branches_select ON public.branches FOR SELECT USING (
  private.is_shop_member(shop_id)
  OR EXISTS (SELECT 1 FROM shops WHERE shops.id = branches.shop_id AND shops.owner_id = auth.uid())
);

-- cash_reconciliations
DROP POLICY IF EXISTS cash_reconciliations_select ON public.cash_reconciliations;
CREATE POLICY cash_reconciliations_select ON public.cash_reconciliations
  FOR SELECT USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

DROP POLICY IF EXISTS cash_reconciliations_write ON public.cash_reconciliations;
CREATE POLICY cash_reconciliations_write ON public.cash_reconciliations
  FOR ALL USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

-- customers
DROP POLICY IF EXISTS customers_select ON public.customers;
CREATE POLICY customers_select ON public.customers
  FOR SELECT USING (private.is_shop_member(shop_id));

DROP POLICY IF EXISTS customers_write ON public.customers;
CREATE POLICY customers_write ON public.customers
  FOR ALL USING (private.is_shop_member(shop_id));

-- discounts
DROP POLICY IF EXISTS discounts_insert ON public.discounts;
CREATE POLICY discounts_insert ON public.discounts FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM sales s
    WHERE s.id = discounts.sale_id
      AND private.is_shop_member(private.shop_id_from_branch(s.branch_id))
  )
);

DROP POLICY IF EXISTS discounts_select ON public.discounts;
CREATE POLICY discounts_select ON public.discounts FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM sales s
    WHERE s.id = discounts.sale_id
      AND private.is_shop_member(private.shop_id_from_branch(s.branch_id))
  )
);

-- expense_categories
DROP POLICY IF EXISTS expense_categories_select ON public.expense_categories;
CREATE POLICY expense_categories_select ON public.expense_categories
  FOR SELECT USING ((shop_id IS NULL) OR private.is_shop_member(shop_id));

DROP POLICY IF EXISTS expense_categories_write ON public.expense_categories;
CREATE POLICY expense_categories_write ON public.expense_categories
  FOR ALL USING ((shop_id IS NOT NULL) AND private.is_shop_member(shop_id));

-- expenses
DROP POLICY IF EXISTS expenses_select ON public.expenses;
CREATE POLICY expenses_select ON public.expenses
  FOR SELECT USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

DROP POLICY IF EXISTS expenses_write ON public.expenses;
CREATE POLICY expenses_write ON public.expenses
  FOR ALL USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

-- export_jobs
DROP POLICY IF EXISTS export_jobs_select ON public.export_jobs;
CREATE POLICY export_jobs_select ON public.export_jobs
  FOR SELECT USING (private.is_shop_member(shop_id));

DROP POLICY IF EXISTS export_jobs_write ON public.export_jobs;
CREATE POLICY export_jobs_write ON public.export_jobs
  FOR ALL USING (private.is_shop_member(shop_id));

-- inventory
DROP POLICY IF EXISTS inventory_select ON public.inventory;
CREATE POLICY inventory_select ON public.inventory
  FOR SELECT USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

DROP POLICY IF EXISTS inventory_write ON public.inventory;
CREATE POLICY inventory_write ON public.inventory
  FOR ALL USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

-- inventory_adjustments
DROP POLICY IF EXISTS inventory_adjustments_insert ON public.inventory_adjustments;
CREATE POLICY inventory_adjustments_insert ON public.inventory_adjustments
  FOR INSERT WITH CHECK (private.is_shop_member(private.shop_id_from_branch(branch_id)));

DROP POLICY IF EXISTS inventory_adjustments_select ON public.inventory_adjustments;
CREATE POLICY inventory_adjustments_select ON public.inventory_adjustments
  FOR SELECT USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

-- measurement_units
DROP POLICY IF EXISTS measurement_units_select ON public.measurement_units;
CREATE POLICY measurement_units_select ON public.measurement_units
  FOR SELECT USING ((shop_id IS NULL) OR private.is_shop_member(shop_id));

DROP POLICY IF EXISTS measurement_units_write ON public.measurement_units;
CREATE POLICY measurement_units_write ON public.measurement_units
  FOR ALL USING ((shop_id IS NOT NULL) AND private.is_shop_member(shop_id));

-- notification_configs
DROP POLICY IF EXISTS notification_configs_select ON public.notification_configs;
CREATE POLICY notification_configs_select ON public.notification_configs
  FOR SELECT USING (private.is_shop_member(shop_id));

DROP POLICY IF EXISTS notification_configs_write ON public.notification_configs;
CREATE POLICY notification_configs_write ON public.notification_configs
  FOR ALL USING (private.is_shop_member(shop_id));

-- notification_logs
DROP POLICY IF EXISTS notification_logs_select ON public.notification_logs;
CREATE POLICY notification_logs_select ON public.notification_logs
  FOR SELECT USING (private.is_shop_member(shop_id));

-- payment_methods
DROP POLICY IF EXISTS payment_methods_select ON public.payment_methods;
CREATE POLICY payment_methods_select ON public.payment_methods
  FOR SELECT USING ((shop_id IS NULL) OR private.is_shop_member(shop_id));

DROP POLICY IF EXISTS payment_methods_write ON public.payment_methods;
CREATE POLICY payment_methods_write ON public.payment_methods
  FOR ALL USING ((shop_id IS NOT NULL) AND private.is_shop_member(shop_id));

-- product_categories
DROP POLICY IF EXISTS product_categories_select ON public.product_categories;
CREATE POLICY product_categories_select ON public.product_categories
  FOR SELECT USING (private.is_shop_member(shop_id));

DROP POLICY IF EXISTS product_categories_write ON public.product_categories;
CREATE POLICY product_categories_write ON public.product_categories
  FOR ALL USING (private.is_shop_member(shop_id));

-- products
DROP POLICY IF EXISTS products_select ON public.products;
CREATE POLICY products_select ON public.products
  FOR SELECT USING (private.is_shop_member(shop_id));

DROP POLICY IF EXISTS products_write ON public.products;
CREATE POLICY products_write ON public.products
  FOR ALL USING (private.is_shop_member(shop_id));

-- refund_items
DROP POLICY IF EXISTS refund_items_insert ON public.refund_items;
CREATE POLICY refund_items_insert ON public.refund_items FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM refunds r
    JOIN sales s ON s.id = r.original_sale_id
    WHERE r.id = refund_items.refund_id
      AND private.is_shop_member(private.shop_id_from_branch(s.branch_id))
  )
);

DROP POLICY IF EXISTS refund_items_select ON public.refund_items;
CREATE POLICY refund_items_select ON public.refund_items FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM refunds r
    JOIN sales s ON s.id = r.original_sale_id
    WHERE r.id = refund_items.refund_id
      AND private.is_shop_member(private.shop_id_from_branch(s.branch_id))
  )
);

-- refunds
DROP POLICY IF EXISTS refunds_insert ON public.refunds;
CREATE POLICY refunds_insert ON public.refunds FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM sales s
    WHERE s.id = refunds.original_sale_id
      AND private.is_shop_member(private.shop_id_from_branch(s.branch_id))
  )
);

DROP POLICY IF EXISTS refunds_select ON public.refunds;
CREATE POLICY refunds_select ON public.refunds FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM sales s
    WHERE s.id = refunds.original_sale_id
      AND private.is_shop_member(private.shop_id_from_branch(s.branch_id))
  )
);

-- sale_items
DROP POLICY IF EXISTS sale_items_insert ON public.sale_items;
CREATE POLICY sale_items_insert ON public.sale_items FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM sales s
    WHERE s.id = sale_items.sale_id
      AND private.is_shop_member(private.shop_id_from_branch(s.branch_id))
  )
);

DROP POLICY IF EXISTS sale_items_select ON public.sale_items;
CREATE POLICY sale_items_select ON public.sale_items FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM sales s
    WHERE s.id = sale_items.sale_id
      AND private.is_shop_member(private.shop_id_from_branch(s.branch_id))
  )
);

-- sales
DROP POLICY IF EXISTS sales_insert ON public.sales;
CREATE POLICY sales_insert ON public.sales
  FOR INSERT WITH CHECK (private.is_shop_member(private.shop_id_from_branch(branch_id)));

DROP POLICY IF EXISTS sales_select ON public.sales;
CREATE POLICY sales_select ON public.sales
  FOR SELECT USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

DROP POLICY IF EXISTS sales_update ON public.sales;
CREATE POLICY sales_update ON public.sales
  FOR UPDATE USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

-- shop_settings
DROP POLICY IF EXISTS shop_settings_select ON public.shop_settings;
CREATE POLICY shop_settings_select ON public.shop_settings
  FOR SELECT USING (private.is_shop_member(shop_id));

DROP POLICY IF EXISTS shop_settings_write ON public.shop_settings;
CREATE POLICY shop_settings_write ON public.shop_settings
  FOR ALL USING (private.is_shop_member(shop_id));

-- shops
DROP POLICY IF EXISTS shops_select ON public.shops;
CREATE POLICY shops_select ON public.shops FOR SELECT USING (
  (owner_id = auth.uid()) OR private.is_shop_member(id)
);

-- suppliers
DROP POLICY IF EXISTS suppliers_select ON public.suppliers;
CREATE POLICY suppliers_select ON public.suppliers
  FOR SELECT USING (private.is_shop_member(shop_id));

DROP POLICY IF EXISTS suppliers_write ON public.suppliers;
CREATE POLICY suppliers_write ON public.suppliers
  FOR ALL USING (private.is_shop_member(shop_id));

-- supply_order_items
DROP POLICY IF EXISTS supply_order_items_select ON public.supply_order_items;
CREATE POLICY supply_order_items_select ON public.supply_order_items FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM supply_orders so
    WHERE so.id = supply_order_items.supply_order_id
      AND private.is_shop_member(private.shop_id_from_branch(so.branch_id))
  )
);

DROP POLICY IF EXISTS supply_order_items_write ON public.supply_order_items;
CREATE POLICY supply_order_items_write ON public.supply_order_items FOR ALL USING (
  EXISTS (
    SELECT 1 FROM supply_orders so
    WHERE so.id = supply_order_items.supply_order_id
      AND private.is_shop_member(private.shop_id_from_branch(so.branch_id))
  )
);

-- supply_orders
DROP POLICY IF EXISTS supply_orders_select ON public.supply_orders;
CREATE POLICY supply_orders_select ON public.supply_orders
  FOR SELECT USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

DROP POLICY IF EXISTS supply_orders_write ON public.supply_orders;
CREATE POLICY supply_orders_write ON public.supply_orders
  FOR ALL USING (private.is_shop_member(private.shop_id_from_branch(branch_id)));

-- 6. Drop old public functions (policies no longer reference them)
DROP FUNCTION IF EXISTS public.is_shop_member(uuid);
DROP FUNCTION IF EXISTS public.shop_id_from_branch(uuid);

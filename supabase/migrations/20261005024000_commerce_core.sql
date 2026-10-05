-- Wantok Service shared commerce core for Food and Groceries / Shops.
-- Provider services are storefronts; catalogue items and transactional orders are
-- kept separate from generic service bookings.

CREATE TABLE public.commerce_catalog_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_service_id uuid NOT NULL REFERENCES public.provider_services(id) ON DELETE CASCADE,
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  description text,
  sku text,
  unit_label text,
  price numeric(12,2) NOT NULL CHECK (price >= 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  image_url text,
  is_available boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX commerce_catalog_items_service_available_idx
  ON public.commerce_catalog_items (provider_service_id, is_available, sort_order, name);
CREATE INDEX commerce_catalog_items_provider_idx
  ON public.commerce_catalog_items (provider_id, provider_service_id);

CREATE TABLE public.commerce_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  provider_id uuid NOT NULL REFERENCES public.provider_profiles(provider_id) ON DELETE RESTRICT,
  provider_service_id uuid NOT NULL REFERENCES public.provider_services(id) ON DELETE RESTRICT,
  category_id uuid NOT NULL REFERENCES public.service_categories(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'placed'
    CHECK (status IN (
      'placed', 'accepted', 'preparing', 'ready',
      'out_for_delivery', 'completed', 'cancelled', 'rejected'
    )),
  fulfillment_type text NOT NULL DEFAULT 'delivery'
    CHECK (fulfillment_type IN ('delivery', 'pickup')),
  delivery_address text,
  delivery_lat double precision CHECK (delivery_lat IS NULL OR delivery_lat BETWEEN -90 AND 90),
  delivery_lng double precision CHECK (delivery_lng IS NULL OR delivery_lng BETWEEN -180 AND 180),
  customer_note text,
  subtotal numeric(12,2) NOT NULL CHECK (subtotal >= 0),
  delivery_fee numeric(12,2) NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
  total_amount numeric(12,2) NOT NULL CHECK (total_amount >= 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  payment_method text NOT NULL DEFAULT 'cash'
    CHECK (payment_method IN ('cash', 'card', 'wallet', 'bank_transfer', 'other')),
  payment_status text NOT NULL DEFAULT 'unpaid'
    CHECK (payment_status IN ('unpaid', 'authorized', 'paid', 'refunded', 'failed')),
  placed_at timestamptz NOT NULL DEFAULT now(),
  accepted_at timestamptz,
  preparing_at timestamptz,
  ready_at timestamptz,
  out_for_delivery_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  rejected_at timestamptz,
  cancellation_reason text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (
    fulfillment_type <> 'delivery'
    OR delivery_address IS NOT NULL
  )
);

CREATE INDEX commerce_orders_customer_created_idx
  ON public.commerce_orders (customer_id, created_at DESC);
CREATE INDEX commerce_orders_provider_status_idx
  ON public.commerce_orders (provider_id, status, created_at DESC);
CREATE INDEX commerce_orders_service_created_idx
  ON public.commerce_orders (provider_service_id, created_at DESC);

CREATE TABLE public.commerce_order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.commerce_orders(id) ON DELETE CASCADE,
  catalog_item_id uuid REFERENCES public.commerce_catalog_items(id) ON DELETE SET NULL,
  item_name text NOT NULL,
  unit_label text,
  quantity numeric(12,3) NOT NULL CHECK (quantity > 0),
  unit_price numeric(12,2) NOT NULL CHECK (unit_price >= 0),
  line_total numeric(12,2) NOT NULL CHECK (line_total >= 0),
  currency text NOT NULL DEFAULT 'PGK' CHECK (char_length(currency) = 3),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX commerce_order_items_order_idx
  ON public.commerce_order_items (order_id, created_at);

CREATE TRIGGER commerce_catalog_items_set_updated_at
BEFORE UPDATE ON public.commerce_catalog_items
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER commerce_orders_set_updated_at
BEFORE UPDATE ON public.commerce_orders
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.commerce_catalog_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commerce_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commerce_order_items ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.commerce_catalog_items TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.commerce_catalog_items TO authenticated;
GRANT SELECT ON public.commerce_orders TO authenticated;
GRANT SELECT ON public.commerce_order_items TO authenticated;

REVOKE INSERT, UPDATE, DELETE ON public.commerce_orders FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.commerce_order_items FROM anon, authenticated;

CREATE POLICY commerce_catalog_items_public_read
ON public.commerce_catalog_items
FOR SELECT
TO anon
USING (
  is_available = true
  AND EXISTS (
    SELECT 1
    FROM public.provider_services AS ps
    JOIN public.service_categories AS sc ON sc.id = ps.category_id
    JOIN public.provider_profiles AS pp ON pp.provider_id = ps.provider_id
    WHERE ps.id = commerce_catalog_items.provider_service_id
      AND ps.provider_id = commerce_catalog_items.provider_id
      AND ps.status = 'active'
      AND sc.booking_mode = 'commerce'
      AND sc.slug IN ('food', 'groceries')
      AND pp.is_active = true
      AND pp.verification_status = 'verified'
  )
);

CREATE POLICY commerce_catalog_items_authenticated_read
ON public.commerce_catalog_items
FOR SELECT
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
  OR (
    is_available = true
    AND EXISTS (
      SELECT 1
      FROM public.provider_services AS ps
      JOIN public.service_categories AS sc ON sc.id = ps.category_id
      JOIN public.provider_profiles AS pp ON pp.provider_id = ps.provider_id
      WHERE ps.id = commerce_catalog_items.provider_service_id
        AND ps.provider_id = commerce_catalog_items.provider_id
        AND ps.status = 'active'
        AND sc.booking_mode = 'commerce'
        AND sc.slug IN ('food', 'groceries')
        AND pp.is_active = true
        AND pp.verification_status = 'verified'
    )
  )
);

CREATE POLICY commerce_catalog_items_insert_own
ON public.commerce_catalog_items
FOR INSERT
TO authenticated
WITH CHECK (
  provider_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.provider_services AS ps
    JOIN public.service_categories AS sc ON sc.id = ps.category_id
    JOIN public.provider_profiles AS pp ON pp.provider_id = ps.provider_id
    WHERE ps.id = commerce_catalog_items.provider_service_id
      AND ps.provider_id = auth.uid()
      AND sc.booking_mode = 'commerce'
      AND sc.slug IN ('food', 'groceries')
      AND pp.is_active = true
      AND pp.verification_status = 'verified'
  )
);

CREATE POLICY commerce_catalog_items_update_own
ON public.commerce_catalog_items
FOR UPDATE
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
)
WITH CHECK (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
);

CREATE POLICY commerce_catalog_items_delete_own
ON public.commerce_catalog_items
FOR DELETE
TO authenticated
USING (
  provider_id = auth.uid()
  OR public.is_admin(auth.uid())
);

CREATE POLICY commerce_orders_select_participants
ON public.commerce_orders
FOR SELECT
TO authenticated
USING (
  customer_id = auth.uid()
  OR provider_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR public.has_role('operations', auth.uid())
  OR public.has_role('support', auth.uid())
  OR public.has_role('finance', auth.uid())
);

CREATE POLICY commerce_order_items_select_participants
ON public.commerce_order_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.commerce_orders AS o
    WHERE o.id = commerce_order_items.order_id
      AND (
        o.customer_id = auth.uid()
        OR o.provider_id = auth.uid()
        OR public.is_admin(auth.uid())
        OR public.has_role('operations', auth.uid())
        OR public.has_role('support', auth.uid())
        OR public.has_role('finance', auth.uid())
      )
  )
);

CREATE OR REPLACE FUNCTION public.create_commerce_order(
  p_provider_service_id uuid,
  p_items jsonb,
  p_fulfillment_type text DEFAULT 'delivery',
  p_delivery_address text DEFAULT NULL,
  p_delivery_lat double precision DEFAULT NULL,
  p_delivery_lng double precision DEFAULT NULL,
  p_customer_note text DEFAULT NULL,
  p_payment_method text DEFAULT 'cash'
)
RETURNS public.commerce_orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_service public.provider_services%ROWTYPE;
  v_category public.service_categories%ROWTYPE;
  v_item jsonb;
  v_catalog public.commerce_catalog_items%ROWTYPE;
  v_quantity numeric(12,3);
  v_subtotal numeric(12,2) := 0;
  v_delivery_fee numeric(12,2) := 0;
  v_order public.commerce_orders%ROWTYPE;
  v_fulfillment text := lower(trim(COALESCE(p_fulfillment_type, 'delivery')));
  v_payment_method text := lower(trim(COALESCE(p_payment_method, 'cash')));
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Order must contain at least one item';
  END IF;

  IF v_fulfillment NOT IN ('delivery', 'pickup') THEN
    RAISE EXCEPTION 'Unsupported fulfillment type';
  END IF;

  IF v_payment_method NOT IN ('cash', 'card', 'wallet', 'bank_transfer', 'other') THEN
    RAISE EXCEPTION 'Unsupported payment method';
  END IF;

  IF v_fulfillment = 'delivery' AND NULLIF(trim(p_delivery_address), '') IS NULL THEN
    RAISE EXCEPTION 'Delivery address is required';
  END IF;

  IF p_delivery_lat IS NOT NULL AND NOT (p_delivery_lat BETWEEN -90 AND 90) THEN
    RAISE EXCEPTION 'Invalid delivery latitude';
  END IF;

  IF p_delivery_lng IS NOT NULL AND NOT (p_delivery_lng BETWEEN -180 AND 180) THEN
    RAISE EXCEPTION 'Invalid delivery longitude';
  END IF;

  SELECT ps.*
  INTO v_service
  FROM public.provider_services AS ps
  JOIN public.provider_profiles AS pp ON pp.provider_id = ps.provider_id
  WHERE ps.id = p_provider_service_id
    AND ps.status = 'active'
    AND pp.is_active = true
    AND pp.verification_status = 'verified';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Store is not available';
  END IF;

  SELECT *
  INTO v_category
  FROM public.service_categories
  WHERE id = v_service.category_id
    AND is_active = true
    AND booking_mode = 'commerce'
    AND slug IN ('food', 'groceries');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Service is not a commerce store';
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    IF NULLIF(v_item ->> 'item_id', '') IS NULL THEN
      RAISE EXCEPTION 'Every order item requires item_id';
    END IF;

    BEGIN
      v_quantity := (v_item ->> 'quantity')::numeric;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Invalid order quantity';
    END;

    IF v_quantity IS NULL OR v_quantity <= 0 THEN
      RAISE EXCEPTION 'Order quantity must be greater than zero';
    END IF;

    SELECT *
    INTO v_catalog
    FROM public.commerce_catalog_items
    WHERE id = (v_item ->> 'item_id')::uuid
      AND provider_service_id = v_service.id
      AND provider_id = v_service.provider_id
      AND is_available = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Order item is not available from this store';
    END IF;

    IF v_catalog.currency <> v_service.currency THEN
      RAISE EXCEPTION 'Store catalogue currency mismatch';
    END IF;

    v_subtotal := v_subtotal + round(v_catalog.price * v_quantity, 2);
  END LOOP;

  INSERT INTO public.commerce_orders (
    customer_id,
    provider_id,
    provider_service_id,
    category_id,
    status,
    fulfillment_type,
    delivery_address,
    delivery_lat,
    delivery_lng,
    customer_note,
    subtotal,
    delivery_fee,
    total_amount,
    currency,
    payment_method,
    payment_status
  )
  VALUES (
    v_user_id,
    v_service.provider_id,
    v_service.id,
    v_service.category_id,
    'placed',
    v_fulfillment,
    CASE WHEN v_fulfillment = 'delivery'
      THEN NULLIF(trim(p_delivery_address), '')
      ELSE NULL
    END,
    CASE WHEN v_fulfillment = 'delivery' THEN p_delivery_lat ELSE NULL END,
    CASE WHEN v_fulfillment = 'delivery' THEN p_delivery_lng ELSE NULL END,
    NULLIF(trim(p_customer_note), ''),
    v_subtotal,
    v_delivery_fee,
    v_subtotal + v_delivery_fee,
    v_service.currency,
    v_payment_method,
    'unpaid'
  )
  RETURNING * INTO v_order;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    v_quantity := (v_item ->> 'quantity')::numeric;

    SELECT *
    INTO v_catalog
    FROM public.commerce_catalog_items
    WHERE id = (v_item ->> 'item_id')::uuid;

    INSERT INTO public.commerce_order_items (
      order_id,
      catalog_item_id,
      item_name,
      unit_label,
      quantity,
      unit_price,
      line_total,
      currency,
      metadata
    )
    VALUES (
      v_order.id,
      v_catalog.id,
      v_catalog.name,
      v_catalog.unit_label,
      v_quantity,
      v_catalog.price,
      round(v_catalog.price * v_quantity, 2),
      v_catalog.currency,
      jsonb_build_object('sku', v_catalog.sku)
    );
  END LOOP;

  RETURN v_order;
END;
$$;

REVOKE ALL ON FUNCTION public.create_commerce_order(
  uuid, jsonb, text, text, double precision, double precision, text, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_commerce_order(
  uuid, jsonb, text, text, double precision, double precision, text, text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.vendor_update_commerce_order_status(
  p_order_id uuid,
  p_status text
)
RETURNS public.commerce_orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_target text := lower(trim(COALESCE(p_status, '')));
  v_order public.commerce_orders%ROWTYPE;
BEGIN
  SELECT *
  INTO v_order
  FROM public.commerce_orders
  WHERE id = p_order_id
    AND (
      provider_id = v_user_id
      OR public.is_admin(v_user_id)
      OR public.has_role('operations', v_user_id)
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Commerce order not found';
  END IF;

  IF NOT (
    (v_order.status = 'placed' AND v_target IN ('accepted', 'rejected'))
    OR (v_order.status = 'accepted' AND v_target = 'preparing')
    OR (v_order.status = 'preparing' AND v_target = 'ready')
    OR (
      v_order.status = 'ready'
      AND (
        (v_order.fulfillment_type = 'delivery' AND v_target = 'out_for_delivery')
        OR (v_order.fulfillment_type = 'pickup' AND v_target = 'completed')
      )
    )
    OR (v_order.status = 'out_for_delivery' AND v_target = 'completed')
  ) THEN
    RAISE EXCEPTION 'Invalid commerce order status transition';
  END IF;

  UPDATE public.commerce_orders
  SET status = v_target,
      accepted_at = CASE WHEN v_target = 'accepted' THEN now() ELSE accepted_at END,
      preparing_at = CASE WHEN v_target = 'preparing' THEN now() ELSE preparing_at END,
      ready_at = CASE WHEN v_target = 'ready' THEN now() ELSE ready_at END,
      out_for_delivery_at = CASE
        WHEN v_target = 'out_for_delivery' THEN now()
        ELSE out_for_delivery_at
      END,
      completed_at = CASE WHEN v_target = 'completed' THEN now() ELSE completed_at END,
      rejected_at = CASE WHEN v_target = 'rejected' THEN now() ELSE rejected_at END
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  RETURN v_order;
END;
$$;

REVOKE ALL ON FUNCTION public.vendor_update_commerce_order_status(uuid, text)
FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.vendor_update_commerce_order_status(uuid, text)
TO authenticated;

CREATE OR REPLACE FUNCTION public.cancel_commerce_order(
  p_order_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS public.commerce_orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_order public.commerce_orders%ROWTYPE;
BEGIN
  SELECT *
  INTO v_order
  FROM public.commerce_orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Commerce order not found';
  END IF;

  IF v_order.customer_id <> v_user_id
     AND NOT public.is_admin(v_user_id)
     AND NOT public.has_role('support', v_user_id) THEN
    RAISE EXCEPTION 'Not authorized for this order';
  END IF;

  IF v_order.status <> 'placed' THEN
    RAISE EXCEPTION 'Order can no longer be cancelled by the customer';
  END IF;

  UPDATE public.commerce_orders
  SET status = 'cancelled',
      cancelled_at = now(),
      cancellation_reason = NULLIF(trim(p_reason), '')
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  RETURN v_order;
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_commerce_order(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_commerce_order(uuid, text) TO authenticated;

ALTER TABLE public.commerce_orders REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'commerce_orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.commerce_orders;
  END IF;
END;
$$;

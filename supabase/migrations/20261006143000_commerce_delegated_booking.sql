-- CX1B delegated Food/Groceries commerce ordering.
-- The authenticated Wantok account remains commerce_orders.customer_id
-- and retains payment/cancellation authority. An optional active Trusted
-- person is snapshotted as the order beneficiary/recipient.

ALTER TABLE public.commerce_orders
  ADD COLUMN trusted_person_id uuid
    REFERENCES public.trusted_people(id) ON DELETE SET NULL,
  ADD COLUMN beneficiary_name text,
  ADD COLUMN beneficiary_relationship text,
  ADD COLUMN beneficiary_phone text,
  ADD COLUMN beneficiary_email text;

ALTER TABLE public.commerce_orders
  ADD CONSTRAINT commerce_orders_beneficiary_name_not_blank
  CHECK (
    beneficiary_name IS NULL
    OR NULLIF(trim(beneficiary_name), '') IS NOT NULL
  );

CREATE INDEX commerce_orders_customer_trusted_person_idx
  ON public.commerce_orders (customer_id, trusted_person_id, created_at DESC)
  WHERE trusted_person_id IS NOT NULL;

COMMENT ON COLUMN public.commerce_orders.trusted_person_id IS
  'Optional customer-owned Trusted person selected as order beneficiary. ON DELETE SET NULL while beneficiary snapshot fields preserve history.';

COMMENT ON COLUMN public.commerce_orders.beneficiary_name IS
  'Recipient/collector name snapshot for delegated Food/Groceries orders. NULL means the account holder receives the order.';

CREATE OR REPLACE FUNCTION public.create_commerce_order(
  p_provider_service_id uuid,
  p_items jsonb,
  p_fulfillment_type text DEFAULT 'delivery',
  p_delivery_address text DEFAULT NULL,
  p_delivery_lat double precision DEFAULT NULL,
  p_delivery_lng double precision DEFAULT NULL,
  p_customer_note text DEFAULT NULL,
  p_payment_method text DEFAULT 'cash',
  p_trusted_person_id uuid DEFAULT NULL
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
  v_beneficiary public.trusted_people%ROWTYPE;
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

  IF p_trusted_person_id IS NOT NULL THEN
    SELECT *
    INTO v_beneficiary
    FROM public.trusted_people
    WHERE id = p_trusted_person_id
      AND owner_id = v_user_id
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Trusted person is not available';
    END IF;
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
    payment_status,
    metadata,
    trusted_person_id,
    beneficiary_name,
    beneficiary_relationship,
    beneficiary_phone,
    beneficiary_email
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
    'unpaid',
    jsonb_build_object(
      'source', 'wantok-flutter',
      'booked_for', CASE
        WHEN p_trusted_person_id IS NULL THEN 'self'
        ELSE 'trusted_person'
      END
    ),
    p_trusted_person_id,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.display_name END,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.relationship END,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.phone END,
    CASE WHEN p_trusted_person_id IS NULL THEN NULL ELSE v_beneficiary.email END
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

DROP FUNCTION IF EXISTS public.create_commerce_order(
  uuid, jsonb, text, text, double precision, double precision, text, text
);

REVOKE ALL ON FUNCTION public.create_commerce_order(
  uuid, jsonb, text, text, double precision, double precision, text, text, uuid
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_commerce_order(
  uuid, jsonb, text, text, double precision, double precision, text, text, uuid
) TO authenticated;

-- Bring pre-Phase-2A cases up to the same checklist shape as new cases.
-- Nothing in this migration marks a vendor verified or active.
INSERT INTO public.vendor_verification_checks
 (case_id,requirement_key,requirement_label,requirement_scope)
SELECT c.id,x.key,x.label,x.scope
FROM public.vendor_intake_cases c
JOIN public.service_categories category ON category.id=c.category_id
CROSS JOIN LATERAL (VALUES
 ('company_registration','Company or business registry validation','business',
   c.applicant_kind='business'),
 ('tax_registration','Tax registration and beneficial ownership checks','business',
   c.applicant_kind='business'),
 ('vehicle_registration','Vehicle registration and roadworthiness check','category',
   category.slug ~ '(taxi|ride|transport|delivery|car-hire)'),
 ('driver_licence','Driver licence class and validity review','category',
   category.slug ~ '(taxi|ride|transport|delivery|car-hire)'),
 ('vehicle_insurance','Vehicle insurance and coverage validation','category',
   category.slug ~ '(taxi|ride|transport|delivery|car-hire)'),
 ('food_hygiene','Food premises and hygiene authority review','category',
   category.slug ~ '(food|catering|grocery|restaurant)' AND
   category.slug !~ '(taxi|ride|transport|delivery|car-hire)'),
 ('equipment_safety','Equipment ownership, inspection and safety review','category',
   category.slug ~ '(equipment|machinery|plant-hire)' AND
   category.slug !~ '(taxi|ride|transport|delivery|car-hire|food|catering|grocery|restaurant)'),
 ('professional_scope','Trade, professional or service competency review','category',
   category.slug !~ '(taxi|ride|transport|delivery|car-hire|food|catering|grocery|restaurant|equipment|machinery|plant-hire)'),
 ('local_regulation','Country-specific regulatory policy review pending','jurisdiction',
   c.country_code<>'PG'),
 ('png_local_authority','PNG-specific licensing authority review required','jurisdiction',
   c.country_code='PG')
) AS x(key,label,scope,include)
WHERE x.include
ON CONFLICT (case_id,requirement_key) DO NOTHING;

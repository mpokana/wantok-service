"""Source-level, no-network checks for the narrow EAGLT02 public catalogue gate."""
import unittest
import importlib.util
from pathlib import Path
import sys

GATE=Path(__file__).resolve().parents[1]/"dev"/"cx1_public_category_gateway.py"
spec=importlib.util.spec_from_file_location("cx1_public_catalog",GATE)
m=importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
FIELDS=m.SELECT

class PublicCataloguePolicyTests(unittest.TestCase):
    def q(self, **params):
        return {"select":[FIELDS],"is_active":["eq.true"],**{k:[str(v)] for k,v in params.items()}}

    def test_exact_public_catalogue_allowed(self): self.assertTrue(m.is_valid_query(self.q()))
    def test_sorted_catalogue_allowed(self): self.assertTrue(m.is_valid_query(self.q(order="sort_order.asc,name.asc")))
    def test_small_page_allowed(self): self.assertTrue(m.is_valid_query(self.q(limit="20",offset="0")))
    def test_wildcard_denied(self): self.assertFalse(m.is_valid_query(self.q(select="*")))
    def test_sensitive_extra_denied(self): self.assertFalse(m.is_valid_query(self.q(select=FIELDS+",updated_by")))
    def test_missing_active_denied(self): self.assertFalse(m.is_valid_query({"select":[FIELDS]}))
    def test_inactive_denied(self): self.assertFalse(m.is_valid_query(self.q(is_active="eq.false")))
    def test_unbounded_export_denied(self): self.assertFalse(m.is_valid_query(self.q(limit="999999")))
    def test_unexpected_filter_denied(self): self.assertFalse(m.is_valid_query(self.q(**{"or":"(is_active.eq.false)"})))
    def test_duplicate_filter_denied(self): self.assertFalse(m.is_valid_query({"select":[FIELDS],"is_active":["eq.true","eq.false"]}))
    def test_unknown_order_denied(self): self.assertFalse(m.is_valid_query(self.q(order="id.desc")))
    def test_empty_query_denied(self): self.assertFalse(m.is_valid_query({}))
    def test_permission_shape(self):
        self.assertEqual(m.ROUTE,"/rest/v1/service_categories")
        self.assertEqual(set(m.ORIGINS),{
            "https://eaglt02.tailfb0609.ts.net",
            "https://eaglt02.tailfb0609.ts.net:8443",
        })
        self.assertNotIn("user_id",m.FIELDS)
        self.assertNotIn("updated_by",m.FIELDS)

if __name__=="__main__":
    unittest.main(verbosity=2)

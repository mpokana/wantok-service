"""EAGLT02 CX1 private tailnet PREVIEW: public catalogue read-only allowlist.

Only GET of published active service category fields is allowed. All upstream
requests use local anon credentials; browser-provided Authorization is ignored.
No service role, writes, private user records, admin or sensitive REST routes.
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit, parse_qs, urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[2]
PUB = None  # Runtime local publishable key loaded only when starting the server.
HOST = "http://127.0.0.1:54321"
ROUTE = "/rest/v1/service_categories"
ORIGINS = {"https://eaglt02.tailfb0609.ts.net",
           "https://eaglt02.tailfb0609.ts.net:8443"}
FIELDS = ("id", "slug", "name", "description", "vertical", "booking_mode",
          "icon_key", "is_active", "sort_order", "show_on_home",
          "show_in_services", "image_path")
SELECT = ",".join(FIELDS)
ORDER = {"sort_order.asc,name.asc", "sort_order.asc,name.asc.nullslast",
         "sort_order.asc.nullslast,name.asc.nullslast",
         "sort_order.asc", "name.asc", "sort_order.asc,name.asc.nullsfirst"}

def is_valid_query(query):
    if not query:
        return False
    allowed = {"select", "is_active", "order", "limit", "offset"}
    if not set(query).issubset(allowed):
        return False
    if any(len(vals) != 1 for vals in query.values()):
        return False
    if query.get("select") != [SELECT]:
        return False
    if query.get("is_active") != ["eq.true"]:
        return False
    if "order" in query and query["order"][0] not in ORDER:
        return False
    for key, ceiling in (("limit", 100), ("offset", 10000)):
        if key in query:
            v=query[key][0]
            if not v.isascii() or not v.isdecimal() or len(v) > 5:
                return False
            if int(v) > ceiling or (key == "limit" and int(v) == 0):
                return False
    return True

class PublicCatalogOnly(BaseHTTPRequestHandler):
    server_version="WantokPublicCatalogOnly/1.0"
    sys_version=""
    def log_message(self, *_): pass  # Avoid copying request headers, account info or tokens
    def send_body(self, status, payload=b"", ct="text/plain; charset=utf-8"):
        self.send_response(status)
        self.send_header("Content-Type", ct)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        orig=self.headers.get("Origin")
        if orig in ORIGINS:
            self.send_header("Access-Control-Allow-Origin", orig)
            self.send_header("Vary", "Origin")
        self.end_headers()
        if payload: self.wfile.write(payload)
    def route(self):
        u=urlsplit(self.path)
        return u.path,u.query
    def do_OPTIONS(self):
        p,_=self.route()
        if p != ROUTE: return self.send_body(404)
        orig=self.headers.get("Origin")
        if orig not in ORIGINS: return self.send_body(403)
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin",orig)
        self.send_header("Access-Control-Allow-Methods","GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers","apikey,authorization,content-type,content-profile,accept-profile,x-client-info,range,prefer,x-supabase-api-version")
        self.send_header("Access-Control-Max-Age","120")
        self.send_header("Cache-Control","no-store")
        self.send_header("Vary","Origin")
        self.send_header("Content-Length","0")
        self.end_headers()
    def do_GET(self):
        path,querystr=self.route()
        if path != ROUTE: return self.send_body(404)
        if len(querystr) > 700: return self.send_body(400)
        try: query=parse_qs(querystr,keep_blank_values=True,strict_parsing=True)
        except ValueError: return self.send_body(400)
        if not is_valid_query(query): return self.send_body(400)
        # Ignore client auth, user-id headers, Range and cookies. Always anonymous.
        try:
            upstream=HOST+ROUTE+"?"+urlencode([(k, v[0]) for k,v in query.items()])
            req=Request(upstream,headers={"apikey":PUB,
                         "Authorization":"Bearer "+PUB},method="GET")
            with urlopen(req,timeout=8) as res:
                if res.status!=200:return self.send_body(502)
                body=res.read(300001)
            if len(body)>300000:return self.send_body(502)
            rows=json.loads(body)
            if not isinstance(rows,list) or len(rows)>100:return self.send_body(502)
            # Constrain output independent of upstream projection / RLS.
            safe=[]
            for row in rows:
                if not isinstance(row,dict) or row.get("is_active") is not True:
                    return self.send_body(502)
                if set(row)-set(FIELDS): return self.send_body(502)
                safe.append({name:row.get(name) for name in FIELDS})
            return self.send_body(200,json.dumps(safe,separators=(",",":")).encode("utf8"),
                                  "application/json; charset=utf-8")
        except (HTTPError,ValueError,UnicodeError,TimeoutError,OSError,TypeError):
            return self.send_body(502)
    def do_POST(self):self.send_body(405 if self.route()[0]==ROUTE else 404)
    def do_PUT(self):self.send_body(405 if self.route()[0]==ROUTE else 404)
    def do_PATCH(self):self.send_body(405 if self.route()[0]==ROUTE else 404)
    def do_DELETE(self):self.send_body(405 if self.route()[0]==ROUTE else 404)

if __name__=="__main__":
    config=json.loads((ROOT/"config"/"local.json").read_text(encoding="utf-8-sig"))
    PUB=config.get("SUPABASE_PUBLISHABLE_KEY")
    if not isinstance(PUB,str) or len(PUB)<20:
        raise SystemExit("Local publishable key not available")
    print("CX1 public service category-only GET adapter 127.0.0.1:3304",flush=True)
    ThreadingHTTPServer(("127.0.0.1",3304),PublicCatalogOnly).serve_forever()

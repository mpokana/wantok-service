from urllib.request import Request,urlopen
from urllib.error import HTTPError
from urllib.parse import urlencode
import json
host="http://127.0.0.1:3304"
path="/rest/v1/service_categories"
fields="id,slug,name,description,vertical,booking_mode,icon_key,is_active,sort_order,show_on_home,show_in_services,image_path"
valid={"select":fields,"is_active":"eq.true","order":"sort_order.asc,name.asc"}
flutter_sdk_valid={**valid,"order":"sort_order.asc.nullslast,name.asc.nullslast"}
orig="https://eaglt02.tailfb0609.ts.net:8443"
url=host+path+"?"+urlencode(valid)
cases=[
 ("catalogue", "GET",url,None,orig,200),
 ("flutter_sdk_nullslast_order","GET",host+path+"?"+urlencode(flutter_sdk_valid),None,orig,200),
 ("limited_catalogue","GET",url+"&limit=2",None,orig,200),
 ("allowed_options","OPTIONS",url,None,orig,204),
 ("denied_origin","OPTIONS",url,None,"https://attacker.example",403),
 ("denied_table","GET",host+"/rest/v1/trusted_people",None,orig,404),
 ("denied_audit_writer","POST",host+"/rest/v1/rpc/write_audit_event",b"{}",orig,404),
 ("denied_unauthorised_list","GET",host+path,None,orig,400),
 ("denied_inactive","GET",host+path+"?"+urlencode({**valid,"is_active":"eq.false"}),None,orig,400),
 ("denied_column","GET",host+path+"?"+urlencode({**valid,"select":"*"}),None,orig,400),
 ("denied_sensitive_column","GET",host+path+"?"+urlencode({**valid,"select":fields+",updated_by"}),None,orig,400),
 ("denied_extra_filter","GET",url+"&or=(is_active.eq.false)",None,orig,400),
 ("denied_duplicate","GET",url+"&is_active=eq.false",None,orig,400),
 ("denied_large_limit","GET",url+"&limit=90000",None,orig,400),
 ("denied_write","POST",url,b"{}",orig,405),
 ("denied_bad_path","GET",host+path+"/other?"+urlencode(valid),None,orig,404)
]
for name,verb,url,data,origin,expected in cases:
 headers={"Origin":origin,"Access-Control-Request-Method":"GET",
 "Access-Control-Request-Headers":"apikey,authorization,x-client-info"}
 req=Request(url,method=verb,data=data,headers=headers)
 try:
  with urlopen(req,timeout=9) as resp:
   actual=resp.status; body=resp.read(); cors=resp.headers.get("Access-Control-Allow-Origin")
 except HTTPError as e:
  actual=e.code; body=e.read();cors=e.headers.get("Access-Control-Allow-Origin")
 assert actual==expected,(name,expected,actual,body[:100])
 if name in ("catalogue","flutter_sdk_nullslast_order","limited_catalogue"):
  rows=json.loads(body)
  assert isinstance(rows,list) and all(item.get("is_active") is True and set(item)<=set(fields.split(",")) for item in rows)
  assert cors==origin
  print("PUBLIC_CATEGORY_ROWS",len(rows),"NO_APP_ROW_EXPORTED")
 if name=="denied_origin":assert cors is None
 print("PASS",name,actual)
print("CX1_SAFE_PUBLIC_ROUTE_TEST_PASS",len(cases))

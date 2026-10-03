from pathlib import Path
import urllib.request,urllib.parse,http.cookiejar,os,time
root=Path(os.environ.get('WP_DEV_DIR',str(Path(__file__).resolve().parent)))
settings=dict(line.split('=',1) for line in (root/'.env').read_text().splitlines() if '=' in line)
base='http://127.0.0.1:'+os.environ.get('WP_DEV_PORT',settings.get('WP_DEV_PORT','8080'))
opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()),urllib.request.ProxyHandler({}))
for attempt in range(30):
 try:
  with opener.open(base+'/wp-login.php',timeout=5) as response: break
 except (OSError,urllib.error.URLError):
  if attempt==29: raise
  time.sleep(1)
with opener.open(base+'/',timeout=20) as r:
 html=r.read().decode();assert r.status==200 and '<html' in html
 print('PASS: frontend renders HTML')
with opener.open(base+'/wp-login.php',timeout=20) as r:assert 'user_login' in r.read().decode()
data=urllib.parse.urlencode({'log':(root/'admin-username.txt').read_text().strip(),'pwd':(root/'admin-password.txt').read_text().strip(),'wp-submit':'Log In','redirect_to':base+'/wp-admin/','testcookie':'1'}).encode()
with opener.open(urllib.request.Request(base+'/wp-login.php',data=data),timeout=20) as r:
 html=r.read().decode();assert r.status==200 and 'adminmenu' in html and '/wp-admin/' in r.geturl()
 print('PASS: login succeeds and dashboard renders admin menu')
with opener.open(base+'/wp-admin/post-new.php?post_type=page',timeout=20) as r:
 html=r.read().decode();assert r.status==200 and 'wp-block-editor' in html
 print('PASS: page block editor loads')

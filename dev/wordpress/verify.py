from pathlib import Path
import urllib.request,urllib.parse,http.cookiejar
root=Path('/workspace/wordpress-dev');base='http://127.0.0.1:8080'
opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()),urllib.request.ProxyHandler({}))
with opener.open(base+'/',timeout=20) as r:
 html=r.read().decode();assert r.status==200 and 'DD 開発サイト' in html
 print('PASS: frontend renders site title')
with opener.open(base+'/wp-login.php',timeout=20) as r:assert 'user_login' in r.read().decode()
data=urllib.parse.urlencode({'log':'dd_dev_admin','pwd':(root/'admin-password.txt').read_text().strip(),'wp-submit':'Log In','redirect_to':base+'/wp-admin/','testcookie':'1'}).encode()
with opener.open(urllib.request.Request(base+'/wp-login.php',data=data),timeout=20) as r:
 html=r.read().decode();assert r.status==200 and 'adminmenu' in html and '/wp-admin/' in r.geturl()
 print('PASS: login succeeds and dashboard renders admin menu')
with opener.open(base+'/wp-admin/post-new.php?post_type=page',timeout=20) as r:
 html=r.read().decode();assert r.status==200 and 'wp-block-editor' in html
 print('PASS: page block editor loads')

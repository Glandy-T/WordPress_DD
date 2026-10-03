from pathlib import Path
import os,secrets,subprocess
root=Path(__file__).resolve().parent
settings=dict(line.split('=',1) for line in (root/'.env').read_text().splitlines() if '=' in line)
compose=['docker','compose','--project-directory',str(root),'-f',str(root/'compose.yaml')]
secret=root/'admin-password.txt'
if not secret.exists():
 secret.write_text(secrets.token_urlsafe(32));secret.chmod(0o600)
user=root/'admin-username.txt'
if not user.exists():
 query=b"<?php define('WP_INSTALLING',true); require '/var/www/html/wp-load.php'; if(is_blog_installed()) { $a=get_users(['role'=>'administrator','number'=>1,'orderby'=>'ID']); if(!$a){exit(1);} echo $a[0]->user_login; }"
 existing=subprocess.check_output(compose+['exec','-T','wordpress','php'],cwd=root,input=query).decode().strip()
 user.write_text(existing or ('dev_'+secrets.token_hex(6)));user.chmod(0o600)
environment=os.environ.copy();environment['DD_DEV_PASSWORD']=secret.read_text().strip();environment['DD_DEV_USERNAME']=user.read_text().strip()
environment['DD_DEV_URL']='http://127.0.0.1:'+settings.get('WP_DEV_PORT','8080')
with (root/'bootstrap.php').open('rb') as source:
 subprocess.run(compose+['exec','-T','-e','DD_DEV_PASSWORD','-e','DD_DEV_USERNAME','-e','DD_DEV_URL','wordpress','php'],cwd=root,env=environment,stdin=source,check=True)

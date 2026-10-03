from pathlib import Path
import os,secrets,subprocess
root=Path('/workspace/wordpress-dev')
secret=root/'admin-password.txt'
if not secret.exists():
 secret.write_text(secrets.token_urlsafe(32));secret.chmod(0o600)
environment=os.environ.copy();environment['DD_DEV_PASSWORD']=secret.read_text().strip()
with (root/'bootstrap.php').open('rb') as source:
 subprocess.run(['docker','compose','exec','-T','-e','DD_DEV_PASSWORD','wordpress','php'],cwd=root,env=environment,stdin=source,check=True)

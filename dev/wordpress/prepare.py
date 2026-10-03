from pathlib import Path
import secrets,shutil
source=Path(__file__).resolve().parent
root=Path('/workspace/wordpress-dev');root.mkdir(mode=0o700,parents=True,exist_ok=True)
for name in ['compose.yaml','bootstrap.php','bootstrap.py','verify.py']:
 target=root/name
 if target.exists() and target.read_bytes()!= (source/name).read_bytes():
  raise SystemExit(f'Existing helper differs: {name}; review before replacing')
 if not target.exists():shutil.copyfile(source/name,target)
p=root/'.env'
if not p.exists():
 p.write_text('DB_PASSWORD='+secrets.token_urlsafe(32)+'\nDB_ROOT_PASSWORD='+secrets.token_urlsafe(32)+'\n');p.chmod(0o600)
print('Development files prepared; existing database and credentials preserved')

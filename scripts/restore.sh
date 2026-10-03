#!/usr/bin/env bash
set +x
set -euo pipefail
umask 077
[[ $# == 1 ]] || { echo 'Usage: scripts/restore.sh /path/to/wordpress-backup.tar.gz' >&2; exit 1; }
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
runtime_dir=${WP_DEV_DIR:-/workspace/wordpress-dev}
project=${WP_COMPOSE_PROJECT:-wordpress-dd-dev}
port=${WP_DEV_PORT:-8080}
[[ "$port" =~ ^[0-9]+$ && "$port" -ge 1024 && "$port" -le 65535 ]] || { echo 'Invalid WP_DEV_PORT.' >&2; exit 1; }
[[ ! -e "$runtime_dir/database" && ! -e "$runtime_dir/site" && ! -e "$runtime_dir/.env" ]] || { echo 'Refusing to overwrite an existing site/database/credentials. Choose a fresh WP_DEV_DIR.' >&2; exit 1; }
[[ -z "$(docker ps -aq --filter "label=com.docker.compose.project=$project")" ]] || { echo 'Compose project already exists. Choose a different WP_COMPOSE_PROJECT.' >&2; exit 1; }
mkdir -p "$repo_dir/backups"
staging=$(mktemp -d "$repo_dir/backups/restore-staging-XXXXXX")
trap 'rm -rf -- "$staging"' EXIT
# Only data files are extracted; reject links, traversal, unknown entries and corrupt hashes.
python3 - "$1" "$staging" <<'PY'
import hashlib,json,pathlib,tarfile,sys
archive=pathlib.Path(sys.argv[1]).resolve();out=pathlib.Path(sys.argv[2])
allowed={'database.sql.gz','wp-content.tar.gz','wordpress-version.txt','manifest.json','SHA256SUMS'}
with tarfile.open(archive,'r:gz') as t:
    roots=set()
    for m in t.getmembers():
        p=pathlib.PurePosixPath(m.name)
        if p.is_absolute() or '..' in p.parts or not p.parts:raise SystemExit('Unsafe backup path')
        roots.add(p.parts[0])
        if m.isdir() and len(p.parts)==1:continue
        if not m.isfile() or len(p.parts)!=2 or p.name not in allowed:raise SystemExit('Unexpected backup entry')
        target=out/p.name
        if target.exists():raise SystemExit('Duplicate backup entry')
        with t.extractfile(m) as source,target.open('wb') as dest:
            import shutil;shutil.copyfileobj(source,dest)
    if len(roots)!=1 or {p.name for p in out.iterdir()}!=allowed:raise SystemExit('Incomplete backup')
checks=(out/'SHA256SUMS').read_text().splitlines();seen=set()
for line in checks:
    digest,name=line.split(None,1);name=name.strip()
    if name not in allowed-{'SHA256SUMS'} or name in seen:raise SystemExit('Invalid checksum entry')
    seen.add(name)
    if hashlib.file_digest((out/name).open('rb'),'sha256').hexdigest()!=digest:raise SystemExit('Backup checksum mismatch')
if seen!=allowed-{'SHA256SUMS'}:raise SystemExit('Missing checksum')
manifest=json.loads((out/'manifest.json').read_text())
if manifest.get('format')!=1:raise SystemExit('Unsupported backup format')
# Verify the nested content archive before it can write into the new site.
with tarfile.open(out/'wp-content.tar.gz','r:gz') as t:
    for m in t.getmembers():
        p=pathlib.PurePosixPath(m.name)
        if p.is_absolute() or '..' in p.parts or not p.parts or p.parts[0]!='wp-content' or not (m.isfile() or m.isdir()):raise SystemExit('Unsafe wp-content entry')
PY
python3 - "$runtime_dir" "$repo_dir" "$staging" "$port" "$project" <<'PY'
import json,pathlib,re,secrets,shutil,sys
root=pathlib.Path(sys.argv[1]);repo=pathlib.Path(sys.argv[2]);manifest=json.loads((pathlib.Path(sys.argv[3])/'manifest.json').read_text())
compose=(repo/'dev/wordpress/compose.yaml').read_text()
for service,original in [('db','mariadb:11.4'),('wordpress','wordpress:7.1.2-php8.3-apache')]:
    image=manifest['images'][service]
    if not re.fullmatch(r'(?:docker\.io/)?(?:library/)?'+('mariadb' if service=='db' else 'wordpress')+r'@sha256:[a-f0-9]{64}',image):raise SystemExit('Unsupported image identity')
    compose=compose.replace('image: '+original,'image: '+image)
root.mkdir(parents=True,exist_ok=True)
(root/'compose.yaml').write_text(compose)
(root/'.env').write_text('DB_PASSWORD='+secrets.token_urlsafe(32)+'\nDB_ROOT_PASSWORD='+secrets.token_urlsafe(32)+'\nWP_DEV_PORT='+sys.argv[4]+'\nCOMPOSE_PROJECT_NAME='+sys.argv[5]+'\n')
(root/'.env').chmod(0o600)
for name in ['bootstrap.php','bootstrap.py','verify.py']:shutil.copyfile(repo/'dev/wordpress'/name,root/name)
(root/'admin-password.txt').write_text(secrets.token_urlsafe(32));(root/'admin-password.txt').chmod(0o600)
PY
compose=(docker compose --project-name "$project" --project-directory "$runtime_dir" -f "$runtime_dir/compose.yaml")
"${compose[@]}" pull
"${compose[@]}" up -d --wait db
gzip -dc "$staging/database.sql.gz" | "${compose[@]}" exec -T db sh -c 'export MYSQL_PWD="$MARIADB_ROOT_PASSWORD"; exec mariadb --user=root'
# run creates the official WordPress core/config, using freshly generated DB credentials.
"${compose[@]}" run --rm --no-deps -T --entrypoint docker-ensure-installed.sh wordpress >&2
"${compose[@]}" run --rm --no-deps -T --entrypoint tar wordpress -C /var/www/html -xzf - < "$staging/wp-content.tar.gz"
"${compose[@]}" run --rm --no-deps -T --entrypoint chown wordpress -R www-data:www-data /var/www/html/wp-content
# Restore the original admin identity, but replace its password and invalidate old sessions.
python3 - "$runtime_dir" "$port" "${compose[@]}" <<'PY'
import os,pathlib,subprocess,sys
root=pathlib.Path(sys.argv[1]);env=os.environ.copy();env['DD_RESTORE_PASSWORD']=(root/'admin-password.txt').read_text();env['DD_RESTORE_URL']='http://127.0.0.1:'+sys.argv[2]
php='''<?php
require '/var/www/html/wp-load.php';
$admins=get_users(['role'=>'administrator','number'=>1,'orderby'=>'ID','order'=>'ASC']);
if (!$admins) {fwrite(STDERR,"No administrator in backup\\n");exit(1);}
wp_set_password(getenv('DD_RESTORE_PASSWORD'),$admins[0]->ID);
WP_Session_Tokens::get_instance($admins[0]->ID)->destroy_all();
update_option('siteurl',getenv('DD_RESTORE_URL'));
update_option('home',getenv('DD_RESTORE_URL'));
echo $admins[0]->user_login;
'''
name=subprocess.check_output(sys.argv[3:]+['run','--rm','--no-deps','-T','-e','DD_RESTORE_PASSWORD','-e','DD_RESTORE_URL','--entrypoint','php','wordpress'],input=php.encode(),env=env)
(root/'admin-username.txt').write_bytes(name);(root/'admin-username.txt').chmod(0o600)
PY
"${compose[@]}" up -d --wait
WP_DEV_DIR="$runtime_dir" WP_DEV_PORT="$port" python3 "$runtime_dir/verify.py"
printf 'Restore verified. Runtime directory: %s\nNew login credentials are in private admin-username.txt and admin-password.txt there.\n' "$runtime_dir"

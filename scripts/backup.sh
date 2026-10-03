#!/usr/bin/env bash
set +x
set -euo pipefail
umask 077
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
runtime_dir=${WP_DEV_DIR:-/workspace/wordpress-dev}
project=${WP_COMPOSE_PROJECT:-wordpress-dd-dev}
compose=(docker compose --project-name "$project" --project-directory "$runtime_dir" -f "$runtime_dir/compose.yaml")
[[ -f "$runtime_dir/compose.yaml" && -d "$runtime_dir/site" ]] || { echo 'Development site not found; set WP_DEV_DIR.' >&2; exit 1; }
mkdir -p "$repo_dir/backups"
bundle=$(mktemp -d "$repo_dir/backups/wordpress-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")
restart_site=0
complete=0
cleanup() {
  result=$?
  if (( restart_site )); then "${compose[@]}" start wordpress >&2 || result=1; fi
  if (( ! complete )); then printf 'Incomplete backup retained for diagnosis: %s\n' "$bundle" >&2; fi
  exit "$result"
}
trap cleanup EXIT
if [[ -n "$("${compose[@]}" ps --status running -q wordpress)" ]]; then
  restart_site=1
  "${compose[@]}" stop wordpress >&2
fi
# Database credentials are read inside the container, never passed as CLI values.
"${compose[@]}" exec -T db sh -c 'export MYSQL_PWD="$MARIADB_ROOT_PASSWORD"; exec mariadb-dump --user=root --single-transaction --quick --hex-blob --routines --events --triggers --databases "$MARIADB_DATABASE"' | gzip > "$bundle/database.sql.gz"
"${compose[@]}" run --rm --no-deps -T --entrypoint tar wordpress -C /var/www/html --exclude=wp-config.php --exclude=.env --exclude='.env.*' --exclude='*.pem' --exclude='*.key' -czf - wp-content > "$bundle/wp-content.tar.gz"
"${compose[@]}" run --rm --no-deps -T --entrypoint php wordpress -r 'require "/var/www/html/wp-includes/version.php"; echo $wp_version;' > "$bundle/wordpress-version.txt"
python3 - "$bundle" "$repo_dir" "${compose[@]}" <<'PY'
import datetime,json,pathlib,subprocess,sys
out=pathlib.Path(sys.argv[1]);repo=sys.argv[2];compose=sys.argv[3:]
config=json.loads(subprocess.check_output(compose+['config','--format','json'],text=True))
images={service: config['services'][service]['image'] for service in ['db','wordpress']}
for service,image in images.items():
    digests=json.loads(subprocess.check_output(['docker','image','inspect',image,'--format','{{json .RepoDigests}}'],text=True))
    if not digests:raise SystemExit('Image digest unavailable')
    images[service]=digests[0]
manifest={'format':1,'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'repository_commit':subprocess.check_output(['git','-C',repo,'rev-parse','HEAD'],text=True).strip(),'images':images,'wordpress_version':(out/'wordpress-version.txt').read_text().strip(),'contains':['WordPress database','wp-content'],'excludes':['database server accounts','wp-config.php','.env','local password files'],'sensitive':True}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
PY
(cd "$bundle" && sha256sum database.sql.gz wp-content.tar.gz wordpress-version.txt manifest.json > SHA256SUMS)
# Transfer one file, with the checksums inside it. No credentials are printed.
archive="$bundle.tar.gz"
tar -C "$(dirname "$bundle")" -czf "$archive" "$(basename "$bundle")"
complete=1
printf 'Backup created: %s\nKeep this private and download it outside this cloud environment.\n' "$archive"

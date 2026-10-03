#!/usr/bin/env bash
set +x
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
runtime_dir=${WP_DEV_DIR:-/workspace/wordpress-dev}
project=${WP_COMPOSE_PROJECT:-wordpress-dd-dev}
compose=(docker compose --project-name "$project" --project-directory "$runtime_dir" -f "$runtime_dir/compose.yaml")
# This script targets the development Docker stack, never the school's server.
"${compose[@]}" exec -T wordpress mkdir -p /var/www/html/wp-content/mu-plugins/dd-design /tmp/dd-content
"${compose[@]}" cp "$repo_dir/wordpress/mu-plugins/dd-design.php" wordpress:/var/www/html/wp-content/mu-plugins/dd-design.php
"${compose[@]}" cp "$repo_dir/wordpress/mu-plugins/dd-design/design.css" wordpress:/var/www/html/wp-content/mu-plugins/dd-design/design.css
"${compose[@]}" cp "$repo_dir/wordpress/content/home-wireframe.html" wordpress:/tmp/dd-content/home-wireframe.html
"${compose[@]}" exec -T wordpress chmod 755 /var/www/html/wp-content/mu-plugins/dd-design
"${compose[@]}" cp "$repo_dir/wordpress/content/header.html" wordpress:/tmp/dd-content/header.html
"${compose[@]}" cp "$repo_dir/wordpress/content/footer.html" wordpress:/tmp/dd-content/footer.html
"${compose[@]}" exec -T wordpress chmod 644 /var/www/html/wp-content/mu-plugins/dd-design.php /var/www/html/wp-content/mu-plugins/dd-design/design.css
"${compose[@]}" exec -T wordpress php < "$repo_dir/wordpress/deploy-development.php"

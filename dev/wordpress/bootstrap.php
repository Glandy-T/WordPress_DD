<?php
$_SERVER['HTTP_HOST'] = '127.0.0.1:8080';
$_SERVER['REQUEST_METHOD'] = 'GET';
define('WP_INSTALLING', true);
require '/var/www/html/wp-load.php';
require '/var/www/html/wp-admin/includes/upgrade.php';
if (!is_blog_installed()) {
    $result = wp_install('DD 開発サイト', 'dd_dev_admin', 'development@example.invalid', false, '', getenv('DD_DEV_PASSWORD'));
    if (is_wp_error($result)) { fwrite(STDERR, "Installation failed\n"); exit(1); }
    update_option('timezone_string', 'Asia/Tokyo');
    update_option('blog_public', 0);
    $theme = wp_get_theme('twentytwentyfive');
    if (!$theme->exists()) { fwrite(STDERR, "Required theme missing\n"); exit(1); }
    switch_theme('twentytwentyfive');
}
update_option('siteurl', 'http://127.0.0.1:8080');
update_option('home', 'http://127.0.0.1:8080');
global $wp_version;
echo 'WordPress version: ' . $wp_version . "\n";
echo 'Active theme: ' . get_option('stylesheet') . "\n";
echo 'Site installed: ' . (is_blog_installed() ? 'yes' : 'no') . "\n";

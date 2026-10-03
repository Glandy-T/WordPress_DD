<?php
/**
 * Plugin Name: DD school baseline
 * Description: Public school-page style baseline for the development copy.
 */
add_action('wp_enqueue_scripts', function () {
    if (get_post_meta(get_queried_object_id(), '_dd_design_surface', true) !== 'wireframe') { return; }
    $path = WPMU_PLUGIN_DIR . '/dd-design/design.css';
    wp_enqueue_style('dd-school-baseline', WPMU_PLUGIN_URL . '/dd-design/design.css', [], filemtime($path));
}, 100);

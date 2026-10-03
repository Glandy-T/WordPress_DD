<?php
/**
 * Plugin Name: DD development design surfaces
 * Description: Scoped styles and behavior for the experimental development pages.
 */
add_action('wp_enqueue_scripts', function () {
    $surface = get_post_meta(get_queried_object_id(), '_dd_design_surface', true);
    if (!in_array($surface, ['wireframe', 'grade-prototype'], true)) { return; }
    $directory = WPMU_PLUGIN_DIR . '/dd-design/';
    $url = WPMU_PLUGIN_URL . '/dd-design/';
    wp_enqueue_style('dd-design', $url . 'design.css', [], filemtime($directory . 'design.css'));
    if ($surface === 'grade-prototype') {
        wp_enqueue_script('dd-grade-entry', $url . 'grade-entry.js', [], filemtime($directory . 'grade-entry.js'), true);
    }
});
add_filter('body_class', function ($classes) {
    $surface = get_post_meta(get_queried_object_id(), '_dd_design_surface', true);
    if (in_array($surface, ['wireframe', 'grade-prototype'], true)) {
        $classes[] = 'dd-design-surface';
        $classes[] = 'dd-surface-' . $surface;
    }
    return $classes;
});

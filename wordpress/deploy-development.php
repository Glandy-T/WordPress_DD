<?php
require '/var/www/html/wp-load.php';
if (get_option('blogname') !== 'DD 開発サイト') {
    fwrite(STDERR, "Refusing deployment: expected development site identity\n"); exit(1);
}
$template_slug = 'dd-development-canvas';
$templates = get_posts(['post_type'=>'wp_template','post_status'=>'any','name'=>$template_slug,'posts_per_page'=>1,'tax_query'=>[['taxonomy'=>'wp_theme','field'=>'slug','terms'=>get_stylesheet()]]]);
if ($templates && !get_post_meta($templates[0]->ID, '_dd_design_owned', true)) {
    fwrite(STDERR, "Refusing to overwrite an unowned template\n"); exit(1);
}
$template = wp_insert_post([
    'ID' => $templates ? $templates[0]->ID : 0,
    'post_type'=>'wp_template','post_status'=>'publish','post_name'=>$template_slug,
    'post_title'=>'DD development canvas',
    'post_content'=>file_get_contents('/tmp/dd-content/header.html').'<!-- wp:group {"tagName":"main","layout":{"type":"constrained"}} --><main class="wp-block-group"><!-- wp:post-content {"align":"full","layout":{"type":"constrained"}} /--></main><!-- /wp:group -->'.file_get_contents('/tmp/dd-content/footer.html'),
], true);
if (is_wp_error($template)) {fwrite(STDERR,"Template creation failed\n");exit(1);}
wp_set_object_terms($template, get_stylesheet(), 'wp_theme');
update_post_meta($template, '_dd_design_owned', true);
function dd_save_page($slug, $title, $surface, $content) {
    $existing = get_page_by_path($slug);
    if ($existing && get_post_meta($existing->ID, '_dd_design_surface', true) !== $surface) {
        fwrite(STDERR, "Refusing to overwrite an unowned page\n"); exit(1);
    }
    $id=wp_insert_post(['ID'=>$existing ? $existing->ID : 0,'post_type'=>'page','post_status'=>'publish','post_name'=>$slug,'post_title'=>$title,'post_content'=>wp_slash($content)],true);
    if(is_wp_error($id)) {fwrite(STDERR,"Page creation failed\n");exit(1);}
    update_post_meta($id, '_wp_page_template', 'dd-development-canvas');
    update_post_meta($id, '_dd_design_surface', $surface);
    return $id;
}
$wireframe=dd_save_page('dd-development-wireframe','ホーム構造草稿（開発用）','wireframe',file_get_contents('/tmp/dd-content/home-wireframe.html'));
// Retire the rejected experiment, preserving it privately as a draft only.
$prototype=get_page_by_path('dd-grade-entry-prototype');
if ($prototype && get_post_meta($prototype->ID, '_dd_design_surface', true)==='grade-prototype') {
    wp_update_post(['ID'=>$prototype->ID,'post_status'=>'draft']);
    delete_post_meta($prototype->ID, '_dd_design_surface');
}
update_option('show_on_front','page');
update_option('page_on_front',$wireframe);
echo json_encode(['wireframe_page_id'=>$wireframe,'template_id'=>$template])."\n";

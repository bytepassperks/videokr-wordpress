<?php
$site_url = getenv('WP_SITE_URL') ?: 'https://lifetime.videokr.com';

define('DB_NAME', getenv('WP_DB_NAME') ?: 'wordpress');
define('DB_USER', getenv('WP_DB_USER') ?: 'wp_user');
define('DB_PASSWORD', getenv('WP_DB_PASSWORD') ?: 'wp_local_dev_only');
define('DB_HOST', '127.0.0.1');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

define('AUTH_KEY',         getenv('WP_AUTH_KEY') ?: 'set-WP_AUTH_KEY-env-var');
define('SECURE_AUTH_KEY',  getenv('WP_SECURE_AUTH_KEY') ?: 'set-WP_SECURE_AUTH_KEY-env-var');
define('LOGGED_IN_KEY',    getenv('WP_LOGGED_IN_KEY') ?: 'set-WP_LOGGED_IN_KEY-env-var');
define('NONCE_KEY',        getenv('WP_NONCE_KEY') ?: 'set-WP_NONCE_KEY-env-var');
define('AUTH_SALT',        getenv('WP_AUTH_SALT') ?: 'set-WP_AUTH_SALT-env-var');
define('SECURE_AUTH_SALT', getenv('WP_SECURE_AUTH_SALT') ?: 'set-WP_SECURE_AUTH_SALT-env-var');
define('LOGGED_IN_SALT',   getenv('WP_LOGGED_IN_SALT') ?: 'set-WP_LOGGED_IN_SALT-env-var');
define('NONCE_SALT',       getenv('WP_NONCE_SALT') ?: 'set-WP_NONCE_SALT-env-var');

$table_prefix = 'wp_';

// Force correct protocol and port behind Render's reverse proxy
// Render terminates SSL and forwards to container on port 10000
// Without this fix, WordPress redirects to http://domain:10000/
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = 443;
}
// Also handle cases where X-Forwarded-Proto is not set but we know we're behind proxy
if (isset($_SERVER['HTTP_X_FORWARDED_FOR']) || isset($_SERVER['HTTP_X_FORWARDED_HOST'])) {
    $_SERVER['SERVER_PORT'] = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 443 : 80;
}
// Strip port from HTTP_HOST if present (prevents :10000 in URLs)
if (isset($_SERVER['HTTP_HOST']) && (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) || isset($_SERVER['HTTP_X_FORWARDED_HOST']))) {
    $_SERVER['HTTP_HOST'] = preg_replace('/:\d+$/', '', $_SERVER['HTTP_HOST']);
}

define('WP_ENVIRONMENT_TYPE', 'production');
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);

define('WP_HOME', $site_url);
define('WP_SITEURL', $site_url);

define('WP_CONTENT_DIR', '/data/wp-content');
define('WP_CONTENT_URL', $site_url . '/wp-content');

define('FS_METHOD', 'direct');

if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';

# Videokr WordPress on Render

Standalone WordPress + MariaDB + Apache container for lifetime.videokr.com.
Persistent WordPress content and database data live under `/data`.

Set `WP_SITE_URL`, `WP_DB_PASSWORD`, `WP_ADMIN_USER`, `WP_ADMIN_PASSWORD`, and `WP_ADMIN_EMAIL`.
Set `WP_AUTH_KEY`, `WP_SECURE_AUTH_KEY`, `WP_LOGGED_IN_KEY`, `WP_NONCE_KEY`,
`WP_AUTH_SALT`, `WP_SECURE_AUTH_SALT`, `WP_LOGGED_IN_SALT`, and `WP_NONCE_SALT`.
Optional database overrides are `WP_DB_NAME` and `WP_DB_USER`.

On Render use the Docker runtime, expose port `10000`, and mount a persistent disk at `/data`.
Use at least the Starter plan; free instances have no persistent disk and lose all data.

#!/bin/bash
set -e

DB_NAME="${WP_DB_NAME:-wordpress}"
DB_USER="${WP_DB_USER:-wp_user}"
DB_PASSWORD="${WP_DB_PASSWORD:?WP_DB_PASSWORD is required}"
WP_SITE_URL="${WP_SITE_URL:-https://lifetime.videokr.com}"

mkdir -p /data/wp-content/plugins /data/wp-content/themes /data/wp-content/uploads
mkdir -p /data/mysql /run/mysqld
chown -R mysql:mysql /data/mysql /run/mysqld

escape_sql_string() {
    printf '%s' "$1" | sed "s/'/''/g"
}

DB_NAME_SQL="$(escape_sql_string "$DB_NAME")"
DB_USER_SQL="$(escape_sql_string "$DB_USER")"
DB_PASSWORD_SQL="$(escape_sql_string "$DB_PASSWORD")"

ensure_database() {
    mysql -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`$DB_NAME_SQL\`;
        CREATE USER IF NOT EXISTS '$DB_USER_SQL'@'localhost' IDENTIFIED BY '$DB_PASSWORD_SQL';
        CREATE USER IF NOT EXISTS '$DB_USER_SQL'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD_SQL';
        CREATE USER IF NOT EXISTS '$DB_USER_SQL'@'%' IDENTIFIED BY '$DB_PASSWORD_SQL';
        ALTER USER '$DB_USER_SQL'@'localhost' IDENTIFIED BY '$DB_PASSWORD_SQL';
        ALTER USER '$DB_USER_SQL'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD_SQL';
        ALTER USER '$DB_USER_SQL'@'%' IDENTIFIED BY '$DB_PASSWORD_SQL';
        GRANT ALL PRIVILEGES ON \`$DB_NAME_SQL\`.* TO '$DB_USER_SQL'@'localhost';
        GRANT ALL PRIVILEGES ON \`$DB_NAME_SQL\`.* TO '$DB_USER_SQL'@'127.0.0.1';
        GRANT ALL PRIVILEGES ON \`$DB_NAME_SQL\`.* TO '$DB_USER_SQL'@'%';
        FLUSH PRIVILEGES;
EOSQL
}

if [ ! -d "/data/mysql/mysql" ]; then
    mysql_install_db --datadir=/data/mysql --user=mysql
    mysqld_safe --datadir=/data/mysql &

    for i in $(seq 1 30); do
        if mysqladmin ping --silent 2>/dev/null; then
            break
        fi
        sleep 2
    done

    ensure_database
    mysqladmin -u root shutdown
    sleep 2
fi

if [ ! -f /var/www/html/wp-login.php ]; then
    cp -r /usr/src/wordpress/* /var/www/html/ 2>/dev/null || true
fi

if [ ! -f /data/wp-content/.initialized ]; then
    cp -rn /usr/src/wordpress/wp-content/* /data/wp-content/ 2>/dev/null || true
    touch /data/wp-content/.initialized
fi

cp /usr/src/wordpress/wp-config-render.php /var/www/html/wp-config.php

cat > /var/www/html/.htaccess <<'HTACCESS'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /

# Pass Authorization header to PHP (required for REST API Basic Auth)
RewriteCond %{HTTP:Authorization} ^(.*)
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
HTACCESS

rm -rf /var/www/html/wp-content
ln -sf /data/wp-content /var/www/html/wp-content

chown -R www-data:www-data /data/wp-content /var/www/html

echo "memory_limit = 128M" > /usr/local/etc/php/conf.d/memory-limit.ini
echo "opcache.memory_consumption = 64" >> /usr/local/etc/php/conf.d/memory-limit.ini
echo "opcache.interned_strings_buffer = 8" >> /usr/local/etc/php/conf.d/memory-limit.ini

sed -i 's/Listen 80/Listen 10000/' /etc/apache2/ports.conf
sed -i 's/:80/:10000/' /etc/apache2/sites-available/000-default.conf

sed -i '/<Directory \/var\/www\/html>/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
if ! grep -q "AllowOverride All" /etc/apache2/apache2.conf; then
    echo '<Directory /var/www/html>' >> /etc/apache2/apache2.conf
    echo '    AllowOverride All' >> /etc/apache2/apache2.conf
    echo '    Require all granted' >> /etc/apache2/apache2.conf
    echo '</Directory>' >> /etc/apache2/apache2.conf
fi

mysqld_safe --datadir=/data/mysql &

for i in $(seq 1 30); do
    if mysqladmin ping --silent 2>/dev/null; then
        break
    fi
    sleep 2
done

ensure_database

if ! wp core is-installed --allow-root --path=/var/www/html 2>/dev/null &&
    [ -n "$WP_ADMIN_USER" ] &&
    [ -n "$WP_ADMIN_PASSWORD" ] &&
    [ -n "$WP_ADMIN_EMAIL" ]; then
    wp core install \
        --allow-root \
        --path=/var/www/html \
        --url="$WP_SITE_URL" \
        --title="${WP_SITE_TITLE:-Videokr}" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email
fi

exec apache2-foreground

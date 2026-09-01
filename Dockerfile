FROM wordpress:6.7-php8.3-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server \
    less \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

RUN mkdir -p /data/mysql /data/wp-content /run/mysqld \
    && chown -R mysql:mysql /data/mysql /run/mysqld

COPY mysql-memory.cnf /etc/mysql/mariadb.conf.d/99-memory.cnf
COPY wp-config-render.php /usr/src/wordpress/wp-config-render.php
COPY entrypoint.sh /usr/local/bin/render-entrypoint.sh
RUN chmod +x /usr/local/bin/render-entrypoint.sh

RUN chown -R www-data:www-data /usr/src/wordpress

EXPOSE 10000

ENTRYPOINT ["render-entrypoint.sh"]

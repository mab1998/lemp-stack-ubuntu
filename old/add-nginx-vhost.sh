read -p "Write the host name, eg. google:" HOST;
read -p "Write the 1st level domain name without starting dot (.), eg. com.au:" DOMAIN;

mkdir -p /var/www/vhosts/$HOST.$DOMAIN/web
mkdir -p /var/www/vhosts/$HOST.$DOMAIN/logs
mkdir -p /var/www/vhosts/$HOST.$DOMAIN/ssl

groupadd $HOST
useradd -g $HOST -d /var/www/vhosts/$HOST.$DOMAIN $HOST
passwd $HOST

chown -R $HOST:$HOST /var/www/vhosts/$HOST.$DOMAIN
chmod -R 0775 /var/www/vhosts/$HOST.$DOMAIN

touch /etc/php/7.0/fpm/pool.d/$HOST.$DOMAIN.conf

echo "[$HOST]
user = $HOST
group = $HOST
listen = /run/php/php7.0-fpm-$HOST.sock
listen.owner = www-data
listen.group = www-data
php_admin_value[disable_functions] = exec,passthru,shell_exec,system
php_admin_flag[allow_url_fopen] = off
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
chdir = /" >> /etc/php/7.0/fpm/pool.d/$HOST.$DOMAIN.conf

service php7.0-fpm restart
ps aux | grep $HOST

touch /etc/nginx/sites-available/$HOST.$DOMAIN

echo "server {
    listen 80;

    root /var/www/vhosts/$HOST.$DOMAIN/web;
    index index.php index.html index.htm;

    server_name www.$HOST.$DOMAIN $HOST.$DOMAIN;

    location / {
        try_files $uri $uri/ /index.php?q=$uri&$args;
    }

    access_log /var/www/vhosts/$HOST.$DOMAIN/logs/access.log;
    error_log /var/www/vhosts/$HOST.$DOMAIN/logs/error.log warn;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_intercept_errors on;
        include fastcgi_params;

        astcgi_cache_use_stale error timeout invalid_header http_500;
        fastcgi_cache_key $host$request_uri;
        fastcgi_cache_valid 200 1m;
        fastcgi_cache_bypass $nocache;
        fastcgi_no_cache $nocache;
    }
}" >> /etc/nginx/sites-available/$HOST.$DOMAIN

ln -s /etc/nginx/sites-available/$HOST.$DOMAIN /etc/nginx/sites-enabled/$HOST.$DOMAIN
service nginx restart ; systemctl status nginx.service

rm ./add-vhost.sh
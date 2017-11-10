server {
    listen      %proxy_port%;
    server_name %domain_idn% %alias_idn%;
    
    root        %docroot%;
    index       index.php index.html index.htm;
    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;

    location / { 
        location ~* ^.+\.(jpeg|jpg|png|gif|bmp|ico|svg|css|js)$ {
            expires     max;
        }

        location ~ [^/]\.php(/|$) {
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
                return  404;
            }

            if ($http_cookie ~ (comment_author_.*|wordpress_logged_in.*|wp-postpass_.*)) {
               set $no_cache 1;
            }

            include         /etc/nginx/fastcgi_params;

            fastcgi_index index.php;
            fastcgi_pass  unix:/var/run/vesta-php-fpm-%domain_idn%.sock;
            fastcgi_param SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            fastcgi_intercept_errors on;

            fastcgi_cache_use_stale error timeout invalid_header http_500;
            fastcgi_cache_key $host$request_uri;
            fastcgi_cache site_diskcached;
            fastcgi_cache_valid 200 1m;
            fastcgi_cache_bypass $no_cache;
            fastcgi_no_cache $no_cache;
        }

    }

    error_page  403 /error/404.html;
    error_page  404 /error/404.html;
    error_page  500 502 503 504 /error/50x.html;

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location /vstats/ {
        alias   %home%/%user%/web/%domain%/stats/;
        include %home%/%user%/web/%domain%/stats/auth.conf*;
    }

    include /etc/nginx/location_optmz_php.conf;

    disable_symlinks if_not_owner from=%docroot%;

    include %home%/%user%/web/%domain%/private/*.conf;
    include %home%/%user%/conf/web/nginx.%domain%.conf*;
}

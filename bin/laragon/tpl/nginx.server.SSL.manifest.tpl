server {
    listen <<PORT>>;
    listen <<SSL_PORT>> ssl;
    server_name <<HOSTNAME>> *.<<HOSTNAME>>;
    root "<<PROJECT_DIR>>";
    
    index index.html index.htm index.php;
 
    location / {
        try_files $uri $uri/ /index.php$is_args$args;
		autoindex on;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass php_upstream;		
        #fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }

    # Enable SSL
    ssl_certificate "<<SSL_DIR>>/<<HOSTNAME>>.crt";
    ssl_certificate_key "<<SSL_DIR>>/<<HOSTNAME>>.key";
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;
    ssl_prefer_server_ciphers on;
	
	
    charset utf-8;
	
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    location ~ /\.ht {
        deny all;
    }
}

# This file is auto-generated.
# If you want Laragon to respect your changes, just remove the [auto.] prefix
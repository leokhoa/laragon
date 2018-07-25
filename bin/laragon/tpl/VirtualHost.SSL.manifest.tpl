define ROOT "<<PROJECT_DIR>>"
define SITE "<<HOSTNAME>>"

<VirtualHost *:<<PORT>>> 
    DocumentRoot "${ROOT}"
    ServerName ${SITE}
    ServerAlias *.${SITE}
    <Directory "${ROOT}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:<<SSL_PORT>>>
    DocumentRoot "${ROOT}"
    ServerName ${SITE}
    ServerAlias *.${SITE}
    <Directory "${ROOT}">
        AllowOverride All
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile      <<SSL_DIR>>/<<HOSTNAME>>.crt
    SSLCertificateKeyFile   <<SSL_DIR>>/<<HOSTNAME>>.key
 
</VirtualHost>
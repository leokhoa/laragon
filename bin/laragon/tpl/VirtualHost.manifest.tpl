<VirtualHost *:<<PORT>>> 
    DocumentRoot "<<PROJECT_DIR>>"
    ServerName <<HOSTNAME>>
    ServerAlias *.<<HOSTNAME>>
    <Directory "<<PROJECT_DIR>>">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

# If you want to use SSL, enable it by going to Menu > Apache > SSL > Enabled
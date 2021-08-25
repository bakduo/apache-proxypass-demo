<VirtualHost *:80>

  ServerName example.com
  ServerAlias example.com

  RewriteEngine On
  RewriteCond %{HTTPS} off
  RewriteRule (.*) https://%{SERVER_NAME}/$1 [R,L]

</VirtualHost>


<VirtualHost *:443>

  ServerName example.com
  ServerAlias example.com


  ErrorLog /var/log/httpd/example-error.log
  CustomLog /var/log/httpd/example-access.log combined

  SSLEngine On
  SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
  SSLHonorCipherOrder On
  # HSTS (optional)
  Header always set Strict-Transport-Security "max-age=63072000;includeSubdomains;"
  Header always set X-Frame-Options DENY
  Header set X-Content-Type-Options "nosniff"

  SSLCertificateFile /etc/httpd/ssl/example.crt
  SSLCertificateKeyFile /etc/httpd/ssl/example.key
  SSLCertificateChainFile /etc/httpd/ssl/example.chain

  ProxyPreserveHost On  
  SSLProxyEngine On
  ProxyRequests off
  ProxyVia off

  ProxyPass / https://ip:8443/
  ProxyPassReverse / https://ip:8443/

</VirtualHost>

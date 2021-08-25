Generate template docker instance for apache proxy pass
===============================================================
# Overview

A fin de la ultima vez que pidierón un modo de caso de uso de proxy dejo algo sencillo desde docker para ahorrar una vm en la DEMO.

# Objetivos

- [ ] qué se puede mejorar?
- [ ] existe una alternativa similar?
- [ ] qué pasa con los logs?
- [ ] qué pasa con el monitor?
- [ ] me conviene usar root?
- [ ] qué pasa con los volumen hacen falta?
- [ ] qué me ofrecen los orquestadores?
- [ ] qué detalles vemos en el dockerfile?
- [ ] ....otros


## First step, generate Dockerfile for image template

```
FROM centos:7

MAINTAINER SfJwmy4A_test@oncosmos.com

RUN yum install -y httpd mod_ssl mariadb

RUN mkdir /etc/httpd/ssl && mkdir /etc/httpd/sites-enabled

COPY httpd.conf /etc/httpd/conf/
COPY welcome.conf /etc/httpd/conf.d

COPY run.sh /run.sh

ENV OPTIONS=""

RUN chmod +x /run.sh

VOLUME ["/var/www/html/","/etc/httpd/ssl/","/etc/httpd/sites-enabled/"]

ENTRYPOINT ["./run.sh"]

```

### Edit httpd.conf for config apache

```
ServerTokens ProductOnly
ServerSignature Off
TraceEnable off
#Timeout 1200
Timeout 600
KeepAlive on

IncludeOptional sites-enabled/*.conf

```
### Comment welcome.conf for dont show

```
# This configuration file enables the default "Welcome" page if there
# is no default index page present for the root URL.  To disable the
# Welcome page, comment out all the lines below. 
#
# NOTE: if this file is removed, it will be restored on upgrades.
#
#<LocationMatch "^/+$">
#    Options -Indexes
#    ErrorDocument 403 /.noindex.html
#</LocationMatch>
#
#<Directory /usr/share/httpd/noindex>
#    AllowOverride None
#    Require all granted
#</Directory>
#
#Alias /.noindex.html /usr/share/httpd/noindex/index.html
#Alias /noindex/css/bootstrap.min.css /usr/share/httpd/noindex/css/bootstrap.min.css
#Alias /noindex/css/open-sans.css /usr/share/httpd/noindex/css/open-sans.css
#Alias /images/apache_pb.gif /usr/share/httpd/noindex/images/apache_pb.gif
#Alias /images/poweredby.png /usr/share/httpd/noindex/images/poweredby.png

```

### Run run.sh command for apache

```
#!/bin/bash


/usr/sbin/httpd $OPTIONS -DFOREGROUND

tail -f /var/log/httpd/*log

```


# Second generate yaml for compose

```
version: '3.1'
services: 
    wodpress:
        image: apache-proxypass:nelix
        env_file:
          - ./config/apache.env
        restart: always
        ports: 
          - 80:80
          - 443:443
        volumes:
            - path/sites-enabled/:/etc/httpd/sites-enabled/

```

### now generate compose and copy certificate and sites

Example proxy pass sites

```

<VirtualHost *:80>

  ServerName example.com
  ServerAlias www.example.com

  RewriteEngine On
  RewriteCond %{HTTPS} off
  RewriteRule (.*) https://%{SERVER_NAME}/$1 [R,L]

</VirtualHost>


<VirtualHost *:443>

  ServerName example.com
  ServerAlias www.example.com


  ErrorLog /var/log/httpd/example-error.log
  CustomLog /var/log/httpd/example-access.log combined

  SSLEngine On
  SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
  SSLHonorCipherOrder On
  # HSTS (optional)
  Header always set Strict-Transport-Security "max-age=63072000;includeSubdomains;"
  Header always set X-Frame-Options DENY
  Header set X-Content-Type-Options "nosniff"

  SSLCertificateFile /etc/httpd/ssl/example.com.crt
  SSLCertificateKeyFile /etc/httpd/ssl/example.com.key
  SSLCertificateChainFile /etc/httpd/ssl/example.com.chain

  ProxyPreserveHost On  
  SSLProxyEngine On
  ProxyRequests off
  ProxyVia off

  ProxyPass / https://ip:8443/
  ProxyPassReverse / https://ip:8443/

</VirtualHost>

```

This example for proxy pass of example.com.

#run apache proxy

```
mkdir config

vim ./config/apache.env

OPTIONS=

```
apache-proxy.yml

```
version: '3.8'
services: 
    wodpress:
        image: apache-proxypass:nelix
        env_file:
          - ./config/apache.env
        restart: always
        ports: 
          - 80:80
          - 443:443
        volumes:
            - path/sites-enabled/:/etc/httpd/sites-enabled/

```

check:

```
docker-compose -f apache-proxy.yml config
```

apache run:

```
docker-compose -f apache-proxy.yml up -d

```

when fail container cp certificate:

```

docker cp cert container:/etc/httpd/ssl/
docker cp key container:/etc/httpd/ssl/
docker cp chain container:/etc/httpd/ssl/

docker restart container 

docker stats

```




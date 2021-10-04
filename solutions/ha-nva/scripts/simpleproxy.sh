#!/bin/bash
echo "simpleproxy.sh was run at $(date) with arguments $@"

WEB_LB=$1
WEB_SUBNET=$2

yum upgrade -y --exclude=WALinuxAgent
yum install firewalld -y
systemctl enable firewalld
systemctl start firewalld

yum install httpd -y

if [ "$WEB_LB" != "NONE" ]; then

firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent

echo """<VirtualHost *:80>
  # Logging
  # Reverse proxy configuration
  <Location />
    ProxyPass http://${WEB_LB}:80/
    ProxyPassReverse http://${WEB_LB}:80/
  </Location>
</VirtualHost>
<VirtualHost *:443>
  # Logging
  # Reverse proxy configuration
  <Location />
    ProxyPass http://${WEB_LB}:443/
    ProxyPassReverse http://${WEB_LB}:443/
  </Location>
</VirtualHost>
""" > /etc/httpd/conf.d/reverse.conf
fi;

if [ "$WEB_SUBNET" != "NONE" ]; then

firewall-cmd --zone=public --add-port=8080/tcp --permanent

echo """Listen 8080
<VirtualHost *:8080>
  ProxyRequests On
  ProxyVia On
  ProxyTimeout 300
  <Proxy *>
    Require ip ${WEB_SUBNET}
  </Proxy>
</VirtualHost>
""" > /etc/httpd/conf.d/forward.conf
fi;

firewall-cmd --reload

systemctl enable httpd
systemctl start httpd

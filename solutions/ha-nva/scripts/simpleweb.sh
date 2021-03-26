#!/bin/bash
echo "simpleweb.sh was run at $(date) with arguments $@"

NVA_LB=$1

yum upgrade -y
yum install firewalld -y
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload

yum install httpd -y
echo """<html>
  <body>
    <h2>Test HTTP Server Running on $(curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/name?api-version=2017-08-01&format=text")</h2>
    <h4>For more details on this sample architecture, see
    <a href="https://docs.microsoft.com/azure/architecture/reference-architectures/dmz/nva-ha">Deploy highly available NVAs</a>
    in the Azure Architecture Center.</h4>
  </body>
</html>""" >  /var/www/html/index.html
systemctl enable httpd
systemctl start httpd

if [ "$NVA_LB" != "NONE" ]; then
echo "http_proxy=http://${NVA_LB}:8080/" >> /etc/environment
echo "https_proxy=http://${NVA_LB}:8080/" >> /etc/environment
fi;
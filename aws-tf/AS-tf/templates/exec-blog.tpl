#!/bin/bash
yum update -y
yum install -y httpd
service httpd start
chkconfig httpd on
cd /var/www/html
echo "This is the blog Website `curl http://169.254.169.254/latest/meta-data/public-ipv4`" > index.html

#!/bin/bash

COLLECTOR=$(grep "skywalking-collector" /etc/hosts |awk -F" " '{print $1}')
sed -e "s%\${collector}%${COLLECTOR}%g" /var/nginx/conf.d/nginx.conf > /var/run/nginx.conf

/usr/bin/openresty -c /var/run/nginx.conf
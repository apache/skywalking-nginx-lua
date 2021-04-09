#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

apt update
apt install -y luarocks

luarocks make rockspec/skywalking-nginx-lua-master-0.rockspec

COLLECTOR=$(grep "skywalking-collector" /etc/hosts |awk -F" " '{print $1}')
sed -e "s%\${collector}%${COLLECTOR}%g" /var/nginx/conf.d/nginx.conf > /var/run/nginx.conf

/usr/bin/openresty -c /var/run/nginx.conf

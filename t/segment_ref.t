#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
use Test::Nginx::Socket 'no_plan';

use Cwd qw(cwd);
my $pwd = cwd();

repeat_each(1);
no_long_string();
no_shuffle();
no_root_location();
log_level('info');

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    error_log logs/error.log debug;
    resolver 114.114.114.114 8.8.8.8 ipv6=off;
    lua_shared_dict tracing_buffer 100m;
};

run_tests;

__DATA__

=== TEST 1: fromSW8Value
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local SegmentRef = require('skywalking.segment_ref')
            local ref = SegmentRef.fromSW8Value('1-My40LjU=-MS4yLjM=-4-c2VydmljZQ==-aW5zdGFuY2U=-L2FwcA==-MTI3LjAuMC4xOjgwODA=')
            ngx.say(ref.trace_id)
            ngx.say(ref.segment_id)
            ngx.say(ref.span_id)
            ngx.say(ref.parent_service)
            ngx.say(ref.parent_service_instance)
            ngx.say(ref.parent_endpoint)
            ngx.say(ref.address_used_at_client)
        }
    }
--- request
GET /t
--- response_body
3.4.5
1.2.3
4
service
instance
/app
127.0.0.1:8080
--- no_error_log
[error]



=== TEST 2: Serialize
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local SegmentRef = require('skywalking.segment_ref')
            local ref = SegmentRef.new()
            ref.trace_id = "3.4.5"
            ref.segment_id = "1.2.3"
            ref.span_id = 4
            ref.parent_service = "service"
            ref.parent_service_instance = "instance"
            ref.parent_endpoint = "/app"
            ref.address_used_at_client = "127.0.0.1:8080"
            ngx.say(SegmentRef.serialize(ref))
        }
    }
--- request
GET /t
--- response_body
1-My40LjU=-MS4yLjM=-4-c2VydmljZQ==-aW5zdGFuY2U=-L2FwcA==-MTI3LjAuMC4xOjgwODA=
--- no_error_log
[error]



=== TEST 3: Transform
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local SegmentRef = require('skywalking.segment_ref')
            local cjson = require("cjson")

            local ref = SegmentRef.new()
            ref.trace_id = "3.4.5"
            ref.segment_id = "1.2.3"
            ref.span_id = 4
            ref.parent_service = "service"
            ref.parent_service_instance = "instance"
            ref.parent_endpoint = "/app"
            ref.address_used_at_client = "127.0.0.1:8080"

            local refProtocol = SegmentRef.transform(ref)
            local inJSON = cjson.encode(refProtocol)
            ngx.say(string.len(inJSON) > 0)
        }
    }
--- request
GET /t
--- response_body
true
--- no_error_log
[error]

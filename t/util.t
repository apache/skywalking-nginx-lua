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

=== TEST 1: timestamp
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local util = require('skywalking.util')
            local timestamp = util.timestamp()
            local regex = [[^\d+$]]
            local m = ngx.re.match(timestamp, regex)
            if m and tonumber(m[0]) == timestamp then
                ngx.say("done")
            else
                ngx.say("failed to generate timestamp: ", timestamp)
            end
        }
    }
--- request
GET /t
--- response_body
done
--- no_error_log
[error]



=== TEST 2: newID
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local util = require('skywalking.util')
            local id = util.newID()
            local regex = [[^[0-9a-f]+\-[0-9a-f]+\-[0-9a-f]+\-[0-9a-f]+\-[0-9a-f]+$]]
            local m = ngx.re.match(id, regex)
            if m then
                ngx.say("done")
                return
            end

            regex = [[^\d+.\d+.\d+$]]
            m = ngx.re.match(id, regex)
            if m then
                ngx.say("done")
            else
                ngx.say("failed to generate id: ", id)
            end
        }
    }
--- request
GET /t
--- response_body
done
--- no_error_log
[error]



=== TEST 3: tablepool, use different name
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local util = require('skywalking.util')

            local tab1_name = util.tablepool_fetch("name1", 1, 1)
            local tab1_name2 = util.tablepool_fetch("name2", 1, 1)
            util.tablepool_release()

            local tab2_name = util.tablepool_fetch("name1", 1, 1)
            local tab2_name2 = util.tablepool_fetch("name2", 1, 1)
            util.tablepool_release()

            if tab1_name == tab2_name then
                ngx.say("fetch same table by name1")
            else
                ngx.say("fetch different table by name1")
            end

            if tab1_name2 == tab2_name2 then
                ngx.say("fetch same table by name2")
            else
                ngx.say("fetch different table by name2")
            end
        }
    }
--- request
GET /t
--- response_body
fetch same table by name1
fetch same table by name2
--- no_error_log
[error]



=== TEST 4: tablepool, use default name
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local util = require('skywalking.util')

            local tab1_name = util.tablepool_fetch()
            local tab1_name2 = util.tablepool_fetch()
            util.tablepool_release()

            local tab2_name = util.tablepool_fetch()
            local tab2_name2 = util.tablepool_fetch()
            util.tablepool_release()

            if tab1_name == tab2_name then
                ngx.say("fetch same table by default name[1]")
            else
                ngx.say("fetch different table by default name[1]")
            end

            if tab1_name2 == tab2_name2 then
                ngx.say("fetch same table by default name[2]")
            else
                ngx.say("fetch different table by default name[2]")
            end

            util.tablepool_release()
            util.tablepool_release()
            ngx.say("done")
        }
    }
--- request
GET /t
--- response_body
fetch same table by default name[1]
fetch same table by default name[2]
done
--- no_error_log
[error]



=== TEST 5: tablepool, call `disable_tablepool` to disable tablepool
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local util = require('skywalking.util')

            local tab1 = util.tablepool_fetch()
            util.tablepool_release()

            local tab2 = util.tablepool_fetch()
            util.tablepool_release()

            if tab1 == tab2 then
                ngx.say("enabled tablepool: fetched same tables")
            else
                ngx.say("enabled tablepool: fetched different tables")
            end

            util.disable_tablepool()

            local tab1 = util.tablepool_fetch()
            util.tablepool_release()

            local tab2 = util.tablepool_fetch()
            util.tablepool_release()

            if tab1 == tab2 then
                ngx.say("disable tablepool: fetched same tables")
            else
                ngx.say("disable tablepool: fetched different tables")
            end
        }
    }
--- request
GET /t
--- response_body
enabled tablepool: fetched same tables
disable tablepool: fetched different tables
--- no_error_log
[error]

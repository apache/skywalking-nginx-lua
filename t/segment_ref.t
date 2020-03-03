use Test::Nginx::Socket 'no_plan';

use Cwd qw(cwd);
my $pwd = cwd();

repeat_each(1);
no_long_string();
no_shuffle();
no_root_location();
log_level('info');

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/skywalking/?.lua;;";
    error_log logs/error.log debug;
    resolver 114.114.114.114 8.8.8.8 ipv6=off;
    lua_shared_dict tracing_buffer 100m;
};

run_tests;

__DATA__

=== TEST 1: fromSW6Value
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local SegmentRef = require('segment_ref')
            local ref = SegmentRef.fromSW6Value('1-My40LjU=-MS4yLjM=-4-1-1-IzEyNy4wLjAuMTo4MDgw-Iy9wb3J0YWw=-MTIz')
            ngx.say(ref.trace_id)
            ngx.say(ref.segment_id)
            ngx.say(ref.span_id)
            ngx.say(ref.parent_service_instance_id)
            ngx.say(ref.entry_service_instance_id)
            ngx.say(ref.network_address)
            ngx.say(ref.network_address_id)
            ngx.say(ref.entry_endpoint_name)
            ngx.say(ref.entry_endpoint_id)
            ngx.say(ref.parent_endpoint_name)
            ngx.say(ref.parent_endpoint_id)
        }
    }
--- request
GET /t
--- response_body
345
123
4
1
1
127.0.0.1:8080
0
/portal
0
nil
123
--- no_error_log
[error]



=== TEST 2: Serialize
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local SegmentRef = require('segment_ref')
            local ref = SegmentRef.new()
            ref.trace_id = {3, 4, 5}
            ref.segment_id = {1, 2, 3}
            ref.span_id = 4
            ref.entry_service_instance_id = 1
            ref.parent_service_instance_id = 1
            ref.network_address = "127.0.0.1:8080"
            ref.entry_endpoint_name = "/portal"
            ref.parent_endpoint_id = 123
            ngx.say(SegmentRef.serialize(ref))
        }
    }
--- request
GET /t
--- response_body
1-My40LjU=-MS4yLjM=-4-1-1-IzEyNy4wLjAuMTo4MDgw-Iy9wb3J0YWw=-MTIz
--- no_error_log
[error]



=== TEST 3: Transform
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local SegmentRef = require('segment_ref')
            local cjson = require("cjson")

            local ref = SegmentRef.new()
            ref.trace_id = {3, 4, 5}
            ref.segment_id = {1, 2, 3}
            ref.span_id = 4
            ref.entry_service_instance_id = 1
            ref.parent_service_instance_id = 1
            ref.network_address = "127.0.0.1:8080"
            ref.entry_endpoint_name = "/portal"
            ref.parent_endpoint_id = 123

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

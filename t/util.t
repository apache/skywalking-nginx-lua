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
=== TEST 1: timestamp
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local util = require('util')
            local new_id = util.timestamp()
            local regex = [[\d+]]
            local m = ngx.re.match(new_id, regex)
            if m and tonumber(m[0]) == new_id then
                ngx.say(true)
            else
                ngx.say(false)
            end
        }
    }
--- request
GET /t
--- response_body
true
--- no_error_log
[error]

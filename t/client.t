use Test::Nginx::Socket 'no_plan';

use Cwd qw(cwd);
my $pwd = cwd();

repeat_each(1);
no_long_string();
no_shuffle();
no_root_location();
log_level('info');

add_block_preprocessor(sub {
    my ($block) = @_;

    if (!$block->request) {
        $block->set_value("request", "GET /t");
    }

    if (!$block->no_error_log) {
        $block->set_value("no_error_log", "[error]\n[alert]");
    }

    my $http_config = $block->http_config // '';
    my $default_http_config = <<_EOC_;
    lua_package_path "$pwd/lib/?.lua;;";
    lua_shared_dict tracing_buffer 100m;
    $http_config
_EOC_

    $block->set_value("http_config", $default_http_config);

    my $config = $block->config;
    my $default_config = <<_EOC_;
    $config
    location = /v3/management/reportProperties {
        content_by_lua_block {
            ngx.req.read_body()
            local data = ngx.req.get_body_data()
            if data then
                data = require("cjson.safe").decode(data)
                ngx.log(ngx.WARN, "language: ", data.properties[1].value)
            end
        }
    }

    location = /v3/management/keepAlive {
        content_by_lua_block {
            ngx.log(ngx.WARN, "Go keepAlive")
            ngx.exit(200)
        }
    }
_EOC_

    $block->set_value("config", $default_config);
});

run_tests;

__DATA__

=== TEST 1: start backend timer
--- config
    location /t {
        content_by_lua_block {
            local client = require("skywalking.client")
            client.backendTimerDelay = 0.01
            client:startBackendTimer("http://127.0.0.1:" .. ngx.var.server_port)
            ngx.sleep(0.02)
            ngx.say('ok')
        }
    }
--- response_body
ok
--- error_log
language: lua
Go keepAlive



=== TEST 2: destroy backend timer
--- config
    location /t {
        content_by_lua_block {
            local client = require("skywalking.client")
            client.backendTimerDelay = 0.01
            client:startBackendTimer("http://127.0.0.1:" .. ngx.var.server_port)
            local ok, err = client:destroyBackendTimer()
            ngx.sleep(0.02)
            if not err then
                ngx.say(ok)
            else
                ngx.say(err)
            end
        }
    }
--- response_body
true
--- no_error_log
language: lua
Go keepAlive

# Changes

## 1.0.1

1. fix: allow timer to restart

## 1.0.0

1. Add IgnoreSuffix feature.
2. CI run lua test cases with luajit.
3. Feat support update the peer before requesting outgoing.
4. Use agent-test-tool docker image instead of building from source.
5. Support to try to use `request-id` as `trace-id` when trace context absent.
6. Stop reporting traces after the worker process begins to exit.
7. Fix tag key from `http.status` to `http.status_code`.

## 0.6.0

1. fix: `skywalking_tracer:finish()` will not be called in some case such as upstream timeout.

## 0.5.0

1. Adapt to Kong agent.
2. Correct the version format luarock.

## 0.4.1

1. fix: missing `constants` in the rockspsec.

## 0.4.0

1. Add a global field 'includeHostInEntrySpan', type 'boolean', mark the entrySpan include host/domain.
2. Add destroyBackendTimer to stop reporting metrics.
3. Doc: set random seed in `init_worker` phase.
4. Local cache some variables and reuse them in Lua module. 
5. Enable local cache and use `tablepool` to reuse the temporary table.

## 0.3.0

1. Load the `base64` module in `utils`, different ENV use different library.
2. Add prefix `skywalking`, avoid conflicts with other lua libraries.
3. Chore: only expose the method of setting random seed, it is optional.
4. Coc: use correct code block type.
5. CI: add upstream_status to tag http.status
6. Add `http.status`

## 0.2.0

1. Adapt the new v3 protocol.
2. Implement correlation protocol.
3. Support batch segment report.
4. Fix wrong context carrier endpoint data.
5. Rocks: fixed wrong version of luarocks.
6. Remove first ref variable.
7. Uniform the SpanLayer type name.

## 0.1.0

1. Establish the LUA tracing core.
2. Add the tracer implementation based on Nginx OpenResty.

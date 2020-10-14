# Changes

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

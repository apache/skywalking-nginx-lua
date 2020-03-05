--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
local Util = require('util')
local Base64 = require('dependencies/base64')
local encode_base64 = Base64.encode
local decode_base64 = Base64.decode

if Util.is_ngx_lua then
    encode_base64 = ngx.encode_base64
    decode_base64 = ngx.decode_base64
end

local _M = {}
-- local SegmentRef = {
--     -- There is no multiple-threads scenario in the LUA, no only hard coded as CROSS_PROCESS
--     type = 'CROSS_PROCESS',
--     trace_id,
--     segment_id,
--     span_id,
--     network_address,
--     network_address_id = 0,
--     entry_service_instance_id = 0,
--     parent_service_instance_id = 0,
--     entry_endpoint_name,
--     entry_endpoint_id = 0,
--     parent_endpoint_name,
--     parent_endpoint_id = 0,
-- }

function _M.new()
    return {
        type = 'CROSS_PROCESS',
        network_address_id = 0,
        entry_service_instance_id = 0,
        parent_service_instance_id = 0,
        entry_endpoint_id = 0,
        parent_endpoint_id = 0,
    }
end

-- Deserialize value from the propagated context and initialize the SegmentRef
function _M.fromSW6Value(value)
    local ref = _M.new()

    local parts = Util.split(value, '-')
    if #parts ~= 9 then
        return nil
    end

    ref.trace_id = Util.formatID(decode_base64(parts[2]))
    ref.segment_id = Util.formatID(decode_base64(parts[3]))
    ref.span_id = tonumber(parts[4])
    ref.parent_service_instance_id = tonumber(parts[5])
    ref.entry_service_instance_id = tonumber(parts[6])
    local peerStr = decode_base64(parts[7])
    if string.sub(peerStr, 1, 1) == '#' then
        ref.network_address = string.sub(peerStr, 2)
    else
        ref.network_address_id = tonumber(peerStr)
    end
    local entryEndpointStr = decode_base64(parts[8])
    if string.sub(entryEndpointStr, 1, 1) == '#' then
        ref.entry_endpoint_name = string.sub(entryEndpointStr, 2)
    else
        ref.entry_endpoint_id = tonumber(entryEndpointStr)
    end
    local parentEndpointStr = decode_base64(parts[9])
    if string.sub(parentEndpointStr, 1, 1) == '#' then
        ref.parent_endpoint_name = string.sub(parentEndpointStr, 2)
    else
        ref.parent_endpoint_id = tonumber(parentEndpointStr)
    end

    return ref
end

-- Return string to represent this ref.
function _M.serialize(ref)
    local encodedRef = '1'
    encodedRef = encodedRef .. '-' .. encode_base64(Util.id2String(ref.trace_id))
    encodedRef = encodedRef .. '-' .. encode_base64(Util.id2String(ref.segment_id))
    encodedRef = encodedRef .. '-' .. ref.span_id
    encodedRef = encodedRef .. '-' .. ref.parent_service_instance_id
    encodedRef = encodedRef .. '-' .. ref.entry_service_instance_id

    local networkAddress
    if ref.network_address_id ~= 0 then
        networkAddress = ref.network_address_id .. ''
    else
        networkAddress = '#' .. ref.network_address
    end
    encodedRef = encodedRef .. '-' .. encode_base64(networkAddress)

    local entryEndpoint
    if ref.entry_endpoint_id ~= 0 then
        entryEndpoint = ref.entry_endpoint_id .. ''
    else
        entryEndpoint = '#' .. ref.entry_endpoint_name
    end
    encodedRef = encodedRef .. '-' .. encode_base64(entryEndpoint)

    local parentEndpoint
    if ref.parent_endpoint_id ~= 0 then
        parentEndpoint = ref.parent_endpoint_id .. ''
    else
        parentEndpoint = '#' .. ref.parent_endpoint_name
    end
    encodedRef = encodedRef .. '-' .. encode_base64(parentEndpoint)

    return encodedRef
end

-- Due to nesting relationship inside Segment/Span/TracingContext at the runtime,
-- RefProtocol is created to prepare JSON format serialization.
-- Following SkyWalking official trace protocol v2
-- https://github.com/apache/skywalking-data-collect-protocol/blob/master/language-agent-v2/trace.proto
-- local RefProtocol = {
--     -- Constant in LUA, no cross-thread
--     refType = 'CrossProcess',
--     parentTraceSegmentId,
--     parentSpanId,
--     parentServiceInstanceId,
--     networkAddress,
--     networkAddressId,
--     entryServiceInstanceId,
--     entryEndpoint,
--     entryEndpointId,
--     parentEndpoint,
--     parentEndpointId,
-- }
-- Return RefProtocol
function _M.transform(ref)
    local refBuilder = {}
    refBuilder.refType = 'CrossProcess'
    refBuilder.parentTraceSegmentId = {idParts = ref.segment_id }
    refBuilder.parentSpanId = ref.span_id
    refBuilder.parentServiceInstanceId = ref.parent_service_instance_id
    refBuilder.networkAddress = ref.network_address
    refBuilder.networkAddressId = ref.network_address_id
    refBuilder.entryServiceInstanceId = ref.entry_service_instance_id
    refBuilder.entryEndpoint = ref.entry_endpoint_name
    refBuilder.entryEndpointId = ref.entry_endpoint_id
    refBuilder.parentEndpoint = ref.parent_endpoint_name
    refBuilder.parentEndpointId = ref.parent_endpoint_id
    return refBuilder
end

return _M

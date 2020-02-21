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

local SegmentRef = {
    -- There is no multiple-threads scenario in the LUA, no only hard coded as CROSS_PROCESS
    type = 'CROSS_PROCESS',
    trace_id,
    segment_id,
    span_id,
    network_address,
    network_address_id = 0,
    entry_service_instance_id = 0,
    parent_service_instance_id = 0,
    entry_endpoint_name,
    entry_endpoint_id = 0,
    parent_endpoint_name,
    parent_endpoint_id = 0,
}

function SegmentRef:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    return o
end

-- Deserialize value from the propagated context and initialize the SegmentRef
function SegmentRef:fromSW6Value(value)
    local parts = Util: split(value, '-')
    if #parts ~= 9 then
        return nil
    end

    self.trace_id = Util:formatID(Base64.decode(parts[2]))
    self.segment_id = Util:formatID(Base64.decode(parts[3]))
    self.span_id = tonumber(parts[4])
    self.parent_service_instance_id = tonumber(parts[5])
    self.entry_service_instance_id = tonumber(parts[6])
    local peerStr = Base64.decode(parts[7])
    if string.sub(peerStr, 1, 1) == '#' then
        self.network_address = string.sub(peerStr, 2)
    else
        self.network_address_id = tonumber(peerStr)
    end
    local entryEndpointStr = Base64.decode(parts[8])
    if string.sub(entryEndpointStr, 1, 1) == '#' then
        self.entry_endpoint_name = string.sub(entryEndpointStr, 2)
    else
        self.entry_endpoint_id = tonumber(entryEndpointStr)
    end
    local parentEndpointStr = Base64.decode(parts[9])
    if string.sub(parentEndpointStr, 1, 1) == '#' then
        self.parent_endpoint_name = string.sub(parentEndpointStr, 2)
    else
        self.parent_endpoint_id = tonumber(parentEndpointStr)
    end

    return self
end

-- Return string to represent this ref.
function SegmentRef:serialize()
    local encodedRef = '1'
    encodedRef = encodedRef .. '-' .. Base64.encode(Util:id2String(self.trace_id))
    encodedRef = encodedRef .. '-' .. Base64.encode(Util:id2String(self.segment_id))
    encodedRef = encodedRef .. '-' .. self.span_id
    encodedRef = encodedRef .. '-' .. self.parent_service_instance_id
    encodedRef = encodedRef .. '-' .. self.entry_service_instance_id

    local networkAddress 
    if self.network_address_id ~= 0 then
        networkAddress = self.network_address_id .. ''
    else
        networkAddress = '#' .. self.network_address
    end
    encodedRef = encodedRef .. '-' .. Base64.encode(networkAddress)

    local entryEndpoint
    if self.entry_endpoint_id ~= 0 then
        entryEndpoint = self.entry_endpoint_id .. ''
    else
        entryEndpoint = '#' .. self.entry_endpoint_name
    end
    encodedRef = encodedRef .. '-' .. Base64.encode(entryEndpoint)

    local parentEndpoint
    if self.parent_endpoint_id ~= 0 then
        parentEndpoint = self.parent_endpoint_id .. ''
    else
        parentEndpoint = '#' .. self.parent_endpoint_name
    end
    encodedRef = encodedRef .. '-' .. Base64.encode(parentEndpoint)

    return encodedRef
end

return SegmentRef

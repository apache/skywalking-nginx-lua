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

-- limit define
local ELEMENT_MAX_NUMBER = 3
local VALUE_MAX_LENGTH = 128

local Util = require('skywalking.util')
local encode_base64 = Util.encode_base64
local decode_base64 = Util.decode_base64

local _M = {}

function _M.new()
    return {}
end

-- Deserialze value from the correlation context and initalize the context
function _M.fromSW8Value(value)
    local context = _M.new()

    if value == nil or #value == 0 then
        return context
    end

    local data = Util.split(value, ',')
    if #data == 0 then
        return context
    end

    for i, per_data in ipairs(data)
    do
        if #data > ELEMENT_MAX_NUMBER then
            return context
        end

        local parts = Util.split(per_data, ':')
        if #parts == 2 then
            local key = decode_base64(parts[1])
            local value = decode_base64(parts[2])

            context[key] = value
        end
    end

    return context
end

-- Return string to represent this correlation context
function _M.serialize(context)
    local encoded = ''
    for name, value in pairs(context) do
        if #encoded > 0 then
            encoded = encoded .. ','
        end

        encoded = encoded .. encode_base64(name) .. ':' .. encode_base64(value)
    end

    return encoded
end

-- Put the custom key/value into correlation context.
function _M.put(context, key, value)
    -- key must not null
    if not key then
        return
    end

    -- remove and return previous value when value is empty
    if not value or #value == 0 then
        context[key] = nil
        return
    end

    -- check value length
    if #value > VALUE_MAX_LENGTH then
        return
    end

    -- already contain key, overwrite it
    if context[key] then
        context[key] = value
        return
    end


    -- check keys count
    local contextLength = 0
    for k,v in pairs(context) do
        contextLength = contextLength + 1
    end
    if contextLength >= ELEMENT_MAX_NUMBER then
        return
    end

    -- setting
    context[key] = value
end

return _M

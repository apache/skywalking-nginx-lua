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
local _M = {}

-- for pure Lua
local split = function(str, delimiter)
    local t = {}
    for substr in string.gmatch(str, "[^".. delimiter.. "]*") do
        if substr ~= nil and string.len(substr) > 0 then
            table.insert(t,substr)
        end
    end
    return t
end

local timestamp = function()
    local _, b = math.modf(os.clock())
    if b==0 then
        b='000'
    else
        b=tostring(b):sub(3,5)
    end

    return os.time() * 1000 + b
end

-- for Nginx Lua
local ok, ngx_re = pcall(require, "ngx.re")
if ok then
    split = ngx_re.split
    timestamp = function()
        return ngx.now() * 1000
    end
end

_M.split = split
_M.timestamp = timestamp
_M.is_ngx_lua = ok

local MAX_ID_PART2 = 1000000000
local MAX_ID_PART3 = 100000

local random_seed = function ()
    local seed
    local frandom = io.open("/dev/urandom", "rb")
    if frandom then
        local str = frandom:read(4)
        frandom:close()
        if str then
            local s = 0
            for i = 1, 4 do
                s = 256 * s + str:byte(i)
            end
            seed = s
        end
    end

    if not seed then
        if _M.is_ngx_lua then
            seed = ngx.now() * 1000 + ngx.worker.pid()
        else
            seed = os.clock()
        end
    end

    return seed
end

math.randomseed(random_seed())

function _M.newID()
    return timestamp() .. math.random(0, MAX_ID_PART2) .. math.random(0, MAX_ID_PART3)
end

-- Format a trace/segment id into an array.
-- An official ID should have three parts separated by '.' and each part of it is a number
function _M.formatID(str)
    local regex = '.'
    if _M.is_ngx_lua then
        regex = [[\.]]
    end
    local parts = split(str, regex)
    if #parts ~= 3 then
        return nil
    end

    return parts
end

-- @param id is an array with length = 3
function _M.id2String(id)
    return id[1] .. '.' .. id[2] .. '.' .. id[3]
end

return _M

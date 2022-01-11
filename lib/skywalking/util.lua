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

-- source: https://github.com/apache/apisix/blob/master/apisix/core/string.lua#L18
local type = type
local ffi         = require("ffi")
local C           = ffi.C
local ffi_cast    = ffi.cast
-- source: https://github.com/apache/apisix/blob/master/apisix/core/string.lua#L26
ffi.cdef[[
    int memcmp(const void *s1, const void *s2, size_t n);
]]

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

-- source: https://github.com/apache/apisix/blob/master/apisix/core/string.lua#L58
local has_suffix = function(s, suffix)
    if type(s) ~= "string" or type(suffix) ~= "string" then
        error("unexpected type: s:" .. type(s) .. ", suffix:" .. type(suffix))
    end
    if #s < #suffix then
        return false
    end
    local rc = C.memcmp(ffi_cast("char *", s) + #s - #suffix, suffix, #suffix)
    return rc == 0
end

local checkIgnoreSuffix = function(operationName)
    if _M.ignore_suffix_table ~= nil then
        for _, suffix in ipairs(_M.ignore_suffix_table) do
            if has_suffix(operationName, suffix) then
                return true
            end
        end
    end

    return false
end

local timestamp = function()
    local _, b = math.modf(os.clock())
    if b == 0 then
        b = '000'
    else
        b = tostring(b):sub(3,5)
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
_M.checkIgnoreSuffix = checkIgnoreSuffix


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


_M.set_randomseed = function ()
    math.randomseed(random_seed())
end

_M.set_ignore_suffix=function (ignore_suffix)
    _M.ignore_suffix_table = split(ignore_suffix, ",")
end

local newID
-- for Nginx Lua
local ok, uuid = pcall(require, "resty.jit-uuid")
if ok then
    newID = function()
        return uuid.generate_v4()
    end
else
    newID = function()
        return timestamp() .. '.' .. math.random(0, MAX_ID_PART2) .. '.'
               .. math.random(0, MAX_ID_PART3)
    end
end


_M.newID = newID


if _M.is_ngx_lua then
    _M.encode_base64 = ngx.encode_base64
    _M.decode_base64 = ngx.decode_base64

else
    local Base64 = require('skywalking.dependencies.base64')
    _M.encode_base64 = Base64.encode
    _M.decode_base64 = Base64.decode
end


if _M.is_ngx_lua then
    local tablepool = require("tablepool")
    local clear_tab = require("table.clear")
    local insert_tab = table.insert
    local ngx = ngx
    _M.tablepool_fetch = function(name, narr, nrec)
        narr = narr or 8
        nrec = nrec or 8
        name = name or "sw_default_tab"

        local sw_tab_pool = ngx.ctx.sw_tab_pool
        if not sw_tab_pool then
            sw_tab_pool = tablepool.fetch("sw_tab_pool", 128, 0)
            insert_tab(sw_tab_pool, "sw_tab_pool")
            insert_tab(sw_tab_pool, sw_tab_pool)

            ngx.ctx.sw_tab_pool = sw_tab_pool
        end

        local tab = tablepool.fetch(name, narr, nrec)
        insert_tab(sw_tab_pool, name)
        insert_tab(sw_tab_pool, tab)
        return tab
    end
    _M.tablepool_release = function()
        local sw_tab_pool = ngx.ctx.sw_tab_pool
        if not sw_tab_pool then
            return
        end

        for i = #sw_tab_pool, 1, -2 do
            local name = sw_tab_pool[i - 1]
            local tab = sw_tab_pool[i]
            tablepool.release(name, tab)
            -- ngx.log(ngx.INFO, "release name: ", name, " ", tostring(tab))
        end
        clear_tab(sw_tab_pool)

        ngx.ctx.sw_tab_pool = nil
    end
else
    _M.tablepool_fetch = function () return {} end
    _M.tablepool_release = function () return true end
end


function _M.disable_tablepool()
    _M.tablepool_fetch = function () return {} end
    _M.tablepool_release = function () return true end
end


return _M

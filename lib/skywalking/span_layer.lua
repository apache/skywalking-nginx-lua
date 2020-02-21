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

local Layer = {
    NONE = {name = "NONE", value=0},
    DB = {name = "DB", value=1},
    RPC_FRAMEWORK = {name = "RPC_FRAMEWORK", value=2},
    HTTP = {name = "HTTP", value=3},
    MQ = {name = "MQ", value=4},
    CACHE = {name = "CACHE", value=5},
}

return Layer
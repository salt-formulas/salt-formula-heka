-- Copyright 2017 Mirantis, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local service_name = read_config('service_name') or error('service_name is required')
local msg = {
    Type = 'watchdog',
    Payload = service_name,
}

-- Filter that emits a message at every ticker interval. It is used to check
-- the liveness of the Heka services.
function timer_event(ns)
    inject_message(msg)
end

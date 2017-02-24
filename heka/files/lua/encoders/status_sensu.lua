-- Copyright 2015 Mirantis, Inc.
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
require 'table'
require 'string'

local afd = require 'afd'
local consts = require 'gse_constants'
local lma = require 'lma_utils'

local source_dimension_field
if read_config('sensu_source_dimension_key') then
    source_dimension_field = string.format('Fields[%s]', read_config('sensu_source_dimension_key'))
end

local sensu_ttl = (read_config('sensu_ttl') + 0) or 0

-- mapping GSE statuses to Sensu states
local sensu_state_map = {
    [consts.OKAY]=0,
    [consts.WARN]=1,
    [consts.CRIT]=2,
    [consts.DOWN]=2,
    [consts.UNKW]=2
}

function process_message()

    local data = {}
    local source
    local service_name
    local status = 0
    local alarms = {}
    local msgtype = read_message('Type')

    if msgtype == "heka.sandbox.watchdog" then
        service_name = "watchdog_" .. (read_message('Payload') or 'unknown')
        source = read_message('Fields[hostname]') or read_message('Hostname')
    else
        service_name = read_message('Fields[member]')
        if not service_name then
            return -1, "Service name is missing in Fields[member]"
        end

        status = afd.get_status()
        if not sensu_state_map[status] then
            return -1, "Status <" .. status .. "> is not mapping any Sensu state"
        end

        alarms = afd.alarms_for_human(afd.extract_alarms())

        if msgtype == "heka.sandbox.gse_metric" then
            if source_dimension_field then
                source = read_message(source_dimension_field) or "Unknown source " .. source_dimension_field
            else
                source = "Unknown source"
            end
        elseif msgtype == "heka.sandbox.afd_metric" then
            source = read_message('Fields[hostname]') or read_message('Hostname')
        else
            -- Should not happen since we track only watchdog, AFD and GSE plugins.
            return -1, "message type <" .. msgtype .. "> is not tracked"
        end
    end

    if sensu_ttl > 0 then
        data['ttl'] = sensu_ttl
    end
    data['source'] = source
    data['name'] = service_name
    data['status'] = sensu_state_map[status]

    local details = string.format('%s: ', consts.status_label(status))

    if data['status']  ~= 0 then
      if #alarms == 0 then
          details = details .. 'No details\n'
      else
          for _, alarm in ipairs(alarms) do
              details = details .. alarm .. '\n'
          end
      end
    end

    data['output'] = details

    local payload = lma.safe_json_encode(data)

    if not payload then
       return -1, "Payload failed to be encoded in JSON"
    end

    return lma.safe_inject_payload('json', 'sensu', payload)
end

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

-- mapping GSE statuses to Sensu states
local sensu_state_map = {
    [consts.OKAY]=0,
    [consts.WARN]=1,
    [consts.CRIT]=2,
    [consts.DOWN]=2,
    [consts.UNKW]=2
}

function process_message()

    local data = {
	source = nil,
	name = nil,
	status = nil,
	output = nil,
    }

    local service_name = read_message('Fields[member]')
    local status = afd.get_status()
    local alarms = afd.alarms_for_human(afd.extract_alarms())
    local msgtype = read_message("Type")

    if not service_name or not sensu_state_map[status] or not alarms or not msgtype then
	return -1
    end

    local source
    if msgtype == "heka.sandbox.gse_metric" then
        if source_dimension_field then
            source = read_message(source_dimension_field) or "Unknown Source" 
        else
            source = "Unknown source"
        end
    elseif msgtype == "heka.sandbox.afd_metric" then
        source = read_message('Fields[hostname]') or read_message('Hostname')
    else
        -- Should not happen since we track only AFD and GSE plugins.
        return -1    
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
       return -1
    end

    return lma.safe_inject_payload('json', 'sensu', payload)
end

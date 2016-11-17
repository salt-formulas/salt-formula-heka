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

local cjson = require 'cjson'

local afd = require 'afd'
local gse = require 'gse'
local lma = require 'lma_utils'
local policies = require('gse_policies')

local topology_file = read_config('topology_file') or error('topology_file must be specified!')
local interval = (read_config('interval') or 10) + 0
local interval_in_ns = interval * 1e9
local max_inject = (read_config('max_inject') or 10) + 0
local warm_up_period = ((read_config('warm_up_period') or 0) + 0) * 1e9
local dimensions_json = read_config('dimensions') or ''
local activate_alerting = read_config('activate_alerting') or true

local first_tick
local last_tick = 0
local last_index = nil

local topology = require(topology_file)

for cluster_name, attributes in pairs(topology.clusters) do
    local policy = policies.find(attributes.policy)
    if not policy then
        error('Cannot find ' .. attributes.policy .. ' policy!')
    end
    gse.add_cluster(cluster_name, attributes.members, attributes.hints or {},
        attributes.group_by, policy)
end

local ok, dimensions = pcall(cjson.decode, dimensions_json)
if not ok then
    error(string.format('dimensions JSON is invalid (%s)', dimensions_json))
end

function process_message()

    local member_id = afd.get_entity_name('member')
    if not member_id then
        return -1, "Cannot find entity's name in the AFD/GSE message"
    end

    local status = afd.get_status()
    if not status then
        return -1, "Cannot find status in the AFD/GSE message"
    end

    local alarms = afd.extract_alarms()
    if not alarms then
        return -1, "Cannot find alarms in the AFD/GSE message"
    end

    -- "hostname" is nil here when the input message is a GSE message, so nil
    -- is not an error condition here
    local hostname = afd.get_entity_name('hostname')

    local cluster_ids = gse.find_cluster_memberships(member_id)

    -- update all clusters that depend on this entity
    for _, cluster_id in ipairs(cluster_ids) do
        gse.set_member_status(cluster_id, member_id, status, alarms, hostname)
    end
    return 0
end

function timer_event(ns)
    if not first_tick then
        first_tick = ns
        return
    elseif ns - first_tick <= warm_up_period then
        -- not started for a long enough period
        return
    elseif last_index == nil and (ns - last_tick) < interval_in_ns then
        -- nothing to send it
        return
    end
    last_tick = ns

    local injected = 0
    for i, cluster_name in ipairs(gse.get_ordered_clusters()) do
        if last_index == nil or i > last_index then
            gse.inject_cluster_metric(cluster_name, dimensions, activate_alerting)
            last_index = i
            injected = injected + 1

            if injected >= max_inject then
                return
            end
        end
    end

    last_index = nil
end

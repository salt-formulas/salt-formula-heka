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
local string = require 'string'

local lma = require 'lma_utils'
local consts = require 'gse_constants'

local read_message = read_message
local assert = assert
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local table = table

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

function get_entity_name(field)
    return read_message(string.format('Fields[%s]', field))
end

function get_status()
    return read_message('Fields[value]')
end

function extract_alarms()
    local ok, payload = pcall(cjson.decode, read_message('Payload'))
    if not ok or not payload.alarms then
        return nil
    end
    return payload.alarms
end

-- return a human-readable message from an alarm table
-- for instance: "CPU load too high (WARNING, rule='last(load_midterm)>=5', current=7)"
function get_alarm_for_human(alarm)
    local metric
    local fields = {}
    for name, value in pairs(alarm.fields) do
        fields[#fields+1] = name .. '="' .. value .. '"'
    end
    if #fields > 0 then
        metric = string.format('%s[%s]', alarm.metric, table.concat(fields, ','))
    else
        metric = alarm.metric
    end

    local host = ''
    if alarm.hostname then
        host = string.format(', host=%s', alarm.hostname)
    end

    return string.format(
        "%s (%s, rule='%s(%s)%s%s', current=%.2f%s)",
        alarm.message,
        alarm.severity,
        alarm['function'],
        metric,
        alarm.operator,
        alarm.threshold,
        alarm.value,
        host
    )
end

function alarms_for_human(alarms)
    local alarm_messages = {}
    local hint_messages = {}

    for _, v in ipairs(alarms) do
        if v.tags and v.tags.dependency_level and v.tags.dependency_level == 'hint' then
            hint_messages[#hint_messages+1] = get_alarm_for_human(v)
        else
            alarm_messages[#alarm_messages+1] = get_alarm_for_human(v)
        end
    end

    if #hint_messages > 0 then
        alarm_messages[#alarm_messages+1] = "Other related alarms:"
    end
    for _, v in ipairs(hint_messages) do
        alarm_messages[#alarm_messages+1] = v
    end

    return alarm_messages
end

local alarms = {}

-- append an alarm to the list of pending alarms
-- the list is sent when inject_afd_metric is called
function add_to_alarms(status, fn, metric, fields, tags, operator, value, threshold, window, periods, message)
    local severity = consts.status_label(status)
    assert(severity)
    alarms[#alarms+1] = {
        severity=severity,
        ['function']=fn,
        metric=metric,
        fields=fields or {},
        tags=tags or {},
        operator=operator,
        value=value,
        threshold=threshold,
        window=window or 0,
        periods=periods or 0,
        message=message
    }
end

function get_alarms()
    return alarms
end

function reset_alarms()
    alarms = {}
end

-- inject an AFD event into the Heka pipeline
function inject_afd_metric(value, hostname, afd_name, dimensions,
                           alerting_enabled, notification_enabled,
                           notification_handler)
    local payload

    if #alarms > 0 then
        payload = lma.safe_json_encode({alarms=alarms})
        reset_alarms()
        if not payload then
            return
        end
    else
        -- because cjson encodes empty tables as objects instead of arrays
        payload = '{"alarms":[]}'
    end

    local msg = {
        Type = 'afd_metric',
        Payload = payload,
        Fields = {
            name = 'status',
            value = value,
            hostname = hostname,
            member = afd_name,
            alerting_enabled = alerting_enabled,
            notification_enabled = notification_enabled,
            notification_handler = notification_handler,
            tag_fields = {'member'}
        }
    }
    if hostname then
        table.insert(msg.Fields.tag_fields, hostname)
    end

    for name, value in pairs(dimensions) do
        table.insert(msg.Fields.tag_fields, name)
        msg.Fields[name] = value
    end

    lma.inject_tags(msg)
    lma.safe_inject_message(msg)
end

MATCH = 1
NO_MATCH = 2
NO_DATA = 3
MISSING_DATA = 4


return M

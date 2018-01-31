-- Copyright 2016 Mirantis, Inc.
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
require "table"
local java        = require 'java_patterns'
local l           = require 'lpeg'
local utils       = require 'lma_utils'
local patt        = require 'patterns'
local table_utils = require 'table_utils'

l.locale(l)

local msg = {
    Timestamp   = nil,
    Type        = 'log',
    Hostname    = nil,
    Payload     = nil,
    Pid         = nil,
    Fields      = nil,
    Severity    = 6,
}

local exception_key = nil
local exception_lines = nil

function prepare_message (timestamp, pid, severity_label, payload)
    msg.Timestamp = timestamp
    msg.Pid = pid
    msg.Payload = payload
    msg.Severity = utils.label_to_severity_map[severity_label or 'INFO'] or 6
    msg.Fields = {}
    msg.Fields.severity_label = utils.severity_to_label_map[msg.Severity]
    msg.Fields.programname = 'zookeeper'
end

function process_message ()
    local log = read_message("Payload")
    local logger = read_message("Logger")

    local m = java.ZookeeperLogGrammar:match(log)
    if not m then
        if exception_key == nil then
            return -1, string.format("Failed to parse %s log: %s", logger, string.sub(log, 1, 64))
        else
            table.insert(exception_lines, log)
            return 0
        end
    end

    local key = {
        Timestamp     = m.Timestamp,
        Pid           = m.Pid,
        SeverityLabel = m.SeverityLabel,
    }

    if exception_key ~= nil then
        -- If exception_key is not nil then it means we've started accumulated
        -- lines of a exception. We keep accumulating the exception lines
        -- until we get a different log key.
        if table_utils.table_equal(exception_key, key) then
            table.insert(exception_lines, m.Message)
            return 0
        else
            prepare_message(exception_key.Timestamp, exception_key.Pid,
                exception_key.SeverityLabel, table.concat(exception_lines, ''))
            exception_key = nil
            exception_lines = nil
            utils.inject_tags(msg)
            -- Ignore safe_inject_message status code here to still get a
            -- chance to inject the current log message.
            utils.safe_inject_message(msg)
        end
    end

    if patt.anywhere(patt.exception):match(m.Message) then
        -- Zookeeper exception detected, begin accumulating the lines making
        -- up the exception.
        exception_key = key
        exception_lines = {}
        table.insert(exception_lines, m.Message)
        return 0
    end

    prepare_message(m.Timestamp, m.Pid, m.SeverityLabel, m.Message)
    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end

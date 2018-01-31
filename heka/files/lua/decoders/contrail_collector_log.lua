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
local contrail = require 'contrail_patterns'
local l        = require 'lpeg'
local utils    = require 'lma_utils'
local patt     = require 'patterns'
local table_utils = require 'table_utils'

l.locale(l)

local msg = {
    Timestamp   = nil,
    Type        = 'log',
    Hostname    = nil,
    Payload     = nil,
    Pid         = nil,
    Fields      = nil,
    Severity    = 5,
}

local multiline_key = nil
local multiline_lines = nil

function prepare_message (timestamp, pid, severity_label, payload, programname)
    msg.Timestamp = timestamp
    msg.Pid = pid
    msg.Payload = payload
    msg.Severity = utils.label_to_severity_map[severity_label or "SYS_NOTICE"] or 5
    msg.Fields = {}
    msg.Fields.severity_label = utils.severity_to_label_map[msg.Severity]
    msg.Fields.programname = programname
end

function process_message ()
    local log = read_message("Payload")
    local logger = read_message("Logger")

    local m = contrail.ControlGrammar:match(log)
    if not m then
        if multiline_key == nil then
            return -1, string.format("Failed to parse %s log: %s", logger, string.sub(log, 1, 64))
        else
            table.insert(multiline_lines, log)
            return 0
        end
    end

    local key = {
        Timestamp     = m.Timestamp,
        Pid           = m.Pid,
        SeverityLabel = m.SeverityLabel,
        Programname   = m.Module,
    }

    if multiline_key ~= nil then
        -- If multiline_key is not nil then it means we've started accumulated
        -- lines of a multiline message. We keep accumulating the lines
        -- until we get a different log key.
        if table_utils.table_equal(multiline_key, key) then
            table.insert(multiline_lines, m.Message)
            return 0
        else
            prepare_message(multiline_key.Timestamp, multiline_key.Pid,
                multiline_key.SeverityLabel, table.concat(multiline_lines, ''),
                multiline_key.Programname)
            multiline_key = nil
            multiline_lines = nil
            utils.inject_tags(msg)
            -- Ignore safe_inject_message status code here to still get a
            -- chance to inject the current log message.
            utils.safe_inject_message(msg)
        end
    end

    if patt.anywhere(patt.multiline):match(m.Message) then
        multiline_key = key
        multiline_lines = {}
        table.insert(multiline_lines, m.Message)
        return 0
    end

    prepare_message(m.Timestamp, m.Pid, m.Severity, m.Message, m.Module)
    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end

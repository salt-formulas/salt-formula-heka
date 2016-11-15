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
local dt     = require "date_time"
local l      = require 'lpeg'
l.locale(l)

local patt   = require 'patterns'
local contrail   = require 'contrail_patterns'
local utils  = require 'lma_utils'

local msg = {
    Timestamp   = nil,
    Type        = 'log',
    Hostname    = nil,
    Payload     = nil,
    Pid         = nil,
    Fields      = nil,
    Severity    = 5,
}

function process_message ()
    local log = read_message("Payload")
    local logger = read_message("Logger")
    local m = contrail.ControlGrammar:match(log)
    if not m then
        return -1, string.format("Failed to parse %s log: %s", logger, string.sub(log, 1, 64))
    end
    msg.Timestamp = m.Timestamp
    msg.Payload = m.Message
    msg.Fields = {}
    msg.Pid = m.Pid
    msg.Fields.programname = m.Module
    local severity = m.Severity or "SYS_NOTICE"
    msg.Severity = utils.label_to_severity_map[severity] or 5
    msg.Fields.severity_label = utils.severity_to_label_map[msg.Severity]
    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end

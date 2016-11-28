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
require "string"
local l      = require 'lpeg'
l.locale(l)

local patt   = require 'patterns'
local utils = require "lma_utils"

local msg = {
    Timestamp   = nil,
    Type        = 'log',
    Hostname    = nil,
    Payload     = nil,
    Pid         = nil,
    Fields      = nil,
    Severity    = nil,
}

-- glusterfs log messages are formatted like this
--
-- [2016-11-09 08:31:55.192673] I [socket.c:3480:socket_init] 0-glusterfs: SSL support is NOT enabled
local sp = l.space
local timestamp = l.P'[' * l.Cg(patt.Timestamp, "Timestamp") * l.P']'
local severity = l.Cg(l.R("AZ") / string.upper, "SeverityLabel")
local message = l.Cg(patt.Message, "Message")

local grammar = l.Ct(timestamp * sp * severity * sp * message)


function process_message ()
    local logger, programname = string.match(read_message('Logger'), '^([^.]+)%.(.+)')
    if not logger or not programname then
        return -1, string.format("Failed to parse Logger field: %s", read_message('Logger'))
    end

    local log = read_message("Payload")
    local m = grammar:match(log)
    if not m then
        return -1, string.format("Failed to parse: %s", string.sub(log, 1, 64))
    end

    msg.Logger = logger
    msg.Timestamp = m.Timestamp
    msg.Severity = utils.label_to_severity_map[m.SeverityLabel] or utils.label_to_severity_map.DEBUG
    msg.Payload = m.Message

    msg.Fields = {}
    msg.Fields.severity_label = utils.severity_to_label_map[msg.Severity]
    msg.Fields.programname = programname

    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end


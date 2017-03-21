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
require "string"

local l      = require 'lpeg'
l.locale(l)

local dt     = require "date_time"
local patt   = require 'patterns'
local syslog = require "syslog"
local utils  = require 'lma_utils'

local msg = {
    Timestamp   = nil,
    Type        = 'log',
    Hostname    = nil,
    Payload     = nil,
    Pid         = nil,
    Fields      = {},
    Severity    = 6, -- INFO
}

local syslog_pattern = read_config("syslog_pattern") or error("syslog_pattern configuration must be specified")
local syslog_grammar = syslog.build_rsyslog_grammar(syslog_pattern)

local k8s_severity = l.Cg(l.P'I' + l.P'W' + l.P'E' + l.P'F', 'Severity')
local k8s_time = dt.rfc3339_partial_time
local message = l.Cg(patt.Message, "Message")
local k8s_pattern = l.Ct(k8s_severity * l.xdigit^4 * patt.sp^1 * k8s_time * patt.sp^1 * patt.Pid * patt.sp^1 * message)


function process_message ()
    local log = read_message("Payload")

    if utils.parse_syslog_message(syslog_grammar, log, msg) then
        kube = k8s_pattern:match(msg.Payload)
        if kube then
           msg.Payload = kube.Message
           msg.Severity = utils.label_to_severity_map[kube.Severity] or 6
        end
    else
        msg.Payload = log
    end
    msg.Fields.severity_label = utils.severity_to_label_map[msg.Severity]
    return utils.safe_inject_message(msg)
end


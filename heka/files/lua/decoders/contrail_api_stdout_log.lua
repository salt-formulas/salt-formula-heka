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
require "table"
local l      = require 'lpeg'
l.locale(l)

local patt = require 'patterns'
local contrail = require 'contrail_patterns'
local utils  = require 'lma_utils'

local default_severity = read_config('default_severity') or 'NOTICE'

local msg = {
    Timestamp   = nil,
    Type        = 'log',
    Hostname    = nil,
    Payload     = nil,
    Pid         = nil,
    Fields      = nil,
    Severity    = nil,
}

function process_message ()
    local log = read_message("Payload")
    local logger = read_message("Logger")

    local m

    m = contrail.ApiGrammar:match(log)
    if not m then
        return -1, string.format("Failed to parse %s log: %s", logger, string.sub(log, 1, 64))
    end

    msg.Logger = logger
    msg.Timestamp = m.Timestamp
    msg.Payload = m.Message
    msg.Pid = m.Pid
    msg.Severity = utils.label_to_severity_map[m.Severity or default_severity]
    msg.Fields = {}
    msg.Fields.severity_label = m.Severity or default_severity
    msg.Fields.programname = m.Module
    msg.Fields.http_client_ip_address = m.ip_address

    m = contrail.RequestGrammar:match(msg.Payload)
    if m then
        msg.Fields.http_method = m.http_method
        msg.Fields.http_status = m.http_status
        msg.Fields.http_url = m.http_url
        msg.Fields.http_version = m.http_version
        msg.Fields.http_response_size = m.http_response_size
        msg.Fields.http_response_time = m.http_response_time
    end

    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end

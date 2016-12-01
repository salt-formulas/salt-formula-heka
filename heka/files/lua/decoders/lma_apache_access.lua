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
-- Largely inspired from heka decoder apache_access.lua
local clf = require "common_log_format"
local l = require 'lpeg'
l.locale(l)

local utils  = require 'lma_utils'
local patt = require 'patterns'

local log_format    = read_config("log_format") or error('log_format configuration is missing')
local msg_type      = read_config("type") or 'log'
local uat           = read_config("user_agent_transform")
local uak           = read_config("user_agent_keep")
local uac           = read_config("user_agent_conditional")
local payload_keep  = read_config("payload_keep")

local msg = {
    Timestamp   = nil,
    Type        = msg_type,
    Payload     = nil,
    Fields      = nil,
    Severity    = 6, -- INFO
}

local severity_label = utils.severity_to_label_map[msg.Severity]

local grammar = clf.build_apache_grammar(log_format)
local request_grammar = l.Ct(patt.http_request)

local lma_map_field = {
    request_method = 'http_method',
    response_length = 'http_response_size',
    status = 'http_status',
    server_protocol = 'http_version',
}

function process_message ()
    local log = read_message("Payload")
    local m = grammar:match(log)
    if not m then return -1 end

    msg.Timestamp = m.time
    m.time = nil

    if payload_keep then
        msg.Payload = log
    end

    if m.http_user_agent and uat then
        m.user_agent_browser,
        m.user_agent_version,
        m.user_agent_os = clf.normalize_user_agent(m.http_user_agent)
        if not ((uac and not m.user_agent_browser) or uak) then
            m.http_user_agent = nil
        end
    end

    local fields = {}
    for f, v in pairs(m) do
        if lma_map_field[f] then
            fields[lma_map_field[f]] = v
        else
            fields[f] = v
        end
    end
    if fields.request_time then
        if fields.request_time.representation == 'us' then
            fields.http_response_size = fields.request_time.value / 1e6
        elseif fields.request_time.representation == 'ms' then
            fields.http_response_size = fields.request_time.value / 1e3
        else
            fields.http_response_size = fields.request_time.value
        end
        fields.request_time = nil
    end

    if fields.request then
        m = request_grammar:match(field.request)
        if m then
            msg.Fields.http_method = m.http_method
            msg.Fields.http_url = m.http_url
            msg.Fields.http_version = m.http_version
            fields.request = nil
        end
    end

    if fields.uri then
        fields.http_url = fields.uri
        fields.uri = nil
        if fields.query_string then
            if fields.query_string ~= '' then
                fields.http_url = fields.http_url .. fields.query_string
            end
            fields.query_string = nil
        end
    end

    msg.Fields = fields
    msg.Fields.severity_label = severity_label
    msg.Fields.programname = read_message('Logger')
    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end

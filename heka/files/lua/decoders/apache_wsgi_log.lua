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

local l      = require 'lpeg'
l.locale(l)

local common_log_format = require 'common_log_format'
local patt = require 'patterns'
local utils  = require 'lma_utils'

local logger = read_config("logger") or error("logger configuration must be specificed")
local apache_log_pattern = read_config("apache_log_pattern") or error(
    "apache_log_pattern configuration must be specificed")
local apache_grammar
if string.match(apache_log_pattern, '%%') then
    -- don't parse log format if it's a nickname (eg 'vhost_combined')
    apache_grammar = common_log_format.build_apache_grammar(apache_log_pattern)
end
local request_grammar = l.Ct(patt.http_request)

local msg = {
    Logger      = logger,
    Type        = 'log',
    Severity    = 6,
}
local severity_label = utils.severity_to_label_map[msg.Severity]

function process_message ()
    local logger = read_message("Logger")
    local log = read_message("Payload")

    msg.Fields = {}
    msg.Payload = log
    msg.Fields.programname = logger
    msg.Fields.severity_label = severity_label

    if not apache_grammar then
        utils.inject_tags(msg)
        return utils.safe_inject_message(msg)
    end

    local m = apache_grammar:match(log)
    if m then
        if m.time then
            msg.Timestamp = m.time
        end

        if m.status then
            msg.Fields.http_status = m.status
        end
        if m.request_time then
            msg.Fields.http_response_time = m.request_time.value
            if m.request_time.representation == 'us' then
                -- convert us to sec, otherwise the value is already in sec
                msg.Fields.http_response_time = msg.Fields.http_response_time / 1e6
            end
        end
        if m.http_x_forwarded_for and patt.ip_address:match(m.http_x_forwarded_for) then
            msg.Fields.http_client_ip_address = m.http_x_forwarded_for
        elseif m.remote_addr then
            msg.Fields.http_client_ip_address = m.remote_addr
        end

        local request = m.request
        m = request_grammar:match(request)
        if m then
            msg.Fields.http_method = m.http_method
            msg.Fields.http_url = m.http_url
            msg.Fields.http_version = m.http_version
        end

        utils.inject_tags(msg)
        return utils.safe_inject_message(msg)
    end

    return -1, string.format("Failed to parse %s log: %s", logger, string.sub(log, 1, 64))
end

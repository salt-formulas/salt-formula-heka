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
require 'string'
require 'os'
local lma = require 'lma_utils'


local default_facility = read_config('facility')
if default_facility == nil or (default_facility + 0 < 0 and default_facility + 0 > 23) then
    -- default to local0
    default_facility = 16
end

-- Encodes Heka messages using the RFC5424 Syslog format
-- https://tools.ietf.org/html/rfc5424
-- A line feed is added at the end of the message to avoid truncated messages
-- on the other side.
function process_message()
    local timestamp = os.date("%FT%TZ", read_message('Timestamp') / 1e9)
    local hostname = read_message('Hostname')
    local msg = string.gsub(read_message('Payload'), "\n", "#")
    local pid = read_message('Pid')
    if pid == nil or pid == 0 then
        pid = '-'
    end
    local severity = read_message('Severity') or 7
    local facility = read_message('Fields[syslogfacility]') or default_facility
    local app = read_message('Fields[programname]') or read_message('Logger')

    return lma.safe_inject_payload(
        'txt',
        'syslog',
        string.format("<%d>1 %s %s %s %s - - %s\n", 8 * facility + severity, timestamp, hostname, app, pid, msg)
    )
end

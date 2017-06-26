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

require 'os'
local utils = require 'lma_utils'

local hostname = read_config('hostname') or error('hostname must be specified')
-- The filter can receive messages that should be discarded because they are
-- way too old (Heka cannot guarantee that messages are processed in real-time).
-- The 'grace_interval' parameter allows to define which messages should be
-- kept and which should be discarded. For instance, a value of '10' means that
-- the filter will take into account messages that are at most 10 seconds
-- older than the current time.
local grace_interval = (read_config('grace_interval') or 0) + 0
local metric_source = read_config('source')
local emit_rates = utils.convert_to_bool(read_config('emit_rates'), true)

local msg = {
    Type = "metric", -- will be prefixed by "heka.sandbox."
    Severity = 6,
    Fields = {
        source = metric_source,
        hostname = hostname,
        tag_fields = { 'hostname' }
    }
}
local global_counter = 0
local ticker_counter = 0
local last_timer_event = os.time() * 1e9

function process_message ()
    if utils.convert_to_sec(read_message('Timestamp')) + grace_interval < utils.convert_to_sec(last_timer_event) then
        -- skip the the message if it doesn't fall into the current interval
        return 0
    end

    if string.match(read_message('Payload'), '^Invalid user') then
        global_counter = global_counter + 1
        ticker_counter = ticker_counter + 1
    end

    return 0
end

function timer_event(ns)
    msg.Timestamp = ns
    msg.Fields.name = 'failed_logins_total'
    msg.Fields.value = global_counter
    msg.Fields.type = utils.metric_type['COUNTER']
    utils.inject_tags(msg)
    utils.safe_inject_message(msg)

    if emit_rates then
        msg.Fields.name = 'failed_logins_rate'
        msg.Fields.type = utils.metric_type['DERIVE']
        msg.Fields.value = ticker_counter / ((ns - last_timer_event) / 1e9)
        utils.safe_inject_message(msg)
    end

    ticker_counter = 0
    last_timer_event = ns

    return 0
end

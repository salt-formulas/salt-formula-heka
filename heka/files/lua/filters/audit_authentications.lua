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

require 'os'
local utils = require 'lma_utils'

-- The filter can receive messages that should be discarded because they are
-- way too old (Heka cannot guarantee that messages are processed in real-time).
-- The 'grace_interval' parameter allows to define which messages should be
-- kept and which should be discarded. For instance, a value of '10' means that
-- the filter will take into account messages that are at most 10 seconds
-- older than the current time.
local grace_interval = (read_config('grace_interval') or 0) + 0
local metric_source = read_config('source')

local msg = {
    Type = "multivalue_metric", -- will be prefixed by "heka.sandbox."
    Severity = 6,
}
local global_counters = {
    total=0,
    failed=0,
    success=0,
}
local ticker_counters = {
    total=0,
    failed=0,
    success=0,
}
local last_timer_event = os.time() * 1e9

function process_message ()
    if utils.convert_to_sec(read_message('Timestamp')) + grace_interval < utils.convert_to_sec(last_timer_event) then
        -- skip the the message if it doesn't fall into the current interval
        return 0
    end

    local auth_success
    if read_message('Type') == 'audit' and read_message('Fields[action]') == 'authenticate' then
        auth_success = (read_message('Fields[outcome]') == 'success')
    else
        return 0
    end

    global_counters.total = global_counters.total + 1
    ticker_counters.total = ticker_counters.total + 1
    if auth_success then
        global_counters.success = global_counters.success + 1
        ticker_counters.success = ticker_counters.success + 1
    else
        global_counters.failed = global_counters.failed + 1
        ticker_counters.failed = ticker_counters.failed + 1
    end

    return 0
end

function timer_event(ns)
    msg.Timestamp = ns
    msg.Fields = {
        name = 'authentications_total',
        value_fields = {'all', 'success', 'failed'},
        source = metric_source,
        type = utils.metric_type['COUNTER'],
    }
    utils.inject_tags(msg)

    -- send the counters
    msg.Fields.all = global_counters.total
    msg.Fields.success = global_counters.success
    msg.Fields.failed = global_counters.failed
    utils.safe_inject_message(msg)

    -- send the rates
    msg.Fields.name = 'authentications_rate'
    msg.Fields.type = utils.metric_type['DERIVE']
    local delta_sec = (ns - last_timer_event) / 1e9
    msg.Fields.all = ticker_counters.total / delta_sec
    msg.Fields.success = ticker_counters.success / delta_sec
    msg.Fields.failed = ticker_counters.failed / delta_sec
    utils.safe_inject_message(msg)

    -- send the percentages
    if ticker_counters.total > 0 then
        msg.Fields.name = 'authentications_percent'
        msg.Fields.type = utils.metric_type['GAUGE']
        msg.Fields.value_fields = {'success', 'failed'}
        msg.Fields.all = nil
        msg.Fields.success = 100.0 * ticker_counters.success / ticker_counters.total
        msg.Fields.failed = 100.0 * ticker_counters.failed / ticker_counters.total
        utils.safe_inject_message(msg)
    end

    -- reset the variables
    ticker_counters = {
        total=0,
        failed=0,
        success=0,
    }
    last_timer_event = ns

    return 0
end

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
local utils  = require 'lma_utils'

local tonumber = tonumber

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local function to_secfrac (num)
    return tonumber(num) / 1000
end

local sp = patt.sp
local spaces = patt.sp^1
local pgname = patt.programname
local delimeter = l.P": "
local message   = l.Cg(patt.Message / utils.chomp, "Message")
local severity  = l.Cg(pgname, "Severity")

-- Common patterns
local modulename =  l.Cg(pgname, "Module")
local ip_address = l.Cg((l.digit + patt.dot)^1, "ip_address")
local http_status = l.Cg(patt.Number / tonumber, "http_status")
local http_response_size = l.Cg(patt.Number, "http_response_size")
local http_response_time = l.Cg(patt.Number, "http_response_time")

local delim = (patt.sp + patt.dash)^1
local hostname = l.Cg(patt.programname, "Hostname")
local process_info = l.P"[" * "Thread" * sp * l.Cg(l.digit^1, "ThreadId") *
                     ", " * "Pid" * sp * l.Cg(l.digit^1, "Pid") * "]"

-- Timestamp patterns
-- 10/31/2016 03:40:47 AM [contrail-alarm-gen]: blabla
local log_num_month_timestamp = l.Cg(dt.build_strftime_grammar("%m/%d/%Y %r") / dt.time_to_ns, "Timestamp")
local log_short_str_month_timestamp = l.Cg(dt.build_strftime_grammar("%b/%d/%Y %r") / dt.time_to_ns, "Timestamp")
local log_full_str_month_timestamp = l.Cg(dt.build_strftime_grammar("%B/%d/%Y %r") / dt.time_to_ns, "Timestamp")
local log_timestamp = l.Ct(log_num_month_timestamp + log_short_str_month_timestamp + log_full_str_month_timestamp)

-- 172.16.10.101 - - [2016-10-31 12:50:36] "POST /subscribe HTTP/1.1" 200 715 0.058196
local api_timestamp = l.Cg(patt.Timestamp, "Timestamp")

-- 2016-10-27 Thu 17:50:37:633.908 CEST  ctl01 [Thread 140024858027968, Pid 23338]: DnsAgent [SYS_INFO]: blabla
local timezone = dt.timezone + l.P"CET" * l.Cg(l.Cc"+", "offset_sign") *
                 l.Cg(l.Cc"01" / tonumber, "offset_hour") * l.Cg(l.Cc"00"/ tonumber, "offset_min")
local day_of_week = l.Cg(l.P"Mon" + l.P"Tue" + l.P"Wed" + l.P"Thu" +
                         l.P"Fri" + l.P"Sat" + l.P"Sun", "day_of_week")
local secfrac_grammar = l.Cg((l.digit^1 * patt.dot * l.digit^1) / to_secfrac, "sec_frac")
local ts_grammar = l.Ct(dt.rfc3339_full_date * patt.sp * day_of_week * sp *
                        dt.rfc3339_partial_time * ":" * secfrac_grammar * sp * timezone)
local control_timestamp = l.Cg(ts_grammar / dt.time_to_ns, "Timestamp")

-- Complete grammars
-- 10/31/2016 03:40:47 AM [contrail-alarm-gen]: blabla
LogGrammar = l.Ct(log_timestamp * patt.sp * "[" * modulename * "]:" * patt.sp * message)
-- wokeup and found a line
-- NoSuchProcess: process name:cassandra pid:22192
-- Exception AssertionError: AssertionError() in <module 'threading' from '/usr/lib/python2.7/threading.pyc'> ignored
-- ...
GenericGrammar = l.Ct(message)

-- 172.16.10.101 - - [2016-10-31 12:50:36] "POST /subscribe HTTP/1.1" 200 715 0.058196
ApiGrammar = l.Ct(ip_address * delim * "["* api_timestamp * "]" * sp * message)
RequestGrammar = l.Ct(l.P'"' * patt.http_request * l.P'"' * sp * http_status * sp * http_response_size * sp * http_response_time)

-- 2016-10-27 Thu 17:50:37:633.908 CEST  ctl01 [Thread 140024858027968, Pid 23338]: DnsAgent [SYS_INFO]: blabla
-- 2016-11-01 Tue 05:24:26:590.824 CET  ctl01 [Thread 140310906029824, Pid 18319]: SANDESH: blabla
ControlGrammar = l.Ct(control_timestamp * spaces * hostname * sp * process_info * l.P": " *
					   modulename * (sp * "[" * severity * "]")^-1 * l.P": "^-1 * message)

return M

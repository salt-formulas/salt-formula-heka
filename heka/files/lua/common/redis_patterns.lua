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
local os     = require 'os'
l.locale(l)

local patt   = require 'patterns'
local utils  = require 'lma_utils'

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

-- Redis logs do not provide year in output
local function extend_date (t)
    if t['year'] == nil then
       t['year'] = os.date("*t").year
    end
    return dt.time_to_ns(t)
end

local message   = l.Cg(patt.Message / utils.chomp, "Message")

-- Common patterns
local delim = (l.P"#" + l.P"*")^1

-- [11633 | signal handler] (1479710114) Received SIGTERM, scheduling shutdown...
-- value between parenthesis is timestamp

-- [11633] 21 Nov 06:35:14.648 [#*] blabla
local redis_pid = l.P"[" * l.Cg(l.digit^1, "Pid") * l.P"]"
local redis_sig_pid = l.P"[" * l.Cg(l.digit^1, "Pid") * patt.sp * l.P"| signal handler]"

-- Timestamp patterns
-- [11633] 21 Nov 06:35:14.648 [#*] blabla
local ts_grammar = l.Ct(dt.date_mday * patt.sp * dt.date_mabbr * patt.sp * dt.rfc3339_partial_time)
local redis_sig_timestamp = l.Cg(dt.build_strftime_grammar("(%s)") / dt.time_to_ns, "Timestamp")
local redis_std_timestamp = l.Cg(ts_grammar / extend_date, "Timestamp")

-- Complete grammars
-- [11633] 21 Nov 06:35:00.925 [#*] blabla
-- [11633 | signal handler] (1479710114) Received SIGTERM, scheduling shutdown...
std_grammar = l.Ct(redis_pid * patt.sp * redis_std_timestamp * patt.sp * delim * patt.sp * message)
sig_grammar = l.Ct(redis_sig_pid * patt.sp * redis_sig_timestamp * patt.sp * message)
LogGrammar = std_grammar + sig_grammar

return M

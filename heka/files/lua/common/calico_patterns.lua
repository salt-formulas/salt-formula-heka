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

local patt   = require 'patterns'

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local goid      = l.Cg(patt.Pid, "GoId")
local goline    = l.Cg(patt.Pid, "GoLine")
local goprog    = l.Cg(patt.programname, "GoProg")
local hostname  = l.Cg(patt.programname, "Hostname")
local message   = l.Cg(patt.Message, "Message")
local severity  = l.Cg(patt.SeverityLabel, "SeverityLabel")
local timestamp = l.Cg(patt.Timestamp, "Timestamp")

-- Complete grammars

-- Felix
-- 2017-02-28 12:01:36.300 [INFO][96] table.go 416: Loading current iptables state and checking it is correct. ipVersion=0x4 table="raw"
local FelixLogGrammar = l.Ct(timestamp * patt.sp^1 * "[" * severity * l.P"][" * goid * l.P"]" * patt.sp^1 * goprog * patt.sp^1 * goline * ":" * patt.sp^1 * message)

-- Confd
-- 2017-02-28T09:57:11Z cmp01 confd[92]: DEBUG Retrieving keys from store
local ConfdLogGrammar = l.Ct(timestamp * patt.sp^1 * hostname * patt.sp^1 * l.P"confd[" * goid * l.P"]:" * patt.sp^1 * severity * patt.sp^1 * message)

-- Bird
-- 2017-02-28_09:57:11.84304 bird: device1: State changed to feed
local BirdLogGrammar = l.Ct(timestamp * patt.sp^1 * l.P"bird:" * patt.sp^1 * message)

patterns = {
    felix = FelixLogGrammar,
    bird = BirdLogGrammar,
    confd = ConfdLogGrammar,
}

return M

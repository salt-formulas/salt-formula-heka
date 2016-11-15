-- Copyright 2015-2016 Mirantis, Inc.
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

local gse_policy = require 'gse_policy'

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local policies = {
{%- for _policy_name, _policy in policy|dictsort %}
    ['{{ _policy_name|replace("'", "\\'") }}'] = {
    {%- for _policy_rule in _policy %}
        gse_policy.new({
            status = '{{ _policy_rule["status"] }}',
        {%- set _trigger = _policy_rule.get("trigger") %}
        {%- if _trigger %}
            trigger = {
                logical_operator = '{{ _trigger["logical_operator"] }}',
                rules = {
            {%- for _rule in _trigger["rules"] %}
                    {
                        ['function'] = '{{ _rule["function"] }}',
                {%- set comma = joiner(",") %}
                        ['arguments'] = {
                {%- for _argument in _rule["arguments"]|sort -%}
                    {{ comma() }}'{{ _argument }}'
                {%- endfor -%}
                        },
                        ['relational_operator'] = '{{ _rule["relational_operator"] }}',
                        ['threshold'] = {{ _rule["threshold"] }},
                    },
            {%- endfor %}
                },
            },
        {%- endif %}
        }),
    {%- endfor %}
    },
{%- endfor %}
}

function find(policy)
    return policies[policy]
end

return M

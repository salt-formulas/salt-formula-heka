local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local alarms = {
{%- for _trigger_name in alarm.triggers %}
{%- set _trigger = trigger.get(_trigger_name) %}
{%- if _trigger and _trigger.get('enabled', True) %}
  {
    ['name'] = '{{ _trigger_name}}',
    ['description'] = '{{ _trigger.get("description", "").replace("'", "\\'") }}',
    ['severity'] = '{{ _trigger.severity }}',
    {%- if _trigger.no_data_policy is defined %}
    ['no_data_policy'] = '{{ _trigger.no_data_policy }}',
    {%- endif %}
    ['trigger'] = {
      ['logical_operator'] = '{{ _trigger.get("logical_operator", "or") }}',
      ['rules'] = {
        {%- for _rule in _trigger.get('rules', []) %}
        {
          ['metric'] = '{{ _rule.metric }}',
          ['fields'] = {
            {%- for _field_name, _field_value in _rule.get('field', {}).iteritems() %}
            ['{{ _field_name }}'] = '{{ _field_value }}',
            {%- endfor %}
          },
          ['relational_operator'] = '{{ _rule.relational_operator }}',
          ['threshold'] = '{{ _rule.threshold }}',
          ['window'] = '{{ _rule.window }}',
          ['periods'] = '{{ _rule.get('periods', 0) }}',
          ['function'] = '{{ _rule.function }}',
          {%- if _rule.group_by is defined %}
          ['group_by'] = {
            {%- for _group_by in _rule.group_by %}
            '{{ _group_by }}',
            {%- endfor %}
          },
          {%- endif %}
        },
        {%- endfor %}
      },
    },
  },
{%- endif %}
{%- endfor %}
}

return alarms

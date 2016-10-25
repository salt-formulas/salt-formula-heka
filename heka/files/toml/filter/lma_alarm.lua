local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local alarms = {
{%- for trigger_name, trigger in alarm.triggers.iteritems() %}
{%- if trigger.get('enabled', True) %}
  {
    ['name'] = '{{ alarm_name }}',
    ['description'] = '{{ alarm.get("description", "").replace("'", "\\'") }}',
    ['severity'] = '{{ alarm.severity }}',
    {%- if alarm.no_data_policy is defined %}
    ['no_data_policy'] = '{{ alarm.no_data_policy }}',
    {%- endif %}
    ['trigger'] = {
      ['logical_operator'] = '{{ alarm.get("logical_operator", "or") }}',
      ['rules'] = {
        {%- for rule in trigger.rules %}
        {
          ['metric'] = '{{ rule.metric }}',
          ['fields'] = {
            {%- for dimension_name, dimension_value in rule.dimension.iteritems() %}
            ['{{ dimension_name }}'] = '{{ dimension_value }}',
            {%- endfor %}
          },
          ['relational_operator'] = '{{ rule.relational_operator }}',
          ['threshold'] = '{{ rule.threshold }}',
          ['window'] = '{{ rule.window }}',
          ['periods'] = '{{ rule.get('periods', 0) }}',
          ['function'] = '{{ rule.function }}',
          ['group_by'] = {
            {%- for group_by in rule.group_by %}
            {{ group_by }},
            {%- endfor %}
          },
        },
        {%- endfor %}
      },
    },
  },
{%- endif %}
{%- endfor %}
}

return alarms
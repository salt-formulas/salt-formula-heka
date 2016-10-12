{%- if pillar.heka.log_collector is defined %}

include:
- heka._common

{%- include "heka/_service.sls" %}

{%- service_config('log_collector') %}

{%- endif %}

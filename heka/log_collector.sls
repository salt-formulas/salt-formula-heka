{%- if pillar.heka.log_collector is defined %}

include:
- heka._common

{%- set service_name = "log_collector" %}

{%- include "heka/_service.sls" %}

{%- endif %}

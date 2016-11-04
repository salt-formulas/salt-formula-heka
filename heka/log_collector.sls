{%- if pillar.heka.log_collector is defined %}

{%- set service_name = "log_collector" %}

{%- include "heka/_service.sls" %}

{%- endif %}

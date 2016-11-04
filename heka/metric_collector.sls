{%- if pillar.heka.metric_collector is defined %}

{%- set service_name = "metric_collector" %}

{%- include "heka/_service.sls" %}

{%- endif %}

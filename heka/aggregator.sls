{%- if pillar.heka.aggregator is defined %}

{%- set service_name = "aggregator" %}

{%- include "heka/_service.sls" %}

{%- endif %}

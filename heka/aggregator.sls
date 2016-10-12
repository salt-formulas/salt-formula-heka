{%- if pillar.heka.aggregator is defined %}

include:
- heka._common

{%- set service_name = "aggregator" %}

{%- include "heka/_service.sls" %}

{%- endif %}

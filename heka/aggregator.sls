{%- if pillar.heka.aggregator is defined %}

include:
- heka._common

{%- include "heka/_service.sls" %}

{%- service_config('aggregator') %}

{%- endif %}

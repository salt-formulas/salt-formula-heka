{%- if pillar.heka.remote_collector is defined %}

include:
- heka._common

{%- include "heka/_service.sls" %}

{%- service_config('remote_collector') %}

{%- endif %}

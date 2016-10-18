{%- if pillar.heka.log_collector is defined %}

include:
- heka._common

{% from "heka/_service.sls" import service_config with context %}

{{ service_config('log_collector') }}

{%- endif %}

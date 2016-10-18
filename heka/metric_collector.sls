{%- if pillar.heka.metric_collector is defined %}

include:
- heka._common

{% from "heka/_service.sls" import service_config with context %}

{{ service_config('metric_collector') }}

{%- endif %}
